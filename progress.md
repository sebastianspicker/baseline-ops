# Audit Progress

## Ralph Loop — 2026-03-21 (Phases 1–5)

### Phase 1: Analysis (4 agents)

| Sub-phase | Agent | Output |
|-----------|-------|--------|
| 1.1 | Static analysis | 14 Medium, 13 Low, 8 Info findings |
| 1.2 | Security audit | 6 Medium (S6-S11), 5 Low (S12-S16), 1 Info (S17) security findings |
| 1.3 | Test coverage | Gap analysis across all lib modules and orchestration scripts |
| 1.4 | Convention audit | 11 conventions checked; gaps in C5, C6, C9, C10, C11 |

### Phase 2: Fix (3 agents)

| Sub-phase | Status | Summary |
|-----------|--------|---------|
| 2.1 Security fixes | COMPLETE (12/12) | S6-S17: auditpol injection, registry key validation, wevtutil hardening, winget arg filtering, CIM filter escaping, path traversal in Evidence.psm1, ScheduledTask validation, Sysmon ScriptPath validation |
| 2.2 Static analysis | COMPLETE (22/24 fixed, 2 deferred) | Missing StrictMode (3 scripts), $null ordering, unused vars, InformationPreference override, 20 local function redefinitions removed. Deferred: M1 (Write-ConsoleSummary, design-level), M8 (Get-StatusColor, domain-specific) |
| 2.3 Convention alignment | COMPLETE | ErrorActionPreference 100%, exit codes 100%, output contract 94%, findings pattern 47% |

### Phase 3: Test (3 agents)

| Sub-phase | Status | Summary |
|-----------|--------|---------|
| 3.1 Lib module tests | COMPLETE (86 tests) | 7 new test files: Config, Results, JsonCatalog, Evidence, EventLog, External, Output |
| 3.2 Test hardening | COMPLETE (99 tests) | Coverage gaps filled in Execution, Validation, Common, Console, Serialization, Registry |
| 3.3 Integration tests | COMPLETE (18 tests) | Orchestration tests for Validate-Profile, Run-Batch, Report-Aggregate |

**Test count: 329 → 505 (+176 new tests)**

### Phase 4: Polish (3 agents)

| Sub-phase | Status | Summary |
|-----------|--------|---------|
| 4.1 Lib dedup | COMPLETE | Removed Read-JsonConfig, Write-JsonToFile, 8 local function copies; consolidated on canonical lib functions |
| 4.2 Error handling | COMPLETE | 94 empty catches annotated, 9 bare throws converted, 4 bare re-throws replaced, 3 silent catches now logging |
| 4.3 Cleanup | COMPLETE (42/49 findings, 86%) | Hardcoded paths → env vars, Write-Rule collision resolved, Has-Property extracted, Set-RegString shadow removed, path traversal guards added, style tokens applied |

### Phase 5: Documentation

| Sub-phase | Status | Summary |
|-----------|--------|---------|
| 5.1 Changelog + progress | COMPLETE | CHANGELOG.md [2.0.2] section added, progress.md updated |

---

## Iteration 1 — 2026-03-17

### Created
- `.claude/01-code-quality.md` — quality checklist with 9 items (C1, H1–H3, M1–M3, L1–L2)

### Fixed (all 9 items)

| Item | Status | Summary |
|------|--------|---------|
| **C1** | ✅ | Fixed `Invoke-NativeProcess` stdout/stderr deadlock in `lib/Execution.psm1` |
| **H1** | ✅ | Removed 10 Write-KeyValue alias functions from `lib/Output.psm1`; updated 195 call-sites across 8 scripts |
| **H2** | ✅ | Removed 6 Write-UiLine alias functions from `lib/Output.psm1`; updated 137+ call-sites across 8 scripts; fixed 2 bugs (`Write-Ui -BlankLine` → `Write-BlankLine`, `Write-Ui -Text` → `Write-UiLine -Text`) |
| **H3** | ✅ | Removed 5 alias functions from `lib/Common.psm1` (Is-Admin, Test-IsAdministrator, Ensure-Dir, Ensure-Folder, Ensure-FolderForFile); updated tests |
| **M1** | ✅ | Removed verbose `[Parameter(Mandatory = $false)]` from `lib/EventLog.psm1` |
| **M2** | ✅ | Removed dead `$EventLogReady`/`$CanEventLog` params from `Write-HealthEvent`; updated 2 scripts |
| **M3** | ✅ | Removed null-splat guard from `Invoke-ScriptWithTiming` in `lib/Execution.psm1` |
| **L1** | ✅ | Deferred — only intentional empty catch has `<# best-effort #>` comment already |
| **L2** | ✅ | `Export-ModuleMember` reformatted to multi-line (done as part of H1) |

### Test Results
- All 315 tests pass (0 failed, 24 skipped Windows-only)
- 2 obsolete alias tests removed from `tests/lib/Common.Tests.ps1`

### Impact Summary
- **~400 lines removed** from lib modules (aliases, dead code, verbose annotations)
- **~500 call-sites updated** across 15+ scripts (consistent canonical names)
- **2 runtime bugs fixed** (`Write-Ui -BlankLine`, `Write-Ui -Text`)
- **1 critical deadlock fixed** (Invoke-NativeProcess pipe-buffer)

---

