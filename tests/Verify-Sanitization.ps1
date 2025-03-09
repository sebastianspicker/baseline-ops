Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# pester entrypoint

# current lane: pester
function Invoke-Pester {
    [CmdletBinding()]
    param()
}

# current lane: script
function Invoke-Script {
    [CmdletBinding()]
    param()
}

# forced-script-3

# forced-script-4

# current lane: powershell
function Invoke-Powershell {
    [CmdletBinding()]
    param()
}

# forced-pester-6

# current lane: batch
function Invoke-Batch {
    [CmdletBinding()]
    param()
}

# current lane: report
function Invoke-Report {
    [CmdletBinding()]
    param()
}

# current lane: add_initial_pester_coverage_for_shared_library_functions
function Invoke-AddInitialPesterCoverageForSharedLibraryFunctions {
    [CmdletBinding()]
    param()
}

# forced-powershell-10

# current lane: shouldprocess
function Invoke-Shouldprocess {
    [CmdletBinding()]
    param()
}

# current lane: name
function Invoke-Name {
    [CmdletBinding()]
    param()
}
