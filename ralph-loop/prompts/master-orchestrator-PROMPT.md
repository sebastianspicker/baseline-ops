# Master Orchestrator — Full Repository Improvement Cycle

You are the master orchestrator for a comprehensive Ralph Loop improvement cycle
on the **win-mdm-security-hardening-kit** repository.

## Overview

This orchestrator drives 6 sequential phases, each with multiple sub-phases,
to systematically analyze, fix, test, refactor, document, and verify the entire codebase.

| Phase | Name | Sub-phases | Max Iter | Parallelism |
|-------|------|-----------|----------|-------------|
| 1 | Analysis & Discovery | 1.1-1.4 | 12 | All parallel |
| 2 | Security & Bug Fixing | 2.1-2.3 | 16 | Sequential |
| 3 | Test Expansion | 3.1-3.3 | 14 | 3.1 first, then 3.2\|3.3 |
| 4 | Refactoring & Quality | 4.1-4.3 | 13 | Sequential |
| 5 | Documentation | 5.1-5.3 | 9 | All parallel |
| 6 | CI & Verification | 6.1-6.3 | 7 | 6.1\|6.2, then 6.3 |
| **Total** | | **19 loops** | **~71 max** | |

## Execution Sequence

### Phase 1: Analysis (read-only, all parallel)

```bash
# Run all 4 analysis loops in parallel (they produce separate documents)
/ralph-loop "$(cat ralph-loop/prompts/phase1.1-PROMPT.md)" --max-iterations 3 --completion-promise "STATIC_ANALYSIS_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase1.2-PROMPT.md)" --max-iterations 4 --completion-promise "SECURITY_AUDIT_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase1.3-PROMPT.md)" --max-iterations 2 --completion-promise "TEST_COVERAGE_GAP_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase1.4-PROMPT.md)" --max-iterations 3 --completion-promise "CONVENTION_AUDIT_COMPLETE"
```

**Gate 1→2**: All 4 findings documents exist in `ralph-loop/phase1/`
```bash
test -f ralph-loop/phase1/1.1-static-analysis-findings.md && \
test -f ralph-loop/phase1/1.2-security-audit-findings.md && \
test -f ralph-loop/phase1/1.3-test-coverage-gap.md && \
test -f ralph-loop/phase1/1.4-convention-audit.md
```

---

### Phase 2: Security Hardening & Bug Fixing (sequential)

```bash
/ralph-loop "$(cat ralph-loop/prompts/phase2.1-PROMPT.md)" --max-iterations 6 --completion-promise "SECURITY_FIXES_COMPLETE"
# Gate: verify.ps1 + Pester pass
/ralph-loop "$(cat ralph-loop/prompts/phase2.2-PROMPT.md)" --max-iterations 5 --completion-promise "STATIC_FIXES_COMPLETE"
# Gate: verify.ps1 + Pester pass
/ralph-loop "$(cat ralph-loop/prompts/phase2.3-PROMPT.md)" --max-iterations 5 --completion-promise "CONVENTION_ALIGNMENT_COMPLETE"
```

**Gate 2→3**: `verify.ps1` + `Pester -CI` pass, all Critical/High findings resolved
```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
```

---

### Phase 3: Test Expansion (3.1 first, then 3.2|3.3 parallel)

```bash
/ralph-loop "$(cat ralph-loop/prompts/phase3.1-PROMPT.md)" --max-iterations 7 --completion-promise "LIB_TESTS_COMPLETE"
# Gate: new test files exist, all pass
/ralph-loop "$(cat ralph-loop/prompts/phase3.2-PROMPT.md)" --max-iterations 4 --completion-promise "TEST_HARDENING_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase3.3-PROMPT.md)" --max-iterations 3 --completion-promise "INTEGRATION_TESTS_COMPLETE"
```

**Gate 3→4**: Test count 400+, all tests pass
```bash
TOTAL=$(pwsh -NoProfile -Command "(Invoke-Pester -Path ./tests -PassThru -Output None).Tests.Count")
[ "$TOTAL" -ge 400 ]
```

---

### Phase 4: Refactoring & Code Quality (sequential)

```bash
/ralph-loop "$(cat ralph-loop/prompts/phase4.1-PROMPT.md)" --max-iterations 4 --completion-promise "LIB_DEDUP_COMPLETE"
# Gate: verify + Pester pass
/ralph-loop "$(cat ralph-loop/prompts/phase4.2-PROMPT.md)" --max-iterations 5 --completion-promise "ERROR_HANDLING_COMPLETE"
# Gate: verify + Pester pass
/ralph-loop "$(cat ralph-loop/prompts/phase4.3-PROMPT.md)" --max-iterations 4 --completion-promise "MEDIUM_LOW_CLEANUP_COMPLETE"
```

**Gate 4→5**: `verify.ps1` + `Pester -CI` + `secret-scan.ps1` all pass
```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath .
```

---

### Phase 5: Documentation (all parallel)

```bash
/ralph-loop "$(cat ralph-loop/prompts/phase5.1-PROMPT.md)" --max-iterations 2 --completion-promise "CHANGELOG_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase5.2-PROMPT.md)" --max-iterations 2 --completion-promise "READMES_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase5.3-PROMPT.md)" --max-iterations 5 --completion-promise "HELP_AUDIT_COMPLETE"
```

**Gate 5→6**: `verify.ps1` passes (validates parse integrity of help blocks)
```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
```

---

### Phase 6: CI & Final Verification (6.1|6.2 parallel, then 6.3)

```bash
/ralph-loop "$(cat ralph-loop/prompts/phase6.1-PROMPT.md)" --max-iterations 3 --completion-promise "CI_IMPROVEMENTS_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase6.2-PROMPT.md)" --max-iterations 3 --completion-promise "FINAL_VERIFICATION_COMPLETE"
# Gate: all verifications pass + FINAL-VERIFICATION.md exists
/ralph-loop "$(cat ralph-loop/prompts/phase6.3-PROMPT.md)" --max-iterations 1 --completion-promise "SUMMARY_COMPLETE"
```

**Final Gate**: Everything passes
```bash
test -f ralph-loop/SUMMARY.md && \
test -f ralph-loop/FINAL-VERIFICATION.md && \
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "=== ALL PHASES COMPLETE — REPOSITORY IMPROVEMENT CYCLE DONE ==="
```

---

## Error Recovery

If any phase fails:
1. Check which sub-phase failed (look at progress files in `ralph-loop/phase*/`).
2. Check if tests are broken: `pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"`
3. If tests fail, revert the last commit: `git revert HEAD`
4. Re-run the failed sub-phase.
5. If a sub-phase repeatedly fails, document the issue and skip to the next sub-phase.

## Tracking

Progress is tracked in:
- `ralph-loop/phase{1-6}/*.md` — per-sub-phase progress files
- `ralph-loop/FINAL-VERIFICATION.md` — final verification results
- `ralph-loop/SUMMARY.md` — overall summary and metrics
- `progress.md` — updated in Phase 5.1 with all iteration records

## Exit Condition
Output `<promise>MASTER_COMPLETE</promise>` when all 6 phases are done and the final gate passes.
