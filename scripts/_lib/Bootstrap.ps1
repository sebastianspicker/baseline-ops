# Resolve lib path relative to script directory only (not CWD) so Import-Module works regardless of current location
$script:LibPath = Join-Path $PSScriptRoot '..\..\lib'
if (-not (Test-Path -LiteralPath $script:LibPath)) {
  $script:LibPath = Join-Path $PSScriptRoot '..\lib'
}
if (-not (Test-Path -LiteralPath $script:LibPath)) {
  $script:LibPath = Join-Path $PSScriptRoot 'lib'
}

$scriptDir = $PSScriptRoot
if (-not [string]::IsNullOrWhiteSpace($scriptDir) -and (Test-Path -LiteralPath $scriptDir -PathType Container)) {
  Push-Location -LiteralPath $scriptDir
  try {
    $resolved = Resolve-Path -LiteralPath $script:LibPath -ErrorAction Stop
    $script:LibPath = $resolved.Path
  } catch {
    $abs = [System.IO.Path]::GetFullPath((Join-Path $scriptDir $script:LibPath))
    if (Test-Path -LiteralPath $abs) { $script:LibPath = $abs }
  } finally {
    Pop-Location
  }
} else {
  # When PSScriptRoot is null/empty (e.g. dot-sourced from host), try to resolve LibPath from current location
  $cwd = Get-Location
  if ($cwd -and $cwd.Provider.Name -eq 'FileSystem') {
    try {
      $resolved = Resolve-Path -LiteralPath $script:LibPath -ErrorAction Stop
      if ($resolved -and (Test-Path -LiteralPath $resolved.Path -PathType Container)) {
        $script:LibPath = $resolved.Path
      }
    } catch {
      # Keep relative LibPath if resolution fails
    }
  }
}
