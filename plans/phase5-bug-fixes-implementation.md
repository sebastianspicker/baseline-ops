# Phase 5: Bug Fixes & Security - Implementation Details

## Overview

This document provides detailed implementation instructions for each bug fix in Phase 5.

---

## Bug Status Analysis

| Bug ID | Description | Current Status | Action Needed |
|--------|-------------|----------------|---------------|
| #3 | Pipeline output commented out | ✅ Already fixed | Verify only |
| #21 | Kill switch schtasks validation | ❌ Not fixed | Fix required |
| #23 | Copy-Local option injection | ✅ Already fixed | Verify only |
| #24 | Supply-chain drift verification | ✅ Already fixed | Verify only |
| #25 | Integrity check before execution | ❌ Not implemented | New feature |

---

## Bug #3: Pipeline Output in 38-SecurityOptions-Drift.ps1

### Analysis

The bug report stated that pipeline output was commented out. However, examining the current code at lines 510-517:

```powershell
# Pipeline output: exactly one structured object (§3).
[pscustomobject]@{
  Summary       = $summary
  Findings      = [object[]]$script:Findings
  CurrentValues = [object[]]$script:CurrentValues
  Drift         = [object[]]$script:Drift
  DesiredLoaded = $desiredLoaded
}
```

**Status: ✅ ALREADY FIXED** - The pipeline output is NOT commented out. The object is properly emitted.

### Verification Test

```powershell
$r = .\scripts\38-SecurityOptions-Drift.ps1
$r.Summary | Format-List
$r.Findings | Format-Table
```

---

## Bug #21: Kill Switch schtasks Validation

### Problem

In [`scripts/21-EmergencyKillSwitch.ps1`](scripts/21-EmergencyKillSwitch.ps1:301), the `Schedule-AutoRollback` function:

1. Calls `schtasks.exe /Create` without checking `$LASTEXITCODE`
2. Uses `$ErrorActionPreference='SilentlyContinue'` in rollback script, hiding failures

### Current Code (Lines 301-330)

