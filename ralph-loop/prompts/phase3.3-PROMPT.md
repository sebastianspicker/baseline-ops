# Phase 3.3 — Integration Tests for Orchestration Layer

You are creating integration tests for the v2 orchestration pipeline.

## How to Use This Loop

1. Create `tests/scripts/Orchestration.Tests.ps1` with tests for:
   a. `00-Validate-Profile.ps1`:
      - Validates all 3 example profiles in `examples/profiles/` succeed.
      - Invalid profiles (missing fields, bad types) fail with exit code 1.
      - Profile with non-existent script references fails.
   b. `00-Run-Local.ps1`:
      - Runs a synthetic test script (created in BeforeAll temp dir) successfully.
      - Fails gracefully when script does not exist.
      - Forwards arguments correctly (extend existing RunLocal.Tests.ps1 patterns).
   c. `00-Run-Batch.ps1`:
      - Runs with empty batch (no scripts selected) and does not crash.
      - Handles `-OutputFormat None` correctly.
   d. `00-Report-Aggregate.ps1`:
      - Aggregates multiple v2 result JSON files correctly.
      - Handles empty input directory gracefully.
2. Use temp directories for all test artifacts. Clean up in AfterAll.
3. Follow the pattern from `tests/scripts/RunLocal.Tests.ps1` for creating synthetic test scripts.
4. Run:
   ```
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests/scripts/Orchestration.Tests.ps1 -Output Detailed -CI"
   ```
5. Then run full suite:
   ```
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit when all pass.
7. Update `ralph-loop/phase3/3.3-integration-tests-progress.md`.

## What NOT to Touch
- Orchestration source scripts.
- Existing test files (create new file only).
- lib/ modules.

## Verification
- `Invoke-Pester -Path ./tests -Output Detailed -CI` exits 0.

## Exit Condition
Output `<promise>INTEGRATION_TESTS_COMPLETE</promise>` when the orchestration test file exists and all tests pass.
