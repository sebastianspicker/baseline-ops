# Phase 2.2 — Fix Static Analysis Issues

You are fixing static analysis issues found in Phase 1.1.

## How to Use This Loop

1. Read `ralph-loop/phase1/1.1-static-analysis-findings.md` for findings.
2. Each iteration: pick the highest severity unfixed item, fix it, update `ralph-loop/phase2/2.2-static-analysis-progress.md`.
3. Fix patterns to follow:
   - `$null` comparison ordering: `$null -eq $variable` not `$variable -eq $null` for arrays.
   - Missing `[CmdletBinding()]`: add to any exported function that lacks it.
   - Hardcoded paths: replace with parameter defaults or environment variable expansion.
   - Uninitialized variables: ensure all variables are initialized before use.
   - Dead code: remove functions/variables that are defined but never used within scope.
   - Inconsistent error handling: standardize to `$ErrorActionPreference = 'Stop'` with `try/catch` at operation boundaries.
4. After each fix, run:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
5. Commit each fix with a message referencing the finding.

## What NOT to Touch
- Do not change security-related code (that is Phase 2.1).
- Do not change test files.
- Do not change parameter contracts.
- Do not change the CI pipeline.

## Verification
- `tools/verify.ps1` (with PSScriptAnalyzer) exits 0.
- All Pester tests pass.

## Exit Condition
Output `<promise>STATIC_FIXES_COMPLETE</promise>` when all Critical and High static analysis findings are resolved. Medium/Low may remain for Phase 4.
