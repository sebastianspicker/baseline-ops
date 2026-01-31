#requires -version 5.1
<#
.SYNOPSIS
Pull latest repo version and copy "scripts" and "lib" to C:\install\mdm\ps1\.

.DESCRIPTION
Ensures the repo is cloned/pulled locally and then copies scripts/ and lib/
into the destination root.

.PARAMETER RepoUrl
Git repository URL to pull from.

.PARAMETER DestinationRoot
Destination root (default: C:\install\mdm\ps1).

.PARAMETER RepoPath
Local clone path (default: <DestinationRoot>\_repo).

.EXAMPLE
.\00-Copy-Local.ps1

.EXAMPLE
.\00-Copy-Local.ps1 -DestinationRoot D:\mdm\ps1

.EXAMPLE
.\00-Copy-Local.ps1 -RepoUrl https://github.com/org/repo.git
#>

[CmdletBinding()]
param(
  [string]$RepoUrl = 'https://github.com/sebastianspicker/win-mdm-security-hardening-kit.git',
  [string]$DestinationRoot = 'C:\install\mdm\ps1',
  [string]$RepoPath
)

. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoPath) {
  $RepoPath = Join-Path $DestinationRoot '_repo'
}

if (-not (Get-Command -Name git.exe -ErrorAction SilentlyContinue)) {
  throw 'git.exe not found. Install Git or add it to PATH.'
}

if (-not (Test-Path -LiteralPath $DestinationRoot)) {
  New-Item -Path $DestinationRoot -ItemType Directory -Force | Out-Null
}

if (Test-Path -LiteralPath (Join-Path $RepoPath '.git')) {
  & git.exe -C $RepoPath fetch --all --prune
  & git.exe -C $RepoPath pull --ff-only
} else {
  if (Test-Path -LiteralPath $RepoPath) {
    Remove-Item -LiteralPath $RepoPath -Recurse -Force
  }
  & git.exe clone --depth 1 $RepoUrl $RepoPath
}

$sourceScripts = Join-Path $RepoPath 'scripts'
$sourceLib = Join-Path $RepoPath 'lib'

if (-not (Test-Path -LiteralPath $sourceScripts)) {
  throw "Source scripts folder not found after pull: $sourceScripts"
}
if (-not (Test-Path -LiteralPath $sourceLib)) {
  throw "Source lib folder not found after pull: $sourceLib"
}

Copy-Item -Path $sourceScripts -Destination $DestinationRoot -Recurse -Force
Copy-Item -Path $sourceLib -Destination $DestinationRoot -Recurse -Force

Write-UiLine "Copied scripts/ and lib/ to $DestinationRoot"
