#requires -version 5.1
<#
.SYNOPSIS
Pester tests for EventLog.psm1 module

.DESCRIPTION
Unit tests for Ensure-EventSource and Write-HealthEvent.
These functions depend on Windows Event Log APIs and are skipped on non-Windows.
#>

[CmdletBinding()]
param()

$script:SkipWindowsTests = (-not $IsWindows)

BeforeAll {
  Import-Module (Join-Path $PSScriptRoot '../../lib/Common.psm1') -Force
  Import-Module (Join-Path $PSScriptRoot '../../lib/EventLog.psm1') -Force
}

Describe 'Ensure-EventSource' {
  It 'Returns false and calls OnError when Source is empty' -Skip:$script:SkipWindowsTests {
    $errorMsg = $null
    $onError = { param($m) $script:errorMsg = $m }
    $result = Ensure-EventSource -Source '' -OnError $onError
    $result | Should -Be $false
    $script:errorMsg | Should -Not -BeNullOrEmpty
  }

  It 'Returns true when source already exists' -Skip:$script:SkipWindowsTests {
    # 'Application' source typically exists on Windows
    Mock -CommandName 'New-EventLog' -MockWith { } -ModuleName EventLog
    $result = Ensure-EventSource -Source 'Application' -LogName 'Application'
    $result | Should -Be $true
  }
}

Describe 'Write-HealthEvent' {
  It 'Returns false when Source is missing' -Skip:$script:SkipWindowsTests {
    $errorMsg = $null
    $onError = { param($m) $script:errorMsg = $m }
    $result = Write-HealthEvent -Id 1000 -Message 'Test' -OnError $onError
    $result | Should -Be $false
    $script:errorMsg | Should -Not -BeNullOrEmpty
  }

  It 'Returns false when LogName is missing' -Skip:$script:SkipWindowsTests {
    $errorMsg = $null
    $onError = { param($m) $script:errorMsg = $m }
    $result = Write-HealthEvent -Id 1000 -Message 'Test' -Source 'TestSource' -OnError $onError
    $result | Should -Be $false
    $script:errorMsg | Should -Not -BeNullOrEmpty
  }
}
