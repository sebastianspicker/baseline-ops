# Phase 5.3 — Comment-Based Help Audit

You are ensuring all scripts and modules have complete comment-based help.

## Task

1. For each of the 45 numbered scripts:
   - Verify `.SYNOPSIS` exists and is accurate.
   - Verify `.DESCRIPTION` exists and is substantive (not just "TODO").
   - Verify `.PARAMETER` exists for ALL parameters (including v2 contract params).
   - Verify `.OUTPUTS` describes the pipeline output when `-PassThru` is used.
   - Verify at least one `.EXAMPLE` exists.
2. For each of the 13 lib modules:
   - Verify the module-level `<# .SYNOPSIS ... #>` comment exists.
   - Verify each exported function has param-level documentation.
3. Each iteration: fix 5-8 scripts or 2-3 modules.
4. Commit each batch.
5. Update `ralph-loop/phase5/5.3-help-audit-progress.md`.

## Reference
- Script `01-ASR-Defender-Allowlist.ps1` has extensive comment-based help — use as reference.
- The v2 template from `tools/new-script.ps1` shows minimum help requirements.

## What NOT to Touch
- Script logic.
- Test files.

## Verification
- `pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .` exits 0 (parse check still passes).

## Exit Condition
Output `<promise>HELP_AUDIT_COMPLETE</promise>` when all 45 scripts and 13 modules have complete comment-based help.
