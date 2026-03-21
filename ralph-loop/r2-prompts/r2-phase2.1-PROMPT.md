# R2 Phase 2.1 — Design Pluggable Write-ConsoleSummary

You are redesigning lib/Console.psm1's Write-ConsoleSummary to support all 24 script-specific variants.

## Context

Read `ralph-loop/r2-phase1/1.1-console-summary-catalog.md` for the catalog of all variants.

## Task

1. Read the current `lib/Console.psm1:Write-ConsoleSummary` implementation.
2. Based on the catalog, design an enhanced version that:
   - Accepts the standard parameters (ComputerName, TimestampUtc, Findings, ScriptName)
   - Accepts **optional custom fields** via a `-CustomFields @{ Label = Value }` hashtable parameter
   - Supports **optional section title** via `-Title` parameter (default: "Audit Summary")
   - Supports suppression via `-Quiet` flag
   - Renders findings with severity-colored output using existing `Get-StatusColor`
   - Handles zero findings gracefully (shows "No findings" or similar)
3. Implement the enhanced function in `lib/Console.psm1`.
4. Update `Export-ModuleMember` if new functions are added.
5. Ensure the existing tests in `tests/lib/Console.Tests.ps1` still pass.
6. Add tests for the new parameters.
7. Run full verification:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
8. Commit with message "enhance Write-ConsoleSummary: pluggable custom fields and title"

## Also: Enhance Get-StatusColor

If the catalog shows scripts need additional status mappings:
1. Add the missing mappings to the lib version.
2. Keep backward compatibility (existing mappings unchanged).
3. Test the additions.

## What NOT to Touch
- Script business logic (migration happens in Phase 3).
- Other lib modules.

## Exit Condition
Output `<promise>CONSOLE_DESIGN_COMPLETE</promise>` when the enhanced function is implemented, tested, and committed.
