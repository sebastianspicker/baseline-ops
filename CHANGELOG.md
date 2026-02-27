# Changelog

All notable changes to this project are documented in this file.

## [2.0.0] - 2026-02-27

### Added

- New orchestration layer:
  - `scripts/00-Validate-Profile.ps1`
  - `scripts/00-Run-Profile.ps1`
  - `scripts/00-Run-Batch.ps1`
  - `scripts/00-Report-Aggregate.ps1`
- New shared modules:
  - `lib/Validation.psm1`
  - `lib/Execution.psm1`
  - `lib/Serialization.psm1`
- Example profiles under `examples/profiles/`.
- New module and orchestration tests.

### Changed

- Root documentation cleaned up to core docs only.
- One-off migration helpers moved from `tools/` to `scripts/dev/`.
- Launcher GUI expanded for profile execution and output export.
- CI extended with Pester test jobs.
- Hard-cutover on script mode contract:
  - `AuditOnly` removed from `Mode` validate sets.
  - legacy top-level `-Remediate` script parameter removed in productive scripts.
  - remediation guarded via `-Mode Remediate` + `SupportsShouldProcess`.

### Fixed

- `Get-FindingStats` now handles empty findings collections.
- Pester suite stabilized for non-Windows environments via OS-aware skips.

## [1.x]

- Historical changes were tracked in prior planning and patch documents.
