# Bugs & Required Fixes

Each item can be turned into a separate issue.

---

## Known Limitations / Bugs

### 1. [Bug] “Audit-only” run still modifies firewall (RDP rules disabled)

**Description:** In `scripts/14-SecureRemoteAccessGuardrails.ps1`, `Disable-LocalBuiltinRdpInbound` is invoked unconditionally inside `Ensure-RdpFirewallRules`, regardless of `-Remediate`. The script claims “Running without -Remediate performs an audit only (no changes).”

**Impact:** Running audit-only on endpoints can silently disable built-in “Remote Desktop” inbound firewall rules and cut off remote access. Violates the audit-only contract.

**Fix:** Only call `Disable-LocalBuiltinRdpInbound` when `$Remediate` is true and when the catalog specifies RDP disabled; otherwise perform read-only checks only.

---

### 2. [Bug/Operational] “Audit-only” mode can still modify registry (e.g. WUFB, Defender)

**Description:** Several scripts create missing registry keys or apply “minimum” baselines even when run in audit-only or proof-only mode. Examples: `06-UpdateHealth-SSU-Proof.ps1` (creates missing keys); `01-ASR-Defender-Allowlist.ps1` (minimum baseline + remediation can remove CFA allowlists when JSON is missing/invalid).

**Impact:** Operators expect audit-only to be read-only. Silent registry changes undermine trust and can cause unintended fleet state.

**Fix:** Gate all registry/key creation and remediation behind an explicit `-Remediate` (or equivalent) and do not create keys or change values in audit-only paths.

---

### 3. [Bug] Pipeline output is commented out (structured object never emitted)

**Description:** In `scripts/38-SecurityOptions-Drift.ps1`, the script documents “Pipeline output: exactly one structured object” but the object emission is commented out. Automation that does `$r = .\38-SecurityOptions-Drift.ps1; $r.Summary` receives `$null`.

**Impact:** Major advertised functionality (Export-Csv, ConvertTo-Json, filtering) is non-functional; audits/remediation pipelines silently get no data.

**Fix:** Uncomment and emit the documented pipeline object after `Write-ConsoleSummary` (or document that pipeline output is not yet implemented).

---

### 4. [Bug] Findings list is not usable (empty list → $null; first Add-Finding throws)

**Description:** `New-FindingsList` returns a `List[object]`; PowerShell enumerates it on the pipeline so the caller receives `$null`. `Add-Finding` treats empty collections as “missing” and throws when no list is found, so the first finding addition fails.

**Impact:** Scripts cannot reliably build or export findings; they either report FindingsCount=0 with Findings=$null, or crash when reporting the first finding.

**Fix:** In `lib/Results.psm1`: (1) Ensure `New-FindingsList` is not enumerated (e.g. `return , (New-Object System.Collections.Generic.List[object])` or assign via variable and return that variable). (2) In `Add-Finding`, treat empty list as valid (e.g. check for `$null` only, or allow empty list and create one if caller provided `$null` and lookup fails).

---

### 5. [Bug] Set-RegDword return value is $null; scripts treat it as boolean

**Description:** `lib/Registry.psm1`’s `Set-RegDword` pipes output to `Out-Null` and does not return `$true`/`$false`. Multiple scripts use `if (Set-RegDword ...) { ... } else { ... }`, so the else branch always runs and remediation is reported as “failed” even when it succeeded.

**Impact:** False “Failed to set …” drift entries, incorrect event IDs, and automation repeatedly attempting “failed” remediations. Machine state and reported state diverge.

**Fix:** Either make `Set-RegDword` return a boolean (e.g. wrap in try/catch and return $true/$false), or change all call sites to not depend on return value and verify by reading back the value.

---

## Required Fixes / Improvements

### 6. [Enhancement] EventLog.psm1 parameter contract: align call sites with function signature

**Description:** `Write-HealthEvent` does not define `-EventLogReady` or `-CanEventLog`; scripts pass these and hit parameter-binding errors. `Ensure-EventSource` requires `-Source` and `-LogName` and does not support `-SourceName`; at least one script uses `-SourceName` and others omit `-LogName`.

