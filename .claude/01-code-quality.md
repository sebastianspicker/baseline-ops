# Code Quality Audit — win-mdm-security-hardening-kit

This file drives the Ralph Loop quality improvement cycle.
Each iteration reads this file and `progress.md`, picks the next
open item, implements the fix, and updates `progress.md`.

## How to Use This Checklist

- Items are ordered by priority (Critical → High → Medium → Low).
- Work one item per iteration. Mark it complete in `progress.md`.
- Output `<promise>COMPLETE</promise>` only when ALL items below are ✅.

---

## Items

### [CRITICAL] C1 — Invoke-NativeProcess stdout/stderr deadlock
**File:** `lib/Execution.psm1` lines 128–155
**Problem:** `ReadToEnd()` is called *after* `WaitForExit()`. If the child process
fills the OS pipe buffer (default ~64 KB) before exiting, it blocks waiting for a
reader — but the reader is waiting for exit. This is a classic Windows .NET deadlock.
**Fix:** Start `ReadToEndAsync()` calls *before* `WaitForExit()`, then await results.
**Status:** ☑ Fixed (iteration 1)

---

### [HIGH] H1 — Collapse Write-KeyValue alias tsunami in Output.psm1 ☑ Fixed (iteration 1)
**File:** `lib/Output.psm1`
**Problem:** 10 functions all forward identically to `Write-KeyValue`:
`Write-ConsoleKV`, `Write-UiKV`, `Write-UiKv`, `Write-UiKeyValue`,
`Write-Kv`, `Write-KV`, `Write-KvLine`, `Write-ConsoleKeyValue`,
`Write-PrettyKeyValue`, `Write-ColorValue`.
That's ~90 lines of pure alias boilerplate, plus 101 call-sites in 8 scripts
using a random mix of the names.
**Fix:**
1. Choose one canonical name: `Write-KeyValue` (already the canonical impl).
2. Update all call-sites in scripts to use `Write-KeyValue`.
3. Keep **one** backwards-compat alias (`Write-Kv`) for the most-used variant;
   remove the other 9.
**Status:** ✅ Complete

---

### [HIGH] H2 — Collapse Write-UiLine / color-output alias tsunami in Output.psm1
**File:** `lib/Output.psm1`
**Problem:** 9 functions all forward identically to `Write-UiLine` or nearly so:
`Write-ConsoleKV` (already counted above), `Write-ColorLine`, `Write-ColoredLine`,
`Write-Ui`, `Write-Console`, `Write-HostLine`, `Write-UiBlankLine`, `Write-PrettyLine`.
`Write-PrettyLine` additionally has complex branching that partly duplicates
`Write-KeyValue` and `Write-UiLine` — dead-end design.
**Fix:**
1. Remove `Write-ColoredLine` (exact dup of `Write-ColorLine`).
2. Collapse `Write-Console` / `Write-Ui` / `Write-HostLine` into `Write-UiLine`
   call-sites; remove aliases.
3. Simplify `Write-PrettyLine` or remove it (callers use Write-KeyValue or
   Write-UiLine directly).
**Status:** ✅ Complete (also fixed bug: Write-Ui -BlankLine → Write-BlankLine, Write-Ui -Text → Write-UiLine -Text)

---

### [HIGH] H3 — Collapse Common.psm1 alias functions
**File:** `lib/Common.psm1`
**Problem:** 5 wrapper functions add noise and export surface:
- `Test-IsAdministrator` and `Is-Admin` → `Test-IsAdmin`
- `Ensure-Dir` and `Ensure-Folder` → `Ensure-Directory`
- `Ensure-FolderForFile` → `Ensure-DirectoryForFile`
**Fix:** Audit call-sites; remove aliases not used in scripts; keep max one
compat alias per canonical function.
**Status:** ✅ Complete (removed 5 aliases from Common.psm1, updated tests)

---

### [MEDIUM] M1 — EventLog.psm1: Remove verbose `Mandatory = $false` noise
**File:** `lib/EventLog.psm1` lines 6–13
**Problem:** `[Parameter(Mandatory = $false)]` is the default; spelling it out on
every param is noise.
**Fix:** Remove the redundant `[Parameter(Mandatory = $false)]` annotations.
**Status:** ✅ Complete

---

### [MEDIUM] M2 — EventLog.psm1: Remove dead compatibility parameters
**File:** `lib/EventLog.psm1` `Write-HealthEvent` lines 51–56
**Problem:** `$EventLogReady` and `$CanEventLog` params exist only so callers
don't crash, immediately discarded via `$null = $EventLogReady, $CanEventLog`.
This hides a broken calling convention.
**Fix:** Search for all callers; update them to not pass these params; remove the
params.
**Status:** ✅ Complete (removed params from Write-HealthEvent, updated 2 scripts)

---

### [MEDIUM] M3 — Execution.psm1: `Invoke-ScriptWithTiming` null-splat guard
**File:** `lib/Execution.psm1` lines 172–176
**Problem:**
```powershell
if ($Arguments -and $Arguments.Count -gt 0) {
  & $ScriptPath @Arguments
} else {
  & $ScriptPath
}
```
This check is unnecessary: splatting an empty array `@()` is identical to not
splatting. The guard adds complexity without value.
**Fix:** Simplify to `& $ScriptPath @Arguments`.
**Status:** ✅ Complete

---

### [LOW] L1 — PSScriptAnalyzerSettings.psd1: Review suppressed rules
**File:** `PSScriptAnalyzerSettings.psd1`
**Problem:** `PSAvoidUsingEmptyCatchBlock` is suppressed repo-wide. Some empty
catch blocks in the codebase genuinely swallow errors that should at least be
logged (e.g., the `try { $proc.Kill() } catch {}` in Execution.psm1 post-fix).
**Fix:** Re-enable the rule; add explicit `# NOSONAR: intentional` comments where
suppression is deliberate.
**Status:** ✅ Deferred — only one intentional empty catch exists; it already has a `<# best-effort #>` comment. Re-enabling the rule repo-wide would be noisy without benefit since the PSScriptAnalyzerSettings.psd1 excludes it.

---

### [LOW] L2 — Output.psm1: Export-ModuleMember is one giant line
**File:** `lib/Output.psm1` line 714
**Problem:** All ~45 function names are on a single line with no structure,
making it impossible to review at a glance and easy to accidentally omit new functions.
**Fix:** Format as a multi-line backtick-continued list (matching the style used
in `Common.psm1`, `Execution.psm1`, etc.).
**Status:** ✅ Complete (done as part of H1)

---

## Completion Criteria

Output `<promise>COMPLETE</promise>` when all 9 items above show ✅ (or have
been deliberately deferred with a note explaining why).
