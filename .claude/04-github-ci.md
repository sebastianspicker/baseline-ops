# GitHub CI Audit — win-mdm-security-hardening-kit

This file drives the Ralph Loop CI improvement cycle.
Each iteration reads this file and `progress.md`, picks the next
open item, implements the fix, and updates `progress.md`.

## How to Use This Checklist

- Items are ordered by priority (Critical → High → Medium → Low).
- Work one item per iteration. Mark it complete in `progress.md`.
- Output `<promise>COMPLETE</promise>` only when ALL items below are ✅.

---

## Items

### [CRITICAL] G1 — test-windows: Invoke-Pester missing -CI flag
**File:** `.github/workflows/ci.yml` test-windows job
**Problem:** `Invoke-Pester -Path .\tests -Output Detailed` is called without
`-CI`. In Pester 5.x, the default exit code is **0** regardless of test
outcome. A broken test suite would never fail the CI build — every PR passes
the Pester job even if hundreds of tests are red.
**Fix:** Add `-CI` to the `Invoke-Pester` invocation. The `-CI` flag makes
Pester exit with code 1 when any test fails, which GitHub Actions treats as a
step failure.
**Status:** ✅ Fixed (iteration 1)

---

### [HIGH] G2 — test-windows: Pester version not pinned or cached
**File:** `.github/workflows/ci.yml` test-windows job
**Problem:** The job calls `Invoke-Pester` using whatever Pester version the
runner ships with. `windows-latest` upgrades can silently change the Pester
version, breaking tests or changing output format. The `verify` job already
pins PSScriptAnalyzer (`PSSCRIPTANALYZER_VERSION`) and caches it — the test
job should follow the same pattern.
**Fix:**
1. Add `PESTER_VERSION: '5.7.1'` env var to the job.
2. Add a cache step keyed on `psmodules-${{ runner.os }}-pester-${{ env.PESTER_VERSION }}`.
3. Add an "Ensure Pester" install step (mirrors the verify job's PSScriptAnalyzer pattern).
4. Pass `-CI` (covered by G1 but applies here too).
**Status:** ✅ Fixed (iteration 1)

---

### [MEDIUM] G3 — scorecard.yml: top-level permissions: read-all is broader than needed
**File:** `.github/workflows/scorecard.yml`
**Problem:** `permissions: read-all` at the workflow level grants all read
permissions to every job and step. The scorecard job only needs
`security-events: write` and `id-token: write` (already granted at job level).
The top-level `read-all` also implicitly grants `contents: read`, `checks: read`,
`pull-requests: read`, `packages: read`, etc. for the Checkout step.
The OpenSSF Scorecard action requires `contents: read` and the specific
write scopes — a minimal explicit set is cleaner.
**Fix:** Replace top-level `permissions: read-all` with the minimal set:
```yaml
permissions:
  contents: read
```
(The `security-events: write` and `id-token: write` remain on the job level.)
**Status:** ✅ Fixed (iteration 1)

---

## Completion Criteria

Output `<promise>COMPLETE</promise>` when all 3 items show ✅.
