# Phase 4.2 — Error Handling Standardization

You are standardizing error handling across all operational scripts.

## How to Use This Loop

1. Read `ralph-loop/phase1/1.1-static-analysis-findings.md` for error handling inconsistencies.
2. The standard pattern (from well-structured scripts like 34-TimeSync-Health.ps1) is:
   - Top-level: `$ErrorActionPreference = 'Stop'` and `Set-StrictMode -Version Latest`.
   - Major operation blocks: wrapped in `try { ... } catch { Add-Finding ... }`.
   - Resource cleanup: in `finally` blocks.
   - Script exit: uses v2 result object with `Result = 'FAIL'` on errors, not bare `throw`.
3. Each iteration: pick 3-5 scripts and standardize their error handling.
4. DO NOT change business logic. Only restructure error flow.
5. Specific fixes:
   - Replace bare `throw` at top-level with `Add-Finding -Severity 'Critical'` + `exit 1`.
   - Replace `$ErrorActionPreference = 'Continue'` with 'Stop' where appropriate.
   - Ensure `catch` blocks log the error (not swallow silently unless intentional with comment).
   - Ensure temp file/registry cleanup in `finally` blocks.
6. After each batch, run:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
7. Commit each batch.
8. Update `ralph-loop/phase4/4.2-error-handling-progress.md`.

## What NOT to Touch
- lib/ modules (already standardized).
- Test files.
- Orchestration scripts (00-*).

## Verification
- verify.ps1 exits 0.
- All Pester tests pass.
- No scripts have inconsistent ErrorActionPreference settings.

## Exit Condition
Output `<promise>ERROR_HANDLING_COMPLETE</promise>` when all 45 scripts follow the standard error handling pattern.
