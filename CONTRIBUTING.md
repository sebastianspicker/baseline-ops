# Contributing

Thanks for helping improve this repository. Please keep changes minimal, well‑scoped, and safe for production environments.

## Ground rules
- Do not include secrets, tokens, or private keys in code, tests, logs, or examples.
- Avoid behavior changes without a clear rationale and documentation.
- Prefer small, focused pull requests.
- Test in a lab environment before running in production.

## Development workflow
1) Create a branch.
2) Make focused changes.
3) Run the verification steps (below).
4) Open a PR with a clear summary and testing notes.

## Verification
- Fast loop (syntax only):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1 -SkipAnalyzer
```

- Full loop (syntax + PSScriptAnalyzer):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify.ps1
```

- Secret scan (basic local scan):
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\secret-scan.ps1
```

## Documentation
- Update `README.md` if behavior, parameters, or usage changes.
- Keep examples accurate and safe (use `PATH/TO/...` placeholders).

## Security reporting
See `SECURITY.md` for vulnerability disclosure guidance.
