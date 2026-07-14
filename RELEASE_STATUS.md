# Release Status

**Evidence cutoff:** 2026-07-13
**Verdict:** NOT READY for alpha RC

## Status Summary

- **NOT READY** for an alpha release candidate.
- Candidate snapshot: `pin-clusterfuzzlite-image-digest` at `180fcb83a5d7`, 80 dirty paths before this report, tracking `origin/pin-clusterfuzzlite-image-digest`, and no tag at `HEAD` (observed 2026-07-13).
- Proposed alpha scope: privileged Windows MDM hardening profiles and rollback tooling only where the exact payload and native execution matrix are verified.

## Verified Evidence

- Current session: read-only Git metadata only; no product test was run while producing this report.
- Planning baseline: static checks and Pester subsets passed; native Windows execution and rollback were not proven.

## Open Blockers

- Reconcile the 80-path candidate and release/version identity.
- Generate and verify a full transitive content manifest, not launcher-only coverage.
- Hash profile input at apply time, guarantee child-process cleanup, and make rollback coverage explicit.
- Add structured capability metadata, dependency locks, SBOM, signing, artifact checksums, and validated release upload behavior.

## External and Owner Evidence

- Disposable Windows VM apply, failure-injection, and rollback matrix.
- Windows version compatibility, code-signing, and operational recovery approval.

## Next Gate

Freeze the intended candidate, pass parser/PSScriptAnalyzer/Pester and transitive-manifest checks, then execute and preserve evidence from the native Windows apply/failure/rollback matrix for the exact signed artifact.
