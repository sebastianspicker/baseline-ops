# R2 Phase 4.1 — Create Comprehensive Example Profiles

You are creating new, comprehensive v2 profile examples.

## Task

Read `examples/profiles/` for existing profiles (baseline-audit.json, rapid-triage.json, hardening-remediate.json).
Read `scripts/00-Run-Batch.ps1` for category definitions.
Read `scripts/README.md` for the script category table.

Create these new profile files:

### 1. `examples/profiles/full-audit.json`
Include ALL scripts that support `-Mode Audit`. Steps should be ordered logically:
- Identity/access first (02, 03, 28, 41)
- OS hardening (04, 05, 06, 13, 33, 38, 39, 40)
- Network/firewall (14, 18, 22, 29, 32, 37, 44)
- Defender/security tools (01, 11, 15, 16, 17, 27, 43)
- Monitoring/logging (07, 26, 31, 34, 45)
- Storage/backup (23, 24, 35, 36)
- Software/apps (08, 19, 25)
- Collection (09)

### 2. `examples/profiles/endpoint-health-check.json`
A quick health check with ~10 key scripts:
- 27 (Defender Health), 15 (TPM), 23 (BitLocker), 05 (WUFB), 06 (UpdateHealth),
- 34 (TimeSync), 35 (Storage), 29 (Network), 28 (Identity), 42 (Security Baseline)

### 3. `examples/profiles/incident-response.json`
For incident triage:
- 26 (WinEvent FastTriage), 11 (IOC Sweep), 12 (Artifact Grabber),
- 09 (SupportBundle), 30 (Service/Process), 07 (ScheduledTasks),
- 37 (Remote Surface), 21 (EmergencyKillSwitch - in DependsOn chain)

### 4. `examples/profiles/compliance-full.json`
Full compliance check:
- 42 (Security Baseline), 33 (Audit Policy), 43 (AppControl),
- 39 (Credential Guard), 40 (LSA Protection), 13 (VBS/HVCI),
- 31 (PowerShell Logging), 22 (SMB Encryption), 44 (Ransomware Protection),
- 01 (ASR), 23 (BitLocker), 41 (NTLM)

Follow the existing profile JSON schema with ProfileName, Version, Defaults, Steps, and Integrity sections.

## Also
Update `examples/README.md` to document the new profiles.

## Verification
- `pwsh -NoProfile -File scripts/00-Validate-Profile.ps1 -ProfilePath examples/profiles/full-audit.json -PassThru` should succeed for each new profile.

## Exit Condition
Output `<promise>PROFILES_COMPLETE</promise>` when all profiles are created, validated, and committed.
