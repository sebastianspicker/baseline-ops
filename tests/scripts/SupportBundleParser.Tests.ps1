#requires -version 5.1

Describe '10-SupportBundle-Parser archive validation' -Tag 'SupportBundle', 'Security' {
  BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '../../scripts/10-SupportBundle-Parser.ps1'
    $helperPath = Join-Path $PSScriptRoot '../../scripts/internal/10-SupportBundle-Parser.helpers.ps1'
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
    $errors | Should -BeNullOrEmpty
    $helperAst = [System.Management.Automation.Language.Parser]::ParseFile($helperPath, [ref]$tokens, [ref]$errors)
    $errors | Should -BeNullOrEmpty

    $required = @('Ensure-ExtractedWorkDir', 'Test-NoReparsePointAncestor', 'Set-AdminOnlyDirectoryAcl', 'Get-ValidatedZipEntries')
    $definitions = @($helperAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $required -contains $node.Name }, $true) | Sort-Object { $_.Extent.StartOffset })
    $definitions.Count | Should -Be $required.Count
    foreach ($definition in $definitions) { . ([scriptblock]::Create($definition.Extent.Text)) }
    function ConvertTo-SafeDisplayPath { param([string]$Path) return $Path }

    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    function New-ParserTestZip {
      param([string]$Path, [hashtable[]]$Entries)
      $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
      try {
        $zip = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList @($stream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
        try {
          foreach ($spec in $Entries) {
            $entry = $zip.CreateEntry([string]$spec.Name)
            if ($null -ne $spec.Content) {
              $writer = New-Object System.IO.StreamWriter($entry.Open())
              try { $writer.Write([string]$spec.Content) } finally { $writer.Dispose() }
            }
          }
        } finally { $zip.Dispose() }
      } finally { $stream.Dispose() }
    }
    function Invoke-ParserZipValidation {
      param([string]$Path, [Int64]$MaxEntryBytes = 128MB, [Int64]$MaxTotalBytes = 512MB, [Int32]$MaxCompressionRatio = 100)
      $stream = [System.IO.File]::OpenRead($Path)
      try {
        $zip = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList @($stream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        try { Get-ValidatedZipEntries -Archive $zip -MaxEntries 2048 -MaxEntryBytes $MaxEntryBytes -MaxTotalBytes $MaxTotalBytes -MaxCompressionRatio $MaxCompressionRatio }
        finally { $zip.Dispose() }
      } finally { $stream.Dispose() }
    }
  }

  It 'does not reuse a stale extraction directory for the same archive' {
    $archivePath = Join-Path $TestDrive 'SupportBundle-stale.zip'
    $extractRoot = Join-Path $TestDrive 'extracted'
    New-ParserTestZip -Path $archivePath -Entries @(@{ Name = 'Summary.json'; Content = '{}' })
    Mock -CommandName Set-AdminOnlyDirectoryAcl -MockWith { }

    $first = Ensure-ExtractedWorkDir -ZipPath $archivePath -ExtractRoot $extractRoot
    Set-Content -LiteralPath (Join-Path $first 'stale.txt') -Value 'must not be reused'
    $second = Ensure-ExtractedWorkDir -ZipPath $archivePath -ExtractRoot $extractRoot

    $first | Should -Not -Be $second
    Test-Path -LiteralPath (Join-Path $second 'stale.txt') | Should -BeFalse
  }

  It 'rejects traversal paths before extraction' {
    $path = Join-Path $TestDrive 'traversal.zip'
    New-ParserTestZip -Path $path -Entries @(@{ Name = '../outside.txt'; Content = 'nope' })
    { Invoke-ParserZipValidation -Path $path } | Should -Throw '*traversal*'
  }

  It 'rejects duplicate canonical paths before extraction' {
    $path = Join-Path $TestDrive 'duplicate.zip'
    New-ParserTestZip -Path $path -Entries @(@{ Name = 'nested\report.txt'; Content = 'one' }, @{ Name = 'nested/report.txt'; Content = 'two' })
    { Invoke-ParserZipValidation -Path $path } | Should -Throw '*duplicate canonical path*'
  }

  It 'rejects entries exceeding the configured uncompressed limit' {
    $path = Join-Path $TestDrive 'oversized.zip'
    New-ParserTestZip -Path $path -Entries @(@{ Name = 'report.txt'; Content = 'more than one byte' })
    { Invoke-ParserZipValidation -Path $path -MaxEntryBytes 1 } | Should -Throw '*exceeds*'
  }

  It 'rejects suspicious compression ratios before extraction' {
    $path = Join-Path $TestDrive 'ratio.zip'
    New-ParserTestZip -Path $path -Entries @(@{ Name = 'repeat.txt'; Content = ('A' * 8192) })
    { Invoke-ParserZipValidation -Path $path -MaxCompressionRatio 10 } | Should -Throw '*compression ratio*'
  }

  It 'rejects Windows-ambiguous ZIP component names before extraction' -ForEach @(
    @{ Name = 'logs/report.txt:payload'; Expected = '*unsafe Windows path component*' },
    @{ Name = 'logs/report. '; Expected = '*unsafe Windows path component*' },
    @{ Name = 'logs/CON.txt'; Expected = '*reserved Windows device name*' }
  ) {
    $path = Join-Path $TestDrive ("unsafe-{0}.zip" -f [guid]::NewGuid().ToString('N'))
    New-ParserTestZip -Path $path -Entries @(@{ Name = $Name; Content = 'nope' })
    { Invoke-ParserZipValidation -Path $path } | Should -Throw $Expected
  }
}

