# Implementation Reference (v2)

## Scope

- Lean repository cleanup
- Shared module consolidation
- Orchestration-first execution (`00-Run-Profile`, `00-Run-Batch`)
- Unified output contracts for orchestrated flows
- Expanded tests and CI checks

## Delivery gates

1. Parse checks pass.
2. PSScriptAnalyzer passes in CI.
3. Pester passes in Windows test job.
4. New orchestration tests pass.

## Notes

Breaking API harmonization for all legacy scripts is handled incrementally.
The v2 orchestration layer provides immediate normalized execution while legacy scripts are migrated over time.

## Deep Inspection Findings (2026-02-27)

1. `P1` `scripts/00-Run-Local.ps1`: `-Param:$value` tokens were not parsed as named arguments, causing argument binding failures in target scripts.
   - Fixed by introducing shared token parsing in `lib/Execution.psm1` (`Convert-ArgumentTokens`) and using it in `00-Run-Local.ps1`.
2. `P1` `scripts/00-Run-Local.ps1`: script root containment check could be bypassed via reparse-point script paths.
   - Fixed by rejecting reparse-point targets and strengthening root path checks.
3. `P1` `scripts/00-Validate-Profile.ps1`: duplicate `Steps[].Script` values were accepted, creating ambiguous dependency/status behavior in profile runs.
   - Fixed by high-severity duplicate-step validation.
4. `P2` `scripts/00-Validate-Profile.ps1`: `Steps[].Args` accepted non-string values, enabling runtime failures during forwarding.
   - Fixed by high-severity argument type and empty-token validation.
5. `P2` `lib/Validation.psm1`: script-name validation allowed unsafe filename characters.
   - Fixed by rejecting control and reserved path characters.
6. `P3` `tools/Launcher-GUI.ps1`: profile extra arguments were forwarded as positional tokens instead of parsed named args.
   - Fixed by parsing with `Convert-ArgumentTokens` before invocation.
7. `P3` `tools/Launcher-GUI.ps1`: runspaces/PowerShell instances were not explicitly disposed after async runs.
   - Fixed by asynchronous cleanup (`EndInvoke` + `Dispose`) on completion.
