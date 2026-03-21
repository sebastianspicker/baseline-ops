# Phase 1.4 — Consistency and Convention Audit

You are auditing convention consistency across the win-mdm-security-hardening-kit scripts.

## Task

1. For each of the 45 numbered scripts (`01-45`), verify:
   - **v2 param contract**: Has Mode, ConfigPath, OutputFormat, OutputPath, PassThru, Strict, Quiet, NoColor parameters (V2Contract.Tests.ps1 already checks this, but verify the contract is USED, not just declared).
   - **v2-init block**: Has the `$script:__V2Context = @{...}` initialization block.
   - **Bootstrap**: Uses `. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')` (not a custom path resolver).
   - **Module imports**: Uses `Import-Module (Join-Path $script:LibPath '*.psm1') -Force` pattern.
   - **StrictMode**: Has `Set-StrictMode -Version Latest` before main logic.
   - **ErrorActionPreference**: Set to 'Stop' at script level.
   - **Comment-based help**: Has `.SYNOPSIS` and `.DESCRIPTION`.
   - **ShouldProcess**: Scripts with `-Mode Remediate` in ValidateSet have `SupportsShouldProcess = $true`.
   - **Output contract**: Scripts use `New-V2ResultObject` and `Write-ResultObject` if they support PassThru/OutputFormat.
   - **Findings pattern**: Scripts use `New-FindingsList`/`Add-Finding` from Results.psm1 (vs inline arrays).
   - **Exit code**: Scripts end with `exit 0` on success.
2. For orchestration scripts (`00-*.ps1`), verify:
   - Validation scripts validate all inputs.
   - Run scripts handle errors from child scripts.
   - Report scripts handle empty input gracefully.
3. Create `ralph-loop/phase1/1.4-convention-audit.md` with:
   - Per-script compliance matrix.
   - Ranked list of scripts most in need of convention alignment.
4. Do NOT modify source files.
5. Commit the findings document.

## Reference Pattern (from tools/new-script.ps1)
The `tools/new-script.ps1` template shows the canonical v2 script structure. Use it as the reference.

## What NOT to Touch
- Source files. Analysis only.

## Verification
- `ralph-loop/phase1/1.4-convention-audit.md` exists with per-script matrix.
- No source files modified.

## Exit Condition
Output `<promise>CONVENTION_AUDIT_COMPLETE</promise>` when the audit document is complete and committed.
