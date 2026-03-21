Set-StrictMode -Version Latest

<#
.SYNOPSIS
Windows Event Log helpers for health scripts.

.DESCRIPTION
Provides functions to ensure an event source exists and to write structured
health events to the Windows Application Event Log.
#>

<#
.SYNOPSIS
  Ensures a Windows Event Log source is registered.
.PARAMETER Source
  Event source name to register.
.PARAMETER SourceName
  Alias for Source.
.PARAMETER LogName
  Event log name (default: Application).
.PARAMETER OnError
  Scriptblock invoked with error message on failure.
#>
function Ensure-EventSource {
  [CmdletBinding()]
  param(
    [string]$Source,
    [Alias('SourceName')][string]$SourceName,
    [Alias('Log')][string]$LogName,
    [scriptblock]$OnError
  )
  if (-not $Source -and $SourceName) { $Source = $SourceName }
  if ([string]::IsNullOrWhiteSpace($Source)) {
    $Source = Get-CallerValue -Name 'EventSource'
    if (-not $Source) { $Source = Get-CallerValue -Name 'EventSourceName' }
  }
  if ([string]::IsNullOrWhiteSpace($LogName)) {
    $LogName = Get-CallerValue -Name 'EventLogName'
    if (-not $LogName) { $LogName = Get-CallerValue -Name 'EventLog' }
    if ([string]::IsNullOrWhiteSpace($LogName)) { $LogName = 'Application' }
  }
  if ([string]::IsNullOrWhiteSpace($Source)) {
    if ($OnError) { & $OnError 'Ensure-EventSource: -Source or -SourceName is required, or set EventSource/EventSourceName in caller scope.' }
    return $false
  }

  try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
      New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop | Out-Null
    }
    return $true
  } catch {
    if ($OnError) { & $OnError ($_.Exception.Message) }
    return $false
  }
}

<#
.SYNOPSIS
  Writes a health event to the Windows Event Log.
.PARAMETER Id
  Event ID for the log entry.
.PARAMETER Message
  Event message text.
.PARAMETER Level
  Entry type: Information, Warning, or Error.
.PARAMETER Source
  Event source name. Falls back to caller-scope EventSource variable.
.PARAMETER LogName
  Event log name. Falls back to caller-scope EventLogName variable.
.PARAMETER OnError
  Scriptblock invoked with error message on failure.
#>
function Write-HealthEvent {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][int]$Id,
    [Parameter(Mandatory)][Alias('Msg')][string]$Message,
    [ValidateSet('Information','Warning','Error')][string]$Level = 'Information',
    [string]$Source,
    [Alias('Log')][string]$LogName,
    [scriptblock]$OnError
  )

  if (-not $Source) {
    $Source = Get-CallerValue -Name 'EventSource'
    if (-not $Source) { $Source = Get-CallerValue -Name 'EventSourceName' }
  }
  if (-not $LogName) {
    $LogName = Get-CallerValue -Name 'EventLogName'
    if (-not $LogName) { $LogName = Get-CallerValue -Name 'EventLog' }
  }

  if ([string]::IsNullOrWhiteSpace($Source) -or [string]::IsNullOrWhiteSpace($LogName)) {
    $msg = 'Write-HealthEvent: Source or LogName is missing. Set EventSource/EventSourceName and EventLogName/EventLog in caller scope or pass -Source and -LogName.'
    if ($OnError) { & $OnError $msg }
    return $false
  }

  try {
    Write-EventLog -LogName $LogName -Source $Source -EntryType $Level -EventId $Id -Message $Message -ErrorAction Stop
    return $true
  } catch {
    if ($OnError) { & $OnError ($_.Exception.Message) }
    return $false
  }
}

Export-ModuleMember -Function Ensure-EventSource,Write-HealthEvent
