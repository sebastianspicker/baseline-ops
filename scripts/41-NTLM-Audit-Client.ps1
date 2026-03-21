#requires -version 5.1
<#
.SYNOPSIS
Audit NTLM / LAN Manager Authentication Level (LmCompatibilityLevel) with quick findings (Windows PowerShell 5.1).

.DESCRIPTION
Reads HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel, evaluates it against a minimum level,
creates findings, optionally exports CSV, and prints a human-friendly console summary.

Design goals:
- Pipeline output: structured objects only (works cleanly with Export-Csv / ConvertTo-Json / Where-Object).
- Console output: display-only formatting via Write-UiLine / Write-Information (never via pipeline strings). [web:102][web:106]

.PARAMETER MinimumLevel
Minimum accepted level (0..5). Default is 3.

.PARAMETER ExportPath
Optional CSV path for the summary. Findings are exported as "<base>_findings.csv" in the same folder.

.PARAMETER ConfigPath
Optional JSON config file path (example: "PATH/TO/JSON/ntlm-audit.json").
If present, settings override defaults; if missing/invalid, defaults are used. [web:62][web:65]

.JSON (optional)
Supported properties (all optional):
{
  "MinimumLevel": 3,
  "SeverityTooLow": "High",
  "SeverityLmAllowed": "High",
  "SeverityNtlmv1": "Medium",
  "EmitInfoFindings": true,
  "ConsoleMode": "Pretty"   // Pretty|Plain
}

.OUTPUTS
Pipeline emits:
- Summary (1 object)
- Findings (0..n objects)
.EXAMPLE
  .\41-NTLM-Audit-Client.ps1

#>


[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [ValidateRange(0,5)]
  [int]$MinimumLevel = 3,

  [string]$ExportPath,

  [string]$ConfigPath

,
  [ValidateSet('Audit','Remediate')][string]$Mode = 'Audit',
  [ValidateSet('Console','Json','Csv','None')][string]$OutputFormat = 'Console',
  [string]$OutputPath,
  [switch]$PassThru,
  [switch]$Strict,
  [switch]$Quiet,
  [switch]$NoColor
)

. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Common.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Console.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Registry.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Results.psm1') -Force
Import-Module (Join-Path $script:LibPath Serialization.psm1) -Force


Set-StrictMode -Version Latest
# v2-init
$null = $Mode, $ConfigPath, $OutputFormat, $OutputPath, $PassThru, $Strict, $Quiet, $NoColor
$script:__V2Context = @{
  Mode = $Mode
  ConfigPath = $ConfigPath
  OutputFormat = $OutputFormat
  OutputPath = $OutputPath
  PassThru = [bool]$PassThru
  Strict = [bool]$Strict
  Quiet = [bool]$Quiet
  NoColor = [bool]$NoColor
}
if ($PSBoundParameters.ContainsKey('Mode')) {
  if (Get-Variable -Name Remediate -ErrorAction SilentlyContinue) {
    Set-Variable -Name Remediate -Scope Script -Value ($Mode -eq 'Remediate')
  }
}
if ($Quiet) {
  $InformationPreference = 'SilentlyContinue'
  $VerbosePreference = 'SilentlyContinue'
}
if ($NoColor) {
  $script:NoColor = $true
}
$ErrorActionPreference = 'Stop'

#region Helpers

function Convert-LmCompatibilityLevelToText {
  [CmdletBinding()]
  param([Nullable[int]]$Value)

  switch ($Value) {
    0 { 'Send LM & NTLM responses' }
    1 { 'Send LM & NTLM - use NTLMv2 session security if negotiated' }
    2 { 'Send NTLM responses only' }
    3 { 'Send NTLMv2 responses only' }
    4 { 'Send NTLMv2 responses only. Refuse LM' }
    5 { 'Send NTLMv2 responses only. Refuse LM & NTLM' }
    $null { 'Not defined (registry value missing)' }
    default { "Unknown($Value)" }
  }
}

