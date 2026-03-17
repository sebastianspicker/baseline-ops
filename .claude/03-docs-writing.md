# Documentation Audit — win-mdm-security-hardening-kit

This file drives the Ralph Loop documentation improvement cycle.
Each iteration reads this file and `progress.md`, picks the next
open item, implements the fix, and updates `progress.md`.

## How to Use This Checklist

- Items are ordered by priority (Critical → High → Medium → Low).
- Work one item per iteration. Mark it complete in `progress.md`.
- Output `<promise>COMPLETE</promise>` only when ALL items below are ✅.

---

## Items

### [HIGH] D1 — lib/README.md: Stale alias reference
**File:** `lib/README.md` line 9
**Problem:** `Common.psm1` entry says "includes aliases for legacy names
(`Is-Admin`, `Ensure-Folder`)" — but all 5 legacy aliases were removed in
the code-quality loop (iteration 1, item H3). The note is now a factual error
that would mislead anyone trying to call those names.
**Fix:** Remove the parenthetical alias note from `Common.psm1`'s description.
**Status:** ✅ Fixed (iteration 1)

---

### [HIGH] D2 — CHANGELOG.md: Missing entries for loop 1 + loop 2
**File:** `CHANGELOG.md`
**Problem:** No changelog entry exists for the code-quality cleanup (Loop 1)
or the security hardening (Loop 2) work done on 2026-03-17. These represent
~400 lines removed, 5 alias removals, 1 critical deadlock fix, 3 injection
vulnerability fixes, and 4 docs corrections.
**Fix:** Add a `[2.0.1] - 2026-03-17` section documenting both loops.
**Status:** ✅ Fixed (iteration 1)

---

### [MEDIUM] D3 — scripts/README.md: Three scripts not in any table
**File:** `scripts/README.md`
**Problem:** Three scripts exist in `scripts/` but appear in no category table:
- `07-ScheduledTasks-Hygiene.ps1` (Audit + Remediate: scheduled task hygiene,
  quarantines risky tasks, re-enables critical ones)
- `24-Cert-AutoEnrollment-Health.ps1` (Audit: certificate autoenrollment health,
  expiring cert report; Remediate: triggers autoenrollment)
- `41-NTLM-Audit-Client.ps1` (Audit: NTLM LAN Manager authentication level check)
**Fix:** Add each script to the appropriate category tables with correct
Purpose and Key Parameters columns.
**Status:** ✅ Fixed (iteration 1)

---

## Completion Criteria

Output `<promise>COMPLETE</promise>` when all 3 items show ✅.
