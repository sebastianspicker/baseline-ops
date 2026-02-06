# CI Audit

Date: 2026-02-06

## Workflow Inventory
`.github/workflows/ci.yml`
- Triggers: `push` to `main`, `pull_request`
- Jobs: `verify`
- Actions: `actions/checkout@v4`, `actions/cache@v4`
- Permissions: `contents: read`, `actions: write`
- Runner: `windows-latest`
- Concurrency + timeout: enabled
- Steps: cache PowerShell modules, ensure PSScriptAnalyzer (pinned), secret scan, static checks

## Recent Failures
GitHub API access is available for run metadata, but job log download returned `403 Must have admin rights to Repository`, so exact log output is unavailable. Failure details below are based on job metadata + local reproduction.

## Failures, Root Cause, Fix Plan

| Workflow | Failure(s) | Root Cause | Fix Plan | Risk | How to Verify |
|---|---|---|---|---|---|
| `ci` | Step `Secret scan (basic)` failed on run `21713386542` (2026-02-05) | `tools/secret-scan.ps1` generic password regex matched a non-secret string: `"Reset-LapsPassword: $err1"` in `scripts/02-LAPS-Hygiene.ps1` | Tighten generic password/token patterns to require a likely value and avoid variable placeholders; rerun secret scan | Low (reduces false positives while still catching hardcoded secrets) | `pwsh -NoProfile -File tools/secret-scan.ps1` and rerun CI on GitHub |
| `ci` | PSScriptAnalyzer would fail after secret scan passes | Analyzer rules triggered by: assignment to automatic variables (`$Args`, `$matches`), unused variable (`$cHeader`), and overriding built-in `Write-Error` | Rename variables, remove unused variable, and remove `Write-Error` wrapper in `lib/Output.psm1`; update `tools/verify.ps1` accordingly | Low (non-functional refactors) | `pwsh -NoProfile -File tools/verify.ps1` (expect exit code 0) |

Status: fixed locally; secret scan and PSScriptAnalyzer both pass. GitHub CI rerun pending.