```powershell
function Schedule-AutoRollback {
  param(
    [int]$Minutes,
    [string]$TaskName,
    [string[]]$RuleNames
  )

  if ($Minutes -le 0) { return $false }

  $runAt = (Get-Date).AddMinutes($Minutes)

  $rollbackPs = @"
`$ErrorActionPreference='SilentlyContinue';
Set-NetFirewallProfile -All -Enabled True -DefaultInboundAction Allow -DefaultOutboundAction Allow;
Get-NetFirewallRule -Name '$($RuleNames -join "','")' | Remove-NetFirewallRule;
schtasks.exe /Delete /TN '$TaskName' /F | Out-Null;
"@

  $bytes = [System.Text.Encoding]::Unicode.GetBytes($rollbackPs)
  $enc   = [Convert]::ToBase64String($bytes)
  $tr    = "PowerShell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"

  try {
    schtasks.exe /Create /TN $TaskName /SC ONCE /ST $runAt.ToString('HH:mm') /TR $tr /RL HIGHEST /F | Out-Null
    return $true
  } catch {
    Add-RunError "Auto-rollback schedule failed: $($_.Exception.Message)"
    return $false
  }
}
```

### Required Fix

```powershell
function Schedule-AutoRollback {
  param(
    [int]$Minutes,
    [string]$TaskName,
    [string[]]$RuleNames
  )

  if ($Minutes -le 0) { return $false }

  $runAt = (Get-Date).AddMinutes($Minutes)
  $logPath = Join-Path $env:TEMP "KillSwitch-Rollback-$($TaskName -replace '[^a-zA-Z0-9]', '').log"

  # Improved rollback script with proper error handling and logging
  $rollbackPs = @"
`$ErrorActionPreference = 'Stop'
`$logPath = '$logPath'
function Write-RollbackLog { param([string]`$Message) Add-Content -Path `$logPath -Value "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') `$Message" }
try {
  Write-RollbackLog 'Starting rollback...'
  Set-NetFirewallProfile -All -Enabled True -DefaultInboundAction Allow -DefaultOutboundAction Allow
  Write-RollbackLog 'Firewall profiles reset to Allow'
  Get-NetFirewallRule -Name '$($RuleNames -join "','")' | Remove-NetFirewallRule -ErrorAction SilentlyContinue
  Write-RollbackLog 'Kill switch rules removed'
  `$delResult = schtasks.exe /Delete /TN '$TaskName' /F 2>&1
  if (`$LASTEXITCODE -eq 0) { Write-RollbackLog 'Rollback task removed' } 
  else { Write-RollbackLog "Task removal exit code: `$LASTEXITCODE" }
  Write-RollbackLog 'Rollback completed successfully'
} catch {
  Write-RollbackLog "ERROR: `$(`$_.Exception.Message)"
  exit 1
}
"@

  $bytes = [System.Text.Encoding]::Unicode.GetBytes($rollbackPs)
  $enc   = [Convert]::ToBase64String($bytes)
  $tr    = "PowerShell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"

  try {
    $output = schtasks.exe /Create /TN $TaskName /SC ONCE /ST $runAt.ToString('HH:mm') /TR $tr /RL HIGHEST /F 2>&1
    if ($LASTEXITCODE -ne 0) {
      Add-RunError "Auto-rollback schedule failed (exit code $LASTEXITCODE): $output"
      return $false
    }
    Add-RunError "Auto-rollback scheduled for $runAt (log: $logPath)"  # Info message
    return $true
  } catch {
    Add-RunError "Auto-rollback schedule failed: $($_.Exception.Message)"
    return $false
  }
}
```

### Changes Made

1. **Exit code validation**: Check `$LASTEXITCODE` after `schtasks.exe /Create`
2. **Error logging**: Rollback script now logs to a temp file for debugging
3. **Proper error handling**: Changed from `SilentlyContinue` to `Stop` with try/catch
4. **Output capture**: Capture schtasks output for error messages

---

## Bug #23: Copy-Local Option Injection

### Analysis

The current code at lines 51-59 already validates against option injection:

```powershell
if ($RepoUrl -match '^\s*-') {
  throw 'RepoUrl must not start with "-" or leading whitespace (option injection prevention).'
}
if (-not [string]::IsNullOrWhiteSpace($RepoPath) -and $RepoPath -match '^\s*-') {
  throw 'RepoPath must not start with "-" or leading whitespace (option injection prevention).'
}
if (-not [string]::IsNullOrWhiteSpace($RepoRef) -and $RepoRef -match '^\s*-') {
  throw 'RepoRef must not start with "-" or leading whitespace (option injection prevention).'
}
```

**Status: ✅ ALREADY FIXED**

### Additional Hardening (Optional)

For extra security, add URL format validation:

```powershell
# Add after line 59
if ($RepoUrl -notmatch '^https?://|^\w+@|git@') {
  throw 'RepoUrl must be a valid git URL (http/https/git/ssh).'
}
```

---

## Bug #24: Supply-Chain Drift Verification

### Analysis

The current code at lines 116-128 already verifies remote URL:

```powershell
if (Test-Path -LiteralPath (Join-Path $RepoPath '.git')) {
  # Verify existing clone matches intended RepoUrl to avoid supply-chain drift (§24)
  try {
    $configuredRemote = (git -C $RepoPath remote get-url origin 2>$null).Trim()
    $normalizedUrl = $RepoUrl.Trim().ToLowerInvariant()
    $normalizedRemote = $configuredRemote.Trim().ToLowerInvariant()
    if (-not [string]::IsNullOrWhiteSpace($configuredRemote) -and $normalizedRemote -ne $normalizedUrl) {
      throw ("Configured remote URL does not match -RepoUrl. Remote: {0}; Expected: {1}. Use a clean path or re-clone." -f $configuredRemote, $RepoUrl)
    }
  } catch {
    if ($_.Exception.Message -match 'does not match') { throw }
    # git remote get-url can fail if no origin; continue
  }
  # ... rest of fetch/pull logic
}
```

**Status: ✅ ALREADY FIXED**

---

## Bug #25: Integrity Check Before Execution

### Problem

`00-Run-Local.ps1` executes scripts without any integrity verification. A tampered deployment directory could lead to malicious code execution.

### Proposed Solution

Add optional signature/hash verification to `00-Run-Local.ps1`.

### New Parameter

```powershell
[switch]$RequireSigned,
[string[]]$ExpectedHashes,  # Format: "script.ps1=SHA256:hash"
[string]$HashAlgorithm = 'SHA256'
```

### Implementation

Add after script path resolution (around line 92):

```powershell
# Integrity verification (optional)
if ($RequireSigned) {
  $signature = Get-AuthenticodeSignature -FilePath $scriptPath
  if ($signature.Status -ne 'Valid') {
    throw "Script signature verification failed for $scriptPath : $($signature.Status)"
  }
  Write-UiLine "Signature verified: $($signature.SignerCertificate.Subject)" -Style Success
}

