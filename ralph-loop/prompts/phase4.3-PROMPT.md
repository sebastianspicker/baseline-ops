# Phase 4.3 — Medium/Low Issue Cleanup

You are cleaning up remaining Medium and Low severity findings from Phase 1.

## How to Use This Loop

1. Read all Phase 1 findings documents:
   - `ralph-loop/phase1/1.1-static-analysis-findings.md`
   - `ralph-loop/phase1/1.2-security-audit-findings.md`
   - `ralph-loop/phase1/1.3-test-coverage-gap.md`
   - `ralph-loop/phase1/1.4-convention-audit.md`
2. Collect all unfixed Medium and Low items.
3. Each iteration: fix 3-5 items, prioritizing Medium over Low.
4. Include fixes like:
   - Remove redundant comments or dead commented-out code.
   - Fix inconsistent whitespace or formatting.
   - Add missing parameter validation attributes.
   - Fix any remaining convention misalignment.
   - Address Medium security items (e.g., the S5 wevtutil query issue if callers now exist).
5. After each batch, run full verification:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath .
   ```
6. Commit each batch.
7. Update `ralph-loop/phase4/4.3-cleanup-progress.md`.

## What NOT to Touch
- CI pipeline (that is Phase 6).
- README files (that is Phase 5).

## Verification
- All three verification commands exit 0.

## Exit Condition
Output `<promise>MEDIUM_LOW_CLEANUP_COMPLETE</promise>` when all Medium items are fixed and at least 80% of Low items are addressed.
