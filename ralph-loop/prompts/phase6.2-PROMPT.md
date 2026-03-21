# Phase 6.2 — Final Integration Verification

You are performing a final comprehensive verification pass.

## Task

1. Run the complete local CI suite:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -File ./tools/secret-scan.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
2. If any command fails:
   - Analyze the error.
   - Fix the root cause (not symptoms).
   - Re-run all three commands.
3. Check for regressions:
   - `V2Contract.Tests.ps1` passes for all 45 scripts.
   - No parse errors in any PS1/PSM1 file.
   - No PSScriptAnalyzer violations.
   - No secret scan matches.
   - All 329+ (original) + new tests pass.
4. Verify git history is clean:
   - No merge artifacts.
   - All commits have meaningful messages.
5. Create `ralph-loop/FINAL-VERIFICATION.md` documenting:
   - Total test count.
   - PSScriptAnalyzer result.
   - Secret scan result.
   - Parse check result.
   - List of all changes made across all phases.
6. Commit the verification report.

## Exit Condition
Output `<promise>FINAL_VERIFICATION_COMPLETE</promise>` when ALL of the following pass:
- `tools/verify.ps1` exits 0
- `tools/secret-scan.ps1` exits 0
- `Invoke-Pester -Path ./tests -CI` exits 0
- Final verification report is committed.
