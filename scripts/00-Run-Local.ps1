#requires -version 5.1
<#
.SYNOPSIS
Run a script from C:\install\mdm\ps1\scripts on the local machine.

.DESCRIPTION
Looks up the script file in C:\install\mdm\ps1\scripts (or an override)
and executes it. Optional -ScriptArgs are passed through to the script.

.PARAMETER ScriptName
Script file name to run (for example: 18-Firewall-Baseline.ps1).

.PARAMETER ScriptNumber
Script number only (for example: 18). Matches "18-*.ps1".

.PARAMETER ScriptArgs
Optional arguments to pass to the target script.

.PARAMETER RootPath
Override root path (default: C:\install\mdm\ps1).

.EXAMPLE
.\00-Run-Local.ps1 -ScriptName 18-Firewall-Baseline.ps1

.EXAMPLE
.\00-Run-Local.ps1 -ScriptNumber 18

.EXAMPLE
.\00-Run-Local.ps1 -ScriptName 31-PowerShell-Logging-Baseline.ps1 -ScriptArgs @('-Mode','AuditOnly')
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

  [string]$RootPath = 'C:\install\mdm\ps1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsRoot = Join-Path $RootPath 'scripts'

if (-not (Test-Path -LiteralPath $scriptsRoot)) {
  throw "Scripts root not found: $scriptsRoot"
}

if ($PSCmdlet.ParameterSetName -eq 'ByNumber') {
  $num = [int]$ScriptNumber
  $prefix = '{0:D2}-' -f $num
  $matches = Get-ChildItem -Path $scriptsRoot -Filter "$prefix*.ps1" -File
  if ($matches.Count -eq 0) {
    throw "No script found for number $prefix in $scriptsRoot"
  }
  if ($matches.Count -gt 1) {
    $names = ($matches | Select-Object -ExpandProperty Name) -join ', '
    throw "Multiple scripts match number $prefix: $names"
  }
  $scriptPath = $matches[0].FullName
} else {
  $scriptPath = Join-Path $scriptsRoot $ScriptName
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Script not found: $scriptPath"
  }
}

if ($ScriptArgs) {
  & $scriptPath @ScriptArgs
} else {
  & $scriptPath
}
