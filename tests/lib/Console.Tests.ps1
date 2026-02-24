#requires -version 5.1
<#
.SYNOPSIS
Pester tests for Console.psm1 module

.DESCRIPTION
Unit tests for the Console module functions including:
- Get-SeverityColor
- Get-StatusColor
- Get-SeverityRank
- Get-SeverityPrefix
#>

[CmdletBinding()]
param()

BeforeAll {
  # Import the module
  $modulePath = Join-Path $PSScriptRoot '../../lib/Console.psm1'
  Import-Module $modulePath -Force
}

Describe "Get-SeverityColor" {
  It "Returns Red for Critical" {
    $result = Get-SeverityColor -Severity 'Critical'
    $result | Should -Be 'Red'
  }

  It "Returns Red for High" {
    $result = Get-SeverityColor -Severity 'High'
    $result | Should -Be 'Red'
  }

  It "Returns Yellow for Medium" {
    $result = Get-SeverityColor -Severity 'Medium'
    $result | Should -Be 'Yellow'
  }

  It "Returns Cyan for Low" {
    $result = Get-SeverityColor -Severity 'Low'
    $result | Should -Be 'Cyan'
  }

  It "Returns Gray for Info" {
    $result = Get-SeverityColor -Severity 'Info'
    $result | Should -Be 'Gray'
  }

  It "Returns Yellow for Warning" {
    $result = Get-SeverityColor -Severity 'Warning'
    $result | Should -Be 'Yellow'
  }

  It "Returns Red for Error" {
    $result = Get-SeverityColor -Severity 'Error'
    $result | Should -Be 'Red'
  }

  It "Returns Green for OK" {
    $result = Get-SeverityColor -Severity 'OK'
    $result | Should -Be 'Green'
  }

  It "Returns Green for Pass" {
    $result = Get-SeverityColor -Severity 'Pass'
    $result | Should -Be 'Green'
  }

  It "Returns Red for Fail" {
    $result = Get-SeverityColor -Severity 'Fail'
    $result | Should -Be 'Red'
  }

  It "Returns DarkGray for Skip" {
    $result = Get-SeverityColor -Severity 'Skip'
    $result | Should -Be 'DarkGray'
  }

  It "Throws for invalid severity" {
    { Get-SeverityColor -Severity 'Invalid' } | Should -Throw
  }
}

Describe "Get-StatusColor" {
  It "Normalizes Critical to Red" {
    $result = Get-StatusColor -Status 'Critical'
    $result | Should -Be 'Red'
  }

  It "Normalizes Crit to Red" {
    $result = Get-StatusColor -Status 'Crit'
    $result | Should -Be 'Red'
  }

  It "Normalizes High to Red" {
    $result = Get-StatusColor -Status 'High'
    $result | Should -Be 'Red'
  }

  It "Normalizes Error to Red" {
    $result = Get-StatusColor -Status 'Error'
    $result | Should -Be 'Red'
  }

  It "Normalizes Err to Red" {
    $result = Get-StatusColor -Status 'Err'
    $result | Should -Be 'Red'
  }

  It "Normalizes Fail to Red" {
    $result = Get-StatusColor -Status 'Fail'
    $result | Should -Be 'Red'
  }

  It "Normalizes Failed to Red" {
    $result = Get-StatusColor -Status 'Failed'
    $result | Should -Be 'Red'
  }

  It "Normalizes Medium to Yellow" {
    $result = Get-StatusColor -Status 'Medium'
    $result | Should -Be 'Yellow'
  }

  It "Normalizes Warn to Yellow" {
    $result = Get-StatusColor -Status 'Warn'
    $result | Should -Be 'Yellow'
  }

  It "Normalizes Warning to Yellow" {
    $result = Get-StatusColor -Status 'Warning'
    $result | Should -Be 'Yellow'
  }

  It "Normalizes Drift to Yellow" {
    $result = Get-StatusColor -Status 'Drift'
    $result | Should -Be 'Yellow'
  }

  It "Normalizes Changed to Yellow" {
    $result = Get-StatusColor -Status 'Changed'
    $result | Should -Be 'Yellow'
  }

  It "Normalizes OK to Green" {
    $result = Get-StatusColor -Status 'OK'
    $result | Should -Be 'Green'
  }

  It "Normalizes Pass to Green" {
    $result = Get-StatusColor -Status 'Pass'
    $result | Should -Be 'Green'
  }

  It "Normalizes Passed to Green" {
    $result = Get-StatusColor -Status 'Passed'
    $result | Should -Be 'Green'
  }

  It "Normalizes Good to Green" {
    $result = Get-StatusColor -Status 'Good'
    $result | Should -Be 'Green'
  }

  It "Normalizes Success to Green" {
    $result = Get-StatusColor -Status 'Success'
    $result | Should -Be 'Green'
  }

  It "Normalizes Skip to DarkGray" {
    $result = Get-StatusColor -Status 'Skip'
    $result | Should -Be 'DarkGray'
  }

  It "Normalizes Skipped to DarkGray" {
    $result = Get-StatusColor -Status 'Skipped'
    $result | Should -Be 'DarkGray'
  }

  It "Defaults unknown status to Gray" {
    $result = Get-StatusColor -Status 'UnknownStatus'
    $result | Should -Be 'Gray'
  }
}