function Get-DefaultConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [int]$CliMinimumLevel
  )

  # Conservative defaults (safe for most environments; override via parameters/JSON as needed).
  [pscustomobject]@{
    MinimumLevel      = $CliMinimumLevel
    SeverityTooLow    = 'High'
    SeverityLmAllowed = 'High'
    SeverityNtlmv1    = 'Medium'
    EmitInfoFindings  = $true
    ConsoleMode       = 'Pretty' # Pretty|Plain
  }
}

function Merge-Config {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [pscustomobject]$Base,
    [Parameter(Mandatory)] [pscustomobject]$Override
  )

  $cfg = [pscustomobject]@{
    MinimumLevel      = $Base.MinimumLevel
    SeverityTooLow    = $Base.SeverityTooLow
    SeverityLmAllowed = $Base.SeverityLmAllowed
    SeverityNtlmv1    = $Base.SeverityNtlmv1
    EmitInfoFindings  = $Base.EmitInfoFindings
    ConsoleMode       = $Base.ConsoleMode
  }

  if ($null -ne $Override.MinimumLevel -and $Override.MinimumLevel -is [int] -and $Override.MinimumLevel -ge 0 -and $Override.MinimumLevel -le 5) {
    $cfg.MinimumLevel = [int]$Override.MinimumLevel
  }

  foreach ($k in 'SeverityTooLow','SeverityLmAllowed','SeverityNtlmv1') {
    if ($null -ne $Override.$k) {
      $sv = [string]$Override.$k
      if ($sv -in @('Info','Low','Medium','High')) { $cfg.$k = $sv }
    }
  }

  if ($null -ne $Override.EmitInfoFindings) {
    $cfg.EmitInfoFindings = [bool]$Override.EmitInfoFindings
  }

  if ($null -ne $Override.ConsoleMode) {
    $cm = [string]$Override.ConsoleMode
    if ($cm -in @('Pretty','Plain')) { $cfg.ConsoleMode = $cm }
  }

  $cfg
}

function Import-JsonConfigOrDefault {
  [CmdletBinding()]
  param(
    [string]$Path,
    [Parameter(Mandatory)] [pscustomobject]$DefaultConfig
  )

  if ([string]::IsNullOrWhiteSpace($Path)) { return $DefaultConfig }
  if (-not (Test-Path -LiteralPath $Path)) { return $DefaultConfig }

  try {
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { return $DefaultConfig }

    # ConvertFrom-Json can behave unexpectedly with errors; try/catch is the robust approach. [web:65][web:62]
    $j = $raw | ConvertFrom-Json
    if ($null -eq $j) { return $DefaultConfig }

    Merge-Config -Base $DefaultConfig -Override $j
  } catch {
    $DefaultConfig
  }
}


