#requires -version 5.1
<#
.SYNOPSIS
Aggregate v2 JSON result objects into one report.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [Parameter(Mandatory)]
  [string[]]$InputPath,

  [ValidateSet('Console','Json','Csv','None')]
  [string]$OutputFormat = 'Console',

  [string]$OutputPath,

  [switch]$PassThru

,
  [ValidateSet('Audit','Remediate')][string]$Mode = 'Audit',
  [string]$ConfigPath,
  [switch]$Strict,
  [switch]$Quiet,
  [switch]$NoColor
)

. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Serialization.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Validation.psm1')

Set-StrictMode -Version Latest
# v2-init (migrated to Initialize-V2Context)
Initialize-V2Context -ScriptName '00-Report-Aggregate.ps1' -BoundParameters $PSBoundParameters
$ErrorActionPreference = 'Stop'

$files = New-Object System.Collections.ArrayList
foreach ($p in $InputPath) {
  if (Test-Path -LiteralPath $p -PathType Leaf) {
    [void]$files.Add((Resolve-Path -LiteralPath $p).Path)
  } elseif (Test-Path -LiteralPath $p -PathType Container) {
    foreach ($f in Get-ChildItem -LiteralPath $p -Filter '*.json' -File) {
      [void]$files.Add($f.FullName)
    }
  }
}

if ($files.Count -eq 0) {
  $message = 'No JSON result files found in InputPath.'
  $finding = [pscustomobject]@{
    Code     = 'Aggregate-NoInputFiles'
    Severity = 'High'
    Message  = $message
  }
  $report = Get-V2ResultObject `
    -ScriptName '00-Report-Aggregate.ps1' `
    -Mode $Mode `
    -Result 'FAIL' `
    -Findings @($finding) `
    -Summary ([pscustomobject]@{ Files = 0; RejectedFiles = 0; OK = 0; WARN = 0; FAIL = 0; Error = $message }) `
    -Metadata @{ Items = @() }
  Write-ResultObject -ResultObject $report -OutputFormat $OutputFormat -OutputPath $OutputPath
  if ($PassThru) { $report }
  exit (Get-V2ExitCode -Result 'FAIL')
}

$items = New-Object System.Collections.ArrayList
$rejectionFindings = New-Object System.Collections.ArrayList
$rejectedFiles = 0
foreach ($file in $files) {
  try {
    $obj = Get-BoundedUtf8FileContent -Path $file -MaximumBytes 16777216 | ConvertFrom-Json -ErrorAction Stop
    # Validate that parsed JSON has required v2 result properties before including
    $props = if ($null -ne $obj) { @($obj.PSObject.Properties.Name) } else { @() }
    $shapeValid = $props -contains 'ScriptName' -and $props -contains 'Result' -and $props -contains 'Mode'
    $valuesValid = $shapeValid `
      -and -not [string]::IsNullOrWhiteSpace([string]$obj.ScriptName) `
      -and @('OK','WARN','FAIL') -contains [string]$obj.Result `
      -and @('Audit','Remediate') -contains [string]$obj.Mode
    if (-not $valuesValid) {
      $message = "Skipping '$file': invalid v2 result shape or values (ScriptName, Result, Mode)."
      Write-Warning $message
      $rejectedFiles++
      [void]$rejectionFindings.Add([pscustomobject]@{
          Code     = 'Aggregate-InvalidResult'
          Severity = 'Medium'
          Message  = $message
          File     = $file
        })
      continue
    }
    [void]$items.Add([pscustomobject]@{
        File   = $file
        Result = [string]$obj.Result
        Script = [string]$obj.ScriptName
        Mode   = [string]$obj.Mode
      })
  } catch {
    $message = "Skipping '$file': failed to parse JSON - $($_.Exception.Message)"
    Write-Warning $message
    $rejectedFiles++
    [void]$rejectionFindings.Add([pscustomobject]@{
        Code     = 'Aggregate-InvalidJson'
        Severity = 'Medium'
        Message  = $message
        File     = $file
      })
  }
}

$arr = @($items)
$ok = @($arr | Where-Object { $_.Result -eq 'OK' }).Count
$warn = @($arr | Where-Object { $_.Result -eq 'WARN' }).Count
$fail = @($arr | Where-Object { $_.Result -eq 'FAIL' }).Count

$token = if ($arr.Count -eq 0 -and $rejectedFiles -gt 0) { 'FAIL' } elseif ($fail -gt 0) { 'FAIL' } elseif ($warn -gt 0 -or $rejectedFiles -gt 0) { 'WARN' } else { 'OK' }
if ($Strict -and $token -eq 'WARN') { $token = 'FAIL' }
$summary = [pscustomobject]@{
  Files         = $arr.Count
  RejectedFiles = $rejectedFiles
  OK            = $ok
  WARN          = $warn
  FAIL          = $fail
}

$report = Get-V2ResultObject `
  -ScriptName '00-Report-Aggregate.ps1' `
  -Mode $Mode `
  -Result $token `
  -Findings @($rejectionFindings) `
  -Summary $summary `
  -Metadata @{ Items = $arr }

if ($OutputFormat -eq 'Console') {
  Write-Section -Title 'Aggregate Report'
  Write-KeyValue -Key 'Files' -Value $summary.Files
  Write-KeyValue -Key 'OK' -Value $summary.OK
  Write-KeyValue -Key 'WARN' -Value $summary.WARN
  Write-KeyValue -Key 'FAIL' -Value $summary.FAIL
}

Write-ResultObject -ResultObject $report -OutputFormat $OutputFormat -OutputPath $OutputPath

if ($PassThru) { $report }

exit (Get-V2ExitCode -Result $token)
