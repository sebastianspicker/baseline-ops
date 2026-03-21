# Phase 3.1 — Lib Module Unit Tests (Missing Modules)

You are creating Pester tests for untested lib modules.

## How to Use This Loop

1. Read `ralph-loop/phase1/1.3-test-coverage-gap.md` for the gap analysis.
2. Each iteration: create tests for ONE module. Prioritize security-critical modules first:
   a. `Config.psm1` (2 functions: ConvertTo-Hashtable, Read-ConfigWithDefaults)
   b. `Results.psm1` (3 functions: New-FindingsList, New-FindingObject, Add-Finding)
   c. `JsonCatalog.psm1` (2 functions: Read-JsonFileSafe, Write-JsonToFile)
   d. `Evidence.psm1` (3 functions: Expand-Env, Get-FileSha256, Copy-ToEvidence)
   e. `EventLog.psm1` (2 functions: Ensure-EventSource, Write-HealthEvent) — Windows-only, use `-Skip` pattern from Registry.Tests.ps1
   f. `External.psm1` (18 functions) — mock external commands, test validation logic
   g. `Output.psm1` (many functions) — test key functions, mock Write-Host
3. Follow existing test patterns:
   - File: `tests/lib/{ModuleName}.Tests.ps1`
   - BeforeAll: `Import-Module (Join-Path $PSScriptRoot '../../lib/{Module}.psm1') -Force`
   - Use `$script:SkipRegistryTests` pattern for Windows-only tests
   - Use temp files/dirs with cleanup in AfterAll/AfterEach
   - Test happy path, error path, edge cases (null, empty, whitespace)
4. After creating each test file, run:
   ```
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests/lib/{Module}.Tests.ps1 -Output Detailed -CI"
   ```
5. After all tests pass individually, run the full suite:
   ```
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit each test file individually.
7. Update `ralph-loop/phase3/3.1-lib-tests-progress.md` after each module.

## Test Count Target
- Aim for 5-15 tests per module depending on complexity.
- Total new tests: ~50-80.

## What NOT to Touch
- Source files in `lib/` or `scripts/`.
- Existing test files.
- CI pipeline.

## Verification
- `Invoke-Pester -Path ./tests -Output Detailed -CI` exits 0.
- New test files exist for all 7 previously untested modules.

## Exit Condition
Output `<promise>LIB_TESTS_COMPLETE</promise>` when test files exist for ALL 13 lib modules and the full Pester suite passes.
