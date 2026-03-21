# Phase 4.1 — Lib Module Deduplication

You are eliminating duplication between lib modules.

## How to Use This Loop

1. Identify overlapping functionality:
   - `Common.psm1:Read-JsonConfig` vs `Config.psm1:Read-ConfigWithDefaults` vs `JsonCatalog.psm1:Read-JsonFileSafe` — three functions that all read JSON files with slightly different APIs.
   - `Serialization.psm1:Save-Json` vs `JsonCatalog.psm1:Write-JsonToFile` — two functions that write JSON files.
   - `Common.psm1:Ensure-Directory` and path helpers vs `Evidence.psm1` path operations.
2. For each duplication:
   - Determine which function is the canonical version (most capable, best-tested).
   - Update all callers of the deprecated version to use the canonical one.
   - Remove the deprecated function and update `Export-ModuleMember`.
   - If removing would break the API too much, add a forwarding wrapper with a deprecation comment (limit to 1-2 wrappers maximum).
3. After each deduplication, run:
   ```
   pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
   pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
   ```
4. Update affected test files if function names change.
5. Commit each deduplication separately.
6. Update `ralph-loop/phase4/4.1-dedup-progress.md`.

## What NOT to Touch
- Script business logic (only update function call names).
- CI pipeline.
- Parameter contracts.

## Verification
- `tools/verify.ps1` exits 0.
- All Pester tests pass.
- `Export-ModuleMember` lists in modified modules are accurate.

## Exit Condition
Output `<promise>LIB_DEDUP_COMPLETE</promise>` when no more cross-module function duplication exists and all tests pass.
