#requires -version 5.1

BeforeAll {
  Import-Module (Join-Path $PSScriptRoot '../../lib/Execution.psm1') -Force
}

Describe 'Invoke-WithRetry' {
  It 'Retries and succeeds' {
    $script:attempts = 0
    $result = Invoke-WithRetry -MaxAttempts 3 -DelaySeconds 0 -Action {
      $script:attempts++
      if ($script:attempts -lt 2) { throw 'fail once' }
      'ok'
    }

    $result | Should -Be 'ok'
    $script:attempts | Should -Be 2
  }
}

Describe 'Invoke-ScriptWithTiming' {
  It 'Returns success for temp script' {
    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("exec-test-{0}.ps1" -f [guid]::NewGuid().ToString('N'))
    try {
      Set-Content -LiteralPath $tempFile -Encoding UTF8 -Value 'Write-Output "hello"'
      $res = Invoke-ScriptWithTiming -ScriptPath $tempFile
      $res.Success | Should -Be $true
      $res.ExitCode | Should -Be 0
      $res.DurationMs | Should -BeGreaterThan -1
    } finally {
      if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue }
    }
  }
}

Describe 'Convert-ArgumentTokens' {
  It 'Parses named tokens and values' {
    $parsed = Convert-ArgumentTokens -Arguments @('-Name','bob','-OutputFormat','None')
    $parsed.Named.Name | Should -Be 'bob'
    $parsed.Named.OutputFormat | Should -Be 'None'
    @($parsed.Positional).Count | Should -Be 0
  }

  It 'Parses colon-style boolean values' {
    $parsed = Convert-ArgumentTokens -Arguments @('-Strict:$false','-NoColor:$true')
    $parsed.Named.Strict | Should -Be $false
    $parsed.Named.NoColor | Should -Be $true
  }
}
