# Phase 4 Orchestrator — Refactoring and Code Quality

You are orchestrating Phase 4: eliminating duplication, standardizing error handling, and cleaning up remaining issues.

## Prerequisites

Phase 3 must be complete (tests must exist before refactoring). Verify:
```bash
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
TOTAL=$(pwsh -NoProfile -Command "(Invoke-Pester -Path ./tests -PassThru -Output None).Tests.Count") && \
[ "$TOTAL" -ge 400 ] && \
echo "PREREQUISITES: PASS ($TOTAL tests)" || echo "PREREQUISITES: FAIL — complete Phase 3 first"
```

## Sub-phases (SEQUENTIAL)

| Order | Sub-phase | Prompt File | Promise | Max Iter |
|-------|-----------|-------------|---------|----------|
| 1st | 4.1 Lib Deduplication | `phase4.1-PROMPT.md` | `LIB_DEDUP_COMPLETE` | 4 |
| 2nd | 4.2 Error Handling | `phase4.2-PROMPT.md` | `ERROR_HANDLING_COMPLETE` | 5 |
| 3rd | 4.3 Medium/Low Cleanup | `phase4.3-PROMPT.md` | `MEDIUM_LOW_CLEANUP_COMPLETE` | 4 |

## Execution Order

Strictly sequential. Refactoring requires tests to validate.

```bash
# Step 1: Lib deduplication
/ralph-loop "$(cat ralph-loop/prompts/phase4.1-PROMPT.md)" --max-iterations 4 --completion-promise "LIB_DEDUP_COMPLETE"

# Gate
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "GATE 4.1->4.2: PASS" || echo "GATE: FAIL"

# Step 2: Error handling standardization
/ralph-loop "$(cat ralph-loop/prompts/phase4.2-PROMPT.md)" --max-iterations 5 --completion-promise "ERROR_HANDLING_COMPLETE"

# Gate
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "GATE 4.2->4.3: PASS" || echo "GATE: FAIL"

# Step 3: Medium/Low cleanup
/ralph-loop "$(cat ralph-loop/prompts/phase4.3-PROMPT.md)" --max-iterations 4 --completion-promise "MEDIUM_LOW_CLEANUP_COMPLETE"
```

## Gate Condition (must pass before Phase 5)

```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath . && \
echo "PHASE 4 GATE: PASS" || echo "PHASE 4 GATE: FAIL"
```

## Rollback Strategy

Refactoring is higher-risk. Incremental commits (3-5 items each) limit blast radius.
If a sub-phase breaks tests:
1. `git log --oneline -5` to find the breaking commit.
2. `git revert HEAD` to undo the last commit.
3. Re-run the sub-phase — it will see the revert and try a different approach.

## Exit Condition
Output `<promise>PHASE4_COMPLETE</promise>` when all three sub-phases complete and all verification commands pass.
