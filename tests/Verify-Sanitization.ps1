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
