# Shared helper modules

This folder contains small PowerShell modules used by multiple scripts to avoid copy/paste helpers.

## Modules
- `Common.psm1`: Caller lookup, admin check, path/config helpers (`Get-CallerValue`, `Require-Admin`, `Test-IsAdmin`, `Ensure-Directory`, `Read-JsonConfig`).
- `Output.psm1`: Console output helpers (Write-UiLine / Write-Info / Write-Warn / Write-Success / Write-Section / Write-KeyValue, plus compatibility wrappers).
- `Console.psm1`: **NEW** Consolidated console functions for severity-based coloring and summary output (`Get-SeverityColor`, `Get-SeverityRank`, `Write-ConsoleSummary`, `Write-FindingLine`).
- `External.psm1`: **NEW** Safe wrappers for external commands with exit code validation (`Invoke-Schtasks`, `Invoke-Auditpol`, `Invoke-Wevtutil`, `Invoke-Git`).
- `Registry.psm1`: Registry helpers (Ensure-RegistryKey, Get-RegValue, Set-RegDword, Set-RegString, Set-RegQword, Set-RegExpandString, Set-RegMultiString, Set-RegBinary, and more).
- `EventLog.psm1`: Event log helpers (Ensure-EventSource, Write-HealthEvent).
- `Results.psm1`: Findings helpers (list creation and Add-Finding).

## API reference (summary)
### Common.psm1
- `Get-CallerValue -Name <var>`: Looks up a variable in caller scope (scopes 1–3); used by EventLog/Results. Import Common before EventLog/Results.
- `Test-IsAdmin()`: Returns `$true` when running elevated.
- `Test-IsAdministrator()`: Alias of `Test-IsAdmin`.
- `Require-Admin [-Message <text>]`: Throws if not elevated; use instead of inline `if (-not (Test-IsAdmin)) { throw ... }`.
- `Ensure-Directory -Path <dir>`: Creates directory if missing.
- `Ensure-DirectoryForFile -FilePath <file>`: Creates parent directory if missing.
- `Ensure-Dir -Path <dir>`: Alias of `Ensure-Directory`.
- `Read-JsonConfig -Path <file>`: Returns deserialized JSON or `$null` on error.

### Output.psm1
- `Write-UiLine -Message <text> [-Style <style>]`: Host/information stream line with optional color/style.
- `Write-Info / Write-Warn / Write-Success`: Standard prefixed status lines with unified colors.
- `Write-Section -Title <text> [-Width <n>]`: Section separator title.
- `Write-KeyValue -Key <k> -Value <v> [-KeyWidth <n>] [-ValueStyle <style>]`: Key/value console line.
- Compatibility wrappers: `Write-UiHeader`, `Write-UiKV`, `Write-PrettyLine`, `Write-ConsoleInfo`, etc.

### Registry.psm1
- `Ensure-RegistryKey -Path <key>`: Creates registry key if missing.
- `Get-RegValue -Path <key> -Name <value>`: Reads a registry value or `$null`.
- `Get-RegValueSafe -Path <key> -Name <value>`: Alias for `Get-RegValue`.
- `Get-RegDword -Path <key> -Name <value> [-DefaultValue <int>]`: Reads a DWORD value with optional default.
- `Get-RegString -Path <key> -Name <value> [-DefaultValue <string>]`: Reads a string value with optional default.
- `Get-RegKeyExists -Path <key>`: Returns `$true` if registry key exists.
- `Get-RegValueExists -Path <key> -Name <value>`: Returns `$true` if registry value exists.
- `Set-RegDword -Path <key> -Name <value> -Value <int>`: Writes a DWORD value; returns `$true` on success.
- `Set-RegString -Path <key> -Name <value> -Value <string>`: Writes a string value; returns `$true` on success.
- `Set-RegQword -Path <key> -Name <value> -Value <int64>`: Writes a QWORD value; returns `$true` on success.
- `Set-RegExpandString -Path <key> -Name <value> -Value <string>`: Writes an expandable string value.
- `Set-RegMultiString -Path <key> -Name <value> -Value <string[]>`: Writes a multi-string value.
- `Set-RegBinary -Path <key> -Name <value> -Value <byte[]>`: Writes a binary value.
- `Remove-RegValueIfExists -Path <key> -Name <value>`: Removes a value if present.
- `Remove-RegistryKeyIfExists -Path <key> [-Recurse]`: Removes a key if present.

### Console.psm1
- `Get-SeverityColor -Severity <level>`: Returns console color for severity level (Critical/High/Medium/Low/Info/Warning/Error/OK/Pass/Fail/Skip).
- `Get-StatusColor -Status <status>`: Returns console color for status string (normalizes various status names).
- `Get-ColorForLevel -Level <level>`: Alias for `Get-SeverityColor` with standard severity levels.
- `Get-ConsoleColor -Kind <kind>`: Returns color for OK/WARN/ERR/INFO/DIM/CRIT/HIGH/MED/LOW kinds.
- `Get-SeverityRank -Severity <level>`: Returns numeric rank for severity (for sorting).
- `Get-SeverityPrefix -Severity <level>`: Returns prefix string like `[HIGH] ` for severity.
- `Write-ColoredLine -Text <text> -Color <color>`: Writes a colored line to console.
- `Write-PrettyLine -Text <text> -Color <color>`: Alias for `Write-ColoredLine`.
- `Write-Rule [-Title <text>] [-Char <char>] [-Width <n>]`: Writes a separator rule.
- `Write-SectionHeader -Title <text> [-Width <n>]`: Writes a section header with rules.
- `Write-SummaryHeader -Title <text> -ComputerName <name> -Timestamp <time> -FindingsCount <n>`: Writes a summary header.
- `Write-FindingLine -Severity <level> -Code <code> [-Message <text>]`: Writes a finding line with color.
- `Write-ConsoleSummary -Summary <object> -Findings <list> [-Title <text>]`: Writes a full summary output.
- `Write-PrettySummary -Result <object> [-Title <text>]`: Writes a simplified summary.
- `Get-FindingStats -Findings <list>`: Returns statistics about findings by severity.

