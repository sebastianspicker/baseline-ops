#requires -version 5.1
<#
.SYNOPSIS
Pester tests for JsonCatalog.psm1 module

.DESCRIPTION
Unit tests for Read-JsonFileSafe and Write-JsonToFile.
#>

[CmdletBinding()]
param()

BeforeAll {
  Import-Module (Join-Path $PSScriptRoot '../../lib/JsonCatalog.psm1') -Force

  $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
  $script:TestDir = Join-Path $tempRoot 'JsonCatalogModuleTests'
  $script:TestJsonFile = Join-Path $script:TestDir 'test.json'
}

AfterAll {
  if (-not [string]::IsNullOrWhiteSpace($script:TestDir) -and (Test-Path -LiteralPath $script:TestDir)) {
    Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Describe 'Read-JsonFileSafe' {
  BeforeEach {
    if (Test-Path -LiteralPath $script:TestDir) {
      Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
  }

  It 'Returns null for missing file' {
    $result = Read-JsonFileSafe -Path (Join-Path $script:TestDir 'nonexistent.json')
    $result | Should -BeNullOrEmpty
  }

  It 'Returns null for empty path' {
    $result = Read-JsonFileSafe -Path ''
    $result | Should -BeNullOrEmpty
  }

  It 'Returns null for empty file' {
    '' | Out-File -FilePath $script:TestJsonFile -Encoding UTF8
    $result = Read-JsonFileSafe -Path $script:TestJsonFile
    $result | Should -BeNullOrEmpty
  }

  It 'Returns null for invalid JSON' {
    'not valid json {{{' | Out-File -FilePath $script:TestJsonFile -Encoding UTF8
    $result = Read-JsonFileSafe -Path $script:TestJsonFile
    $result | Should -BeNullOrEmpty
  }

  It 'Parses valid JSON file' {
    '{"Name": "Test", "Value": 42}' | Out-File -FilePath $script:TestJsonFile -Encoding UTF8
    $result = Read-JsonFileSafe -Path $script:TestJsonFile
    $result.Name | Should -Be 'Test'
    $result.Value | Should -Be 42
  }
}

Describe 'Write-JsonToFile' {
  BeforeEach {
    if (Test-Path -LiteralPath $script:TestDir) {
      Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
  }

  It 'Writes valid JSON to file' {
    $obj = [pscustomobject]@{ Key = 'Value'; Num = 10 }
    Write-JsonToFile -Object $obj -Path $script:TestJsonFile
    Test-Path -LiteralPath $script:TestJsonFile | Should -Be $true
    $content = Get-Content -LiteralPath $script:TestJsonFile -Raw | ConvertFrom-Json
    $content.Key | Should -Be 'Value'
    $content.Num | Should -Be 10
  }

  It 'Creates parent directory if it does not exist' {
    $nestedPath = Join-Path $script:TestDir 'sub1/sub2/output.json'
    $obj = @{ Data = 'test' }
    Write-JsonToFile -Object $obj -Path $nestedPath
    Test-Path -LiteralPath $nestedPath | Should -Be $true
  }

  It 'Throws for empty path' {
    { Write-JsonToFile -Object @{ A = 1 } -Path '' } | Should -Throw '*Path*'
  }

  It 'Throws for path traversal attempt' {
    { Write-JsonToFile -Object @{ A = 1 } -Path (Join-Path $script:TestDir '../../escape.json') } | Should -Throw '*path traversal*'
  }

  It 'Roundtrip: write then read returns same data' {
    $original = [pscustomobject]@{ Name = 'Roundtrip'; Items = @(1, 2, 3) }
    Write-JsonToFile -Object $original -Path $script:TestJsonFile
    $loaded = Read-JsonFileSafe -Path $script:TestJsonFile
    $loaded.Name | Should -Be 'Roundtrip'
    $loaded.Items.Count | Should -Be 3
  }

  It 'Writes NoBom encoded file' {
    $obj = @{ Encoding = 'NoBom' }
    Write-JsonToFile -Object $obj -Path $script:TestJsonFile -NoBom
    Test-Path -LiteralPath $script:TestJsonFile | Should -Be $true
    $content = Get-Content -LiteralPath $script:TestJsonFile -Raw | ConvertFrom-Json
    $content.Encoding | Should -Be 'NoBom'
  }
}
