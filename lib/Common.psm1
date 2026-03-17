Set-StrictMode -Version Latest

function Get-CallerValue {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name)

  foreach ($scope in 1..3) {
    try {
      $var = Get-Variable -Name $Name -Scope $scope -ErrorAction Stop
      return $var.Value
    } catch {
      # continue
    }
  }
  return $null
}

function Test-IsAdmin {
  [CmdletBinding()]
  param()
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch {
    # On non-Windows platforms (like Mac testing), [Security.Principal.WindowsIdentity] won't work.
    return $false
  }
}

function Require-Admin {
  [CmdletBinding()]
  param(
    [string]$Message = 'Administrative privileges are required. Run the script elevated.'
  )
  if (-not (Test-IsAdmin)) {
    # We only throw if on Windows, otherwise we just warn for Mac testing.
    if ($IsWindows) {
      throw $Message
    } else {
      Write-Warning "Non-Windows OS detected; skipping administrative check for testing: $Message"
    }
  }
}

function Ensure-Directory {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) { return }
  if ($Path -match '\.\.') {
    Write-Warning "Ensure-Directory: Path must not contain '..' (path traversal not allowed)."
    return
  }
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
  }
}

function Ensure-DirectoryForFile {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$FilePath)

  $dir = Split-Path -Path $FilePath -Parent
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  Ensure-Directory -Path $dir
}

function Sanitize-Path {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$MustExist
  )

  if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

  try {
    # Expand environment variables first
    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if ([string]::IsNullOrWhiteSpace($expanded)) { return $null }

    # Reject any path containing ".." to prevent traversal (covers "..\", "../", "....\", leading "\..", etc.)
    if ($expanded -match '\.\.') {
      Write-Warning "Path traversal not allowed (contains '..'): path rejected."
      return $null
    }

    if ($MustExist) {
      if (Test-Path -LiteralPath $expanded) {
        $resolved = [System.IO.Path]::GetFullPath($expanded)
        if ($resolved -match '\.\.') { return $null }
        return $resolved
      }
      return $null
    }

    # Normalize and resolve full path; GetFullPath can throw on invalid chars
    return [System.IO.Path]::GetFullPath($expanded)
  } catch {
    return $null
  }
}

function Read-JsonConfig {
  [CmdletBinding()]
  param([string]$Path)

  $sanitized = Sanitize-Path -Path $Path -MustExist
  if (-not $sanitized) { return $null }

  try {
    $raw = Get-Content -LiteralPath $sanitized -Raw -Encoding UTF8 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return ($raw | ConvertFrom-Json -ErrorAction Stop)
  } catch {
    Write-Error "Failed to parse JSON config at $sanitized : $($_.Exception.Message)"
    return $null
  }
}

Export-ModuleMember -Function `
  Get-CallerValue, `
  Test-IsAdmin, `
  Require-Admin, `
  Ensure-Directory, `
  Ensure-DirectoryForFile, `
  Read-JsonConfig, `
  Sanitize-Path
