# R2 Phase 4.2 — New Security Audit Scripts

You are creating new security audit scripts to fill coverage gaps.

## Scripts to Create

Use `tools/new-script.ps1` as the canonical template. Follow ALL v2 conventions established in Round 1.

### 46-SecureBoot-UEFI-Audit.ps1
**Purpose**: Audit Secure Boot status and UEFI configuration.
**Checks**:
- Secure Boot enabled (`Confirm-SecureBootUEFI`)
- UEFI mode (not Legacy BIOS) via `Get-CimInstance Win32_OperatingSystem` FirmwareType
- Boot manager configuration integrity
- Measured Boot status
**Mode**: Audit only (no remediation — Secure Boot changes require BIOS access)

### 47-WDAG-Readiness-Audit.ps1
**Purpose**: Audit Windows Defender Application Guard readiness.
**Checks**:
- Hyper-V enabled (`Get-WindowsOptionalFeature`)
- WDAG feature installed
- WDAG policy configuration via registry
- Hardware virtualization support
**Mode**: Audit only

### 48-ExploitProtection-Audit.ps1
**Purpose**: Audit Windows Defender Exploit Guard / Exploit Protection settings.
**Checks**:
- System-level exploit mitigation settings (`Get-ProcessMitigation -System`)
- Per-process mitigations for key executables (browser, Office)
- ASR rule enforcement level (extends script 01's allowlist focus)
- Network protection status
**Mode**: Audit only

### 49-DriverSigning-Integrity-Audit.ps1
**Purpose**: Audit driver signing and kernel code integrity.
**Checks**:
- Driver signing enforcement (`bcdedit /enum` for TESTSIGNING, NOINTEGRITYCHECKS)
- HVCI status (extends script 13's VBS check)
- Unsigned driver inventory via `driverquery /SI`
- Memory integrity (Core isolation) status
**Mode**: Audit only

## For EACH script:
1. Use the v2 template from `tools/new-script.ps1`.
2. Include full v2 param contract (Mode, ConfigPath, OutputFormat, OutputPath, PassThru, Strict, Quiet, NoColor).
3. Include v2-init block, Bootstrap, module imports.
4. Use New-FindingsList/Add-Finding for findings.
5. Use New-V2ResultObject/Write-ResultObject for output.
6. Include complete comment-based help (.SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE, .OUTPUTS).
7. End with `exit 0`.
8. Put files in `scripts/` directory.

## Verification
After each script:
```
pwsh -NoProfile -File ./tools/verify.ps1 -RootPath .
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed -CI"
```

## Exit Condition
Output `<promise>NEW_SCRIPTS_COMPLETE</promise>` when all 4 scripts are created, pass verification, and are committed.
