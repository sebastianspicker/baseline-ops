# R2 Phase 1.3 — C10 Findings Pattern Migration Feasibility

You are analyzing which scripts can feasibly migrate to the New-FindingsList/Add-Finding pattern.

## Context

Round 1 achieved only 47% compliance on C10 (findings pattern). ~27 scripts still use custom patterns.

## Task

For each script NOT using New-FindingsList/Add-Finding (check `ralph-loop/phase1/1.4-convention-audit.md` for the list):

1. Read the script's findings/results collection pattern:
   - `$findings = @()` + `$findings += @{...}` (old array pattern)
   - `$findings = [System.Collections.Generic.List[object]]::new()` + `.Add()` (generic list)
   - `$notes = @()` + string accumulation
   - `$driftItems = @()` + custom objects
   - Other patterns
2. Check if the custom pattern can be replaced with Add-Finding:
   - Does it use Severity, ID, Message fields? (compatible)
   - Does it use custom fields not in New-FindingObject? (needs extension)
   - Is it a string/note accumulation? (incompatible without redesign)
3. Classify as: Easy / Moderate / Hard / Incompatible

## Output
Create `ralph-loop/r2-phase1/1.3-c10-migration-feasibility.md` with:
- Table: Script | Current Pattern | Classification | Migration Notes
- Count per classification
- Recommended migration order (Easy first)

## What NOT to Touch
- Do NOT modify any source files.

## Exit Condition
Output `<promise>C10_FEASIBILITY_COMPLETE</promise>` when complete and committed.
