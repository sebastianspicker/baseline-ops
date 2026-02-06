# CI Decision

Date: 2026-02-06

## Decision
LIGHT CI (static checks only).

## Rationale
- This repo is a PowerShell script toolkit. There is no build artifact to compile or package.
- Most scripts require Windows endpoints, admin rights, and sometimes MDM/Defender/Sysmon context, which are not reproducible in GitHub-hosted runners.
- Full integration runs on `windows-latest` would be environment-bound and flaky, increasing risk of red PRs without real signal.
- Static checks (syntax parsing, PSScriptAnalyzer, secret scan) are deterministic, fast, and provide high value for every PR.

## What Runs Where
- `pull_request` and `push` to `main`: secret scan + static PowerShell parsing + PSScriptAnalyzer.
- No deploy steps. No secret-dependent jobs.
- No scheduled/nightly jobs yet.

## CI Threat Model
- Untrusted fork PRs: run only static checks that require no secrets.
- No use of `pull_request_target`.
- `GITHUB_TOKEN` has minimal permissions and is not used to write to the repo.
- Caching uses the Actions cache service; no sensitive artifacts are stored.

## If We Later Want FULL CI
We would need:
- A controlled Windows test lab or self-hosted Windows runner that can safely exercise scripts.
- Non-production fixtures and secrets (e.g., test tenant, mock endpoints).
- Clear segregation: PRs run only safe checks; heavier integration tests run on `push` to `main`, `workflow_dispatch`, or scheduled.
- Environment protection rules and explicit approvals for any job that could modify system state.
