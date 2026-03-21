# Phase 2 Orchestrator — Security Hardening and Bug Fixing

You are orchestrating Phase 2: fixing security issues, static analysis problems, and convention violations.

## Prerequisites

Phase 1 must be complete. Verify:
```bash
test -f ralph-loop/phase1/1.1-static-analysis-findings.md && \
test -f ralph-loop/phase1/1.2-security-audit-findings.md && \
test -f ralph-loop/phase1/1.4-convention-audit.md && \
echo "PREREQUISITES: PASS" || echo "PREREQUISITES: FAIL — run Phase 1 first"
```

## Sub-phases (SEQUENTIAL — do NOT run in parallel)

| Order | Sub-phase | Prompt File | Promise | Max Iter |
|-------|-----------|-------------|---------|----------|
| 1st | 2.1 Security Fixes | `phase2.1-PROMPT.md` | `SECURITY_FIXES_COMPLETE` | 6 |
| 2nd | 2.2 Static Analysis Fixes | `phase2.2-PROMPT.md` | `STATIC_FIXES_COMPLETE` | 5 |
| 3rd | 2.3 Convention Alignment | `phase2.3-PROMPT.md` | `CONVENTION_ALIGNMENT_COMPLETE` | 5 |

## Execution Order

Run strictly sequential. Each sub-phase modifies source files.

```bash
# Step 1: Security fixes
/ralph-loop "$(cat ralph-loop/prompts/phase2.1-PROMPT.md)" --max-iterations 6 --completion-promise "SECURITY_FIXES_COMPLETE"

# Gate check before 2.2
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "GATE 2.1->2.2: PASS" || echo "GATE 2.1->2.2: FAIL — fix issues before continuing"

# Step 2: Static analysis fixes
/ralph-loop "$(cat ralph-loop/prompts/phase2.2-PROMPT.md)" --max-iterations 5 --completion-promise "STATIC_FIXES_COMPLETE"

# Gate check before 2.3
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "GATE 2.2->2.3: PASS" || echo "GATE 2.2->2.3: FAIL — fix issues before continuing"

# Step 3: Convention alignment
/ralph-loop "$(cat ralph-loop/prompts/phase2.3-PROMPT.md)" --max-iterations 5 --completion-promise "CONVENTION_ALIGNMENT_COMPLETE"
```

## Gate Condition (must pass before Phase 3)

```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "PHASE 2 GATE: PASS" || echo "PHASE 2 GATE: FAIL"
```

## Rollback Strategy

Each sub-phase commits incrementally. If a sub-phase breaks tests:
1. Identify the breaking commit: `git log --oneline -5`
2. Revert the last commit: `git revert HEAD`
3. Re-run the sub-phase (it will see the revert and try a different approach).

## Exit Condition
Output `<promise>PHASE2_COMPLETE</promise>` when all three sub-phases complete and verify.ps1 + Pester pass.
