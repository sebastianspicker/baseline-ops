Set-StrictMode -Version Latest

<#
.SYNOPSIS
Safe JSON reading helper.

.DESCRIPTION
Provides safe JSON file reading that returns $null on any error.
For JSON writing, use Save-Json from Serialization.psm1.
#>

function Read-JsonFileSafe {
  [CmdletBinding()]
  param(
    [string]$Path
  )
  if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return $null
  }
  try {
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return $raw | ConvertFrom-Json -ErrorAction Stop
  } catch {
    return $null
  }
}

Export-ModuleMember -Function Read-JsonFileSafe