if ($ExpectedHashes) {
  $scriptName = Split-Path $scriptPath -Leaf
  $expectedEntry = $ExpectedHashes | Where-Object { $_ -like "$scriptName=*" } | Select-Object -First 1
  if ($expectedEntry) {
    $expectedHash = ($expectedEntry -split '=', 2)[1]
    if ($expectedHash -match '^(\w+):(.+)$') {
      $alg = $Matches[1]
      $hash = $Matches[2]
    } else {
      $alg = $HashAlgorithm
      $hash = $expectedHash
    }
    $actualHash = (Get-FileHash -Path $scriptPath -Algorithm $alg).Hash
    if ($actualHash -ne $hash) {
      throw "Hash mismatch for $scriptPath. Expected: $hash, Actual: $actualHash"
    }
    Write-UiLine "Hash verified ($alg)" -Style Success
  }
}
```

### Usage Examples

```powershell
# Require signed scripts
.\00-Run-Local.ps1 -ScriptNumber 18 -RequireSigned

# Verify specific hash
.\00-Run-Local.ps1 -ScriptName "18-Firewall-Baseline.ps1" `
  -ExpectedHashes @("18-Firewall-Baseline.ps1=SHA256:ABC123...")

# Multiple script hashes from config file
$hashes = Get-Content .\script-hashes.txt
.\00-Run-Local.ps1 -ScriptNumber 18 -ExpectedHashes $hashes
```

---

## Implementation Checklist

### Must Do (Critical)

- [ ] **Bug #21**: Fix schtasks exit code validation in `21-EmergencyKillSwitch.ps1`
  - File: `scripts/21-EmergencyKillSwitch.ps1`
  - Lines: 301-330
  - Replace `Schedule-AutoRollback` function

### Should Do (High)

- [ ] **Bug #25**: Add integrity check to `00-Run-Local.ps1`
  - File: `scripts/00-Run-Local.ps1`
  - Add parameters: `-RequireSigned`, `-ExpectedHashes`
  - Add verification logic after path resolution

### Nice to Have (Medium)

- [ ] Add URL format validation to `00-Copy-Local.ps1`
- [ ] Add rollback log file cleanup mechanism
- [ ] Document integrity verification in README

---

## Testing Plan

### Bug #21 Test

```powershell
# Test 1: Verify schtasks failure is caught
# Temporarily break the task name to force failure
.\scripts\21-EmergencyKillSwitch.ps1 -AutoRollbackMinutes 1 -Confirm:$false
# Check $result.Actions.RollbackScheduled is $false on failure

# Test 2: Verify rollback log is created
# Check $env:TEMP for KillSwitch-Rollback-*.log after scheduled time
```

### Bug #25 Test

```powershell
# Test 1: Hash verification success
$hash = (Get-FileHash .\scripts\18-Firewall-Baseline.ps1).Hash
.\scripts\00-Run-Local.ps1 -ScriptNumber 18 -ExpectedHashes @("18-Firewall-Baseline.ps1=$hash") -WhatIf

# Test 2: Hash verification failure
.\scripts\00-Run-Local.ps1 -ScriptNumber 18 -ExpectedHashes @("18-Firewall-Baseline.ps1=WRONGHASH") -WhatIf
# Should throw hash mismatch error
```

---

## Files to Modify

| File | Changes | Lines Affected |
|------|---------|----------------|
| `scripts/21-EmergencyKillSwitch.ps1` | Fix Schedule-AutoRollback | 301-330 |
| `scripts/00-Run-Local.ps1` | Add integrity verification | ~92+ |
| `scripts/README.md` | Document new parameters | - |

---

## Next Steps

1. Switch to Code mode to implement Bug #21 fix
2. Test the fix with various scenarios
3. Implement Bug #25 integrity check
4. Update documentation
5. Create Pester tests for new functionality