function Write-ConsoleSummary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [pscustomobject]$Summary,
    [Parameter(Mandatory)] [System.Collections.Generic.List[object]]$Findings,
    [Parameter(Mandatory)] [pscustomobject]$Config
  )

  $sorted = @($Findings | Sort-Object @{ Expression = { Get-SeverityRank $_.Severity }; Descending = $true }, Code)
  $top    = $sorted | Select-Object -First 1

  $bannerColor = 'Green'
  if ($Summary.FindingsCount -gt 0 -and $null -ne $top) {
    if ($top.Severity -eq 'High') { $bannerColor = 'Red' }
    elseif ($top.Severity -eq 'Medium') { $bannerColor = 'Yellow' }
    elseif ($top.Severity -eq 'Low') { $bannerColor = 'Cyan' }
  }

  Write-UiLine ''
  Write-UiLine ('=' * 34) -ForegroundColor DarkGray
  Write-UiLine 'NTLM Audit (LmCompatibilityLevel)' -ForegroundColor $bannerColor
  Write-UiLine ('=' * 34) -ForegroundColor DarkGray

  Write-KeyValue -Key 'ComputerName' -Value $Summary.ComputerName -ValueColor White
  Write-KeyValue -Key 'Timestamp' -Value ($Summary.Timestamp.ToString('s')) -ValueColor Gray

  $lvlValue = if ($null -eq $Summary.LmCompatibilityLevel) { '<not set>' } else { [string]$Summary.LmCompatibilityLevel }
  $lvlColor = if ($null -eq $Summary.LmCompatibilityLevel) { 'Yellow' } elseif ($Summary.LmCompatibilityLevel -lt $Summary.MinimumLevel) { 'Red' } else { 'Green' }

  Write-KeyValue -Key 'LmCompatibilityLevel' -Value $lvlValue -ValueColor $lvlColor
  Write-KeyValue -Key 'LmCompatibilityText' -Value $Summary.LmCompatibilityText -ValueColor Gray
  Write-KeyValue -Key 'MinimumLevel' -Value ([string]$Summary.MinimumLevel) -ValueColor Gray
  Write-KeyValue -Key 'FindingsCount' -Value ([string]$Summary.FindingsCount) -ValueColor $(if ($Summary.FindingsCount -gt 0) { 'Yellow' } else { 'Green' })
  Write-KeyValue -Key 'ConfigLoaded' -Value ([string]$Summary.ConfigLoaded) -ValueColor $(if ($Summary.ConfigLoaded) { 'Green' } else { 'DarkGray' })

  if ($null -ne $top) {
    $c = Get-SeverityColor -Severity $top.Severity
    Write-KeyValue -Key 'TopFinding' -Value ("{0} ({1})" -f $top.Severity, $top.Code) -ValueColor $c
  } else {
    Write-KeyValue -Key 'TopFinding' -Value 'None' -ValueColor Green
  }

  $counts = @{ High = 0; Medium = 0; Low = 0; Info = 0 }
  foreach ($g in ($Findings | Group-Object Severity)) {
    if ($counts.ContainsKey($g.Name)) { $counts[$g.Name] = [int]$g.Count }
  }

  Write-UiLine ''
  Write-UiLine 'Findings by severity:' -ForegroundColor DarkGray
  Write-UiLine ("  High  : {0}" -f $counts.High)   -ForegroundColor (Get-SeverityColor -Severity 'High')
  Write-UiLine ("  Medium: {0}" -f $counts.Medium) -ForegroundColor (Get-SeverityColor -Severity 'Medium')
  Write-UiLine ("  Low   : {0}" -f $counts.Low)    -ForegroundColor (Get-SeverityColor -Severity 'Low')
  Write-UiLine ("  Info  : {0}" -f $counts.Info)   -ForegroundColor (Get-SeverityColor -Severity 'Info')

  if ($sorted.Count -gt 0 -and $Config.ConsoleMode -eq 'Pretty') {
    Write-UiLine ''
    Write-UiLine 'Top findings:' -ForegroundColor DarkGray
    foreach ($f in ($sorted | Select-Object -First 5)) {
      $color = Get-SeverityColor -Severity $f.Severity
      Write-UiLine ("- [{0}] {1}: {2}" -f $f.Severity, $f.Code, $f.Message) -ForegroundColor $color
    }
  }

  Write-UiLine ''
}

#endregion Helpers

#region Config
$defaultConfig = Get-DefaultConfig -CliMinimumLevel $MinimumLevel
$config        = Import-JsonConfigOrDefault -Path $ConfigPath -DefaultConfig $defaultConfig
$MinimumLevel  = $config.MinimumLevel

# Track whether a config file was successfully loaded (without leaking internal paths).
$configLoaded = $false
if (-not [string]::IsNullOrWhiteSpace($ConfigPath) -and (Test-Path -LiteralPath $ConfigPath)) {
  try {
    $raw = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 -ErrorAction Stop
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
      $null = $raw | ConvertFrom-Json
      $configLoaded = $true
    }
  } catch {
    $configLoaded = $false
  }
}
#endregion Config

#region Audit
$findings = New-FindingsList

$lsaPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$val     = Get-RegDwordOrNull -Path $lsaPath -Name 'LmCompatibilityLevel'
$valText = Convert-LmCompatibilityLevelToText -Value $val

