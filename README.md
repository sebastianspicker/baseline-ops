# Windows MDM Endpoint Security Hardening Kit

PowerShell toolkit for Windows endpoint hardening, drift detection, triage, and controlled remediation in MDM-managed environments.

## Repository policy

This repository uses a lean root layout. The root intentionally keeps only core project docs:

- `README.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `CHANGELOG.md`

Operational bug tracking and investigation history live in GitHub Issues/PRs, not in large root markdown artifacts.

## Requirements

- Windows 10/11 or Windows Server (script dependent)
- PowerShell 5.1+ (PowerShell 7.x supported for local dev tooling)
- Elevated shell for scripts that modify system state
- Optional components by script: Defender, BitLocker, Sysmon, WinGet

## Core structure

- `scripts/` : operational scripts
- `lib/` : shared modules
- `examples/` : sample JSON configs and profiles
- `tests/` : Pester tests
- `tools/` : CI and operator utilities (GUI launcher, verify, secret scan)

## v2 execution model

New orchestration scripts provide a normalized execution layer:

- `scripts/00-Validate-Profile.ps1` : validates profile JSON
- `scripts/00-Run-Profile.ps1` : executes profile steps with dependency/order controls
- `scripts/00-Run-Batch.ps1` : runs category/tag based script batches
- `scripts/00-Report-Aggregate.ps1` : aggregates multiple JSON outputs

Deployment helpers:

- `scripts/00-Copy-Local.ps1`
- `scripts/00-Run-Local.ps1`

### Breaking changes (v2 hard cutover)

- `-Mode` is the normalized execution switch (`Audit|Remediate`) for productive scripts.
- Legacy top-level `-Remediate` parameters were removed from productive scripts.
- Legacy `AuditOnly` mode values were removed from script parameter contracts.

## Profile schema (v2)

`examples/profiles/*.json` follow this shape:

- `ProfileName`
- `Version`
- `Defaults`
  - `Mode` (`Audit` or `Remediate`)
  - `Strict`
  - `OutputFormat` (`Console|Json|Csv|None`)
  - `OutputPath`
- `Steps[]`
  - `Script`
  - `Args`
  - `ContinueOnError`
  - `DependsOn`
- `Integrity`
  - `RequireSigned`
  - `ExpectedHashes`

## Validation and local CI

From repository root:

```powershell
# Parse checks only
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1 -SkipAnalyzer

# Parse + PSScriptAnalyzer
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1

# Secret scan
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\secret-scan.ps1

# Tests
pwsh -NoProfile -Command "Invoke-Pester -Path .\tests -Output Detailed"
```

Cross-platform local CI wrapper:

```bash
./scripts/ci-local.sh
```

## Launcher GUI

Run the launcher from repository root:

```powershell
pwsh -ExecutionPolicy Bypass -File .\tools\Launcher-GUI.ps1
```

Launcher supports:

- single script runs via `00-Run-Local.ps1`
- profile runs via `00-Run-Profile.ps1`
- argument presets and live output
- saving output to log file

![Launcher GUI Preview](reports/screenshots/launcher-gui-preview.png)

## Security and safety notes

- Validate all remediation flows in a lab before production.
- Prefer `-WhatIf` / `-Confirm` when supported.
- Use script signing or expected hash checks in deployment pipelines.
- Treat generated evidence and export artifacts as sensitive.

## Related docs

- [scripts/README.md](scripts/README.md)
- [lib/README.md](lib/README.md)
- [examples/README.md](examples/README.md)
- [SECURITY.md](SECURITY.md)
