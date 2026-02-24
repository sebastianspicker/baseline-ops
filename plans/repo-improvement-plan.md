# Windows MDM Security Hardening Kit - Comprehensive Improvement Plan

## Overview

This plan outlines a systematic approach to improve the repository across multiple dimensions: cleanup, bug fixes, code deduplication, refactoring, and new features.

---

## 1. Repository Cleanup

### 1.1 File Structure Analysis

Current structure:
```
/
├── .gitignore
├── BUGS_AND_FIXES.md          # 369 lines - should be converted to Issues
├── CONTRIBUTING.md            # OK
├── LICENSE                    # OK
├── PSScriptAnalyzerSettings.psd1
├── README.md                  # 9123 chars - comprehensive
├── SECURITY.md                # OK
├── .github/                   # Empty? Needs investigation
├── lib/                       # 6 modules
├── scripts/                   # 45 scripts + _lib/
├── tests/
└── tools/
```

### 1.2 Cleanup Tasks

| Task | Priority | Description |
|------|----------|-------------|
| Remove empty `.github/` or add workflows | High | Either remove or add proper CI/CD workflows |
| Convert BUGS_AND_FIXES.md to GitHub Issues | High | 36 documented bugs should be trackable issues |
| Consolidate documentation | Medium | Merge lib/README.md content into main README or keep separate |
| Add `.editorconfig` | Low | Consistent formatting across editors |
| Add `CHANGELOG.md` | Medium | Track version history |

---

## 2. Remove Unnecessary Documentation and Artifacts

### 2.1 Documentation Audit

| File | Action | Reason |
|------|--------|--------|
| `BUGS_AND_FIXES.md` | Convert to Issues | Better tracking, assignees, labels |
| `lib/README.md` | Keep but update | Useful API reference, needs sync with actual functions |
| `CONTRIBUTING.md` | Keep | Standard OSS file |
| `SECURITY.md` | Keep | Standard OSS file |

### 2.2 Code Artifacts to Remove

| Artifact | Location | Action |
|----------|----------|--------|
| Placeholder paths | Multiple scripts | Replace `PATH/TO/JSON` with proper defaults or examples |
| Commented-out code | `38-SecurityOptions-Drift.ps1` | Remove or implement pipeline output |
| Duplicate functions | Multiple scripts | Consolidate into lib modules |

---

## 3. Bug Fixes - Critical Issues

Based on `BUGS_AND_FIXES.md`, prioritize fixes:

### 3.1 Critical Bugs - Must Fix

| ID | Bug | Impact | Fix |
|----|-----|--------|-----|
| #11 | Path traversal in `00-Run-Local.ps1` | Security | Validate ScriptName, resolve under scripts root |
| #1, #16 | Audit-only modifies firewall | Trust | Gate `Disable-LocalBuiltinRdpInbound` behind `-Remediate` |
| #2, #17 | Audit-only creates registry keys | Trust | Gate all key creation behind `-Remediate` |
| #4, #15, #29 | `New-FindingsList` returns `$null` | Functionality | Use comma operator to prevent enumeration |
| #5, #14 | `Set-RegDword` returns `$null` | False failures | Return boolean properly |
| #12 | `Write-HealthEvent` unknown parameters | Runtime failure | Add `-EventLogReady`/`-CanEventLog` parameters |
| #13 | `Ensure-EventSource` parameter mismatch | Runtime failure | Add `-SourceName` alias, make `-LogName` optional |

### 3.2 High Priority Bugs

| ID | Bug | Impact | Fix |
|----|-----|--------|-----|
| #23 | Option injection in `00-Copy-Local.ps1` | Security | Validate RepoUrl/RepoPath/RepoRef |
| #24 | Supply-chain drift | Security | Verify remote URL matches when .git exists |
| #21 | schtasks exit code not validated | Reliability | Check `$LASTEXITCODE` after external commands |
| #7, #30, #32 | External command exit codes | Reliability | Validate all `schtasks`, `auditpol`, `reg`, `wevtutil`, `wecutil` |
| #8, #31 | SilentlyContinue on remediation | Reliability | Use `-ErrorAction Stop` with try/catch |

---

## 4. Code Deduplication

### 4.1 Duplicate Function Analysis

Found **50+ duplicate function patterns** across scripts:

