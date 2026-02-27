#requires -Version 5.1
<#
.SYNOPSIS
GUI launcher for MDM Security Hardening scripts and profiles.

.DESCRIPTION
Windows Forms launcher to:
- run a single script via 00-Run-Local.ps1
- run a profile via 00-Run-Profile.ps1
- stream output live
- save output logs
#>

if ($env:OS -ne 'Windows_NT') {
  Write-Error 'Launcher-GUI requires Windows.'
  exit 1
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:DefaultRoot = 'C:\install\mdm\ps1'
$guiDir = $PSScriptRoot
$parent = Split-Path -Parent $guiDir
if ((Split-Path -Leaf $guiDir) -eq 'tools' -and (Test-Path -LiteralPath (Join-Path $parent 'scripts') -PathType Container)) {
  $script:DefaultRoot = $parent
}

$executionModulePath = Join-Path $parent 'lib\Execution.psm1'
if (Test-Path -LiteralPath $executionModulePath -PathType Leaf) {
  Import-Module $executionModulePath -Force
}

function Parse-ArgumentString {
  param([string]$ArgString)
  if ([string]::IsNullOrWhiteSpace($ArgString)) { return @() }

  $tokens = [System.Collections.ArrayList]::new()
  $current = [System.Text.StringBuilder]::new()
  $inQuotes = $false
  $chars = $ArgString.ToCharArray()

  for ($i = 0; $i -lt $chars.Length; $i++) {
    $c = $chars[$i]
    if ($c -eq '"') {
      if ($inQuotes) {
        [void]$tokens.Add($current.ToString())
        $current = [System.Text.StringBuilder]::new()
        $inQuotes = $false
      } else {
        $inQuotes = $true
      }
      continue
    }

    if (-not $inQuotes -and ($c -eq ' ' -or $c -eq "`t")) {
      $s = $current.ToString().Trim()
      if ($s) { [void]$tokens.Add($s) }
      $current = [System.Text.StringBuilder]::new()
      continue
    }

    [void]$current.Append($c)
  }

  $tail = $current.ToString().Trim()
  if ($tail) { [void]$tokens.Add($tail) }
  return @($tokens)
}

function Get-ScriptListItems {
  param([string]$RootPath)

  if ([string]::IsNullOrWhiteSpace($RootPath) -or $RootPath -match '\.\.') { return @() }
  $scriptsDir = Join-Path $RootPath 'scripts'
  if (-not (Test-Path -LiteralPath $scriptsDir -PathType Container)) { return @() }

  $files = Get-ChildItem -LiteralPath $scriptsDir -Filter '*.ps1' -File |
    Where-Object { $_.Name -match '^\d{2}-' }

  $list = [System.Collections.ArrayList]::new()
  foreach ($f in ($files | Sort-Object Name)) {
    if ($f.BaseName -match '^(\d+)-') {
      $num = $Matches[1]
      [void]$list.Add([pscustomobject]@{
          Number = $num
          Name = $f.Name
          Display = $f.Name
        })
    }
  }
  return @($list)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'MDM Security Hardening - Launcher v2'
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(780, 560)

$lblRoot = New-Object System.Windows.Forms.Label
$lblRoot.Text = 'Root path:'
$lblRoot.Location = New-Object System.Drawing.Point(12, 12)
$lblRoot.AutoSize = $true
$form.Controls.Add($lblRoot)

$txtRoot = New-Object System.Windows.Forms.TextBox
$txtRoot.Text = $script:DefaultRoot
$txtRoot.Location = New-Object System.Drawing.Point(12, 30)
$txtRoot.Size = New-Object System.Drawing.Size(700, 23)
$txtRoot.Anchor = 'Top,Left,Right'
$form.Controls.Add($txtRoot)

$btnBrowseRoot = New-Object System.Windows.Forms.Button
$btnBrowseRoot.Text = 'Browse...'
$btnBrowseRoot.Location = New-Object System.Drawing.Point(720, 28)
$btnBrowseRoot.Size = New-Object System.Drawing.Size(80, 26)
$btnBrowseRoot.Anchor = 'Top,Right'
$form.Controls.Add($btnBrowseRoot)

$lblScripts = New-Object System.Windows.Forms.Label
$lblScripts.Text = 'Scripts:'
$lblScripts.Location = New-Object System.Drawing.Point(12, 62)
$lblScripts.AutoSize = $true
$form.Controls.Add($lblScripts)

$listScripts = New-Object System.Windows.Forms.ListBox
$listScripts.Location = New-Object System.Drawing.Point(12, 80)
$listScripts.Size = New-Object System.Drawing.Size(788, 170)
$listScripts.Anchor = 'Top,Left,Right'
$listScripts.DisplayMember = 'Display'
$form.Controls.Add($listScripts)

$lblMode = New-Object System.Windows.Forms.Label
$lblMode.Text = 'Preset mode:'
$lblMode.Location = New-Object System.Drawing.Point(12, 258)
$lblMode.AutoSize = $true
$form.Controls.Add($lblMode)

$cmbMode = New-Object System.Windows.Forms.ComboBox
$cmbMode.Location = New-Object System.Drawing.Point(12, 276)
$cmbMode.Size = New-Object System.Drawing.Size(160, 23)
$cmbMode.DropDownStyle = 'DropDownList'
[void]$cmbMode.Items.Add('Audit')
[void]$cmbMode.Items.Add('Remediate')
$cmbMode.SelectedIndex = 0
$form.Controls.Add($cmbMode)

$lblArgs = New-Object System.Windows.Forms.Label
$lblArgs.Text = 'Additional arguments:'
$lblArgs.Location = New-Object System.Drawing.Point(190, 258)
$lblArgs.AutoSize = $true
$form.Controls.Add($lblArgs)

$txtArgs = New-Object System.Windows.Forms.TextBox
$txtArgs.Location = New-Object System.Drawing.Point(190, 276)
$txtArgs.Size = New-Object System.Drawing.Size(610, 23)
$txtArgs.Anchor = 'Top,Left,Right'
$form.Controls.Add($txtArgs)

$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = 'Profile JSON:'
$lblProfile.Location = New-Object System.Drawing.Point(12, 308)
$lblProfile.AutoSize = $true
$form.Controls.Add($lblProfile)

$txtProfile = New-Object System.Windows.Forms.TextBox
$txtProfile.Location = New-Object System.Drawing.Point(12, 326)
$txtProfile.Size = New-Object System.Drawing.Size(700, 23)
$txtProfile.Anchor = 'Top,Left,Right'
$form.Controls.Add($txtProfile)

$btnBrowseProfile = New-Object System.Windows.Forms.Button
$btnBrowseProfile.Text = 'Browse...'
$btnBrowseProfile.Location = New-Object System.Drawing.Point(720, 324)
$btnBrowseProfile.Size = New-Object System.Drawing.Size(80, 26)
$btnBrowseProfile.Anchor = 'Top,Right'
$form.Controls.Add($btnBrowseProfile)

$btnRunScript = New-Object System.Windows.Forms.Button
$btnRunScript.Text = 'Run Script'
$btnRunScript.Location = New-Object System.Drawing.Point(12, 360)
$btnRunScript.Size = New-Object System.Drawing.Size(110, 30)
$form.Controls.Add($btnRunScript)

$btnRunProfile = New-Object System.Windows.Forms.Button
$btnRunProfile.Text = 'Run Profile'
$btnRunProfile.Location = New-Object System.Drawing.Point(128, 360)
$btnRunProfile.Size = New-Object System.Drawing.Size(110, 30)
$form.Controls.Add($btnRunProfile)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = 'Clear'
$btnClear.Location = New-Object System.Drawing.Point(244, 360)
$btnClear.Size = New-Object System.Drawing.Size(80, 30)
$form.Controls.Add($btnClear)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = 'Save Output'
$btnSave.Location = New-Object System.Drawing.Point(330, 360)
$btnSave.Size = New-Object System.Drawing.Size(110, 30)
$form.Controls.Add($btnSave)

$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = 'Output:'
$lblOutput.Location = New-Object System.Drawing.Point(12, 398)
$lblOutput.AutoSize = $true
$form.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ReadOnly = $true
$txtOutput.ScrollBars = 'Both'
$txtOutput.WordWrap = $false
$txtOutput.Location = New-Object System.Drawing.Point(12, 416)
$txtOutput.Size = New-Object System.Drawing.Size(860, 230)
$txtOutput.Anchor = 'Top,Bottom,Left,Right'
$txtOutput.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($txtOutput)

function Update-ScriptList {
  $root = $txtRoot.Text.Trim()
  $listScripts.Items.Clear()
  foreach ($item in (Get-ScriptListItems -RootPath $root)) {
    [void]$listScripts.Items.Add($item)
  }
}

function Start-BackgroundRun {
  param(
    [scriptblock]$ScriptBlock,
    [object[]]$ScriptArguments
  )

  $btnRunScript.Enabled = $false
  $btnRunProfile.Enabled = $false

  $runspace = [runspacefactory]::CreateRunspace()
  $runspace.Open()
  $pwsh = [powershell]::Create().AddScript($ScriptBlock)
  foreach ($arg in $ScriptArguments) { [void]$pwsh.AddArgument($arg) }
  $pwsh.Runspace = $runspace
  $asyncResult = $pwsh.BeginInvoke()
  $cleanupState = [pscustomobject]@{
    PowerShell = $pwsh
    Runspace = $runspace
    AsyncResult = $asyncResult
  }
  [void][System.Threading.ThreadPool]::QueueUserWorkItem([System.Threading.WaitCallback]{
      param($state)
      try {
        [void]$state.PowerShell.EndInvoke($state.AsyncResult)
      } catch {
      } finally {
        try { $state.PowerShell.Dispose() } catch {}
        try { $state.Runspace.Dispose() } catch {}
      }
    }, $cleanupState)
}

$btnBrowseRoot.Add_Click({
  $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
  $dlg.Description = 'Select kit root (contains scripts\\)'
  $dlg.SelectedPath = $txtRoot.Text.Trim()
  if ($dlg.ShowDialog() -eq 'OK') {
    $txtRoot.Text = $dlg.SelectedPath
    Update-ScriptList
  }
})

$btnBrowseProfile.Add_Click({
  $dlg = New-Object System.Windows.Forms.OpenFileDialog
  $dlg.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
  if ($dlg.ShowDialog() -eq 'OK') {
    $txtProfile.Text = $dlg.FileName
  }
})

$btnClear.Add_Click({ $txtOutput.Clear() })

$btnSave.Add_Click({
  $dlg = New-Object System.Windows.Forms.SaveFileDialog
  $dlg.Filter = 'Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*'
  $dlg.FileName = "launcher-output-$(Get-Date -Format yyyyMMdd-HHmmss).log"
  if ($dlg.ShowDialog() -eq 'OK') {
    Set-Content -LiteralPath $dlg.FileName -Value $txtOutput.Text -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Saved: $($dlg.FileName)", 'Launcher', 'OK', 'Information') | Out-Null
  }
})

$btnRunScript.Add_Click({
  $root = $txtRoot.Text.Trim()
  if ([string]::IsNullOrWhiteSpace($root) -or $root -match '\.\.') {
    [System.Windows.Forms.MessageBox]::Show('Root path is invalid.', 'Launcher', 'OK', 'Warning') | Out-Null
    return
  }

  $selected = $listScripts.SelectedItem
  if (-not $selected) {
    [System.Windows.Forms.MessageBox]::Show('Select a script first.', 'Launcher', 'OK', 'Warning') | Out-Null
    return
  }

  $runLocal = Join-Path (Join-Path $root 'scripts') '00-Run-Local.ps1'
  if (-not (Test-Path -LiteralPath $runLocal -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show("Missing 00-Run-Local.ps1 in $root\\scripts", 'Launcher', 'OK', 'Warning') | Out-Null
    return
  }

  $mode = [string]$cmbMode.SelectedItem
  $scriptArgs = Parse-ArgumentString -ArgString $txtArgs.Text
  if ($mode -eq 'Remediate' -and $scriptArgs -notcontains '-Remediate') {
    $scriptArgs += '-Remediate'
  }

  $txtOutput.AppendText("[RUN] Script: $($selected.Name)`r`n")
  $sb = {
    param($RunLocalPath, $ScriptName, $RootPath, $ScriptArgs, $OutputControl, $RunScriptButton, $RunProfileButton)
    try {
      & $RunLocalPath -ScriptName $ScriptName -RootPath $RootPath -ScriptArgs $ScriptArgs 2>&1 | ForEach-Object {
        $line = [string]$_
        [void]$OutputControl.Invoke([Action]{ $OutputControl.AppendText("$line`r`n") })
      }
    } catch {
      $line = "ERROR: $($_.Exception.Message)"
      [void]$OutputControl.Invoke([Action]{ $OutputControl.AppendText("$line`r`n") })
    } finally {
      [void]$RunScriptButton.Invoke([Action]{ $RunScriptButton.Enabled = $true })
      [void]$RunProfileButton.Invoke([Action]{ $RunProfileButton.Enabled = $true })
    }
  }

  Start-BackgroundRun -ScriptBlock $sb -ScriptArguments @($runLocal, $selected.Name, $root, $scriptArgs, $txtOutput, $btnRunScript, $btnRunProfile)
})

$btnRunProfile.Add_Click({
  $root = $txtRoot.Text.Trim()
  $profilePathText = $txtProfile.Text.Trim()

  if ([string]::IsNullOrWhiteSpace($root) -or $root -match '\.\.') {
    [System.Windows.Forms.MessageBox]::Show('Root path is invalid.', 'Launcher', 'OK', 'Warning') | Out-Null
    return
  }
  if ([string]::IsNullOrWhiteSpace($profilePathText) -or -not (Test-Path -LiteralPath $profilePathText -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid profile JSON file.', 'Launcher', 'OK', 'Warning') | Out-Null
    return
  }

  $runProfile = Join-Path (Join-Path $root 'scripts') '00-Run-Profile.ps1'
  if (-not (Test-Path -LiteralPath $runProfile -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show("Missing 00-Run-Profile.ps1 in $root\\scripts", 'Launcher', 'OK', 'Warning') | Out-Null
    return
  }

  $mode = [string]$cmbMode.SelectedItem
  $extra = Parse-ArgumentString -ArgString $txtArgs.Text
  $parsedExtra = if (Get-Command -Name Convert-ArgumentTokens -ErrorAction SilentlyContinue) {
    Convert-ArgumentTokens -Arguments $extra
  } else {
    [pscustomobject]@{ Named = @{}; Positional = @($extra) }
  }

  $txtOutput.AppendText("[RUN] Profile: $profilePathText`r`n")
  $sb = {
    param($RunProfilePath, $ProfilePath, $RootPath, $Mode, $NamedExtraArgs, $PositionalExtraArgs, $OutputControl, $RunScriptButton, $RunProfileButton)
    try {
      $params = @{
        ProfilePath = $ProfilePath
        RootPath    = $RootPath
        Mode        = $Mode
      }

      & $RunProfilePath @params @NamedExtraArgs @PositionalExtraArgs 2>&1 | ForEach-Object {
        $line = [string]$_
        [void]$OutputControl.Invoke([Action]{ $OutputControl.AppendText("$line`r`n") })
      }
    } catch {
      $line = "ERROR: $($_.Exception.Message)"
      [void]$OutputControl.Invoke([Action]{ $OutputControl.AppendText("$line`r`n") })
    } finally {
      [void]$RunScriptButton.Invoke([Action]{ $RunScriptButton.Enabled = $true })
      [void]$RunProfileButton.Invoke([Action]{ $RunProfileButton.Enabled = $true })
    }
  }

  Start-BackgroundRun -ScriptBlock $sb -ScriptArguments @($runProfile, $profilePathText, $root, $mode, $parsedExtra.Named, @($parsedExtra.Positional), $txtOutput, $btnRunScript, $btnRunProfile)
})

$txtRoot.Add_TextChanged({ Update-ScriptList })
$form.Add_Load({ Update-ScriptList })

[void]$form.ShowDialog()
