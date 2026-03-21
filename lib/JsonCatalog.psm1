Set-StrictMode -Version Latest

<#
.SYNOPSIS
Shared JSON read/write helpers to avoid duplication across scripts.

.DESCRIPTION
Provides safe JSON file read/write with optional UTF-8 no-BOM encoding.
Scripts should import Common.psm1 first for Ensure-Directory/Ensure-Dir when using Write-JsonToFile.
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

function Write-JsonToFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object]$Object,
    [Parameter(Mandatory)]
    [string]$Path,
    [int]$Depth = 20,
    [switch]$NoBom
  )
  if ([string]::IsNullOrWhiteSpace($Path)) {
    throw 'Write-JsonToFile: Path cannot be null or empty.'
  }
  if ($Path -match '\.\.') {
    throw 'Write-JsonToFile: Path must not contain ".." (path traversal not allowed).'
  }
  $dir = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $json = $Object | ConvertTo-Json -Depth $Depth
  if ($NoBom) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
  } else {
    $json | Out-File -FilePath $Path -Encoding UTF8 -Force
  }
}

Export-ModuleMember -Function Read-JsonFileSafe, Write-JsonToFile