if ($null -eq $val) {
  Add-Finding -FindingList $findings -Code 'NTLM-LmCompatibilityNotDefined' -Severity 'Info' -Message `
    'LmCompatibilityLevel is not set (policy not defined). Effective defaults may still apply; validate via GPO/RSOP if needed.'
} else {
  if ($val -lt $MinimumLevel) {
    Add-Finding -FindingList $findings -Code 'NTLM-LmCompatibilityTooLow' -Severity $config.SeverityTooLow -Message `
      ('LmCompatibilityLevel={0} ({1}) is below MinimumLevel={2}.' -f $val, $valText, $MinimumLevel)
  }

  if ($val -le 1) {
    Add-Finding -FindingList $findings -Code 'NTLM-LMAllowed' -Severity $config.SeverityLmAllowed -Message `
      ('LmCompatibilityLevel={0} ({1}) allows LM/NTLM. Recommended minimum is 3 (NTLMv2 only), if compatible.' -f $val, $valText)
  } elseif ($val -eq 2) {
    Add-Finding -FindingList $findings -Code 'NTLM-NTLMv1ClientAuth' -Severity $config.SeverityNtlmv1 -Message `
      'LmCompatibilityLevel=2 implies NTLMv1 for client auth (Send NTLM response only). Recommended minimum is 3 (NTLMv2), if compatible.'
  } else {
    if ($config.EmitInfoFindings) {
      if ($val -ge 3 -and $val -lt 5) {
        Add-Finding -FindingList $findings -Code 'NTLM-NTLMv2ClientOnly' -Severity 'Info' -Message `
          ('LmCompatibilityLevel={0} ({1}). Client uses NTLMv2; depending on level, LM/NTLM may still be accepted.' -f $val, $valText)
      } elseif ($val -eq 5) {
        Add-Finding -FindingList $findings -Code 'NTLM-Strictest' -Severity 'Info' -Message `
          'LmCompatibilityLevel=5 is the strictest setting (refuse LM and NTLM). Verify legacy compatibility before enforcing broadly.'
      }
    }
  }
}
#endregion Audit

#region Output objects (pipeline-safe)
$summary = [pscustomobject]@{
  ComputerName         = $env:COMPUTERNAME
  LmCompatibilityLevel = $val
  LmCompatibilityText  = $valText
  MinimumLevel         = $MinimumLevel
  FindingsCount        = $findings.Count
  Timestamp            = Get-Date
  ConfigLoaded         = $configLoaded
  ConfigPath           = $(if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $null } else { 'PATH/TO/JSON/ntlm-audit.json' })
}
#endregion Output objects (pipeline-safe)

#region Export
if ($ExportPath) {
  Ensure-DirectoryForFile -FilePath $ExportPath

  # Windows PowerShell 5.1 writes UTF-8 with BOM for -Encoding UTF8; keep for broad CSV/tool compatibility. [web:66]
  $summary | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

  $base   = [IO.Path]::GetFileNameWithoutExtension($ExportPath)
  $folder = Split-Path -Path $ExportPath -Parent
  if (-not $folder) { $folder = (Get-Location).Path }

  $findings | Export-Csv -Path (Join-Path $folder ($base + '_findings.csv')) -NoTypeInformation -Encoding UTF8
}
#endregion Export

#region Console-only output (no pipeline pollution)
Write-ConsoleSummary -Summary $summary -Findings $findings -Config $config
#endregion Console-only output

# V2 output contract
$resultToken = if ($Strict -and $findings.Count -gt 0) { 'FAIL' } elseif ($findings.Count -gt 0) { 'WARN' } else { 'OK' }
$v2Result = New-V2ResultObject -ScriptName '41-NTLM-Audit-Client.ps1' -Mode $Mode -Result $resultToken -Findings @($findings) -Summary $summary -Metadata @{}
Write-ResultObject -ResultObject $v2Result -OutputFormat $OutputFormat -OutputPath $OutputPath
if ($PassThru) { $v2Result }
exit 0
