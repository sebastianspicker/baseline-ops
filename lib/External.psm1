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
Provides centralized external command exit code validation for runtime scripts.
#>

function Test-CommandExists {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  return ($null -ne (Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue))
}

function Ensure-Cmdlet {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,
    [string]$Message
  )
  if ($null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)) { return $true }
  $msg = if ($Message) { $Message } else { "Required cmdlet or function not found: $Name" }
  throw $msg
}

function Ensure-Exe {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,
    [string]$Message
  )
  $exe = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue
  if ($exe) { return $true }
  $msg = if ($Message) { $Message } else { "Required executable not found: $Name" }
  throw $msg
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

  # Restrict -Command to a single executable name or path (no spaces) to avoid command injection
  $trimmed = $Command.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed -match '\s') {
    throw "Invoke-NativeCommand: -Command must be a single executable name or path (no spaces)."
  }

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

  $wevtArgs = @('epl', $LogName, $OutputPath, '/ow:true')
  if ($Query) {
    $wevtArgs += "/q:`"$Query`""
  }

  $result = Invoke-Wevtutil -Arguments $wevtArgs -ThrowOnError
  return ($result -eq $true)
}

function New-ScheduledTask {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TaskName,

    [Parameter(Mandatory)]
    [string]$TaskRun,

    [string]$Schedule = 'ONCE',

    [string]$StartTime,

    [string]$RunLevel = 'HIGHEST',

    [switch]$Force
  )

  # S16 fix: validate TaskName to prevent path traversal in task folders and special chars.
  # Callers are responsible for validating $TaskRun content.
  if ($TaskName -notmatch '^[a-zA-Z0-9\-_\\]+$') {
    throw "New-ScheduledTask: TaskName contains invalid characters. Only alphanumeric, hyphens, underscores, and backslashes (for task folders) are allowed."
  }

  $taskArgs = @('/Create', '/TN', $TaskName, '/SC', $Schedule, '/TR', $TaskRun, '/RL', $RunLevel)
  if ($Force) { $taskArgs += '/F' }
  if ($StartTime) { $taskArgs += '/ST', $StartTime }

  $result = Invoke-Schtasks -Arguments $taskArgs -ThrowOnError
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
  Ensure-Cmdlet, `
  Ensure-Exe, `
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
