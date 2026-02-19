Set-StrictMode -Version Latest

function New-FindingsList {
  [CmdletBinding()]
  param()
  $list = New-Object System.Collections.Generic.List[object]
  return , $list
}

function New-FindingObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Code,
    [Parameter(Mandatory)][string]$Severity,
    [Parameter(Mandatory)][string]$Message,
    [string]$TypeName,
    [hashtable]$Extra
  )

  $obj = [pscustomobject]@{
    Code     = $Code
    Severity = $Severity
    Message  = $Message
  }

  if ($TypeName) { $obj.PSTypeNames.Insert(0, $TypeName) }
  if ($Extra) {
    foreach ($k in $Extra.Keys) {
      $obj | Add-Member -NotePropertyName $k -NotePropertyValue $Extra[$k] -Force
    }
  }

  return $obj
}

function Add-Finding {
  [CmdletBinding()]
  param(
    [Alias('Findings','List')][System.Collections.Generic.List[object]]$FindingList,
    [Parameter(Mandatory)][string]$Code,
    [Parameter(Mandatory)][string]$Severity,
    [Parameter(Mandatory)][string]$Message,
    [string]$TypeName,
    [string]$ProfileName,
    [hashtable]$Extra
  )

  if ($null -eq $FindingList) {
    $FindingList = Get-CallerValue -Name 'Findings'
    if ($null -eq $FindingList) { $FindingList = Get-CallerValue -Name 'script:Findings' }
  }
  if ($null -eq $FindingList) {
    throw 'FindingList not provided and no $Findings/$script:Findings found.'
  }

  $extraFields = @{}
  if ($Extra) {
    foreach ($k in $Extra.Keys) { $extraFields[$k] = $Extra[$k] }
  }
  if ($ProfileName) { $extraFields['Profile'] = $ProfileName }

  $useUtc = Get-CallerValue -Name 'FindingsTimeUtc'
  $useLocal = Get-CallerValue -Name 'FindingsTimestampLocal'
  if ($useUtc) { $extraFields['TimeUtc'] = (Get-Date).ToUniversalTime() }
  if ($useLocal) { $extraFields['Timestamp'] = (Get-Date) }

  $obj = New-FindingObject -Code $Code -Severity $Severity -Message $Message -TypeName $TypeName -Extra $extraFields
  $FindingList.Add($obj) | Out-Null
  return $FindingList
}

Export-ModuleMember -Function New-FindingsList,New-FindingObject,Add-Finding
