# Phase 6 Orchestrator — CI Enhancement and Final Verification

You are orchestrating Phase 6: the final phase of CI improvements, verification, and summary.

## Prerequisites

Phase 5 must be complete. Verify:
```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
echo "PREREQUISITES: PASS" || echo "PREREQUISITES: FAIL — complete Phase 5 first"
```

## Sub-phases

| Order | Sub-phase | Prompt File | Promise | Max Iter |
|-------|-----------|-------------|---------|----------|
| 1st (parallel) | 6.1 CI Improvements | `phase6.1-PROMPT.md` | `CI_IMPROVEMENTS_COMPLETE` | 3 |
| 1st (parallel) | 6.2 Final Verification | `phase6.2-PROMPT.md` | `FINAL_VERIFICATION_COMPLETE` | 3 |
| 2nd | 6.3 Summary Report | `phase6.3-PROMPT.md` | `SUMMARY_COMPLETE` | 1 |

## Execution Order

6.1 and 6.2 can run in parallel. 6.3 must follow both.

```bash
# Step 1: CI improvements and final verification (parallel)
/ralph-loop "$(cat ralph-loop/prompts/phase6.1-PROMPT.md)" --max-iterations 3 --completion-promise "CI_IMPROVEMENTS_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase6.2-PROMPT.md)" --max-iterations 3 --completion-promise "FINAL_VERIFICATION_COMPLETE"

# Gate: all verifications pass
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
test -f ralph-loop/FINAL-VERIFICATION.md && \
echo "GATE 6.2->6.3: PASS" || echo "GATE: FAIL"

# Step 2: Summary report
/ralph-loop "$(cat ralph-loop/prompts/phase6.3-PROMPT.md)" --max-iterations 1 --completion-promise "SUMMARY_COMPLETE"
```

## Gate Condition (final gate — project complete)

```bash
test -f ralph-loop/SUMMARY.md && \
test -f ralph-loop/FINAL-VERIFICATION.md && \
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "PHASE 6 GATE: PASS — ALL PHASES COMPLETE" || echo "PHASE 6 GATE: FAIL"
```

## Rollback Strategy

- If CI YAML changes break the workflow definition, revert and simplify.
- If final verification reveals regressions, fix them before generating the summary.

## Exit Condition
Output `<promise>PHASE6_COMPLETE</promise>` when summary report is committed and all verifications pass.
