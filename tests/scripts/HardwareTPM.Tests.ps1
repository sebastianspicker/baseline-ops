#requires -version 5.1

Describe '15-HardwareTPM-Audit fatal failure reporting' -Tag 'HardwareTPM' {
  BeforeAll {
    $script:HardwareTpmScript = Join-Path $PSScriptRoot '../../scripts/15-HardwareTPM-Audit.ps1'
    Import-Module (Join-Path $PSScriptRoot '../../lib/EventLog.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../lib/Serialization.psm1') -Force
    $global:HardwareTpmTestSaveJsonThrows = $false
    $global:HardwareTpmTestWriteEventResult = $true
    $global:HardwareTpmTestTpmObject = $null
    $global:HardwareTpmTestTpmMethods = @{}
    $global:HardwareTpmTestSecureBoot = $true
    $global:HardwareTpmTestBitLockerProtectionStatus = 1
    $global:HardwareTpmTestEventSourceResult = $true

    Mock -CommandName Ensure-EventSource -MockWith { $global:HardwareTpmTestEventSourceResult }
    Mock -CommandName Write-HealthEvent -MockWith { $global:HardwareTpmTestWriteEventResult }
    Mock -CommandName Save-Json -MockWith {
      if ($global:HardwareTpmTestSaveJsonThrows) {
        throw 'proof write failed'
      }
    }

    function Invoke-HardwareTpmFatalFailureCase {
      $oldOS = $env:OS
      $oldComputerName = $env:COMPUTERNAME
      $oldUserName = $env:USERNAME

      try {
        $env:OS = 'Windows_NT'
        $env:COMPUTERNAME = 'TEST-HOST'
        $env:USERNAME = 'tester'
        $global:HardwareTpmTestSaveJsonThrows = $true
        $global:HardwareTpmTestWriteEventResult = $true
        $global:HardwareTpmTestEventSourceResult = $true

        function global:Confirm-SecureBootUEFI { $true }
        function global:Get-BitLockerVolume {
          [pscustomobject]@{
            VolumeType           = 'OperatingSystem'
            ProtectionStatus     = 1
            MountPoint           = 'C:'
            VolumeStatus         = 'FullyEncrypted'
            EncryptionPercentage = 100
            EncryptionMethod     = 'XtsAes256'
          }
        }
        function global:Get-CimInstance {
          param([string]$Namespace, [string]$ClassName)
          if ($ClassName -eq 'Win32_BIOS') {
            return [pscustomobject]@{
              SerialNumber      = 'SERIAL'
              SMBIOSBIOSVersion = '1.0'
              Manufacturer      = 'Vendor'
              Name              = 'BIOS'
              ReleaseDate       = '20260101000000.000000+000'
            }
          }
          return [pscustomobject]@{
            SpecVersion    = '2.0'
            ManufacturerID = 'MSFT'
            PCRBanks       = @('SHA256')
            IsFirmware     = $false
          }
        }
        function global:Invoke-CimMethod {
          param($InputObject, [string]$MethodName)
          switch ($MethodName) {
            'IsOwned' { return [pscustomobject]@{ IsOwned = $true } }
            'IsEnabled' { return [pscustomobject]@{ IsEnabled = $true } }
            'IsActivated' { return [pscustomobject]@{ IsActivated = $true } }
            'IsReady' { return [pscustomobject]@{ IsReady = $true } }
            default { return $null }
          }
        }

        $output = & $script:HardwareTpmScript -OutputFormat None -PassThru -Confirm:$false 2>&1 3>&1 6>&1
        $exitCode = $LASTEXITCODE
      } finally {
        if ($null -eq $oldOS) {
          Remove-Item -LiteralPath Env:OS -ErrorAction SilentlyContinue
        } else {
          $env:OS = $oldOS
        }
        if ($null -eq $oldComputerName) {
          Remove-Item -LiteralPath Env:COMPUTERNAME -ErrorAction SilentlyContinue
        } else {
          $env:COMPUTERNAME = $oldComputerName
        }
        if ($null -eq $oldUserName) {
          Remove-Item -LiteralPath Env:USERNAME -ErrorAction SilentlyContinue
        } else {
          $env:USERNAME = $oldUserName
        }
        foreach ($name in @('Confirm-SecureBootUEFI','Get-BitLockerVolume','Get-CimInstance','Invoke-CimMethod')) {
          Remove-Item -LiteralPath "Function:\$name" -ErrorAction SilentlyContinue
        }
      }

      $result = @($output | Where-Object {
          $null -ne $_ -and
          $_.PSObject.Properties.Name -contains 'Result' -and
          $_.PSObject.Properties.Name -contains 'Findings'
        })[-1]

      return [pscustomobject]@{
        ExitCode = $exitCode
        Result   = $result
        Text     = ($output | Out-String)
      }
    }

    function Invoke-HardwareTpmEventWriteFailureCase {
      $oldOS = $env:OS
      $oldComputerName = $env:COMPUTERNAME
      $oldUserName = $env:USERNAME

      try {
        $env:OS = 'Windows_NT'
        $env:COMPUTERNAME = 'TEST-HOST'
        $env:USERNAME = 'tester'
        $global:HardwareTpmTestSaveJsonThrows = $false
        $global:HardwareTpmTestWriteEventResult = $false
        $global:HardwareTpmTestEventSourceResult = $true

        function global:Confirm-SecureBootUEFI { $true }
        function global:Get-BitLockerVolume {
          [pscustomobject]@{
            VolumeType           = 'OperatingSystem'
            ProtectionStatus     = 1
            MountPoint           = 'C:'
            VolumeStatus         = 'FullyEncrypted'
            EncryptionPercentage = 100
            EncryptionMethod     = 'XtsAes256'
          }
        }
        function global:Get-CimInstance {
          param([string]$Namespace, [string]$ClassName)
          if ($ClassName -eq 'Win32_BIOS') {
            return [pscustomobject]@{
              SerialNumber      = 'SERIAL'
              SMBIOSBIOSVersion = '1.0'
              Manufacturer      = 'Vendor'
              Name              = 'BIOS'
              ReleaseDate       = '20260101000000.000000+000'
            }
          }
          return [pscustomobject]@{
            SpecVersion    = '2.0'
            ManufacturerID = 'MSFT'
            PCRBanks       = @()
            IsFirmware     = $false
          }
        }
        function global:Invoke-CimMethod {
          param($InputObject, [string]$MethodName)
          switch ($MethodName) {
            'IsOwned' { return [pscustomobject]@{ IsOwned = $true } }
            'IsEnabled' { return [pscustomobject]@{ IsEnabled = $true } }
            'IsActivated' { return [pscustomobject]@{ IsActivated = $true } }
            'IsReady' { return [pscustomobject]@{ IsReady = $true } }
            default { return $null }
          }
        }

        $output = & $script:HardwareTpmScript -OutputFormat None -PassThru -Confirm:$false 2>&1 3>&1 6>&1
        $exitCode = $LASTEXITCODE
      } finally {
        if ($null -eq $oldOS) {
          Remove-Item -LiteralPath Env:OS -ErrorAction SilentlyContinue
        } else {
          $env:OS = $oldOS
        }
        if ($null -eq $oldComputerName) {
          Remove-Item -LiteralPath Env:COMPUTERNAME -ErrorAction SilentlyContinue
        } else {
          $env:COMPUTERNAME = $oldComputerName
        }
        if ($null -eq $oldUserName) {
          Remove-Item -LiteralPath Env:USERNAME -ErrorAction SilentlyContinue
        } else {
          $env:USERNAME = $oldUserName
        }
        foreach ($name in @('Confirm-SecureBootUEFI','Get-BitLockerVolume','Get-CimInstance','Invoke-CimMethod')) {
          Remove-Item -LiteralPath "Function:\$name" -ErrorAction SilentlyContinue
        }
      }

      $result = @($output | Where-Object {
          $null -ne $_ -and
          $_.PSObject.Properties.Name -contains 'Result' -and
          $_.PSObject.Properties.Name -contains 'Findings'
        })[-1]

      return [pscustomobject]@{
        ExitCode = $exitCode
        Result   = $result
        Text     = ($output | Out-String)
      }
    }

    function Invoke-HardwareTpmComplianceCase {
      param(
        [AllowNull()]$TpmObject,
        [hashtable]$TpmMethods = @{
          IsOwned = $true
          IsEnabled = $true
          IsActivated = $true
          IsReady = $true
        },
        [bool]$SecureBoot = $true,
        [int]$BitLockerProtectionStatus = 1,
        [bool]$EventSourceResult = $true
      )

      $oldOS = $env:OS
      $oldComputerName = $env:COMPUTERNAME
      $oldUserName = $env:USERNAME

      try {
        $env:OS = 'Windows_NT'
        $env:COMPUTERNAME = 'TEST-HOST'
        $env:USERNAME = 'tester'
        $global:HardwareTpmTestSaveJsonThrows = $false
        $global:HardwareTpmTestWriteEventResult = $true
        $global:HardwareTpmTestTpmObject = $TpmObject
        $global:HardwareTpmTestTpmMethods = $TpmMethods
        $global:HardwareTpmTestSecureBoot = $SecureBoot
        $global:HardwareTpmTestBitLockerProtectionStatus = $BitLockerProtectionStatus
        $global:HardwareTpmTestEventSourceResult = $EventSourceResult

        function global:Confirm-SecureBootUEFI { $global:HardwareTpmTestSecureBoot }
        function global:Get-BitLockerVolume {
          [pscustomobject]@{
            VolumeType           = 'OperatingSystem'
            ProtectionStatus     = $global:HardwareTpmTestBitLockerProtectionStatus
            MountPoint           = 'C:'
            VolumeStatus         = 'FullyEncrypted'
            EncryptionPercentage = 100
            EncryptionMethod     = 'XtsAes256'
          }
        }
        function global:Get-CimInstance {
          param([string]$Namespace, [string]$ClassName)
          if ($ClassName -eq 'Win32_BIOS') {
            return [pscustomobject]@{
              SerialNumber      = 'SERIAL'
              SMBIOSBIOSVersion = '1.0'
              Manufacturer      = 'Vendor'
              Name              = 'BIOS'
              ReleaseDate       = '20260101000000.000000+000'
            }
          }
          if ($ClassName -eq 'Win32_Tpm') {
            return $global:HardwareTpmTestTpmObject
          }
          return $null
        }
        function global:Invoke-CimMethod {
          param($InputObject, [string]$MethodName)
          $value = $null
          if ($global:HardwareTpmTestTpmMethods.ContainsKey($MethodName)) {
            $value = $global:HardwareTpmTestTpmMethods[$MethodName]
          }
          switch ($MethodName) {
            'IsOwned' { return [pscustomobject]@{ IsOwned = $value } }
            'IsEnabled' { return [pscustomobject]@{ IsEnabled = $value } }
            'IsActivated' { return [pscustomobject]@{ IsActivated = $value } }
            'IsReady' { return [pscustomobject]@{ IsReady = $value } }
            default { return $null }
          }
        }

        $output = & $script:HardwareTpmScript -OutputFormat None -PassThru -Confirm:$false 2>&1 3>&1 6>&1
        $exitCode = $LASTEXITCODE
      } finally {
        if ($null -eq $oldOS) {
          Remove-Item -LiteralPath Env:OS -ErrorAction SilentlyContinue
        } else {
          $env:OS = $oldOS
        }
        if ($null -eq $oldComputerName) {
          Remove-Item -LiteralPath Env:COMPUTERNAME -ErrorAction SilentlyContinue
        } else {
          $env:COMPUTERNAME = $oldComputerName
        }
        if ($null -eq $oldUserName) {
          Remove-Item -LiteralPath Env:USERNAME -ErrorAction SilentlyContinue
        } else {
          $env:USERNAME = $oldUserName
        }
        foreach ($name in @('Confirm-SecureBootUEFI','Get-BitLockerVolume','Get-CimInstance','Invoke-CimMethod')) {
          Remove-Item -LiteralPath "Function:\$name" -ErrorAction SilentlyContinue
        }
      }

      $result = @($output | Where-Object {
          $null -ne $_ -and
          $_.PSObject.Properties.Name -contains 'Result' -and
          $_.PSObject.Properties.Name -contains 'Findings'
        })[-1]

      return [pscustomobject]@{
        ExitCode = $exitCode
        Result   = $result
        Text     = ($output | Out-String)
      }
    }
  }

  It 'Reports a fatal audit exception as structured failure instead of success' {
    $run = Invoke-HardwareTpmFatalFailureCase

    $run.ExitCode | Should -Be 1
    $run.Result.Result | Should -Be 'FAIL'
    @($run.Result.Findings | Where-Object {
        $_.Code -eq 'HW-Error' -and $_.Message -match 'proof write failed'
      }).Count | Should -Be 1
    @($run.Result.Summary.Errors | Where-Object { $_ -match 'proof write failed' }).Count |
      Should -BeGreaterThan 0
    $run.Text | Should -Not -Match 'baseline compliant'
  }

  It 'Reports required event-log write failure as partial structured output' {
    $run = Invoke-HardwareTpmEventWriteFailureCase

    $run.ExitCode | Should -Be 2 -Because ($run.Result | ConvertTo-Json -Depth 6)
    $run.Result.Result | Should -Be 'WARN'
    $run.Result.Summary.EventWriteSucceeded | Should -BeFalse
    @($run.Result.Findings | Where-Object {
        $_.Code -eq 'HW-EventLogWriteFailed'
      }).Count | Should -Be 1
  }

  It 'Emits a warning when EventSource cannot be registered' {
    $run = Invoke-HardwareTpmComplianceCase -TpmObject ([pscustomobject]@{
        SpecVersion    = '2.0'
        ManufacturerID = 'MSFT'
        PCRBanks       = @('SHA256')
        IsFirmware     = $true
      }) -EventSourceResult:$false

    $run.Result.Summary.EventSourceSucceeded | Should -BeFalse
    $run.Text | Should -Match 'EventSource could not be registered'
  }

  It 'Returns OK when TPM 2.0 is present and baseline controls are enabled' {
    $run = Invoke-HardwareTpmComplianceCase -TpmObject ([pscustomobject]@{
        SpecVersion    = '2.0'
        ManufacturerID = 'MSFT'
        PCRBanks       = @('SHA256')
        IsFirmware     = $false
      })

    $run.ExitCode | Should -Be 0 -Because ($run.Result | ConvertTo-Json -Depth 6)
    $run.Result.Result | Should -Be 'OK'
    @($run.Result.Findings | Where-Object Code -eq 'HW-TPMDrift').Count | Should -Be 0
  }

  It 'Returns WARN when only TPM 1.2 is present' {
    $run = Invoke-HardwareTpmComplianceCase -TpmObject ([pscustomobject]@{
        SpecVersion    = '1.2'
        ManufacturerID = 'MSFT'
        PCRBanks       = @('SHA256')
        IsFirmware     = $false
      })

    $run.Result.Result | Should -Be 'WARN'
    @($run.Result.Findings | Where-Object {
        $_.Code -eq 'HW-TPMDrift' -and
        $_.Message -match 'SpecVersion'
      }).Count | Should -Be 1
  }

  It 'Returns FAIL when no TPM is present' {
    $run = Invoke-HardwareTpmComplianceCase -TpmObject $null

    $run.ExitCode | Should -Be 1 -Because ($run.Result | ConvertTo-Json -Depth 6)
    $run.Result.Result | Should -Be 'FAIL'
    @($run.Result.Findings | Where-Object {
        $_.Code -eq 'HW-TPMDrift' -and
        $_.Message -match 'TPM not present'
      }).Count | Should -Be 1
  }
}
