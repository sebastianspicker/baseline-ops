Set-StrictMode -Version Latest

function Ensure-RegistryKey {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -Path $Path -Force | Out-Null
  }
}

function Get-RegValue {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name
  )

  try {
    return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name
  } catch {
    return $null
  }
}

function Get-RegValueSafe {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name
  )

  return (Get-RegValue -Path $Path -Name $Name)
}

function Set-RegDword {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][int]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Registry value name cannot be empty." }

  try {
    Ensure-RegistryKey -Path $Path
    $null = New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType DWord -Value $Value -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Error "Failed to set REG_DWORD '$Name' at '$Path': $($_.Exception.Message)"
    return $false
  }
}

function Set-RegString {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Registry value name cannot be empty." }

  try {
    Ensure-RegistryKey -Path $Path
    $null = New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType String -Value $Value -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Error "Failed to set REG_SZ '$Name' at '$Path': $($_.Exception.Message)"
    return $false
  }
}

function Remove-RegValueIfExists {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path)) { return $false }

  try {
    $props = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
    if ($null -ne $props.PSObject.Properties[$Name]) {
        Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        return $true
    }
  } catch {
    Write-Error "Failed to remove registry value '$Name' at '$Path': $($_.Exception.Message)"
  }

  return $false
}

function Set-RegQword {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][int64]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Registry value name cannot be empty." }

  try {
    Ensure-RegistryKey -Path $Path
    $null = New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType QWord -Value $Value -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Error "Failed to set REG_QWORD '$Name' at '$Path': $($_.Exception.Message)"
    return $false
  }
}

function Set-RegExpandString {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Registry value name cannot be empty." }

  try {
    Ensure-RegistryKey -Path $Path
    $null = New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType ExpandString -Value $Value -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Error "Failed to set REG_EXPAND_SZ '$Name' at '$Path': $($_.Exception.Message)"
    return $false
  }
}

function Set-RegMultiString {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string[]]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Registry value name cannot be empty." }

  try {
    Ensure-RegistryKey -Path $Path
    $null = New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType MultiString -Value $Value -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Error "Failed to set REG_MULTI_SZ '$Name' at '$Path': $($_.Exception.Message)"
    return $false
  }
}

function Set-RegBinary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][byte[]]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Registry value name cannot be empty." }

  try {
    Ensure-RegistryKey -Path $Path
    $null = New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType Binary -Value $Value -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Error "Failed to set REG_BINARY '$Name' at '$Path': $($_.Exception.Message)"
    return $false
  }
}

function Get-RegKeyExists {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path
  )

  return (Test-Path -LiteralPath $Path)
}

function Get-RegValueExists {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path)) { return $false }

  try {
    $props = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
    return ($null -ne $props.PSObject.Properties[$Name])
  } catch {
    return $false
  }
}

function Get-RegDword {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [int]$DefaultValue = 0
  )

  $value = Get-RegValue -Path $Path -Name $Name
  if ($null -eq $value) { return $DefaultValue }
  
  try {
    return [int]$value
  } catch {
    return $DefaultValue
  }
}

function Get-RegDwordOrNull {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name
  )
  $value = Get-RegValue -Path $Path -Name $Name
  if ($null -eq $value) { return $null }
  try {
    return [int]$value
  } catch {
    return $null
  }
}

function Get-RegString {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [string]$DefaultValue = ''
  )

  $value = Get-RegValue -Path $Path -Name $Name
  if ($null -eq $value) { return $DefaultValue }
  
  return [string]$value
}

function Remove-RegistryKeyIfExists {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$Recurse
  )

  if (-not (Test-Path -LiteralPath $Path)) { return $false }

  try {
    if ($Recurse) {
      Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    } else {
      Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
    }
    return $true
  } catch {
    Write-Error "Failed to remove registry key '$Path': $($_.Exception.Message)"
    return $false
  }
}

Export-ModuleMember -Function `
  Ensure-RegistryKey, `
  Get-RegValue, `
  Get-RegValueSafe, `
  Set-RegDword, `
  Set-RegString, `
  Remove-RegValueIfExists, `
  Set-RegQword, `
  Set-RegExpandString, `
  Set-RegMultiString, `
  Set-RegBinary, `
  Get-RegKeyExists, `
  Get-RegValueExists, `
  Get-RegDword, `
  Get-RegDwordOrNull, `
  Get-RegString, `
  Remove-RegistryKeyIfExists
