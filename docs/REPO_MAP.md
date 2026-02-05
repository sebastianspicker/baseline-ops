# REPO_MAP

## Top-level layout
- `scripts/`: Numbered PowerShell scripts (01-45) for audits, hardening, and remediation; includes deployment helpers.
- `scripts/_lib/Bootstrap.ps1`: Resolves `lib/` module path for all scripts.
- `lib/`: Shared helper modules (`Common`, `Output`, `Registry`, `Config`, `EventLog`, `Results`).
- `tools/verify.ps1`: Static verification (parse + optional PSScriptAnalyzer).
- `PSScriptAnalyzerSettings.psd1`: Analyzer rules.
- `.github/`: Issue/PR templates.
- `README.md`, `SECURITY.md`, `LICENSE`, `.gitignore`.

## Primary entry points
- `scripts/*.ps1`: Standalone scripts intended for direct execution.
- `scripts/00-Copy-Local.ps1`: Pulls repo and stages `scripts/` + `lib/` into a local deployment path.
- `scripts/00-Run-Local.ps1`: Runs a staged script by name or number.
- `tools/verify.ps1`: Repo-level static verification.

## Shared modules (lib)
- `lib/Common.psm1`: Admin/path/config helpers.
- `lib/Output.psm1`: Unified console output helpers.
- `lib/Registry.psm1`: Registry helpers (read/write/remove).
- `lib/Config.psm1`: JSON config loading/merging helpers.
- `lib/EventLog.psm1`: Event log helpers.
- `lib/Results.psm1`: Findings list and add helpers.

## Typical flow
1) Script dot-sources `scripts/_lib/Bootstrap.ps1`.
2) Script imports one or more modules from `lib/`.
3) Script performs audit/remediation and outputs via `lib/Output.psm1` and `lib/Results.psm1`.

## Hotspots / risk areas to review first
- Scripts with `Remediate`, `Enforcer`, `Guardrail`, `KillSwitch` in the name (system-changing behavior).
- Deployment helpers that pull/clone repositories and copy files: `scripts/00-Copy-Local.ps1`.
- Scripts that likely rely on external tools (by name): WinGet, Sysmon, Defender, BitLocker.

## Docs
- `README.md`: Usage, requirements, script inventory.
- `SECURITY.md`: Security contact/handling guidance.
