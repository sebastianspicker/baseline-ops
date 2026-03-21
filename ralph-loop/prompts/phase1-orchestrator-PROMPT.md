# Phase 1 Orchestrator — Deep Analysis and Issue Discovery

You are orchestrating Phase 1: analysis of the win-mdm-security-hardening-kit repository.

## Sub-phases

Run ALL four sub-phases. They are read-only analysis tasks that produce separate documents.

| Sub-phase | Prompt File | Output File | Promise |
|-----------|-------------|-------------|---------|
| 1.1 Static Analysis | `phase1.1-PROMPT.md` | `ralph-loop/phase1/1.1-static-analysis-findings.md` | `STATIC_ANALYSIS_COMPLETE` |
| 1.2 Security Audit | `phase1.2-PROMPT.md` | `ralph-loop/phase1/1.2-security-audit-findings.md` | `SECURITY_AUDIT_COMPLETE` |
| 1.3 Test Coverage Gap | `phase1.3-PROMPT.md` | `ralph-loop/phase1/1.3-test-coverage-gap.md` | `TEST_COVERAGE_GAP_COMPLETE` |
| 1.4 Convention Audit | `phase1.4-PROMPT.md` | `ralph-loop/phase1/1.4-convention-audit.md` | `CONVENTION_AUDIT_COMPLETE` |

## Execution Order

All four sub-phases can run **in parallel** — they are read-only and produce separate output files.

```
/ralph-loop "$(cat ralph-loop/prompts/phase1.1-PROMPT.md)" --max-iterations 3 --completion-promise "STATIC_ANALYSIS_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase1.2-PROMPT.md)" --max-iterations 4 --completion-promise "SECURITY_AUDIT_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase1.3-PROMPT.md)" --max-iterations 2 --completion-promise "TEST_COVERAGE_GAP_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase1.4-PROMPT.md)" --max-iterations 3 --completion-promise "CONVENTION_AUDIT_COMPLETE"
```

## Gate Condition (must pass before Phase 2)

All four findings documents must exist:
```bash
test -f ralph-loop/phase1/1.1-static-analysis-findings.md && \
test -f ralph-loop/phase1/1.2-security-audit-findings.md && \
test -f ralph-loop/phase1/1.3-test-coverage-gap.md && \
test -f ralph-loop/phase1/1.4-convention-audit.md && \
echo "PHASE 1 GATE: PASS" || echo "PHASE 1 GATE: FAIL"
```

## Post-Gate: Create Summary

After all four complete, create `ralph-loop/phase1/SUMMARY.md`:
1. Merge key findings from all four documents.
2. Prioritize by severity: Critical > High > Medium > Low.
3. Count total findings per severity.
4. Identify the top 10 items to fix first.

## Rollback Strategy

This phase is non-destructive (analysis only). If any sub-phase fails:
- Check that it didn't accidentally modify source files: `git diff --name-only | grep -v '^ralph-loop/'`
- Re-run the failed sub-phase.
- No rollback needed since no source files are touched.

## Exit Condition
Output `<promise>PHASE1_COMPLETE</promise>` when all 4 findings documents and the summary exist.
