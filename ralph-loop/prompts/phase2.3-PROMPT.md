# Phase 2.3 — Convention Alignment

You are aligning scripts to the v2 convention standard.

## How to Use This Loop

1. Read `ralph-loop/phase1/1.4-convention-audit.md` for the compliance matrix.
2. Each iteration: pick the script(s) with the MOST convention violations and fix them.
3. Convention fixes to apply (in priority order):
   a. Add missing `v2-init` block if absent (copy pattern from `scripts/34-TimeSync-Health.ps1` lines 61-72).
   b. Add missing `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`.
   c. Ensure Bootstrap import is the standard pattern: `. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')`.
   d. Ensure module imports use `$script:LibPath` from Bootstrap.
   e. Add missing `.SYNOPSIS`/`.DESCRIPTION` comment-based help if absent.
   f. Add `SupportsShouldProcess = $true, ConfirmImpact = 'High'` if Mode supports Remediate and it is missing.
   g. Ensure scripts that emit PassThru output use `New-V2ResultObject` and `Write-ResultObject`.
4. Do NOT change script logic or behavior. Only align to conventions.
5. After fixing each batch, run:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
6. Commit each batch with descriptive message.

## Reference Files
- `tools/new-script.ps1` — canonical v2 template
- `scripts/34-TimeSync-Health.ps1` — example of full v2 compliance
- `scripts/00-Run-Profile.ps1` — orchestration pattern

## What NOT to Touch
- Script business logic.
- Test files.
- CI pipeline.
- lib/ modules.

## Verification
- `tools/verify.ps1` exits 0.
- All Pester tests pass (especially V2Contract.Tests.ps1).

## Exit Condition
Output `<promise>CONVENTION_ALIGNMENT_COMPLETE</promise>` when 80%+ of scripts meet all convention checks from the 1.4 audit. Remaining edge cases are documented.