#### Console Output Functions - 15+ duplicates
```
Get-SeverityColor / Get-StatusColor / Get-ColorForLevel / Get-ConsoleColor
Write-ConsoleSummary / Write-PrettySummary / Show-ConsoleSummary
Get-SeverityRank
```

#### Config/JSON Functions - 12+ duplicates
```
Load-Catalog / Load-JsonFile / Read-Json / Try-LoadJsonFile / Import-JsonConfig
Get-DefaultConfig / New-DefaultCatalog / Get-DefaultCatalog
Save-Json / Save-JsonUtf8NoBom
```

#### Path Helpers - 8+ duplicates
```
Ensure-Dir / Ensure-Directory / Ensure-Folder / Ensure-ExportDirectory
Expand-Env / Expand-EnvPath
```

#### Admin Checks - 3+ duplicates
```
Is-Admin / Test-IsAdmin / SB_IsAdmin
```

#### Registry Helpers - 5+ duplicates
```
Ensure-Key / Ensure-RegKey / Ensure-RegistryKey
Get-Reg / Get-RegValue / Get-RegDword
Set-REGDWORD / Set-REGSZ / Set-RegString
```

### 4.2 Proposed Library Extensions

#### New Module: `lib/Console.psm1`
```powershell
# Consolidated console helpers
function Get-SeverityColor { param([string]$Severity) ... }
function Get-SeverityRank { param([string]$Severity) ... }
function Write-ConsoleSummary { param([object]$Result, [hashtable]$Config) ... }
function Write-SectionHeader { param([string]$Title, [int]$Width = 70) ... }
```

#### New Module: `lib/Config.psm1` - Extensions
```powershell
# Already exists, add:
function Get-DefaultConfig { param([string]$ScriptName) ... }
function Merge-ConfigWithDefaults { param([object]$Config, [hashtable]$Defaults) ... }
```

#### New Module: `lib/External.psm1`
```powershell
# External command wrappers with exit code validation
function Invoke-Git { param([string[]]$Arguments) ... }
function Invoke-Schtasks { param([string[]]$Arguments) ... }
function Invoke-Auditpol { param([string[]]$Arguments) ... }
function Invoke-RegExe { param([string[]]$Arguments) ... }
function Invoke-Wevtutil { param([string[]]$Arguments) ... }
```

#### Extend: `lib/Registry.psm1`
```powershell
# Add missing types
function Set-RegQword { ... }
function Set-RegExpandString { ... }
function Set-RegMultiString { ... }
function Set-RegBinary { ... }
function Get-RegKeyExists { ... }
```

### 4.3 Deduplication Priority Matrix

| Priority | Functions | Affected Scripts | Effort |
|----------|-----------|------------------|--------|
| P1 | `Get-SeverityColor`, `Get-SeverityRank` | 15+ scripts | Low |
| P1 | `Ensure-Dir` variants | 10+ scripts | Low |
| P1 | JSON loading functions | 20+ scripts | Medium |
| P2 | `Write-ConsoleSummary` variants | 25+ scripts | Medium |
| P2 | Admin check functions | 5+ scripts | Low |
| P3 | Registry helpers | 8+ scripts | Medium |

---

## 5. Code Refactoring

### 5.1 Standardize Script Structure

All scripts should follow this template:
```powershell
#requires -version 5.1
<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER
.OUTPUTS
.EXAMPLE
.NOTES
#>

[CmdletBinding()]
param(
  [switch]$Remediate,
  [string]$ConfigPath = $null,  # No placeholder!
  # ... other params
)

# Bootstrap and imports
. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Common.psm1') -Force
# Import only what's needed

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Script-level variables
$script:EventSource = 'MyScript'
$script:EventLogName = 'Application'

# Helper functions (only script-specific)
# ...

# Main logic
try {
  # ...
} catch {
  # ...
}
```

### 5.2 Refactoring Tasks

| Task | Scripts Affected | Description |
|------|------------------|-------------|
| Remove placeholder paths | All with `PATH/TO/*` | Use `$null` or script-specific defaults |
| Standardize parameter names | Multiple | Use consistent `-ConfigPath`, `-AuditPath`, `-Remediate` |
| Add `-WhatIf`/`-Confirm` | Remediation scripts | Support ShouldProcess |
| Fix pipeline output | `38-SecurityOptions-Drift.ps1` | Uncomment or remove documentation |
| Extract inline functions | All | Move duplicates to lib modules |
| Add proper error handling | All | Replace `SilentlyContinue` with structured handling |

### 5.3 Error Handling Standardization

