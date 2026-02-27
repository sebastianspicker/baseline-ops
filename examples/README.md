# Examples

## Config examples

`examples/configs/` contains JSON config samples for individual scripts:

- `asr-defender-allowlist.json`
- `local-admins-allowlist.json`
- `firewall-baseline.json`
- `wufb-proofing.json`

Use with script-level `-ConfigPath` parameters.

## Profile examples (v2 orchestration)

`examples/profiles/` contains orchestration profiles for `00-Run-Profile.ps1`:

- `baseline-audit.json`
- `rapid-triage.json`
- `hardening-remediate.json`

Run example:

```powershell
pwsh -NoProfile -File .\scripts\00-Run-Profile.ps1 -ProfilePath .\examples\profiles\baseline-audit.json
```

Validate profile before execution:

```powershell
pwsh -NoProfile -File .\scripts\00-Validate-Profile.ps1 -ProfilePath .\examples\profiles\baseline-audit.json
```
