# R2 Phase 3.1 — Migrate Scripts to Lib Write-ConsoleSummary

You are migrating ~24 scripts from local Write-ConsoleSummary/Get-StatusColor to the enhanced lib versions.

## Context

Read `ralph-loop/r2-phase1/1.1-console-summary-catalog.md` for the classification of each script.

## Task

For each script classified as "Drop-in" or "Adaptable":

1. Read the script's local Write-ConsoleSummary function.
2. Read the script's call-site(s) where Write-ConsoleSummary is called.
3. Remove the local function definition.
4. Update call-sites to use the lib/Console.psm1 version:
   - Map script-specific fields to `-CustomFields @{ Label = Value }` parameter.
   - Map script-specific title to `-Title` parameter.
   - Ensure `Import-Module Console.psm1` is present.
5. If the script also has a local Get-StatusColor, remove it (lib version was enhanced in Phase 2.1).
6. Run verification after each batch of 3-5 scripts:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
7. Commit each batch with message like "migrate Write-ConsoleSummary: scripts 01, 03, 04, 05"
8. Track in `ralph-loop/r2-phase3/3.1-console-migration-progress.md`

## Priority
Start with "Drop-in" scripts (easiest), then "Adaptable" scripts.
Skip "Incompatible" scripts — document why.

## What NOT to Touch
- Script business logic (only change the summary rendering).
- Test files (unless a test directly asserts on the local function).
- Lib modules (already enhanced in Phase 2.1).

## Exit Condition
Output `<promise>CONSOLE_MIGRATION_COMPLETE</promise>` when all Drop-in + Adaptable scripts are migrated and tests pass.
