#requires -version 5.1

BeforeAll {
  Import-Module (Join-Path $PSScriptRoot '../../lib/Serialization.psm1') -Force
}

Describe 'New-V2ResultObject' {
  It 'Creates required contract fields' {
    $obj = New-V2ResultObject -ScriptName 'x.ps1' -Mode 'Audit' -Result 'OK' -Findings @() -Summary @{ A = 1 } -Metadata @{}
    $obj.SchemaVersion | Should -Be '2.0'
    $obj.ScriptName | Should -Be 'x.ps1'
    $obj.Mode | Should -Be 'Audit'
    $obj.Result | Should -Be 'OK'
  }
}

Describe 'Save-Json' {
  It 'Writes JSON file' {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ser-{0}.json" -f [guid]::NewGuid().ToString('N'))
    try {
      Save-Json -InputObject @{ test = 1 } -Path $tmp -NoBom
      Test-Path -LiteralPath $tmp | Should -Be $true
      $raw = Get-Content -LiteralPath $tmp -Raw
      $raw | Should -Match '"test"'
    } finally {
      if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
  }
}

Describe 'Write-ResultObject' {
  It 'Throws for Json without OutputPath' {
    $obj = New-V2ResultObject -ScriptName 'x.ps1' -Mode 'Audit' -Result 'OK' -Findings @() -Summary @{} -Metadata @{}
    { Write-ResultObject -ResultObject $obj -OutputFormat Json } | Should -Throw
  }
}
