$script:LibPath = Join-Path $PSScriptRoot '..\..\lib'
if (-not (Test-Path -LiteralPath $script:LibPath)) {
  $script:LibPath = Join-Path $PSScriptRoot '..\lib'
}
if (-not (Test-Path -LiteralPath $script:LibPath)) {
  $script:LibPath = Join-Path $PSScriptRoot 'lib'
}

try {
  $script:LibPath = (Resolve-Path -LiteralPath $script:LibPath).Path
} catch {
  # Resolve-Path failed (e.g. wrong CWD); try absolute path relative to script dir so Import-Module works regardless of CWD
  $abs = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $script:LibPath))
  if (Test-Path -LiteralPath $abs) { $script:LibPath = $abs }
}
