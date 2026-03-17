# Security Audit — win-mdm-security-hardening-kit

This file drives the Ralph Loop security improvement cycle.
Each iteration reads this file and `progress.md`, picks the next
open item, implements the fix, and updates `progress.md`.

## How to Use This Checklist

- Items are ordered by priority (Critical → High → Medium → Low).
- Work one item per iteration. Mark it complete in `progress.md`.
- Output `<promise>COMPLETE</promise>` only when ALL items below are ✅.

---

## Items

### [HIGH] S1 — WQL injection in 02-LAPS-Hygiene.ps1
**File:** `scripts/02-LAPS-Hygiene.ps1` line 432
**Problem:** `$Name` (from LAPS registry policy `AdministratorAccountName`) is
interpolated directly into a WMI/CIM filter string without escaping single quotes:
```powershell
Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND Name='$Name'"
```
A crafted value like `x' OR '1'='1` would alter the filter semantics.
**Fix:** Escape single quotes before interpolation:
```powershell
$escapedName = $Name -replace "'", "''"
... -Filter "LocalAccount=True AND Name='$escapedName'"
```
**Status:** ✅ Fixed (iteration 1)

---

### [HIGH] S2 — WQL injection in 11-IOC-Sweep-Defender.ps1
**File:** `scripts/11-IOC-Sweep-Defender.ps1` line 597
**Problem:** `$name` (from external IOC JSON catalog) is interpolated into a
CIM filter without escaping:
```powershell
Get-CimInstance -ClassName Win32_Service -Filter ("Name='{0}'" -f $name)
```
A crafted IOC entry containing a single quote would corrupt the WQL filter.
**Fix:** Escape before use:
```powershell
$escapedSvcName = $name -replace "'", "''"
... -Filter ("Name='{0}'" -f $escapedSvcName)
```
**Status:** ✅ Fixed (iteration 1)

---

### [HIGH] S3 — PowerShell code injection via heredoc in 21-EmergencyKillSwitch.ps1
**File:** `scripts/21-EmergencyKillSwitch.ps1` lines 342–370 (`Schedule-AutoRollback`)
**Problem:** `$TaskName` and `$RuleNames` values from JSON config are embedded into
a PowerShell heredoc that is later base64-encoded and run as a scheduled task:
- Line 357: `Get-NetFirewallRule -Name '$($RuleNames -join "','")'` — any `'` in
  a rule name breaks the quoted string and allows code injection.
- Line 362: `` `$delOutput = schtasks.exe /Delete /TN '$TaskName' `` — a `'` in
  `$TaskName` breaks the single-quoted argument.
**Fix:** Validate `$TaskName` and all `$RuleNames` entries at the top of
`Schedule-AutoRollback` before the heredoc is constructed. Reject any value
containing characters outside `[a-zA-Z0-9\-_\\]` for `$TaskName`, and reject
any rule name containing a single quote.
**Status:** ✅ Fixed (iteration 1)

---

### [MEDIUM] S4 — Unquoted $TaskName in schtasks.exe call
**File:** `scripts/21-EmergencyKillSwitch.ps1` line 377
**Problem:** `schtasks.exe /Create /TN $TaskName ...` passes `$TaskName` as a
bare token. In PowerShell, native-command argument passing is safe from
space-splitting, but quoting makes intent explicit and avoids future regressions.
**Fix:** Use array-based invocation:
```powershell
$schtasksArgs = @('/Create', '/TN', $TaskName, '/SC', 'ONCE',
                  '/ST', $runAt.ToString('HH:mm'), '/TR', $tr, '/RL', 'HIGHEST', '/F')
$output = schtasks.exe @schtasksArgs 2>&1
```
**Status:** ✅ Fixed (iteration 1, fixed together with S3)

---

### [LOW] S5 — wevtutil query embedding in lib/External.psm1
**File:** `lib/External.psm1` line 324
**Problem:** `$Query` parameter is embedded in a wevtutil `/q:` argument:
```powershell
$wevtArgs += "/q:`"$Query`""
```
No callers exist in the codebase today (dead export), but if called with a
crafted query string, the double-quoted argument could be broken.
**Fix:** Deferred — function is unused in all scripts. Add a note.
**Status:** ⬜ Deferred — `Export-EventLog` has no callers in any script;
WQL-style filter injection via wevtutil has no privilege-escalation path.
No change needed until the function is actually used.

---

## Completion Criteria

Output `<promise>COMPLETE</promise>` when S1, S2, S3, S4 are ✅
(S5 is intentionally deferred with a note above).
