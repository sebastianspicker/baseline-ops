#requires -version 5.1

BeforeAll {
  Import-Module (Join-Path $PSScriptRoot '../../lib/Validation.psm1') -Force
}

Describe 'Test-PathTraversal' {
  It 'Returns true for traversal path' {
    Test-PathTraversal -Path '..\evil\file.txt' | Should -Be $true
  }

  It 'Returns false for safe path' {
    Test-PathTraversal -Path 'C:\Temp\safe.txt' | Should -Be $false
  }
}

Describe 'Test-SafeScriptName' {
  It 'Accepts numbered script names' {
    Test-SafeScriptName -Name '18-Firewall-Baseline.ps1' | Should -Be $true
  }

  It 'Rejects path components' {
    Test-SafeScriptName -Name '..\outside.ps1' | Should -Be $false
  }

  It 'Rejects unsafe characters' {
    Test-SafeScriptName -Name '18-Bad:Name.ps1' | Should -Be $false
    Test-SafeScriptName -Name '18-Bad*Name.ps1' | Should -Be $false
  }
}

Describe 'Test-ValidGitRef' {
  It 'Accepts branch ref' {
    Test-ValidGitRef -Ref 'main' | Should -Be $true
  }

  It 'Rejects unsafe ref' {
    Test-ValidGitRef -Ref '../main' | Should -Be $false
  }
}

Describe 'Assert-NoPathTraversal' {
  It 'Does not throw for safe path' {
    { Assert-NoPathTraversal -Path 'C:\Temp\safe.txt' } | Should -Not -Throw
  }

  It 'Throws for traversal path' {
    { Assert-NoPathTraversal -Path '..\evil\file.txt' } | Should -Throw '*path traversal*'
  }

  It 'Throws with custom parameter name in message' {
    { Assert-NoPathTraversal -Path '..\escape' -ParameterName 'ConfigPath' } | Should -Throw '*ConfigPath*'
  }
}

Describe 'Test-SafeUrl' {
  It 'Accepts https URL' {
    Test-SafeUrl -Url 'https://example.com/resource' | Should -Be $true
  }

  It 'Accepts http URL' {
    Test-SafeUrl -Url 'http://example.com/resource' | Should -Be $true
  }

  It 'Rejects file:// scheme' {
    Test-SafeUrl -Url 'file:///etc/passwd' | Should -Be $false
  }

  It 'Rejects ftp:// scheme' {
    Test-SafeUrl -Url 'ftp://evil.com/payload' | Should -Be $false
  }

  It 'Rejects null or empty' {
    Test-SafeUrl -Url $null | Should -Be $false
    Test-SafeUrl -Url '' | Should -Be $false
    Test-SafeUrl -Url '   ' | Should -Be $false
  }

  It 'Rejects argument injection via leading dash' {
    Test-SafeUrl -Url '-http://evil.com' | Should -Be $false
  }

  It 'Rejects relative URLs' {
    Test-SafeUrl -Url '/relative/path' | Should -Be $false
  }

  It 'Accepts custom allowed schemes' {
    Test-SafeUrl -Url 'ftp://example.com' -AllowedSchemes @('ftp') | Should -Be $true
  }
}

Describe 'Test-PathUnderRoot' {
  It 'Returns true when path is under root' {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
    $child = Join-Path $tempRoot 'subdir/file.txt'
    Test-PathUnderRoot -Path $child -Root $tempRoot | Should -Be $true
  }

  It 'Returns false when path escapes root' {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
    $escaped = Join-Path $tempRoot '../../etc/passwd'
    Test-PathUnderRoot -Path $escaped -Root $tempRoot | Should -Be $false
  }

  It 'Returns false for a sibling directory' {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
    $sibling = Join-Path (Split-Path $tempRoot -Parent) 'sibling-dir'
    Test-PathUnderRoot -Path $sibling -Root $tempRoot | Should -Be $false
  }
}
