# RUNBOOK

## Setup
- Supported platforms: Windows 10/11 or Windows Server (script-dependent).
- PowerShell 5.1+ (some scripts may also work with PowerShell 7.x).
- Optional: PSScriptAnalyzer module for static analysis.
- Optional: Git for `scripts/00-Copy-Local.ps1` (uses `git.exe`).

If Windows blocked downloaded scripts, unblock them:
```powershell
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
```

## Fast loop (syntax only)
Parses all scripts/modules and skips analyzer (fastest feedback):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1 -SkipAnalyzer
```

## Full loop (static checks)
Parses all scripts/modules and runs PSScriptAnalyzer (if installed):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1
```

## Lint / format
The repo uses PSScriptAnalyzer via `tools/verify.ps1`:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1
```

## Typecheck / static checks
PowerShell parsing is enforced by `tools/verify.ps1`.

## Build
Not applicable (standalone PowerShell scripts).

## Tests
No automated tests currently.

## Security minimum
- Secret scan (basic local scan):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\secret-scan.ps1
```
- SAST: PSScriptAnalyzer via `tools/verify.ps1`.
- SCA/Dependencies: Not applicable (no package/lockfiles).

## Troubleshooting
- If `Invoke-ScriptAnalyzer` is missing, install PSScriptAnalyzer or run with `-SkipAnalyzer`.
- If `tools/verify.ps1` cannot find `scripts/` or `lib/`, run from repo root.
- Use PowerShell 7 with `pwsh` if preferred (ensure script compatibility).
