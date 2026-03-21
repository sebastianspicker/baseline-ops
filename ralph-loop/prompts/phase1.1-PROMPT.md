# Phase 1.1 — Static Analysis Deep Dive

You are analyzing the win-mdm-security-hardening-kit repository for static analysis issues.

## Task

1. Read `PSScriptAnalyzerSettings.psd1` to understand current exclusions.
2. For every `.ps1` file in `scripts/` and `tools/`, and every `.psm1` in `lib/`:
   - Parse the file AST using `[System.Management.Automation.Language.Parser]::ParseFile()`.
   - Record any parse errors (there should be zero; if not, flag them as Critical).
   - Identify patterns that would trigger PSScriptAnalyzer warnings even with current exclusions.
3. Look for these specific anti-patterns across all scripts:
   - Uninitialized variables used before assignment.
   - `$null` on the right side of comparisons (should be left side for arrays).
   - Missing `[CmdletBinding()]` on exported functions.
   - Functions that use `Write-Host` directly instead of `lib/Output.psm1` helpers.
   - Inconsistent error handling patterns (some scripts use `try/catch`, some use `$ErrorActionPreference`).
   - Dead code: functions defined but never called within the same file.
   - Hardcoded paths (e.g., `C:\install\mdm\ps1`, `C:\Windows`) that should use variables.
4. Create `ralph-loop/phase1/1.1-static-analysis-findings.md` with:
   - A table of all findings, severity, file, line, description.
   - Group by severity (Critical > High > Medium > Low > Info).
   - Exclude anything already fixed in iterations 1-5 (check `progress.md`).
5. Do NOT modify any source files. This is analysis only.
6. Commit the findings document.

## Verification
- `ralph-loop/phase1/1.1-static-analysis-findings.md` exists and has structured content.
- No source files were modified (`git diff --name-only` shows only new files in `ralph-loop/`).

## Exit Condition
Output `<promise>STATIC_ANALYSIS_COMPLETE</promise>` when the findings document is complete and committed.
