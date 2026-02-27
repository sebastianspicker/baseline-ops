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
