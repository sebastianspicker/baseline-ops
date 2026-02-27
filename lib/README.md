# Shared modules (`lib/`)

Shared PowerShell modules used to remove script-level duplication and standardize behavior.

## Module index

- `Common.psm1`
  - caller-scope lookup, admin checks, safe directory/path helpers
  - includes aliases for legacy names (`Is-Admin`, `Ensure-Folder`)
- `Output.psm1`
  - unified console output helpers
- `Console.psm1`
  - severity colors, summary rendering, finding statistics
- `Registry.psm1`
  - registry read/write wrappers
- `Config.psm1`
  - config loading/merge helpers
- `External.psm1`
  - validated native command wrappers
- `EventLog.psm1`
  - event source and health event helpers
- `Results.psm1`
  - finding object/list helpers
- `JsonCatalog.psm1`
  - safe JSON read/write helpers
- `Evidence.psm1`
  - evidence copy/hash helpers
- `Validation.psm1` (v2)
  - path traversal checks, script-name validation, URL/ref validation
- `Execution.psm1` (v2)
  - retry helpers, process execution, timed script execution
- `Serialization.psm1` (v2)
  - JSON/CSV writers and standardized v2 result objects

## Recommended import pattern

```powershell
. (Join-Path $PSScriptRoot '_lib/Bootstrap.ps1')
Import-Module (Join-Path $script:LibPath 'Output.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Common.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Console.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Validation.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Execution.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Serialization.psm1') -Force
Import-Module (Join-Path $script:LibPath 'Results.psm1') -Force
```

Import only what the target script needs.

## v2 result contract helper

Use `New-V2ResultObject` from `Serialization.psm1` for orchestration-compatible output:

- `SchemaVersion`
- `ScriptName`
- `Mode`
- `ComputerName`
- `TimestampUtc`
- `Result`
- `Findings`
- `Summary`
- `Metadata`