Replace patterns like:
```powershell
# BAD
try {
  Remove-Item $path -ErrorAction SilentlyContinue
  Write-Success "Removed $path"
} catch { }
```

With:
```powershell
# GOOD
try {
  Remove-Item $path -ErrorAction Stop
  Write-Success "Removed $path"
} catch {
  Add-Finding -Code 'REMOVE_FAILED' -Severity 'Warning' -Message "Failed to remove $path: $($_.Exception.Message)"
}
```

---

## 6. Quality of Life Improvements

### 6.1 Developer Experience

| Improvement | Description |
|-------------|-------------|
| Add `scripts/README.md` | Document all 45 scripts with one-liner descriptions |
| Add script categories | Group scripts: Audit, Remediate, Collection, Utility |
| Add `-Verbose` support | All scripts should support verbose output |
| Add `-Quiet` support | Suppress console output for automation |
| Improve comment-based help | Ensure all scripts have complete help |

### 6.2 Operational Improvements

| Improvement | Description |
|-------------|-------------|
| Add exit code constants | Define `$EXIT_SUCCESS = 0`, `$EXIT_ERROR = 1`, `$EXIT_PARTIAL = 2` |
| Standardize JSON schemas | Create JSON schema files for config validation |
| Add config examples | Provide example JSON configs in `examples/` directory |
| Add logging options | Optional file logging for all scripts |

### 6.3 Testing Infrastructure

| Improvement | Description |
|-------------|-------------|
| Add Pester tests | Unit tests for lib modules |
| Add integration tests | Test script syntax and parameter binding |
| Add mock data | Sample configs and outputs for testing |

---

## 7. Potential New Functions

### 7.1 New Library Functions

#### `lib/External.psm1`
```powershell
function Invoke-NativeCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [switch]$ThrowOnError
  )
  # Execute, capture output, validate exit code
}
```

#### `lib/Validation.psm1`
```powershell
function Test-PathTraversal {
  param([string]$Path)
  # Check for ..\ and other traversal patterns
}

function Test-SafeScriptName {
  param([string]$Name)
  # Validate script name is safe (no path chars)
}

function Test-ValidGitRef {
  param([string]$Ref)
  # Validate git ref format
}
```

#### `lib/Crypto.psm1`
```powershell
function Get-FileHashSafe {
  param([string]$Path, [string]$Algorithm = 'SHA256')
  # Wrapper with error handling
}

function Test-FileSignature {
  param([string]$Path)
  # Get authenticode signature info
}
```

### 7.2 New Scripts

| Script | Purpose |
|--------|---------|
| `46-Intune-Policy-Drift.ps1` | Compare local settings with Intune policy baseline |
| `47-EventLog-Forwarding-Test.ps1` | Test WEF connectivity and forwarding |
| `48-Security-Baseline-Compare.ps1` | Compare against Microsoft security baselines |
| `49-Audit-Policy-Enforce.ps1` | Enforce advanced audit policy settings |
| `50-Service-Hardening.ps1` | Service configuration hardening |

### 7.3 New Utility Functions

```powershell
# In lib/Common.psm1
function Get-ScriptMetadata {
  # Extract version, author, etc. from script header
}

function Compare-ObjectDeep {
  # Deep object comparison for drift detection
}

function Export-ObjectToMultipleFormats {
  # Export to CSV, JSON, XML in one call
}
```

---

## 8. Implementation Phases

### Phase 1: Critical Fixes - ✅ COMPLETED

| Bug | Status | Notes |
|-----|--------|-------|
| Path traversal in `00-Run-Local.ps1` | ✅ Already fixed | Lines 72-92 validate ScriptName |
| Audit-only modifying state bugs | ✅ Fixed | Updated `05-WUFB-Proofing.ps1` and `04-OfficeBrowser-Hardening-Proof.ps1` |
| `New-FindingsList` enumeration bug | ✅ Already fixed | Line 7 uses comma operator |
| `Set-RegDword` return value | ✅ Already fixed | Returns `$true`/`$false` properly |
| EventLog parameter mismatches | ✅ Already fixed | Parameters added in `lib/EventLog.psm1` |

### Phase 2: Library Consolidation - ✅ COMPLETED

