# Phase 1.3 — Test Coverage Gap Analysis

You are analyzing test coverage gaps in the win-mdm-security-hardening-kit.

## Task

1. For each of the 13 modules in `lib/`, extract the `Export-ModuleMember` function list.
2. For each exported function, check if a corresponding test exists in `tests/lib/`.
3. Current test files exist for: Common, Console, Execution, Registry, Serialization, Validation.
4. Missing test files for: Config, EventLog, External, Evidence, JsonCatalog, Results, Output.
5. For modules WITH tests, check coverage depth:
   - Does every exported function have at least one `Describe` or `It` block?
   - Are error paths tested (e.g., invalid input, missing files)?
   - Are edge cases tested (null, empty, whitespace)?
6. For `tests/scripts/`, check:
   - `V2Contract.Tests.ps1`: Does it cover all 45 scripts?
   - `Profile.Tests.ps1`, `RunLocal.Tests.ps1`, `RunProfile.Tests.ps1`: Are failure modes tested?
7. Create `ralph-loop/phase1/1.3-test-coverage-gap.md` with:
   - Table: Module | Exported Functions | Functions Tested | Functions Untested | Test File Exists
   - Prioritized list of functions needing tests (security-critical first).
   - Recommended test file organization.
8. Do NOT modify any source or test files.
9. Commit the findings document.

## Key Counts (verify these)
- 13 modules in `lib/`
- ~85 exported functions total
- 6 lib test files, 4 script test files
- 329 existing tests

## Verification
- `ralph-loop/phase1/1.3-test-coverage-gap.md` exists.
- No source or test files modified.

## Exit Condition
Output `<promise>TEST_COVERAGE_GAP_COMPLETE</promise>` when the findings document is complete and committed.
