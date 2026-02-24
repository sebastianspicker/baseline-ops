#requires -version 5.1
<#
.SYNOPSIS
Run a script from C:\install\mdm\ps1\scripts on the local machine.

.DESCRIPTION
Looks up the script file in C:\install\mdm\ps1\scripts (or an override)
and executes it. Optional -ScriptArgs are passed through to the script.

Supports optional integrity verification via signature check or hash comparison.

.PARAMETER ScriptName
Script file name to run (for example: 18-Firewall-Baseline.ps1).

.PARAMETER ScriptNumber
Script number only (for example: 18). Matches "18-*.ps1".

.PARAMETER ScriptArgs
Optional arguments to pass to the target script.

.PARAMETER RootPath
Override root path (default: C:\install\mdm\ps1).

.PARAMETER RequireSigned
If set, verifies the script has a valid Authenticode signature before execution.

.PARAMETER ExpectedHash
Expected hash value for the script. Format: "ALGORITHM:HASH" or just "HASH" (defaults to SHA256).
Example: "SHA256:ABC123..." or just "ABC123..."

.PARAMETER HashAlgorithm
Hash algorithm to use for verification (default: SHA256).
Valid values: SHA256, SHA384, SHA512, MD5, SHA1

.EXAMPLE
.\00-Run-Local.ps1 -ScriptName 18-Firewall-Baseline.ps1

.EXAMPLE
.\00-Run-Local.ps1 -ScriptNumber 18

.EXAMPLE
.\00-Run-Local.ps1 -ScriptName 31-PowerShell-Logging-Baseline.ps1 -ScriptArgs @('-Mode','AuditOnly')

.EXAMPLE
.\00-Run-Local.ps1 -ScriptNumber 18 -RequireSigned

.EXAMPLE
.\00-Run-Local.ps1 -ScriptName 18-Firewall-Baseline.ps1 -ExpectedHash "SHA256:ABC123DEF456..."

.EXAMPLE
# Verify hash from a hash file
$hash = (Get-Content .\hashes.txt | Where-Object { $_ -like "18-Firewall-Baseline.ps1=*" }).Split('=')[1]
.\00-Run-Local.ps1 -ScriptNumber 18 -ExpectedHash $hash
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory, ParameterSetName = 'ByName')]
  [ValidateNotNullOrEmpty()]
  [string]$ScriptName,

  [Parameter(Mandatory, ParameterSetName = 'ByNumber')]
  [ValidatePattern('^\d{1,2}$')]
  [string]$ScriptNumber,

  [string[]]$ScriptArgs,

  [string]$RootPath = 'C:\install\mdm\ps1',

  [switch]$RequireSigned,

  [string]$ExpectedHash,

  [ValidateSet('SHA256','SHA384','SHA512','MD5','SHA1')]
  [string]$HashAlgorithm = 'SHA256'
)

. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsRoot = Join-Path $RootPath 'scripts'

if (-not (Test-Path -LiteralPath $scriptsRoot)) {
  throw "Scripts root not found: $scriptsRoot"
}

if ($PSCmdlet.ParameterSetName -eq 'ByNumber') {
  $num = [int]$ScriptNumber
  $prefix = '{0:D2}-' -f $num
  $scriptMatches = Get-ChildItem -Path $scriptsRoot -Filter "$prefix*.ps1" -File
  if ($scriptMatches.Count -eq 0) {
    throw "No script found for number $prefix in $scriptsRoot"
  }
  if ($scriptMatches.Count -gt 1) {
    $names = ($scriptMatches | Select-Object -ExpandProperty Name) -join ', '
    throw "Multiple scripts match number ${prefix}: $names"
  }
  $scriptPath = $scriptMatches[0].FullName
} else {
  # Constrain to basename only to prevent path traversal (§11/§10)
  if ($ScriptName -match '[/\\]' -or $ScriptName -match '\.\.') {
    throw "ScriptName must be a script file name without path components (e.g. 18-Firewall-Baseline.ps1)."
  }
  $baseName = [System.IO.Path]::GetFileName($ScriptName)
  if ([string]::IsNullOrWhiteSpace($baseName)) {
    throw "ScriptName must be a script file name (e.g. 18-Firewall-Baseline.ps1)."
  }
  if ([System.IO.Path]::GetExtension($baseName) -ne '.ps1') {
    throw "ScriptName must reference a .ps1 file."
  }
  $scriptPath = Join-Path $scriptsRoot $baseName
  if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Script not found: $scriptPath"
  }
  $scriptsRootFull = [System.IO.Path]::GetFullPath($scriptsRoot)
  $resolvedFull = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $scriptPath).Path)
  if (-not $resolvedFull.StartsWith($scriptsRootFull, [StringComparison]::OrdinalIgnoreCase) -or $resolvedFull -eq $scriptsRootFull) {
    throw "Resolved script path is outside scripts root or invalid."
  }
  $scriptPath = $resolvedFull
}

# Integrity verification (fixes #25)
if ($RequireSigned) {
  $signature = Get-AuthenticodeSignature -FilePath $scriptPath
  if ($signature.Status -ne 'Valid') {
    throw "Script signature verification failed for $scriptPath : $($signature.Status)"
  }
  Write-UiLine "Signature verified: $($signature.SignerCertificate.Subject)" -Style Success
}

if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
  # Parse expected hash - format can be "ALGORITHM:HASH" or just "HASH"
  $expectedAlg = $HashAlgorithm
  $expectedHashValue = $ExpectedHash.Trim()
  
  if ($expectedHashValue -match '^(\w+):([A-Fa-f0-9]+)$') {
    $expectedAlg = $Matches[1]
    $expectedHashValue = $Matches[2]
  }
  
  $actualHashObj = Get-FileHash -Path $scriptPath -Algorithm $expectedAlg
  $actualHash = $actualHashObj.Hash
  
  if ($actualHash -ne $expectedHashValue) {
    throw "Hash mismatch for $scriptPath. Expected ($expectedAlg): $expectedHashValue, Actual: $actualHash"
  }
  Write-UiLine "Hash verified ($expectedAlg)" -Style Success
}

if ($ScriptArgs) {
  & $scriptPath @ScriptArgs
} else {
  & $scriptPath
}
