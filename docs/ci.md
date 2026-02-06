# CI

## Overview
This repository uses a single GitHub Actions workflow for deterministic, fast static checks on every PR and on `main`.

Workflow: `.github/workflows/ci.yml`
Jobs:
- `verify`: secret scan + PowerShell parsing + PSScriptAnalyzer

Triggers:
- `pull_request`
- `push` to `main`

## Local Run (CI-Equivalent)
Recommended (cross-platform, requires PowerShell 7+):
```bash
./scripts/ci-local.sh
```

Optional: skip PSScriptAnalyzer if you cannot install it locally:
```bash
CI_SKIP_ANALYZER=1 ./scripts/ci-local.sh
```

Direct PowerShell invocations (Windows-friendly):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\secret-scan.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1
```

## Tooling Details
- PSScriptAnalyzer is pinned to version `1.24.0` in CI for determinism.
- PowerShell module caching is enabled to speed up installs.
- Jobs have timeouts and concurrency limits to avoid duplicate work.

## Secrets and Repo Settings
- No repository secrets are required for CI.
- The workflow uses minimal permissions and does not write to the repo.

## Extending CI
When adding checks:
1. Update `.github/workflows/ci.yml` to include the new step.
2. Mirror the step in `scripts/ci-local.sh` for local reproducibility.
3. Document any new prerequisites here.

## Notes on `act`
This workflow targets `windows-latest`. Local runners via `act` (Linux containers) will not faithfully reproduce Windows-specific behavior. Prefer running `scripts/ci-local.sh` or a Windows VM for accurate results.
