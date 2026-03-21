# Phase 2.1 — Fix Security Findings

You are fixing security vulnerabilities found in Phase 1.2.

## How to Use This Loop

1. Read `ralph-loop/phase1/1.2-security-audit-findings.md` for the full findings list.
2. Read `progress.md` and `.claude/02-security.md` to see what was already fixed (do not re-fix).
3. Each iteration: pick the HIGHEST severity unfixed finding, implement the fix, update `ralph-loop/phase2/2.1-security-fixes-progress.md`.
4. Follow existing fix patterns:
   - WQL injection: escape single quotes with `-replace "'", "''"` before interpolation.
   - Path traversal: use `Sanitize-Path` from `lib/Common.psm1` or `Test-PathTraversal`/`Assert-NoPathTraversal` from `lib/Validation.psm1`.
   - Command injection: use array-based argument passing (see `lib/External.psm1` wrappers).
   - Input validation: add `[ValidatePattern()]` or explicit regex checks at function entry.
5. After each fix, run:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit each fix separately with descriptive message referencing the finding ID.

## What NOT to Touch
- Do not modify test files in this sub-phase (tests come in Phase 3).
- Do not change the v2 parameter contracts.
- Do not refactor unrelated code.

## Verification After Each Fix
- `pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .` exits 0.
- `pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"` exits 0.

## Exit Condition
Output `<promise>SECURITY_FIXES_COMPLETE</promise>` when ALL Critical and High findings from 1.2 are fixed (or documented as intentionally deferred with justification). Medium/Low may remain.