Describe "Get-ColorForLevel" {
  It "Returns Red for Critical" {
    $result = Get-ColorForLevel -Level 'Critical'
    $result | Should -Be 'Red'
  }

  It "Returns Red for High" {
    $result = Get-ColorForLevel -Level 'High'
    $result | Should -Be 'Red'
  }

  It "Returns Yellow for Medium" {
    $result = Get-ColorForLevel -Level 'Medium'
    $result | Should -Be 'Yellow'
  }

  It "Returns Cyan for Low" {
    $result = Get-ColorForLevel -Level 'Low'
    $result | Should -Be 'Cyan'
  }

  It "Returns Gray for Info" {
    $result = Get-ColorForLevel -Level 'Info'
    $result | Should -Be 'Gray'
  }
}

Describe "Get-ConsoleColor" {
  It "Returns Green for OK" {
    $result = Get-ConsoleColor -Kind 'OK'
    $result | Should -Be 'Green'
  }

  It "Returns Yellow for WARN" {
    $result = Get-ConsoleColor -Kind 'WARN'
    $result | Should -Be 'Yellow'
  }

  It "Returns Red for ERR" {
    $result = Get-ConsoleColor -Kind 'ERR'
    $result | Should -Be 'Red'
  }

  It "Returns Gray for INFO" {
    $result = Get-ConsoleColor -Kind 'INFO'
    $result | Should -Be 'Gray'
  }

  It "Returns DarkGray for DIM" {
    $result = Get-ConsoleColor -Kind 'DIM'
    $result | Should -Be 'DarkGray'
  }

  It "Returns Red for CRIT" {
    $result = Get-ConsoleColor -Kind 'CRIT'
    $result | Should -Be 'Red'
  }

  It "Returns Red for HIGH" {
    $result = Get-ConsoleColor -Kind 'HIGH'
    $result | Should -Be 'Red'
  }

  It "Returns Yellow for MED" {
    $result = Get-ConsoleColor -Kind 'MED'
    $result | Should -Be 'Yellow'
  }

  It "Returns Cyan for LOW" {
    $result = Get-ConsoleColor -Kind 'LOW'
    $result | Should -Be 'Cyan'
  }
}

