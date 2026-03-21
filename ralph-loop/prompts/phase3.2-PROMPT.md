# Phase 3.2 — Existing Test Hardening

You are improving existing Pester tests with better coverage.

## How to Use This Loop

1. Read `ralph-loop/phase1/1.3-test-coverage-gap.md` for per-function gaps in existing test files.
2. Each iteration: pick the test file with the largest gap and add tests.
3. Priority areas:
   a. `Execution.Tests.ps1`: Missing tests for `Invoke-NativeProcess` (the deadlock fix from C1 has no test), `Convert-TokenValue`.
   b. `Common.Tests.ps1`: Missing edge-case tests for `Sanitize-Path` (environment variable expansion, concurrent access).
   c. `Serialization.Tests.ps1`: Missing tests for `Save-Csv`, `Write-ResultObject` success paths.
   d. `Registry.Tests.ps1`: Missing tests for `Set-RegQword`, `Set-RegExpandString`, `Set-RegMultiString`, `Set-RegBinary`, `Get-RegDword`, `Get-RegDwordOrNull`, `Get-RegString`, `Remove-RegistryKeyIfExists`.
   e. `Validation.Tests.ps1`: Already has 14 tests from F2, but `Test-ValidGitRef` only has 2 tests — add more edge cases.
   f. `V2Contract.Tests.ps1`: Verify it covers all 45 numbered scripts (not just some).
4. Follow existing test patterns and style (see current files for reference).
5. Run full suite after each addition:
   ```
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit each batch of additions.
7. Update `ralph-loop/phase3/3.2-test-hardening-progress.md` after each batch.

## What NOT to Touch
- Source files in `lib/` or `scripts/`.
- New test files created in Phase 3.1 (do not modify those).
- CI pipeline.

## Verification
- `Invoke-Pester -Path ./tests -Output Detailed -CI` exits 0.
- Test count increased (verify with `Invoke-Pester -Path ./tests -PassThru` and check `.Tests.Total`).

## Exit Condition
Output `<promise>TEST_HARDENING_COMPLETE</promise>` when identified gaps in existing test files are filled and total test count is 400+.
