#requires -version 5.1
<#
.SYNOPSIS
Pester tests for Common.psm1 module

.DESCRIPTION
Unit tests for the Common module functions including:
- Test-IsAdmin
- Ensure-Directory
- Sanitize-Path
- Read-JsonConfig
#>

[CmdletBinding()]
param()

BeforeAll {
  # Import the module
  $modulePath = Join-Path $PSScriptRoot '../../lib/Common.psm1'
  Import-Module $modulePath -Force

  # Test directory
  $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
  $script:TestDir = Join-Path $tempRoot 'CommonModuleTests'
  $script:TestJsonFile = Join-Path $script:TestDir 'test-config.json'
}

AfterAll {
  # Cleanup test directory
  if (-not [string]::IsNullOrWhiteSpace($script:TestDir) -and (Test-Path -LiteralPath $script:TestDir)) {
    Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Describe "Test-IsAdmin" {
  It "Returns a boolean" {
    $result = Test-IsAdmin
    $result | Should -BeOfType [bool]
  }

  It "Does not throw" {
    { Test-IsAdmin } | Should -Not -Throw
  }
}

Describe "Ensure-Directory" {
  BeforeEach {
    # Clean up
    if (Test-Path -LiteralPath $script:TestDir) {
      Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It "Creates a new directory" {
    Ensure-Directory -Path $script:TestDir
    Test-Path -LiteralPath $script:TestDir | Should -Be $true
  }

  It "Does not throw when directory exists" {
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    { Ensure-Directory -Path $script:TestDir } | Should -Not -Throw
  }

  It "Handles empty path gracefully" {
    { Ensure-Directory -Path '' } | Should -Throw
  }

  It "Creates nested directories" {
    $nestedPath = Join-Path $script:TestDir 'Level1\Level2\Level3'
    Ensure-Directory -Path $nestedPath
    Test-Path -LiteralPath $nestedPath | Should -Be $true
  }
}

Describe "Ensure-DirectoryForFile" {
  BeforeEach {
    if (Test-Path -LiteralPath $script:TestDir) {
      Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It "Creates parent directory for file path" {
    $filePath = Join-Path $script:TestDir 'subdir\test.txt'
    Ensure-DirectoryForFile -FilePath $filePath
    Test-Path -LiteralPath (Join-Path $script:TestDir 'subdir') | Should -Be $true
  }
}

Describe "Sanitize-Path" {
  It "Returns null for whitespace path" {
    $result = Sanitize-Path -Path '   '
    $result | Should -BeNullOrEmpty
  }

  It "Expands environment variables" {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
    $env:COMMON_TEST_TMP = $tempRoot
    $result = Sanitize-Path -Path '%COMMON_TEST_TMP%'
    $result | Should -Not -BeNullOrEmpty
  }

  It "Returns null for path traversal attempt" {
    $result = Sanitize-Path -Path 'C:\Test\..\..\Windows\System32'
    # Note: The function may normalize this, but should warn
    # The actual behavior depends on implementation
    $result | Should -BeNullOrEmpty
  }

  It "Returns normalized path for valid path" {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
    $result = Sanitize-Path -Path $tempRoot
    $result | Should -Not -BeNullOrEmpty
  }

  It "Returns null for non-existent path with MustExist" {
    $result = Sanitize-Path -Path 'C:\NonExistentPath12345' -MustExist
    $result | Should -BeNullOrEmpty
  }

  It "Returns path for existing path with MustExist" {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
    $result = Sanitize-Path -Path $tempRoot -MustExist
    $result | Should -Not -BeNullOrEmpty
  }

  It "Rejects forward-slash traversal" {
    $result = Sanitize-Path -Path '/tmp/../etc/passwd'
    $result | Should -BeNullOrEmpty
  }

  It "Returns a full path for a relative safe path" {
    $result = Sanitize-Path -Path 'some-folder'
    $result | Should -Not -BeNullOrEmpty
    # Should be an absolute path
    [System.IO.Path]::IsPathRooted($result) | Should -Be $true
  }
}

Describe "Require-Admin" {
  It "Does not throw on non-Windows (warns instead)" -Skip:$IsWindows {
    { Require-Admin } | Should -Not -Throw
  }

  It "Accepts a custom message parameter" {
    # Just verifies the parameter binding works; on non-Windows this warns rather than throwing
    { Require-Admin -Message 'Custom admin message' } | Should -Not -Throw
  }
}

Describe "Ensure-Directory path traversal guard" {
  It "Does not create directory when path contains .." {
    $traversalPath = Join-Path ([System.IO.Path]::GetTempPath()) "test-ensure-dir/../../../should-not-create"
    Ensure-Directory -Path $traversalPath
    Test-Path -LiteralPath $traversalPath | Should -Be $false
  }
}

Describe "Get-CallerValue" {
  It "Returns null when variable is not found in any scope" {
    $result = Get-CallerValue -Name 'VariableThatDoesNotExist_12345XYZ'
    $result | Should -BeNullOrEmpty
  }

  It "Does not throw when looking up any variable name" {
    # Get-CallerValue should never throw, even when variable does not exist
    { Get-CallerValue -Name 'PATH' } | Should -Not -Throw
  }
}

Describe "Read-JsonConfig" {
  BeforeEach {
    if (Test-Path -LiteralPath $script:TestDir) {
      Remove-Item -LiteralPath $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
  }

  It "Returns null for non-existent file" {
    $result = Read-JsonConfig -Path 'C:\NonExistent12345\config.json'
    $result | Should -BeNullOrEmpty
  }

  It "Parses valid JSON" {
    $json = '{"Key": "Value", "Number": 42}'
    $json | Out-File -FilePath $script:TestJsonFile -Encoding UTF8

    $result = Read-JsonConfig -Path $script:TestJsonFile
    $result.Key | Should -Be 'Value'
    $result.Number | Should -Be 42
  }

  It "Returns null for invalid JSON" {
    'not valid json' | Out-File -FilePath $script:TestJsonFile -Encoding UTF8

    $result = Read-JsonConfig -Path $script:TestJsonFile
    $result | Should -BeNullOrEmpty
  }

  It "Returns null for empty file" {
    '' | Out-File -FilePath $script:TestJsonFile -Encoding UTF8

    $result = Read-JsonConfig -Path $script:TestJsonFile
    $result | Should -BeNullOrEmpty
  }

  It "Handles nested JSON objects" {
    $json = '{"Outer": {"Inner": {"Value": "Deep"}}}'
    $json | Out-File -FilePath $script:TestJsonFile -Encoding UTF8

    $result = Read-JsonConfig -Path $script:TestJsonFile
    $result.Outer.Inner.Value | Should -Be 'Deep'
  }

  It "Handles JSON arrays" {
    $json = '{"Items": [1, 2, 3]}'
    $json | Out-File -FilePath $script:TestJsonFile -Encoding UTF8

    $result = Read-JsonConfig -Path $script:TestJsonFile
    $result.Items.Count | Should -Be 3
    $result.Items[1] | Should -Be 2
  }
}
