Set-StrictMode -Version Latest

<#
.SYNOPSIS
Wrappers for external command-line tools with exit code validation.

.DESCRIPTION
This module provides safe wrappers for common Windows command-line utilities
that are used across multiple scripts. Each wrapper:
- Validates the command exists before execution
- Captures and validates exit codes
- Provides consistent error handling
- Supports -ErrorAction and -WarningAction

.NOTES
Addresses bugs #7, #21, #30, #31, #32 from BUGS_AND_FIXES.md related to
external command exit code validation.
#>

function Test-CommandExists {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  return ($null -ne (Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue))
}

function Invoke-NativeCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Command,
    
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput,
    
    [switch]$Quiet
  )

  # Validate command exists
  if (-not (Test-CommandExists -Name $Command)) {
    $msg = "Command not found: $Command"
    if ($ThrowOnError) {
      throw $msg
    }
    Write-Warning $msg
    return $null
  }

  try {
    if ($CaptureOutput) {
      $output = & $Command @Arguments 2>&1
      $exitCode = $LASTEXITCODE
      
      if ($exitCode -ne 0 -and -not $Quiet) {
        $msg = "$Command exited with code $exitCode"
        if ($ThrowOnError) {
          throw $msg
        }
        Write-Warning $msg
      }
      
      return [pscustomobject]@{
        Output   = $output
        ExitCode = $exitCode
        Success  = ($exitCode -eq 0)
      }
    } else {
      & $Command @Arguments | Out-Null
      $exitCode = $LASTEXITCODE
      
      if ($exitCode -ne 0 -and -not $Quiet) {
        $msg = "$Command exited with code $exitCode"
        if ($ThrowOnError) {
          throw $msg
        }
        Write-Warning $msg
        return $false
      }
      
      return $true
    }
  } catch {
    $msg = "Failed to execute $Command : $($_.Exception.Message)"
    if ($ThrowOnError) {
      throw $msg
    }
    Write-Warning $msg
    return $null
  }
}

function Invoke-Schtasks {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput
  )

  $result = Invoke-NativeCommand -Command 'schtasks.exe' -Arguments $Arguments `
    -ThrowOnError:$ThrowOnError -CaptureOutput:$CaptureOutput
  
  return $result
}

function Invoke-Auditpol {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput
  )

  $result = Invoke-NativeCommand -Command 'auditpol.exe' -Arguments $Arguments `
    -ThrowOnError:$ThrowOnError -CaptureOutput:$CaptureOutput
  
  return $result
}

function Invoke-Wevtutil {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput
  )

  $result = Invoke-NativeCommand -Command 'wevtutil.exe' -Arguments $Arguments `
    -ThrowOnError:$ThrowOnError -CaptureOutput:$CaptureOutput
  
  return $result
}

function Invoke-Wecutil {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput
  )

  $result = Invoke-NativeCommand -Command 'wecutil.exe' -Arguments $Arguments `
    -ThrowOnError:$ThrowOnError -CaptureOutput:$CaptureOutput
  
  return $result
}

function Invoke-RegExe {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput
  )

  $regExe = Join-Path $env:WINDIR 'System32\reg.exe'
  
  $result = Invoke-NativeCommand -Command $regExe -Arguments $Arguments `
    -ThrowOnError:$ThrowOnError -CaptureOutput:$CaptureOutput
  
  return $result
}

function Invoke-Git {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments,
    
    [string]$WorkingDirectory,
    
    [switch]$ThrowOnError,
    
    [switch]$CaptureOutput
  )

  # Validate git exists
  if (-not (Test-CommandExists -Name 'git')) {
    $msg = "git command not found. Please install Git."
    if ($ThrowOnError) {
      throw $msg
    }
    Write-Warning $msg
    return $null
  }

  $originalLocation = $null
  if ($WorkingDirectory) {
    $originalLocation = Get-Location
    Set-Location -LiteralPath $WorkingDirectory
  }

  try {
    $result = Invoke-NativeCommand -Command 'git' -Arguments $Arguments `
      -ThrowOnError:$ThrowOnError -CaptureOutput:$CaptureOutput
    return $result
  } finally {
    if ($originalLocation) {
      Set-Location -LiteralPath $originalLocation
    }
  }
}

function Get-AuditPolSubcategories {
  [CmdletBinding()]
  param()

  $result = Invoke-Auditpol -Arguments @('/get', '/category:*') -CaptureOutput
  
  if ($result -and $result.Success) {
    return $result.Output
  }
  
  return $null
}

function Get-EventLogInfo {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$LogName
  )

  $result = Invoke-Wevtutil -Arguments @('gl', $LogName) -CaptureOutput
  
  if ($result -and $result.Success) {
    return $result.Output
  }
  
  return $null
}

function Enable-EventLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$LogName
  )

  $result = Invoke-Wevtutil -Arguments @('sl', $LogName, '/e:true')
  return ($result -eq $true)
}

function Set-EventLogMaxSize {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$LogName,
    
    [Parameter(Mandatory)]
    [int64]$MaxSizeBytes
  )

  $result = Invoke-Wevtutil -Arguments @('sl', $LogName, "/ms:$MaxSizeBytes")
  return ($result -eq $true)
}

function Export-EventLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$LogName,
    
    [Parameter(Mandatory)]
    [string]$OutputPath,
    
    [string]$Query
  )

  $args = @('epl', $LogName, $OutputPath, '/ow:true')
  if ($Query) {
    $args += "/q:`"$Query`""
  }

  $result = Invoke-Wevtutil -Arguments $args -ThrowOnError
  return ($result -eq $true)
}

function New-ScheduledTask {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TaskName,
    
    [Parameter(Mandatory)]
    [string]$TaskRun,
    
    [string]$Schedule = 'ONCE',
    
    [string]$StartTime,
    
    [string]$RunLevel = 'HIGHEST',
    
    [switch]$Force
  )

  $args = @('/Create', '/TN', $TaskName, '/SC', $Schedule, '/TR', $TaskRun, '/RL', $RunLevel)
  if ($Force) { $args += '/F' }
  if ($StartTime) { $args += '/ST', $StartTime }

  $result = Invoke-Schtasks -Arguments $args -ThrowOnError
  return ($result -eq $true)
}

function Remove-ScheduledTask {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TaskName
  )

  $result = Invoke-Schtasks -Arguments @('/Delete', '/TN', $TaskName, '/F')
  return ($result -eq $true)
}

function Export-RegistryKey {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$KeyPath,
    
    [Parameter(Mandatory)]
    [string]$OutputPath
  )

  $result = Invoke-RegExe -Arguments @('export', $KeyPath, $OutputPath, '/y') -ThrowOnError
  return ($result -eq $true)
}

Export-ModuleMember -Function `
  Test-CommandExists, `
  Invoke-NativeCommand, `
  Invoke-Schtasks, `
  Invoke-Auditpol, `
  Invoke-Wevtutil, `
  Invoke-Wecutil, `
  Invoke-RegExe, `
  Invoke-Git, `
  Get-AuditPolSubcategories, `
  Get-EventLogInfo, `
  Enable-EventLog, `
  Set-EventLogMaxSize, `
  Export-EventLog, `
  New-ScheduledTask, `
  Remove-ScheduledTask, `
  Export-RegistryKey
