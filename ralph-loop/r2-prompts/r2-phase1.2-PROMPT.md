# R2 Phase 1.2 — Local Save-Json Variants + Batch Category Audit

You are analyzing two things: remaining local JSON save functions, and batch category completeness.

## Part A: Local Save-Json Variants

Search for local Save-Json, Write-JsonFile, SB_SaveJsonFile functions in scripts:
```
grep -rn 'function Save-Json\|function Write-JsonFile\|function SB_Save' scripts/
```

For each found:
1. Read the local implementation.
2. Compare with `lib/Serialization.psm1:Save-Json` (the canonical version with path-traversal guard).
3. Document differences in parameters, error handling, depth control.
4. Classify as Drop-in / Adaptable / Incompatible.

## Part B: Batch Category Audit

Read `scripts/00-Run-Batch.ps1` and find the category definitions (Audit, Remediation, Collection, Utility, Monitoring).

For EVERY script 01-45:
1. Read the script's purpose (from .SYNOPSIS).
2. Determine which categories it should belong to.
3. Flag scripts missing from categories they should be in.

Key expected gaps:
- Script 07 (ScheduledTasks-Hygiene): Should be in Audit
- Script 24 (Cert-AutoEnrollment-Health): Should be in Audit
- Script 32 (Firewall-Logging-Audit): Should be in Audit
- Script 41 (NTLM-Audit-Client): Should be in Audit

## Output
Create `ralph-loop/r2-phase1/1.2-json-save-and-batch-audit.md` with both analyses.

## What NOT to Touch
- Do NOT modify any source files. Analysis only.

## Exit Condition
Output `<promise>JSON_BATCH_CATALOG_COMPLETE</promise>` when complete and committed.
