# R2 Phase 5.1 — Tests for New/Changed Functions

You are adding tests for all new and changed lib functions from Round 2.

## Task

### Console.psm1 enhancements (from Phase 2.1)
Add tests to `tests/lib/Console.Tests.ps1`:
- Write-ConsoleSummary with `-CustomFields` parameter
- Write-ConsoleSummary with `-Title` parameter
- Write-ConsoleSummary with zero findings
- Get-StatusColor with new status mappings (if any added)

### Common.psm1 additions (from Phase 2.2)
Add tests to `tests/lib/Common.Tests.ps1`:
- `New-SafeFileName` with valid input
- `New-SafeFileName` with special characters
- `New-SafeFileName` with null/empty input

### New scripts (from Phase 4.2)
Update `tests/scripts/V2Contract.Tests.ps1`:
- Verify it dynamically picks up scripts 46-49
- If it uses a hardcoded list, add the new scripts

### Integration tests
Add to `tests/scripts/Orchestration.Tests.ps1`:
- Validate the new example profiles (full-audit, endpoint-health-check, incident-response, compliance-full)

## Process
1. Add tests incrementally.
2. Run after each batch:
   ```
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
3. Commit each batch.
4. Track in `ralph-loop/r2-phase5/5.1-tests-progress.md`

## Target
- 15-25 new tests
- Total test count should exceed 520

## Exit Condition
Output `<promise>R2_TESTS_COMPLETE</promise>` when all new tests pass and total exceeds 520.