Describe '10-SupportBundle-Parser terminal failures and defaults' -Tag 'SupportBundle', 'Security' {
  BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '../../scripts/10-SupportBundle-Parser.ps1'

    function New-SupportBundleParserFixture {
      param(
        [Parameter(Mandatory)][string]$Root,
        [AllowEmptyCollection()][string[]]$Errors = @()
      )
      $supportDir = Join-Path $Root 'bundles'
      $extractRoot = Join-Path $Root 'extract'
      $sourceDir = Join-Path $Root 'source'
      [void][System.IO.Directory]::CreateDirectory($supportDir)
      [void][System.IO.Directory]::CreateDirectory($sourceDir)

      $summary = [ordered]@{
        Hostname = 'PARSER-TEST'
        Time = '2026-07-14T12:00:00'
        User = 'parser-test'
        Admin = $true
        Errors = @($Errors)
        Notes = @()
        Outputs = @('ZIP:SupportBundle-parser-test.zip')
      }
      $summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $sourceDir 'Summary.json') -Encoding utf8
      Set-Content -LiteralPath (Join-Path $sourceDir 'proof.txt') -Value 'proof'

      $configPath = Join-Path $Root 'support-bundle.json'
      @{ ProofOutFiles = @{
          SupportBundle = 'proof.txt'
          SysmonState = 'proof.txt'
          SysmonDriftState = 'proof.txt'
          SoftwareInventory = 'proof.txt'
          FirewallAudit = 'proof.txt'
          HardwareAudit = 'proof.txt'
        } } |
        ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $configPath -Encoding utf8

      $archivePath = Join-Path $supportDir 'SupportBundle-parser-test.zip'
      [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceDir, $archivePath)
      return [pscustomobject]@{
        SupportDir = $supportDir
        ExtractRoot = $extractRoot
        ConfigPath = $configPath
      }
    }

    function Invoke-SupportBundleParserFixture {
      param(
        [Parameter(Mandatory)]$Fixture
      )
      $oldOS = $env:OS
      $oldProgramData = $env:ProgramData
      try {
        $env:OS = 'Windows_NT'
        $env:ProgramData = $TestDrive
        $output = @(& $scriptPath `
          -SupportDir $Fixture.SupportDir `
          -ExtractRoot $Fixture.ExtractRoot `
          -ConfigPath $Fixture.ConfigPath `
          -OutputFormat None `
          -PassThru `
          -Quiet `
          -NoColor `
          -Confirm:$false 6>$null)
        return [pscustomobject]@{ Output = $output; ExitCode = $LASTEXITCODE }
      } finally {
        if ($null -eq $oldOS) { Remove-Item -LiteralPath Env:OS -ErrorAction SilentlyContinue } else { $env:OS = $oldOS }
        if ($null -eq $oldProgramData) { Remove-Item -LiteralPath Env:ProgramData -ErrorAction SilentlyContinue } else { $env:ProgramData = $oldProgramData }
      }
    }
  }

  It 'emits exactly one V2 object for a successful PassThru parse' {
    $fixture = New-SupportBundleParserFixture -Root (Join-Path $TestDrive 'success')
    $run = Invoke-SupportBundleParserFixture -Fixture $fixture

    $run.ExitCode | Should -Be 0
    @($run.Output).Count | Should -Be 1
    $run.Output[0].ScriptName | Should -Be '10-SupportBundle-Parser.ps1'
    $run.Output[0].Result | Should -Be 'OK'
    $run.Output[0].Summary.Hostname | Should -Be 'PARSER-TEST'
  }

  It 'turns producer Summary.Errors into canonical findings and a non-OK result' {
    $fixture = New-SupportBundleParserFixture -Root (Join-Path $TestDrive 'producer-error') -Errors @("collector failed`nwhile reading evidence")
    $run = Invoke-SupportBundleParserFixture -Fixture $fixture

    $run.ExitCode | Should -Be 2
    @($run.Output).Count | Should -Be 1
    $run.Output[0].Result | Should -Be 'WARN'
    @($run.Output[0].Summary.Errors).Count | Should -Be 1
    $finding = @($run.Output[0].Findings | Where-Object { $_.Code -eq 'SB-ProducerError' })
    $finding.Count | Should -Be 1
    $finding[0].Severity | Should -Be 'Medium'
    $finding[0].Message | Should -Be 'SupportBundle producer reported an error: collector failed while reading evidence'
  }

  It 'uses the fixed ProgramData support-bundle root and terminates with V2 FAIL when no ZIP exists' {
    $oldOS = $env:OS
    $oldProgramData = $env:ProgramData
    try {
      $env:OS = 'Windows_NT'
      $env:ProgramData = $TestDrive
      $output = & $scriptPath -OutputFormat None -PassThru -Confirm:$false 6>$null
      $exitCode = $LASTEXITCODE
    } finally {
      if ($null -eq $oldOS) { Remove-Item -LiteralPath Env:OS -ErrorAction SilentlyContinue } else { $env:OS = $oldOS }
      if ($null -eq $oldProgramData) { Remove-Item -LiteralPath Env:ProgramData -ErrorAction SilentlyContinue } else { $env:ProgramData = $oldProgramData }
    }
    $exitCode | Should -Be 1
    $result = @($output | Where-Object { $_.PSObject.Properties.Name -contains 'Result' })[-1]
    $result.Result | Should -Be 'FAIL'
    $result.Summary.SupportDir | Should -Be (Join-Path (Join-Path $TestDrive 'WinMdmSecurityHardeningKit') 'SupportBundles')
  }

  It 'emits terminal V2 FAIL when the newest archive has no Summary.json' {
    $supportDir = Join-Path $TestDrive 'bundles'
    $extractRoot = Join-Path $TestDrive 'extract'
    [void][System.IO.Directory]::CreateDirectory($supportDir)
    $archivePath = Join-Path $supportDir 'SupportBundle-no-summary.zip'
    $sourceDir = Join-Path $TestDrive 'empty-source'
    [void][System.IO.Directory]::CreateDirectory($sourceDir)
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceDir, $archivePath)
    $oldOS = $env:OS
    $oldProgramData = $env:ProgramData
    try {
      $env:OS = 'Windows_NT'
      $env:ProgramData = $TestDrive
      $output = & $scriptPath -SupportDir $supportDir -ExtractRoot $extractRoot -OutputFormat None -PassThru -Confirm:$false 6>$null
      $exitCode = $LASTEXITCODE
    } finally {
      if ($null -eq $oldOS) { Remove-Item -LiteralPath Env:OS -ErrorAction SilentlyContinue } else { $env:OS = $oldOS }
      if ($null -eq $oldProgramData) { Remove-Item -LiteralPath Env:ProgramData -ErrorAction SilentlyContinue } else { $env:ProgramData = $oldProgramData }
    }
    $exitCode | Should -Be 1
    $result = @($output | Where-Object { $_.PSObject.Properties.Name -contains 'Result' })[-1]
    $result.Result | Should -Be 'FAIL'
    $result.Summary.Error | Should -Match 'valid Summary.json'
  }
}
