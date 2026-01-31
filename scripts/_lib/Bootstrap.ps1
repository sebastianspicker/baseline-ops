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
  # leave as-is; Import-Module will surface the error if the path is invalid
}
