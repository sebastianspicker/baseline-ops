# Phase 1.2 — Security Audit (Beyond Previous Work)

You are performing a deep security audit of the win-mdm-security-hardening-kit.

## Context
Iterations 1-5 (see `progress.md` and `.claude/02-security.md`) already fixed:
- WQL injection in scripts 02 and 11
- PS code injection via heredoc in script 21
- Unquoted schtasks arguments in script 21
DO NOT re-report these. Focus on NEW findings.

## Task

1. For each of the 45 operational scripts (`scripts/01-45*.ps1`), check:
   - **Command injection**: Any place user/config input reaches `Invoke-Expression`, `& $variable`, `Start-Process`, `schtasks.exe`, `reg.exe`, `wevtutil.exe`, `auditpol.exe`, or PowerShell heredocs without validation.
   - **Path traversal**: Any place a file path from config/param is used with `Get-Content`, `Set-Content`, `Copy-Item`, `New-Item`, `Remove-Item` without calling `Sanitize-Path` or `Test-PathTraversal` first.
   - **WQL/CIM injection**: Any `Get-CimInstance -Filter` or `Get-WmiObject -Filter` where variables are interpolated without escaping single quotes.
   - **Unsafe registry operations**: Registry paths from config used without validation.
   - **Credential exposure**: Any place credentials, tokens, or secrets might be logged to console, event log, or file output.
   - **TOCTOU**: Any check-then-act patterns on files or registry that could race.
2. Check `lib/External.psm1`:
   - The `Export-EventLog` function still has the `$Query` embedding issue (marked deferred in S5). Re-evaluate if this needs fixing given new callers.
   - Check all wrapper functions for argument injection possibilities.
3. Check `lib/Evidence.psm1`:
   - `Copy-ToEvidence` uses regex replacement for path sanitization. Verify this is sufficient.
4. Create `ralph-loop/phase1/1.2-security-audit-findings.md` with a prioritized table.
5. Do NOT modify any source files.
6. Commit the findings document.

## Files to Focus On
- `scripts/09-SupportBundle.ps1` (creates ZIP archives, handles paths)
- `scripts/12-Suspicious-Artifact-Grabber.ps1` (copies files to evidence)
- `scripts/14-SecureRemoteAccessGuardrails.ps1` (modifies firewall, RDP)
- `scripts/16-Sysmon-Config-Updater.ps1` (downloads and applies config)
- `scripts/18-Firewall-Baseline.ps1` (creates firewall rules from JSON)
- `scripts/21-EmergencyKillSwitch.ps1` (high-impact containment)
- `scripts/25-WinGet-Config-Baseline-Runner.ps1` (runs WinGet with config)
- `lib/External.psm1`, `lib/Evidence.psm1`, `lib/Common.psm1`

## What NOT to Touch
- Do not modify source files.
- Do not re-report S1-S5 from `.claude/02-security.md`.

## Verification
- `ralph-loop/phase1/1.2-security-audit-findings.md` exists.
- No source files modified.

## Exit Condition
Output `<promise>SECURITY_AUDIT_COMPLETE</promise>` when the findings document is complete and committed.
