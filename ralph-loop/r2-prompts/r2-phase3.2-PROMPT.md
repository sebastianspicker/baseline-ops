# R2 Phase 3.2 — C10 Findings Pattern Migration

You are migrating scripts to use New-FindingsList/Add-Finding from lib/Results.psm1.

## Context

Read `ralph-loop/r2-phase1/1.3-c10-migration-feasibility.md` for the classification.

## Task

For each script classified as "Easy" or "Moderate":

1. Read the script's current findings collection pattern.
2. Replace with the standardized pattern:
   ```powershell
   $findings = New-FindingsList
   # ... in detection blocks:
   Add-Finding -FindingsList $findings -Id 'XXX-001' -Severity 'High' -Message 'Description'
   ```
3. Ensure `Import-Module Results.psm1` is present.
4. Update the v2 result object (from Phase 2.3 of Round 1) to use `$findings` if it doesn't already.
5. Run verification after each batch:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit each batch.
7. Track in `ralph-loop/r2-phase3/3.2-c10-migration-progress.md`

## Important
- Do NOT change what the script detects or reports — only change HOW it stores findings.
- Keep backward-compatible: if a script passes findings to Write-ConsoleSummary, ensure the list format is compatible.
- Skip "Hard" and "Incompatible" scripts — document why.

## Exit Condition
Output `<promise>C10_MIGRATION_COMPLETE</promise>` when all Easy + Moderate scripts are migrated and tests pass.
