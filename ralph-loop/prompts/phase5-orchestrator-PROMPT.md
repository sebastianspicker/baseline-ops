# Phase 5 Orchestrator — Documentation and Changelog

You are orchestrating Phase 5: updating all project documentation to reflect changes from Phases 2-4.

## Prerequisites

Phase 4 must be complete. Verify:
```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI" && \
echo "PREREQUISITES: PASS" || echo "PREREQUISITES: FAIL — complete Phase 4 first"
```

## Sub-phases (ALL PARALLEL — different files)

| Sub-phase | Prompt File | Promise | Max Iter |
|-----------|-------------|---------|----------|
| 5.1 CHANGELOG & Progress | `phase5.1-PROMPT.md` | `CHANGELOG_COMPLETE` | 2 |
| 5.2 README Updates | `phase5.2-PROMPT.md` | `READMES_COMPLETE` | 2 |
| 5.3 Comment-Based Help | `phase5.3-PROMPT.md` | `HELP_AUDIT_COMPLETE` | 5 |

## Execution Order

All three can run **in parallel** — they modify different files:
- 5.1: `CHANGELOG.md`, `progress.md`
- 5.2: `README.md`, `scripts/README.md`, `lib/README.md`, `examples/README.md`
- 5.3: `scripts/01-45*.ps1` (help blocks only), `lib/*.psm1` (help blocks only)

```bash
/ralph-loop "$(cat ralph-loop/prompts/phase5.1-PROMPT.md)" --max-iterations 2 --completion-promise "CHANGELOG_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase5.2-PROMPT.md)" --max-iterations 2 --completion-promise "READMES_COMPLETE"
/ralph-loop "$(cat ralph-loop/prompts/phase5.3-PROMPT.md)" --max-iterations 5 --completion-promise "HELP_AUDIT_COMPLETE"
```

## Gate Condition (must pass before Phase 6)

```bash
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath . && \
echo "PHASE 5 GATE: PASS" || echo "PHASE 5 GATE: FAIL"
```

## Rollback Strategy

Documentation changes are low-risk. `verify.ps1` catches broken help blocks immediately.
If a sub-phase breaks parsing, revert and re-run.

## Exit Condition
Output `<promise>PHASE5_COMPLETE</promise>` when all three sub-phases complete and verify.ps1 passes.
