# R2 Phase 2.2 — Consolidate Local Save-Json Variants

You are consolidating remaining local JSON save functions to use lib/Serialization.psm1.

## Context

Read `ralph-loop/r2-phase1/1.2-json-save-and-batch-audit.md` for the catalog.

## Task

For each script with a local Save-Json or Write-JsonFile function classified as "Drop-in" or "Adaptable":

1. Verify `lib/Serialization.psm1` is imported by the script (add import if missing).
2. Remove the local function definition.
3. Update call-sites to use `Save-Json` from Serialization.psm1.
4. If the local version has different parameters:
   - If the lib version supports the same functionality, just update the call.
   - If the lib version needs a minor enhancement (e.g., different depth), add the parameter to the lib function.
5. Run verification after each script:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit each batch.

## Also: Fix Batch Categories

Based on the batch category audit from Phase 1.2:
1. Read `scripts/00-Run-Batch.ps1`.
2. Add missing scripts to appropriate categories.
3. Run Pester (especially Orchestration.Tests.ps1) to verify.
4. Commit separately.

## Also: Extract Safe-FileName

1. Read `scripts/09-SupportBundle.ps1` and find `SB_SafeFileName`.
2. Create `New-SafeFileName` in `lib/Common.psm1` with the same logic.
3. Update `Export-ModuleMember` in Common.psm1.
4. Add test in `tests/lib/Common.Tests.ps1`.
5. Do NOT migrate script 09's SB_SafeFileName yet (it's deeply integrated).
6. Commit.

## What NOT to Touch
- Script 09's SB_ functions (too deeply integrated for this phase).
- Test files from Round 1 (only add new tests).

## Exit Condition
Output `<promise>JSON_BATCH_FIXES_COMPLETE</promise>` when all consolidations are done and tests pass.