**Fix:** Extend `Write-HealthEvent` to accept optional `-EventLogReady`/`-CanEventLog` (or remove from call sites). Extend `Ensure-EventSource` to accept `-SourceName` as alias for `-Source` and make `-LogName` optional with a safe default, or fix all call sites to pass `-Source` and `-LogName`.

---

### 7. [Enhancement] Validate external command exit codes (schtasks, auditpol, reg, wevtutil, wecutil)

**Description:** Many scripts call `schtasks.exe`, `auditpol.exe`, `reg.exe`, `wevtutil`, `wecutil` inside try/catch or without checking `$LASTEXITCODE`. External command failures do not throw PowerShell exceptions by default, so success is assumed incorrectly.

**Fix:** After each external invocation, check `$LASTEXITCODE` and treat non-zero as failure (throw or return error). Do not rely on try/catch alone for external executables.

---

### 8. [Enhancement] Avoid SilentlyContinue for remediation and evidence collection

**Description:** Remediation and evidence paths use `-ErrorAction SilentlyContinue` so failures are not thrown; scripts then record “success” or continue as if the operation succeeded. Applies to service/task disable, firewall rule removal, registry cleanup, and various exports.

**Fix:** Use `-ErrorAction Stop` for remediation and critical collection paths, and handle errors in try/catch with explicit logging/findings. Reserve SilentlyContinue only for optional or best-effort steps and document that.

---

### 9. [Operational] Document “audit-only” vs “remediate” and recovery for stuck state

**Description:** Scripts that can change system state (firewall, registry, services) should document clearly when they are read-only vs when they modify. Recovery steps for interrupted runs (e.g. stuck “processing” or half-applied config) are not centralized.

**Fix:** Add a short “Audit vs Remediate” and “Recovery” subsection in README or `docs/RUNBOOK.md`; reference script-specific behaviour and link to FAQ/operations where applicable.

---

### 10. [Enhancement] Deployment helper: validate RepoUrl, RepoPath, RepoRef, DestinationRoot and constrain ScriptName

**Description:** `00-Copy-Local.ps1` passes RepoUrl/RepoPath/RepoRef to git without validation (option injection risk); DestinationRoot is not validated (risky paths). `00-Run-Local.ps1` does not constrain `-ScriptName` to a basename (path traversal → arbitrary execution).

**Fix:** Validate RepoUrl/RepoPath/RepoRef (e.g. reject leading `-`, constrain format). Validate DestinationRoot (e.g. block system roots, require subdirectory). For Run-Local: resolve script path under RootPath\scripts, then ensure resolved path is under that directory and is a .ps1 file (reject traversal and non-scripts).

---

## Critical

### 11. [Bug] Run-Local: `-ScriptName` allows path traversal and can execute arbitrary local files