Describe "Get-SeverityRank" {
  It "Returns 4 for Critical" {
    $result = Get-SeverityRank -Severity 'Critical'
    $result | Should -Be 4
  }

  It "Returns 3 for High" {
    $result = Get-SeverityRank -Severity 'High'
    $result | Should -Be 3
  }

  It "Returns 2 for Medium" {
    $result = Get-SeverityRank -Severity 'Medium'
    $result | Should -Be 2
  }

  It "Returns 1 for Low" {
    $result = Get-SeverityRank -Severity 'Low'
    $result | Should -Be 1
  }

  It "Returns 0 for Info" {
    $result = Get-SeverityRank -Severity 'Info'
    $result | Should -Be 0
  }

  It "Returns -1 for OK" {
    $result = Get-SeverityRank -Severity 'OK'
    $result | Should -Be -1
  }

  It "Returns -2 for Skip" {
    $result = Get-SeverityRank -Severity 'Skip'
    $result | Should -Be -2
  }

  It "Normalizes Error to High (3)" {
    $result = Get-SeverityRank -Severity 'Error'
    $result | Should -Be 3
  }

  It "Normalizes Warning to Medium (2)" {
    $result = Get-SeverityRank -Severity 'Warning'
    $result | Should -Be 2
  }
}

Describe "Get-SeverityPrefix" {
  It "Returns [CRIT] for Critical" {
    $result = Get-SeverityPrefix -Severity 'Critical'
    $result | Should -Be '[CRIT] '
  }

  It "Returns [HIGH] for High" {
    $result = Get-SeverityPrefix -Severity 'High'
    $result | Should -Be '[HIGH] '
  }

  It "Returns [MED] for Medium" {
    $result = Get-SeverityPrefix -Severity 'Medium'
    $result | Should -Be '[MED]  '
  }

  It "Returns [LOW] for Low" {
    $result = Get-SeverityPrefix -Severity 'Low'
    $result | Should -Be '[LOW]  '
  }

  It "Returns [INFO] for Info" {
    $result = Get-SeverityPrefix -Severity 'Info'
    $result | Should -Be '[INFO] '
  }

  It "Returns [OK] for OK" {
    $result = Get-SeverityPrefix -Severity 'OK'
    $result | Should -Be '[OK]   '
  }

  It "Returns [SKIP] for Skip" {
    $result = Get-SeverityPrefix -Severity 'Skip'
    $result | Should -Be '[SKIP] '
  }
}

Describe "Get-FindingStats" {
  BeforeAll {
    # Create mock findings
    $script:MockFindings = [System.Collections.ArrayList]@(
      [pscustomobject]@{ Severity = 'High'; Code = 'TEST001'; Message = 'Test 1' }
      [pscustomobject]@{ Severity = 'High'; Code = 'TEST002'; Message = 'Test 2' }
      [pscustomobject]@{ Severity = 'Medium'; Code = 'TEST003'; Message = 'Test 3' }
      [pscustomobject]@{ Severity = 'Low'; Code = 'TEST004'; Message = 'Test 4' }
      [pscustomobject]@{ Severity = 'Info'; Code = 'TEST005'; Message = 'Test 5' }
      [pscustomobject]@{ Severity = 'Warning'; Code = 'TEST006'; Message = 'Test 6' }
    )
  }

  It "Returns correct total count" {
    $result = Get-FindingStats -Findings $script:MockFindings
    $result.Total | Should -Be 6
  }

  It "Returns correct High count" {
    $result = Get-FindingStats -Findings $script:MockFindings
    $result.High | Should -Be 2
  }

  It "Returns correct Medium count" {
    $result = Get-FindingStats -Findings $script:MockFindings
    $result.Medium | Should -Be 2  # Medium + Warning
  }

  It "Returns correct Low count" {
    $result = Get-FindingStats -Findings $script:MockFindings
    $result.Low | Should -Be 1
  }

  It "Returns correct Info count" {
    $result = Get-FindingStats -Findings $script:MockFindings
    $result.Info | Should -Be 1
  }

  It "Handles empty findings list" {
    $empty = [System.Collections.ArrayList]@()
    $result = Get-FindingStats -Findings $empty
    $result.Total | Should -Be 0
  }
}