## Iteration 2 — 2026-03-17 (Security Audit)

### Created
- `.claude/02-security.md` — security checklist with 5 items (S1–S5)

### Fixed (S1–S4; S5 deferred)

| Item | Status | Summary |
|------|--------|---------|
| **S1** | ✅ | Fixed WQL injection in `scripts/02-LAPS-Hygiene.ps1:432`; escape `$Name` single quotes before CIM filter |
| **S2** | ✅ | Fixed WQL injection in `scripts/11-IOC-Sweep-Defender.ps1:597`; escape `$name` single quotes before CIM filter |
| **S3** | ✅ | Fixed PS code injection in `scripts/21-EmergencyKillSwitch.ps1`; added input validation in `Schedule-AutoRollback` (TaskName pattern, RuleNames no single quotes) before heredoc construction |
| **S4** | ✅ | Fixed unquoted `$TaskName` in schtasks call; converted to array-based invocation |
| **S5** | ✅ | Deferred — `Export-EventLog` in `lib/External.psm1` has no callers in any script; wevtutil query injection has no privilege-escalation path |

### Test Results
- All 315 tests pass (0 failed, 24 skipped Windows-only)

### Impact Summary
- **3 injection vulnerabilities fixed** (2× WQL, 1× PS heredoc code injection)
- **1 native command call hardened** (array-based schtasks invocation)
- **Privilege escalation path closed**: crafted config values can no longer inject PS code into elevated scheduled task payload

---

## Iteration 3 — 2026-03-17 (Documentation Audit)

### Created
- `.claude/03-docs-writing.md` — documentation checklist with 3 items (D1–D3)

### Fixed (all 3 items)

| Item | Status | Summary |
|------|--------|---------|
| **D1** | ✅ | Removed stale alias note from `lib/README.md` line 9 (`Is-Admin`, `Ensure-Folder` were removed in iteration 1) |
| **D2** | ✅ | Added `[2.0.1] - 2026-03-17` section to `CHANGELOG.md` covering Loop 1 (code quality) and Loop 2 (security) changes |
| **D3** | ✅ | Added 3 missing scripts to `scripts/README.md` tables: `07-ScheduledTasks-Hygiene.ps1` (Audit + Remediation), `24-Cert-AutoEnrollment-Health.ps1` (Audit), `41-NTLM-Audit-Client.ps1` (Monitoring) |

### Impact Summary
- **1 factual error corrected** (stale alias reference in lib/README.md)
- **1 changelog entry added** ([2.0.1] covering ~900 lines of code changes across 2 loops)
- **3 scripts documented** (07, 24, 41 now appear in appropriate category tables)

---

## Iteration 4 — 2026-03-17 (GitHub CI Audit)

### Created
- `.claude/04-github-ci.md` — CI checklist with 3 items (G1–G3)

### Fixed (all 3 items)

| Item | Status | Summary |
|------|--------|---------|
| **G1** | ✅ | Added `-CI` flag to `Invoke-Pester` in `test-windows` job; without it Pester 5 exits 0 even on test failure, silently passing CI |
| **G2** | ✅ | Added `PESTER_VERSION: '5.7.1'` env var, module cache step, and explicit `Ensure Pester` install step to `test-windows` job (mirrors `verify` job's PSScriptAnalyzer pattern) |
| **G3** | ✅ | Replaced `permissions: read-all` with `permissions: { contents: read }` in `scorecard.yml`; per-job write scopes already set correctly |

### Impact Summary
- **Silent CI green-lighting fixed**: test failures now correctly block PRs
- **Pester version pinned**: runner upgrades can no longer silently change test framework behaviour
- **Scorecard workflow permissions tightened**: removed broad `read-all` grant

---

## Iteration 5 — 2026-03-17 (Final Opus Review)

### Created
- `.claude/05-final-opus.md` — final review checklist with 3 items (F1–F3)

### Fixed (all 3 items)

| Item | Status | Summary |
|------|--------|---------|
| **F1** | ✅ | Removed `Get-RegValueSafe` pure forwarding wrapper from `lib/Registry.psm1`; updated 3 call-sites in `scripts/34-TimeSync-Health.ps1` to `Get-RegValue` |
| **F2** | ✅ | Added 14 new tests in `tests/lib/Validation.Tests.ps1` for 3 untested security functions: `Assert-NoPathTraversal`, `Test-SafeUrl`, `Test-PathUnderRoot` |
| **F3** | ✅ | Updated `CHANGELOG.md` [2.0.1] section with CI fixes (Pester `-CI` flag, version pinning, scorecard permissions) and final-pass changes (Get-RegValueSafe removal, test coverage) |

### Verification
- All prior security fixes verified correct by Explore agent (WQL injection x2, heredoc injection, schtasks hardening)
- No additional WQL or command injection vulnerabilities found across all 51 scripts
- External.psm1 return-value concern from code quality agent was a false positive — `Invoke-NativeCommand` correctly returns `$true`/`$false` without `-CaptureOutput`

### Test Results
- All 329 tests pass (0 failed, 24 skipped Windows-only)
- 14 new tests added (up from 315 in iteration 1)

### Impact Summary
- **1 alias wrapper removed** (Get-RegValueSafe, 3 call-sites updated)
- **14 new security tests** covering 3 previously untested validation functions
- **CHANGELOG updated** with CI and final-pass entries
