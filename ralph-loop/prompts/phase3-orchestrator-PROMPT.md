# Phase 3 Orchestrator — Test Expansion

You are orchestrating Phase 3: expanding test coverage across all lib modules and orchestration scripts.

## Prerequisites

Phase 2 must be complete. Verify:
```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "PREREQUISITES: PASS" || echo "PREREQUISITES: FAIL — complete Phase 2 first"
```

## Sub-phases

| Order | Sub-phase | Prompt File | Promise | Max Iter |
|-------|-----------|-------------|---------|----------|
| 1st | 3.1 Lib Module Tests | `phase3.1-PROMPT.md` | `LIB_TESTS_COMPLETE` | 7 |
| 2nd (parallel) | 3.2 Test Hardening | `phase3.2-PROMPT.md` | `TEST_HARDENING_COMPLETE` | 4 |
| 2nd (parallel) | 3.3 Integration Tests | `phase3.3-PROMPT.md` | `INTEGRATION_TESTS_COMPLETE` | 3 |

## Execution Order

3.1 first (creates new test files), then 3.2 and 3.3 can run in parallel (they modify different files).

```bash
# Step 1: Create tests for 7 untested modules
/ralph-loop "$(cat ralph-loop/prompts/phase3.1-PROMPT.md)" --max-iterations 7 --completion-promise "LIB_TESTS_COMPLETE"

# Gate: all new test files exist and pass
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "GATE 3.1->3.2/3.3: PASS" || echo "GATE: FAIL"

# Step 2a and 2b: Run in parallel
/ralph-loop "$(cat ralph-loop/prompts/phase3.2-PROMPT.md)" --max-iterations 4 --completion-promise "TEST_HARDENING_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase3.3-PROMPT.md)" --max-iterations 3 --completion-promise "INTEGRATION_TESTS_COMPLETE"
```

## Gate Condition (must pass before Phase 4)

```bash
TOTAL=$(pwsh -NoProfile -Command "(Invoke-Pester -Path ./tests -PassThru -Output None).Tests.Count")
echo "Total tests: $TOTAL"
[ "$TOTAL" -ge 400 ] && echo "PHASE 3 GATE: PASS (400+ tests)" || echo "PHASE 3 GATE: FAIL (need 400+ tests, have $TOTAL)"
```

## Rollback Strategy

If new tests fail against existing code, the test is likely wrong (not the code):
1. Review the failing test for correctness.
2. Fix the test, not the source.
3. If the test reveals a genuine bug, document it in the progress file for Phase 4.

## Exit Condition
Output `<promise>PHASE3_COMPLETE</promise>` when all test files exist, total count is 400+, and full Pester suite passes.
