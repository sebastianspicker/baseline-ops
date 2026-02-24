# Implementation Plan: Phases 1-4 Remaining Tasks

## Status Summary

| Phase | Status | Remaining Work |
|-------|--------|----------------|
| Phase 1: Critical Fixes | ✅ Complete | All bugs fixed per plan |
| Phase 2: Library Consolidation | ✅ Complete | Console.psm1, External.psm1, Registry.psm1 extended |
| Phase 3: Code Quality | ⏳ 30% | Error handling, WhatIf/Confirm, help |
| Phase 4: Documentation & Testing | ⏳ 0% | scripts/README.md, Pester tests, examples |

---

## Phase 3 Remaining Tasks

### 3.1 Standardize Error Handling

**Problem:** Many scripts use `-ErrorAction SilentlyContinue` which hides failures.

**Solution Pattern:**
```powershell
# BAD
try {
  Remove-Item $path -ErrorAction SilentlyContinue
  Write-Success "Removed $path"
} catch { }

# GOOD
try {
  Remove-Item $path -ErrorAction Stop
  Write-Success "Removed $path"
} catch {
  Add-Finding -Code 'REMOVE_FAILED' -Severity 'Warning' -Message "Failed to remove $path: $($_.Exception.Message)"
}
```

**Implementation Steps:**
1. Search for `-ErrorAction SilentlyContinue` patterns
2. Replace with `-ErrorAction Stop` + try/catch
3. Add findings for non-critical failures
4. Throw for critical failures

**Files to Update:** ~15 scripts with SilentlyContinue patterns

### 3.2 Add -WhatIf/-Confirm Support

**Problem:** Remediation scripts should support ShouldProcess for safety.

**Solution Pattern:**
```powershell
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
  [switch]$Remediate
)

# In remediation code:
if ($Remediate) {
  if ($PSCmdlet.ShouldProcess($Target, $Operation)) {
    # Perform remediation
  }
}
```

**Implementation Steps:**
1. Add `SupportsShouldProcess=$true` to CmdletBinding
2. Wrap remediation actions in `ShouldProcess` checks
3. Test with `-WhatIf` flag

**Files to Update:** Scripts with `-Remediate` parameter (~20 scripts)

### 3.3 Add Comprehensive Comment-Based Help

**Problem:** Some scripts lack complete help documentation.

**Required Elements:**
```powershell
<#
.SYNOPSIS
Brief description (one line).

.DESCRIPTION
Detailed description of what the script does.

.PARAMETER Remediate
If set, applies remediation instead of audit-only mode.

.PARAMETER ConfigPath
Path to JSON configuration file. If not provided, uses defaults.

.EXAMPLE
.\ScriptName.ps1 -Remediate

.EXAMPLE
.\ScriptName.ps1 -ConfigPath "C:\Config\script-config.json"

.NOTES
Author: Organization
Requires: Admin rights, Windows 10/11
#>
```

**Implementation Steps:**
1. Audit scripts for missing help elements
2. Add missing .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE
3. Ensure consistency across all scripts

**Files to Update:** ~45 scripts

---

## Phase 4 Tasks

### 4.1 Add scripts/README.md

**Content Structure:**
```markdown
# Security Hardening Scripts

## Categories

### Audit Scripts
Scripts that check configuration and report drift.

| Script | Purpose |
|--------|---------|
| 01-ASR-Defender-Allowlist.ps1 | ASR rules and Defender exclusions |
| ... | ... |

### Remediation Scripts
Scripts that can apply fixes.

| Script | Purpose |
|--------|---------|
| ... | ... |

### Collection Scripts
Scripts that gather data for analysis.

| Script | Purpose |
|--------|---------|
| 09-SupportBundle.ps1 | Collect diagnostic bundle |
| ... | ... |

## Usage Patterns
...
```

### 4.2 Add Pester Tests for lib Modules

**Test File Structure:**
```
tests/
├── lib/
│   ├── Common.Tests.ps1
│   ├── Console.Tests.ps1
│   ├── External.Tests.ps1
│   ├── Registry.Tests.ps1
│   ├── Config.Tests.ps1
│   ├── EventLog.Tests.ps1
│   └── Results.Tests.ps1
```

**Example Test (Registry.Tests.ps1):**
```powershell
Describe "Registry Module" {
  BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../lib/Registry.psm1') -Force
  }

  Context "Get-RegValue" {
    It "Returns null for non-existent value" {
      $result = Get-RegValue -Path 'HKLM:\SOFTWARE\NonExistent' -Name 'Value'
      $result | Should -BeNullOrEmpty
    }
  }

  Context "Set-RegDword" {
    It "Returns true on success" {
      # Test with a safe registry location
      $result = Set-RegDword -Path 'HKCU:\Software\Test' -Name 'TestValue' -Value 1
      $result | Should -Be $true
    }
  }
}
```

### 4.3 Create Example Configs

**Directory Structure:**
```
examples/
├── configs/
│   ├── asr-defender-allowlist.json
│   ├── firewall-baseline.json
│   ├── laps-hygiene.json
│   ├── local-admins-allowlist.json
│   ├── office-browser-hardening.json
│   ├── scheduled-tasks-catalog.json
│   └── wufb-proofing.json
└── README.md
```

**Example Config (asr-defender-allowlist.json):**
```json
{
  "Defender": {
    "ExclusionPaths": [
      "C:\\Program Files\\MyApp"
    ],
    "ExclusionProcesses": [
      "myapp.exe"
    ],
    "ExclusionExtensions": [
      ".myext"
    ]
  },
  "ASR": {
    "OnlyExclusions": [
      "C:\\Program Files\\MyApp\\"
    ]
  }
}
```

---

## Implementation Order

1. **Phase 3.1:** Standardize error handling (high impact)
2. **Phase 3.2:** Add -WhatIf/-Confirm support (safety)
3. **Phase 4.1:** Add scripts/README.md (documentation)
4. **Phase 4.3:** Create example configs (usability)
5. **Phase 3.3:** Add comprehensive help (documentation)
6. **Phase 4.2:** Add Pester tests (quality assurance)

---

## Estimated Effort

| Task | Effort | Priority |
|------|--------|----------|
| Error handling standardization | 2-3 hours | High |
| WhatIf/Confirm support | 2-3 hours | High |
| scripts/README.md | 1 hour | Medium |
| Example configs | 1-2 hours | Medium |
| Comment-based help | 3-4 hours | Low |
| Pester tests | 4-5 hours | Medium |

**Total:** ~14-18 hours of work
