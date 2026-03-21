Set-StrictMode -Version Latest

function Save-Json {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object]$InputObject,
    [Parameter(Mandatory)]
    [string]$Path,
    [int]$Depth = 20,
    [switch]$NoBom
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    throw 'Save-Json: Path cannot be null or empty.'
  }
  if ($Path -match '\.\.') {
    throw 'Save-Json: Path must not contain ".." (path traversal not allowed).'
  }

  $dir = Split-Path -Path $Path -Parent
  if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
  }

  $json = $InputObject | ConvertTo-Json -Depth $Depth
  if ($NoBom) {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
  } else {
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
  }
}

function Save-Csv {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object[]]$InputObject,
    [Parameter(Mandatory)]
    [string]$Path
  )

  $dir = Split-Path -Path $Path -Parent
  if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
  }

  $InputObject | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

function New-V2ResultObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ScriptName,
    [Parameter(Mandatory)]
    [ValidateSet('Audit','Remediate')]
    [string]$Mode,
    [Parameter(Mandatory)]
    [ValidateSet('OK','WARN','FAIL')]
    [string]$Result,
    [object[]]$Findings = @(),
    [object]$Summary = $null,
    [hashtable]$Metadata = @{},
    [string]$SchemaVersion = '2.0'
  )

  return [pscustomobject]@{
    SchemaVersion = $SchemaVersion
    ScriptName    = $ScriptName
    Mode          = $Mode
    ComputerName  = $env:COMPUTERNAME
    TimestampUtc  = (Get-Date).ToUniversalTime()
    Result        = $Result
    Findings      = @($Findings)
    Summary       = $Summary
    Metadata      = $Metadata
  }
}

function Write-ResultObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object]$ResultObject,
    [ValidateSet('Console','Json','Csv','None')]
    [string]$OutputFormat = 'Console',
    [string]$OutputPath
  )

  switch ($OutputFormat) {
    'None' {
      return
    }
    'Console' {
      return
    }
    'Json' {
      if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw 'OutputPath is required when OutputFormat is Json.'
      }
      Save-Json -InputObject $ResultObject -Path $OutputPath -Depth 10 -NoBom
      return
    }
    'Csv' {
      if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw 'OutputPath is required when OutputFormat is Csv.'
      }

      if ($ResultObject.PSObject.Properties.Name -contains 'Findings') {
        Save-Csv -InputObject @($ResultObject.Findings) -Path $OutputPath
      } else {
        Save-Csv -InputObject @($ResultObject) -Path $OutputPath
      }
      return
    }
  }
}

Export-ModuleMember -Function `
  Save-Json, `
  Save-Csv, `
  New-V2ResultObject, `
  Write-ResultObject