### External.psm1
- `Test-CommandExists -Name <command>`: Returns `$true` if command exists.
- `Invoke-NativeCommand -Command <name> -Arguments <string[]> [-ThrowOnError] [-CaptureOutput]`: Generic native command wrapper with exit code validation.
- `Invoke-Schtasks -Arguments <string[]> [-ThrowOnError] [-CaptureOutput]`: Wrapper for `schtasks.exe`.
- `Invoke-Auditpol -Arguments <string[]> [-ThrowOnError] [-CaptureOutput]`: Wrapper for `auditpol.exe`.
- `Invoke-Wevtutil -Arguments <string[]> [-ThrowOnError] [-CaptureOutput]`: Wrapper for `wevtutil.exe`.
- `Invoke-Wecutil -Arguments <string[]> [-ThrowOnError] [-CaptureOutput]`: Wrapper for `wecutil.exe`.
- `Invoke-RegExe -Arguments <string[]> [-ThrowOnError] [-CaptureOutput]`: Wrapper for `reg.exe`.
- `Invoke-Git -Arguments <string[]> [-WorkingDirectory <path>] [-ThrowOnError] [-CaptureOutput]`: Wrapper for `git`.
- `Get-AuditPolSubcategories`: Returns output of `auditpol /get /category:*`.
- `Get-EventLogInfo -LogName <name>`: Returns info about an event log.
- `Enable-EventLog -LogName <name>`: Enables an event log.
- `Set-EventLogMaxSize -LogName <name> -MaxSizeBytes <int64>`: Sets event log max size.
- `Export-EventLog -LogName <name> -OutputPath <path> [-Query <xpath>]`: Exports event log to file.
- `New-ScheduledTask -TaskName <name> -TaskRun <command> [-Schedule <type>] [-StartTime <time>] [-RunLevel <level>] [-Force]`: Creates a scheduled task.
- `Remove-ScheduledTask -TaskName <name>`: Removes a scheduled task.
- `Export-RegistryKey -KeyPath <key> -OutputPath <file>`: Exports registry key to file.

### Config.psm1
- `Read-ConfigWithDefaults -Path <file> -Defaults <hashtable> [switches]`: Loads JSON config, merges with defaults, returns `Config` + `Meta`.
- `ConvertTo-Hashtable -Object <psobject>`: Converts a PSCustomObject to hashtable.

### EventLog.psm1
- `Ensure-EventSource [-Source <source>] [-SourceName <source>] [-LogName <log>]`: Ensures event source exists. `-LogName` defaults to `Application` if omitted; source can come from caller scope (`EventSource`/`EventSourceName`, `EventLogName`/`EventLog`).
- `Write-HealthEvent -Id <int> -Message <text> [-Level] [-EventLogReady] [-CanEventLog]`: Writes an event log entry. Optional `-EventLogReady`/`-CanEventLog` are accepted for compatibility and ignored.

### Results.psm1
- `New-FindingsList()`: Creates a list for findings objects.
- `New-FindingObject -Code <id> -Severity <level> -Message <text> [-TypeName] [-Extra]`: Creates a finding object.
- `Add-Finding -Code <id> -Severity <level> -Message <text> [-FindingList] [-ProfileName] [-TypeName] [-Extra]`: Adds a finding (uses `$Findings` or `$script:Findings` if list omitted).
- Optional caller flags: set `$FindingsTimeUtc = $true` or `$FindingsTimestampLocal = $true` to auto-include timestamps.

## Usage pattern
Place imports after `#requires` and the comment-based help block. **Recommended order:** Output → Common → Console → Registry → Config → External → EventLog → Results (Common must load before EventLog/Results so `Get-CallerValue` is available).

```powershell
. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Common.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Console.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Registry.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Config.psm1') -Force
Import-Module (Join-Path $script:LibPath 'External.psm1') -Force
Import-Module (Join-Path $script:LibPath 'EventLog.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Results.psm1') -Force
```

Import only what the script needs.

## Coding standards (recommended)
- `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` at script start.
- Use `Require-Admin` from Common for scripts that need elevation instead of inline `if (-not (Test-IsAdmin)) { throw ... }`.
- Prefer `Write-KeyValue` or `Write-UiKV` for key/value output; other wrappers are compatibility aliases.
- Use `Get-SeverityColor` from Console.psm1 instead of inline color switch statements.
- Use `Invoke-*` wrappers from External.psm1 for native commands to ensure exit code validation.
