# Final Review — win-mdm-security-hardening-kit

This file drives the Ralph Loop final review cycle (Opus pass).
Each iteration reads this file and `progress.md`, picks the next
open item, implements the fix, and updates `progress.md`.

## How to Use This Checklist

- Items are ordered by priority (Critical → High → Medium → Low).
- Work one item per iteration. Mark it complete in `progress.md`.
- Output `<promise>COMPLETE</promise>` only when ALL items below are ✅.

---

## Items

### [HIGH] F1 — Registry.psm1: Remove Get-RegValueSafe pure alias
**File:** `lib/Registry.psm1` lines 26–34, export list
**Problem:** `Get-RegValueSafe` is a one-line forwarding wrapper that adds
nothing over `Get-RegValue`:
```powershell
function Get-RegValueSafe {
  param([string]$Path, [string]$Name)
  return (Get-RegValue -Path $Path -Name $Name)
}
```
3 call-sites exist in `scripts/34-TimeSync-Health.ps1`. This is the same
alias bloat pattern fixed in iteration 1 (H1–H3).
**Fix:**
1. Update 3 call-sites in `34-TimeSync-Health.ps1` to `Get-RegValue`.
2. Remove `Get-RegValueSafe` from `lib/Registry.psm1`.
3. Remove from `Export-ModuleMember`.
**Status:** ✅ Fixed (iteration 1)

---

### [HIGH] F2 — Validation.Tests.ps1: Missing tests for security functions
**File:** `tests/lib/Validation.Tests.ps1`
**Problem:** 3 of 6 exported Validation.psm1 functions have zero test coverage:
- `Assert-NoPathTraversal` — throws on traversal (security boundary enforcement)
- `Test-SafeUrl` — URL scheme whitelist validation
- `Test-PathUnderRoot` — path containment check (prevents path escape attacks)
These are security-critical functions used to prevent injection and traversal.
**Fix:** Add Describe blocks with targeted test cases for each function.
**Status:** ✅ Fixed (iteration 1)

---

### [MEDIUM] F3 — CHANGELOG.md: Missing CI fix entries from iteration 4
**File:** `CHANGELOG.md`
**Problem:** The `[2.0.1]` changelog entry covers iterations 1–3 but omits
iteration 4's CI fixes:
- Pester `-CI` flag (test failures were silently passing CI)
- Pester version pinning + cache
- Scorecard permissions tightened from `read-all` to `contents: read`
**Fix:** Add these to the existing `[2.0.1]` Fixed/Changed sections.
**Status:** ✅ Fixed (iteration 1)

---

## Completion Criteria

Output `<promise>COMPLETE</promise>` when all 3 items show ✅.
