# R2 Phase 1.1 — Catalog Write-ConsoleSummary and Get-StatusColor Variants

You are analyzing local Write-ConsoleSummary and Get-StatusColor implementations across 24 scripts.

## Task

For each of the ~24 scripts that have local Write-ConsoleSummary or Get-StatusColor functions:

1. Read the local function implementation.
2. Read the lib/Console.psm1 canonical version (`Write-ConsoleSummary` at ~line 283, `Get-StatusColor` at ~line 60).
3. Document the differences:
   - Parameter names and types (signature differences)
   - Custom fields displayed (computer name, findings count, etc.)
   - Color mapping differences
   - Formatting differences
4. Classify each script's local version as:
   - **Drop-in**: Can directly replace with lib version (identical or subset behavior)
   - **Adaptable**: Can replace with lib version if we add 1-2 parameters to the lib function
   - **Incompatible**: Fundamentally different purpose, keep as local

5. Create `ralph-loop/r2-phase1/1.1-console-summary-catalog.md` with:
   - Table: Script | Function | Classification | Key Differences | Migration Notes
   - Proposed lib/Console.psm1 enhancements needed to support "Adaptable" scripts
   - Count of scripts per classification

## Scripts to Check
Search with: `grep -rn 'function Write-ConsoleSummary\|function Get-StatusColor' scripts/`

## What NOT to Touch
- Do NOT modify any source files. Analysis only.

## Exit Condition
Output `<promise>CONSOLE_CATALOG_COMPLETE</promise>` when catalog is complete and committed.