| Task | Status | Notes |
|------|--------|-------|
| Create `lib/Console.psm1` | ✅ Complete | Consolidated Get-SeverityColor, Get-SeverityRank, Write-ConsoleSummary, and related functions |
| Create `lib/External.psm1` | ✅ Complete | Added wrappers for schtasks, auditpol, wevtutil, wecutil, reg.exe, git with exit code validation |
| Extend `lib/Registry.psm1` | ✅ Complete | Added Set-RegQword, Set-RegExpandString, Set-RegMultiString, Set-RegBinary, Get-RegKeyExists, Get-RegValueExists, Get-RegDword, Get-RegString, Remove-RegistryKeyIfExists |
| Update `lib/README.md` | ✅ Complete | Documented all new modules and functions |
| Update scripts to use consolidated functions | ⏳ Pending | Scripts can be updated incrementally; new functions are backward-compatible |

### Phase 3: Code Quality - ⏳ IN PROGRESS

| Task | Status | Notes |
|------|--------|-------|
| Remove placeholder paths from parameter defaults | ✅ Complete | Fixed 31 parameter defaults using tools/fix-placeholders.ps1 |
| Remove placeholder paths from internal variables | ✅ Complete | Fixed key scripts: 07, 09, 11 |
| Standardize error handling | ✅ Complete | Fixed SilentlyContinue in remediation scripts: 11, 14, 21 |
| Add proper `-WhatIf`/`-Confirm` support | ✅ Complete | Added SupportsShouldProcess to 22 remediation scripts |
| Add comprehensive comment-based help | ⏳ Pending | Ensure all scripts have complete help |

**Note:** Remaining PATH/TO occurrences in documentation/examples are intentional for illustration purposes.

### Phase 4: Documentation & Testing - ✅ COMPLETED

| Task | Status | Notes |
|------|--------|-------|
| Add `scripts/README.md` | ✅ Complete | Comprehensive documentation of all 45 scripts with categories, usage patterns, and examples |
| Add Pester tests for lib modules | ✅ Complete | Created tests for Registry.psm1, Common.psm1, Console.psm1 in `tests/lib/` |
| Create example configs | ✅ Complete | Created 4 example configs in `examples/configs/` with README |
| Convert BUGS_AND_FIXES.md to GitHub Issues | ⏳ Pending | Manual process - create issues from documented bugs |

### Phase 5: New Features
1. Implement new library functions
2. Create new scripts as prioritized
3. Add CI/CD workflows

---

## 9. Architecture Diagram

```mermaid
graph TB
    subgraph Library Layer
        Common[Common.psm1]
        Output[Output.psm1]
        Registry[Registry.psm1]
        Config[Config.psm1]
        EventLog[EventLog.psm1]
        Results[Results.psm1]
        Console[Console.psm1 - NEW]
        External[External.psm1 - NEW]
        Validation[Validation.psm1 - NEW]
    end

    subgraph Script Categories
        Audit[Audit Scripts - 20+]
        Remediate[Remediation Scripts - 10+]
        Collection[Collection Scripts - 5+]
        Utility[Utility Scripts - 5+]
    end

    subgraph Infrastructure
        Bootstrap[_lib/Bootstrap.ps1]
        Tests[tests/]
        Tools[tools/]
    end

    Audit --> Common
    Audit --> Output
    Audit --> Console
    Audit --> Results

    Remediate --> Common
    Remediate --> Registry
    Remediate --> External
    Remediate --> EventLog

    Collection --> Common
    Collection --> Output
    Collection --> External

    Utility --> Common
    Utility --> Config
    Utility --> Validation

    Bootstrap --> Library Layer
```

---

## 10. Metrics and Success Criteria

| Metric | Current | Target |
|--------|---------|--------|
| Duplicate functions | 50+ | <10 |
| Scripts with placeholder paths | 30+ | 0 |
| Scripts with proper error handling | ~50% | 100% |
| Library test coverage | 0% | 80%+ |
| Open bugs in BUGS_AND_FIXES.md | 36 | 0 - converted to Issues |
| Scripts with `-WhatIf` support | ~30% | 100% for remediation scripts |

---

## 11. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking changes in lib modules | Medium | High | Version modules, deprecation warnings |
| Scripts fail after deduplication | Medium | High | Comprehensive testing before merge |
| New bugs introduced | Medium | Medium | Add tests, code review |
| Scope creep | High | Medium | Stick to phased approach |

---

## Next Steps

1. Review and approve this plan
2. Create GitHub Issues for each phase
3. Begin Phase 1 implementation
4. Set up CI/CD for automated testing