**Description:** `scripts/00-Run-Local.ps1` builds `$scriptPath` with `Join-Path $scriptsRoot $ScriptName` without constraining `ScriptName` to a basename or blocking `..\`. After normalization, a path outside `scripts` can be executed.

**Fix:** Resolve path under `$scriptsRoot`; ensure the resolved path starts with `$scriptsRoot` and is a single file with extension `.ps1`. Reject traversal and directories.

---

### 12. [Bug] Write-HealthEvent called with non-existent parameters (runtime failure)

**Description:** Scripts pass `-EventLogReady` or `-CanEventLog` to `Write-HealthEvent`, which does not define these parameters. Parameter-binding error stops execution.

**Fix:** Add optional parameters to `Write-HealthEvent` or remove them from all call sites.

---

### 13. [Bug] Ensure-EventSource parameter mismatch (-SourceName, missing -LogName)

**Description:** Call sites use `-SourceName` or omit mandatory `-LogName`. Parameter-binding fails and can halt the script before any event logging.

**Fix:** Align `Ensure-EventSource` signature with usage (e.g. add `-SourceName` alias, or make `-LogName` optional with default) and fix call sites that omit required params.

---

### 14. [Bug] Set-RegDword returns no success signal; boolean checks always take failure path

**Description:** `Set-RegDword` returns `$null`; `if (Set-RegDword ...)` is always false. Drift/remediation reporting and control flow are wrong.

**Fix:** Have `Set-RegDword` return a boolean (e.g. try/catch around write, return $true/$false), or stop using its return value in conditionals and verify by read-back.

---

### 15. [Bug] New-FindingsList return value is enumerated; caller gets $null

**Description:** Returning a new empty `List[object]` from a function causes PowerShell to enumerate it; the caller receives `$null`, so list methods and Add-Finding fail.

**Fix:** Return the list without enumeration (e.g. `return , (New-Object System.Collections.Generic.List[object])` or use a variable and return that).

---

### 16. [Bug] Audit-only still disables built-in RDP inbound firewall rules

**Description:** `Disable-LocalBuiltinRdpInbound` is called unconditionally in `Ensure-RdpFirewallRules` in 14-SecureRemoteAccessGuardrails.ps1, regardless of -Remediate.

**Fix:** Call it only when remediating and when catalog specifies RDP disabled.

---

### 17. [Bug] WUFB/Update “audit-only” can still create missing registry keys

**Description:** In audit-only mode, the script can create missing keys for Windows Update policy, changing system state.

**Fix:** Do not create registry keys when not in remediation mode.

---

### 18. [Bug] Defender ASR “minimum” baseline + remediation can remove CFA allowlists when JSON missing/invalid

**Description:** When JSON is missing or invalid, minimum baseline plus remediation can remove existing CFA allowlists.

**Fix:** In the “no config” path, do not apply remediation that removes allowlists; or require explicit confirmation and document behaviour.

---

### 19. [Bug] Built-in Administrator (RID 500) protection can fail; SID detection returns $null and allows removal

**Description:** `Get-BuiltinAdministratorSid` can return `$null` on failure; then `AlwaysKeepSIDs` is empty and the built-in Administrator is not protected. Remediation can then remove RID 500.

**Fix:** On failure to resolve RID 500, either fail safe (do not remove any account that might be RID 500) or add a well-known RID 500 SID to `AlwaysKeepSIDs` as fallback. Document behaviour when SID cannot be resolved.

---

### 20. [Bug] Domain-like principal protection misses Entra (AzureAD) PrincipalSource

**Description:** `Is-DomainLikePrincipal` only checks a fixed list of `PrincipalSource` strings. Entra principals may report `AzureAD` or other values not in the list and are then treated as removable without `-AllowDomainRemediation`.

**Fix:** Extend the list to include all known Entra/Azure AD principal source values (e.g. `AzureAD`, `Azure Active Directory`) and/or derive from documentation or runtime discovery. Prefer over-inclusion for “domain-like” to avoid accidental removal.

**Sources:** `audit/05-laps-localadmin.md` Finding #16, INDEX #10

---

### 21. [Bug] Kill switch: schtasks/success not validated; rollback payload uses SilentlyContinue

**Description:** `Schedule-AutoRollback` uses try/catch around `schtasks.exe /Create`, but non-zero exit code does not throw; success can be reported incorrectly. The generated rollback script sets `$ErrorActionPreference='SilentlyContinue'`, so rollback failures are invisible.

**Fix:** Check `$LASTEXITCODE` after schtasks; only set RollbackScheduled when exit code is 0. In rollback payload, avoid global SilentlyContinue or log failures to a known path.

**Sources:** `audit/17-error-handling.md` Finding #1, `audit/10-killswitch-remediation.md`

---

### 22. [Bug] Kill switch: firewall rule removal uses SilentlyContinue; outcomes not verified

**Description:** Rule deletion and break-glass cleanup use `-ErrorAction SilentlyContinue` with no verification. Failed removals can leave duplicate or stale rules and allow rules in place during/after isolation.

**Fix:** Use explicit error handling and verify rule state after delete; record and surface failures.

**Sources:** `audit/17-error-handling.md` Finding #2

---

## High

### 23. [Bug] Copy-Local: RepoUrl/RepoPath/RepoRef passed to git without validation (option injection)

**Description:** Values are passed to `git clone`/`checkout`; leading `-` or option-like strings can change git behaviour.

**Fix:** Validate and reject or sanitize RepoUrl, RepoPath, RepoRef (e.g. disallow leading `-`, constrain format).

**Sources:** `audit/03-deployment-helpers.md` Findings #1, #2

---

### 24. [Bug] Copy-Local: Existing .git causes RepoUrl to be ignored (supply-chain drift)

**Description:** If `$RepoPath\.git` exists, script does fetch/pull/checkout without verifying remote matches `-RepoUrl`. Content can come from a different repo.

**Fix:** When .git exists, verify configured remote URL matches intended RepoUrl (or document and require clean path for trusted clone).

**Sources:** `audit/03-deployment-helpers.md` Finding #3

---

### 25. [Bug] Run-Local: No integrity/signature check before executing script from disk

**Description:** Script executes whatever file is resolved under RootPath\scripts without integrity or provenance check. Tampered deployment directory can lead to execution of malicious code.

**Fix:** Document as risk; optionally add signature/hash check or require signed scripts when available.

**Sources:** `audit/03-deployment-helpers.md` Finding #14

---

### 26. [Bug] Output.psm1: Get-CallerSwitchValue finds local params first (Quiet/NoConsole/NoColor not inherited)

**Description:** Caller-scope lookup uses scope 1..3; scope 1 is the function’s own params (e.g. Quiet, NoConsole), which default to $false. Script-level flags are often never seen.

**Fix:** Adjust scope order or parameter resolution so script-level switches are respected when not explicitly passed (e.g. skip scope 1 for these names, or document that callers must pass switches explicitly).

**Sources:** `audit/01-lib-modules.md` Finding #4

---

### 27. [Bug] Registry helpers can throw (Ensure-RegistryKey, Set-RegDword, Remove-RegValueIfExists)

**Description:** No try/catch in lib; New-Item/New-ItemProperty/Remove-ItemProperty with -ErrorAction Stop can terminate callers on permission or provider failure.

**Fix:** Add try/catch in helpers and return/throw consistently, or document that callers must handle exceptions.

**Sources:** `audit/01-lib-modules.md` Finding #5

---

### 28. [Bug] Read-ConfigWithDefaults: -Defaults $null throws before try/catch

**Description:** `foreach ($k in $Defaults.Keys)` runs before any try/catch; if Defaults is $null, script terminates.

**Fix:** Guard: if ($null -eq $Defaults -or $Defaults.Keys.Count -eq 0) { ... } before iterating, or validate parameter at start.

**Sources:** `audit/01-lib-modules.md` Finding #6

---

### 29. [Bug] Add-Finding: empty list treated as “missing” and causes throw on first finding

**Description:** Truthiness of empty list is $false; Add-Finding then tries caller lookup, fails, and throws when the first finding is added.

**Fix:** Treat “empty list” as valid (e.g. only treat $null as missing, or allow creating list when caller provided $null and lookup fails).

**Sources:** `audit/14-output-results.md` Finding #2

---

### 30. [Bug] auditpol.exe output and remediation exit code not validated

**Description:** Get-AuditPolText and remediation both call auditpol without checking $LASTEXITCODE. Parser and “remediated” state can be wrong.

**Fix:** Check $LASTEXITCODE after each auditpol invocation; treat non-zero as failure and set/return error state.

**Sources:** `audit/17-error-handling.md` Findings #3, #4

---

### 31. [Bug] reg.exe export and service/task remediation use SilentlyContinue; success logged incorrectly

**Description:** Export-Reg and service/task remediation in IOC script use -ErrorAction SilentlyContinue; failures do not throw but success is still recorded.

**Fix:** Use -ErrorAction Stop for these operations and handle in try/catch; only record success when command/exit code indicates success.

**Sources:** `audit/17-error-handling.md` Findings #5, #6, #7

---

### 32. [Bug] wevtutil/wecutil invoked without exit-code validation; stderr suppressed

**Description:** Sysmon and WEF scripts call wevtutil/wecutil and discard stderr; exit status not checked. Channel enable/size and readiness can be misreported.

**Fix:** Check $LASTEXITCODE after each call; do not suppress stderr when diagnosing; treat non-zero as failure.

**Sources:** `audit/17-error-handling.md` Findings #14, #16, #18, `audit/07-sysmon.md`

---

### 33. [Bug] Firewall helper returns $true even when rule not found (Remove-LocalFirewallRuleByDisplayName)

**Description:** Function returns $true even if Get-NetFirewallRule returned $null, so “Removed local rule” is logged when nothing was removed.

**Fix:** Return $true only when a rule was found and removed; otherwise $false and optionally record finding.

**Sources:** `audit/10-killswitch-remediation.md` Finding #4

---

### 34. [Bug] 38-SecurityOptions-Drift: Desired JSON load failure can throw again inside catch

**Description:** In catch block, Test-Path -LiteralPath $InputValue can throw on invalid path-like strings, aborting graceful fallback.

**Fix:** Wrap the hint computation in try/catch or avoid Test-Path on untrusted InputValue in catch; use a safe hint or no hint.

**Sources:** `audit/12-registry-security-options.md` Finding #2

---

### 35. [Bug] 38-SecurityOptions-Drift: Registry type “Unknown” and REG_DWORD-style strings

**Description:** Normalize-RegistryType allows “Unknown” but New-ItemProperty does not support PropertyType Unknown. Common strings like REG_DWORD are rejected.

**Fix:** Map REG_* to valid PropertyType; do not allow Unknown for write path, or map to a supported type and document.

**Sources:** `audit/12-registry-security-options.md` Finding #3

---

### 36. [Bug] Local admins: ADSI fallback misclassifies local COMPUTERNAME\* as “Active Directory”

**Description:** Pattern `^[^\\]+\\` matches local computer accounts as well as domain; they are then protected as “domain-like” and may require -AllowDomainRemediation to remove local drift.

**Fix:** Exclude local computer name (e.g. match against $env:COMPUTERNAME) or use a more precise classification so local accounts are not treated as domain.

**Sources:** `audit/05-laps-localadmin.md` Finding #17

---

## Quick reference: common failure causes

| Symptom | Typical cause | Fix / see |
|--------|----------------|-----------|
| Parameter binding error (Write-HealthEvent / Ensure-EventSource) | Unknown params or missing mandatory -LogName / wrong param name | Extend lib/EventLog.psm1 or fix call sites (§12, §13) |
| “Failed to set …” despite successful registry change | Set-RegDword returns $null, used as boolean | Fix Set-RegDword return or call sites (§5, §14) |
| Findings empty or $null; Add-Finding throws on first finding | New-FindingsList enumerated; empty list treated as missing | Fix Results.psm1 return and Add-Finding logic (§4, §15, §29) |
| Audit-only run changed firewall/registry | Logic calls remediation or key creation without -Remediate check | Gate all writes on -Remediate (§1, §2, §16, §17) |
| Script not found / wrong script executed (Run-Local) | -ScriptName path traversal or non-.ps1 | Validate ScriptName and resolve path under scripts root (§11, §10) |
| External command “succeeded” but nothing changed | Exit code not checked (schtasks, auditpol, reg, wevtutil) | Check $LASTEXITCODE after every external call (§7, §21, §30, §32) |
| Remediation “success” but operation failed | -ErrorAction SilentlyContinue on critical ops | Use -ErrorAction Stop and try/catch for remediation (§8, §31, §33) |
| RID 500 or Entra admin removed unintentionally | SID resolution failed or PrincipalSource not in list | Harden RID 500 fallback; extend PrincipalSource list (§19, §20, §36) |
| Pipeline output $null (e.g. 38-SecurityOptions-Drift) | Pipeline object commented out | Emit documented object (§3) |
| Copy-Local pulls wrong repo / ref | .git exists and RepoUrl ignored; RepoRef unvalidated | Verify remote; validate refs (§24, §23) |

---

## Using this list for issues

- **Labels:** `bug`, `enhancement`, `documentation`, `operational`, `critical`, `high` as appropriate.
- **Title:** Use the **[Bug]** / **[Enhancement]** / **[Operational]** prefix; include short descriptor.
- **Body:** Copy the relevant section (description, impact, fix).
- The **quick reference** table can be linked from README or RUNBOOK as “Common issues / Troubleshooting”.
