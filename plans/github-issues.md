# GitHub Issues - Generated from BUGS_AND_FIXES.md
# This file contains GitHub issue templates for all documented bugs
# Each issue can be created using: gh issue create --title "..." --body "..." --label "..."

## Issue Creation Commands

### Critical Issues

# Issue 1: Audit-only modifies firewall (RDP rules disabled)
gh issue create --title "[Bug] Audit-only run still modifies firewall (RDP rules disabled)" --body "## Description
In \`scripts/14-SecureRemoteAccessGuardrails.ps1\`, \`Disable-LocalBuiltinRdpInbound\` is invoked unconditionally inside \`Ensure-RdpFirewallRules\`, regardless of \`-Remediate\`. The script claims \"Running without -Remediate performs an audit only (no changes).\"

## Impact
Running audit-only on endpoints can silently disable built-in \"Remote Desktop\" inbound firewall rules and cut off remote access. Violates the audit-only contract.

## Fix
Only call \`Disable-LocalBuiltinRdpInbound\` when \`$Remediate\` is true and when the catalog specifies RDP disabled; otherwise perform read-only checks only.

## Status
✅ Fixed in Phase 1" --label "bug,critical"

# Issue 2: Audit-only mode can still modify registry
gh issue create --title "[Bug] Audit-only mode can still modify registry (e.g. WUFB, Defender)" --body "## Description
Several scripts create missing registry keys or apply \"minimum\" baselines even when run in audit-only or proof-only mode. Examples: \`06-UpdateHealth-SSU-Proof.ps1\` (creates missing keys); \`01-ASR-Defender-Allowlist.ps1\` (minimum baseline + remediation can remove CFA allowlists when JSON is missing/invalid).

## Impact
Operators expect audit-only to be read-only. Silent registry changes undermine trust and can cause unintended fleet state.

## Fix
Gate all registry/key creation and remediation behind an explicit \`-Remediate\` (or equivalent) and do not create keys or change values in audit-only paths.

## Status
✅ Fixed in Phase 1" --label "bug,critical"

# Issue 3: Pipeline output commented out
gh issue create --title "[Bug] Pipeline output is commented out (structured object never emitted)" --body "## Description
In \`scripts/38-SecurityOptions-Drift.ps1\`, the script documents \"Pipeline output: exactly one structured object\" but the object emission is commented out. Automation that does \`$r = .\\38-SecurityOptions-Drift.ps1; $r.Summary\` receives \`$null\`.

## Impact
Major advertised functionality (Export-Csv, ConvertTo-Json, filtering) is non-functional; audits/remediation pipelines silently get no data.

## Fix
Uncomment and emit the documented pipeline object after \`Write-ConsoleSummary\` (or document that pipeline output is not yet implemented)." --label "bug,high"

# Issue 4: Findings list not usable
gh issue create --title "[Bug] Findings list is not usable (empty list → \$null; first Add-Finding throws)" --body "## Description
\`New-FindingsList\` returns a \`List[object]\`; PowerShell enumerates it on the pipeline so the caller receives \`$null\`. \`Add-Finding\` treats empty collections as \"missing\" and throws when no list is found, so the first finding addition fails.

## Impact
Scripts cannot reliably build or export findings; they either report FindingsCount=0 with Findings=\$null, or crash when reporting the first finding.

## Fix
In \`lib/Results.psm1\`: (1) Ensure \`New-FindingsList\` is not enumerated (e.g. \`return , (New-Object System.Collections.Generic.List[object])\` or assign via variable and return that variable). (2) In \`Add-Finding\`, treat empty list as valid (e.g. check for \`$null\` only, or allow empty list and create one if caller provided \`$null\` and lookup fails).

## Status
✅ Already fixed - Line 7 uses comma operator" --label "bug,critical"

# Issue 5: Set-RegDword return value
gh issue create --title "[Bug] Set-RegDword return value is \$null; scripts treat it as boolean" --body "## Description
\`lib/Registry.psm1\`'s \`Set-RegDword\` pipes output to \`Out-Null\` and does not return \`$true\`/\`$false\`. Multiple scripts use \`if (Set-RegDword ...) { ... } else { ... }\`, so the else branch always runs and remediation is reported as \"failed\" even when it succeeded.

## Impact
False \"Failed to set …\" drift entries, incorrect event IDs, and automation repeatedly attempting \"failed\" remediations. Machine state and reported state diverge.

## Fix
Either make \`Set-RegDword\` return a boolean (e.g. wrap in try/catch and return $true/$false), or change all call sites to not depend on return value and verify by reading back the value.

## Status
✅ Already fixed - Returns boolean properly" --label "bug,critical"

# Issue 11: Path traversal in Run-Local
gh issue create --title "[Bug] Run-Local: -ScriptName allows path traversal and can execute arbitrary local files" --body "## Description
\`scripts/00-Run-Local.ps1\` builds \`$scriptPath\` with \`Join-Path $scriptsRoot $ScriptName\` without constraining \`ScriptName\` to a basename or blocking \`..\\\`. After normalization, a path outside \`scripts\` can be executed.

## Impact
Arbitrary code execution from outside the scripts directory.

## Fix
Resolve path under \`$scriptsRoot\`; ensure the resolved path starts with \`$scriptsRoot\` and is a single file with extension \`.ps1\`. Reject traversal and directories.

## Status
✅ Already fixed - Lines 72-92 validate ScriptName" --label "bug,critical,security"

# Issue 12: Write-HealthEvent parameter mismatch
gh issue create --title "[Bug] Write-HealthEvent called with non-existent parameters (runtime failure)" --body "## Description
Scripts pass \`-EventLogReady\` or \`-CanEventLog\` to \`Write-HealthEvent\`, which does not define these parameters. Parameter-binding error stops execution.

## Fix
Add optional parameters to \`Write-HealthEvent\` or remove them from all call sites.

## Status
✅ Already fixed - Parameters added in lib/EventLog.psm1" --label "bug,critical"

# Issue 13: Ensure-EventSource parameter mismatch
gh issue create --title "[Bug] Ensure-EventSource parameter mismatch (-SourceName, missing -LogName)" --body "## Description
Call sites use \`-SourceName\` or omit mandatory \`-LogName\`. Parameter-binding fails and can halt the script before any event logging.

## Fix
Align \`Ensure-EventSource\` signature with usage (e.g. add \`-SourceName\` alias, or make \`-LogName\` optional with default) and fix call sites that omit required params.

## Status
✅ Already fixed - Parameters added in lib/EventLog.psm1" --label "bug,critical"

---

### High Priority Issues

# Issue 6: EventLog.psm1 parameter contract
gh issue create --title "[Enhancement] EventLog.psm1 parameter contract: align call sites with function signature" --body "## Description
\`Write-HealthEvent\` does not define \`-EventLogReady\` or \`-CanEventLog\`; scripts pass these and hit parameter-binding errors. \`Ensure-EventSource\` requires \`-Source\` and \`-LogName\` and does not support \`-SourceName\`; at least one script uses \`-SourceName\` and others omit \`-LogName\`.

## Fix
Extend \`Write-HealthEvent\` to accept optional \`-EventLogReady\`/\`-CanEventLog\` (or remove from call sites). Extend \`Ensure-EventSource\` to accept \`-SourceName\` as alias for \`-Source\` and make \`-LogName\` optional with a safe default, or fix all call sites to pass \`-Source\` and \`-LogName\`.

## Status
✅ Fixed in Phase 1" --label "enhancement,high"

# Issue 7: Validate external command exit codes
gh issue create --title "[Enhancement] Validate external command exit codes (schtasks, auditpol, reg, wevtutil, wecutil)" --body "## Description
Many scripts call \`schtasks.exe\`, \`auditpol.exe\`, \`reg.exe\`, \`wevtutil\`, \`wecutil\` inside try/catch or without checking \`$LASTEXITCODE\`. External command failures do not throw PowerShell exceptions by default, so success is assumed incorrectly.

## Fix
After each external invocation, check \`$LASTEXITCODE\` and treat non-zero as failure (throw or return error). Do not rely on try/catch alone for external executables.

## Status
✅ lib/External.psm1 created with exit code validation wrappers" --label "enhancement,high"

# Issue 8: Avoid SilentlyContinue for remediation
gh issue create --title "[Enhancement] Avoid SilentlyContinue for remediation and evidence collection" --body "## Description
Remediation and evidence paths use \`-ErrorAction SilentlyContinue\` so failures are not thrown; scripts then record \"success\" or continue as if the operation succeeded. Applies to service/task disable, firewall rule removal, registry cleanup, and various exports.

## Fix
Use \`-ErrorAction Stop\` for remediation and critical collection paths, and handle errors in try/catch with explicit logging/findings. Reserve SilentlyContinue only for optional or best-effort steps and document that.

## Status
✅ Fixed in key remediation scripts (11, 14, 21)" --label "enhancement,high"

# Issue 21: Kill switch schtasks validation
gh issue create --title "[Bug] Kill switch: schtasks/success not validated; rollback payload uses SilentlyContinue" --body "## Description
\`Schedule-AutoRollback\` uses try/catch around \`schtasks.exe /Create\`, but non-zero exit code does not throw; success can be reported incorrectly. The generated rollback script sets \`$ErrorActionPreference='SilentlyContinue'\`, so rollback failures are invisible.

## Fix
Check \`$LASTEXITCODE\` after schtasks; only set RollbackScheduled when exit code is 0. In rollback payload, avoid global SilentlyContinue or log failures to a known path." --label "bug,high"

# Issue 23: Copy-Local option injection
gh issue create --title "[Bug] Copy-Local: RepoUrl/RepoPath/RepoRef passed to git without validation (option injection)" --body "## Description
Values are passed to \`git clone\`/checkout; leading \`-\` or option-like strings can change git behaviour.

## Fix
Validate and reject or sanitize RepoUrl, RepoPath, RepoRef (e.g. disallow leading \`-\`, constrain format)." --label "bug,high,security"

# Issue 24: Supply-chain drift
gh issue create --title "[Bug] Copy-Local: Existing .git causes RepoUrl to be ignored (supply-chain drift)" --body "## Description
If \`$RepoPath\\.git\` exists, script does fetch/pull/checkout without verifying remote matches \`-RepoUrl\`. Content can come from a different repo.

## Fix
When .git exists, verify configured remote URL matches intended RepoUrl (or document and require clean path for trusted clone)." --label "bug,high,security"

---

### Medium Priority Issues

# Issue 9: Document audit-only vs remediate
gh issue create --title "[Operational] Document \"audit-only\" vs \"remediate\" and recovery for stuck state" --body "## Description
Scripts that can change system state (firewall, registry, services) should document clearly when they are read-only vs when they modify. Recovery steps for interrupted runs (e.g. stuck \"processing\" or half-applied config) are not centralized.

## Fix
Add a short \"Audit vs Remediate\" and \"Recovery\" subsection in README; reference script-specific behaviour and link to FAQ/operations where applicable.

## Status
✅ scripts/README.md created with comprehensive documentation" --label "documentation,medium"

# Issue 10: Deployment helper validation
gh issue create --title "[Enhancement] Deployment helper: validate RepoUrl, RepoPath, RepoRef, DestinationRoot and constrain ScriptName" --body "## Description
\`00-Copy-Local.ps1\` passes RepoUrl/RepoPath/RepoRef to git without validation (option injection risk); DestinationRoot is not validated (risky paths). \`00-Run-Local.ps1\` does not constrain \`-ScriptName\` to a basename (path traversal → arbitrary execution).

## Fix
Validate RepoUrl/RepoPath/RepoRef (e.g. reject leading \`-\`, constrain format). Validate DestinationRoot (e.g. block system roots, require subdirectory). For Run-Local: resolve script path under RootPath\\scripts, then ensure resolved path is under that directory and is a .ps1 file (reject traversal and non-scripts).

## Status
✅ Run-Local path traversal fixed" --label "enhancement,medium,security"

---

## Summary

| Priority | Count | Status |
|----------|-------|--------|
| Critical | 8 | 6 Fixed, 2 Open |
| High | 6 | 3 Fixed, 3 Open |
| Medium | 2 | 2 Fixed |
| **Total** | **16** | **11 Fixed, 5 Open** |

## Remaining Open Issues

1. **Issue 3**: Pipeline output commented out in 38-SecurityOptions-Drift.ps1
2. **Issue 21**: Kill switch schtasks validation
3. **Issue 23**: Copy-Local option injection
4. **Issue 24**: Supply-chain drift
5. **Issue 25**: Run-Local integrity/signature check

## Notes

- Many issues were already fixed before this audit
- lib/External.psm1 provides wrappers for external commands with exit code validation
- scripts/README.md provides comprehensive documentation for all scripts
- All 47 scripts have complete comment-based help
