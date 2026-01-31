# Shared helper modules

This folder contains small PowerShell modules used by multiple scripts to avoid copy/paste helpers.

## Modules
- `Common.psm1`: Admin check and path/config helpers.
- `Output.psm1`: Console output helpers (Write-UiLine / Write-Info / Write-Warn / Write-Success / Write-Section / Write-KeyValue, plus compatibility wrappers).
- `Registry.psm1`: Registry helpers (Ensure-RegistryKey, Get-RegValue, Set-RegDword, Remove-RegValueIfExists).
- `EventLog.psm1`: Event log helpers (Ensure-EventSource, Write-HealthEvent).
- `Results.psm1`: Findings helpers (list creation and Add-Finding).

## API reference (summary)
### Common.psm1
- `Test-IsAdmin()`: Returns `$true` when running elevated.
- `Test-IsAdministrator()`: Alias of `Test-IsAdmin`.
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
- `Set-RegDword -Path <key> -Name <value> -Value <int>`: Writes a DWORD value.
- `Remove-RegValueIfExists -Path <key> -Name <value>`: Removes a value if present.

### Config.psm1
- `Read-ConfigWithDefaults -Path <file> -Defaults <hashtable> [switches]`: Loads JSON config, merges with defaults, returns `Config` + `Meta`.
- `ConvertTo-Hashtable -Object <psobject>`: Converts a PSCustomObject to hashtable.

### EventLog.psm1
- `Ensure-EventSource -Source <source> -LogName <log>`: Ensures event source exists.
- `Write-HealthEvent -Id <int> -Message <text> [-Level]`: Writes an event log entry.

### Results.psm1
- `New-FindingsList()`: Creates a list for findings objects.
- `New-FindingObject -Code <id> -Severity <level> -Message <text> [-TypeName] [-Extra]`: Creates a finding object.
- `Add-Finding -Code <id> -Severity <level> -Message <text> [-FindingList] [-ProfileName] [-TypeName] [-Extra]`: Adds a finding (uses `$Findings` or `$script:Findings` if list omitted).
- Optional caller flags: set `$FindingsTimeUtc = $true` or `$FindingsTimestampLocal = $true` to auto-include timestamps.

## Usage pattern
Place imports after `#requires` and the comment-based help block:

```powershell
. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Common.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Registry.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Config.psm1') -Force
Import-Module (Join-Path $script:LibPath 'EventLog.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Results.psm1') -Force
```

Import only what the script needs.
