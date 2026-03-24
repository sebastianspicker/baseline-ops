#requires -version 5.1

<#
.SYNOPSIS
  Meta-test: verifies that every script declaring SupportsShouldProcess wraps
  all Set-Reg* and Remove-Reg* calls inside a ShouldProcess guard.

.DESCRIPTION
  Reads the raw text of each script that declares SupportsShouldProcess=$true
  and scans for Set-RegDword, Set-RegString, Remove-RegValueIfExists, and
  Remove-RegistryKeyIfExists calls. Each such call must appear inside an
  if ($PSCmdlet.ShouldProcess(...)) { ... } block.

  The detection is heuristic (text-based), not AST-based, but catches the
  common pattern where a registry-write call sits outside any ShouldProcess
  guard within the same remediation block.
#>

Describe 'ShouldProcess guards for registry-write calls' {

  $scriptsDir = Join-Path $PSScriptRoot '../../scripts'
  $scriptFiles = Get-ChildItem -LiteralPath $scriptsDir -Filter '*.ps1' -File |
    Where-Object { $_.Name -match '^\d{2}-' }

  # Filter to scripts that declare SupportsShouldProcess
  $shouldProcessScripts = @()
  foreach ($file in $scriptFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match 'SupportsShouldProcess\s*=\s*\$true') {
      $shouldProcessScripts += [pscustomobject]@{ Name = $file.Name; FullName = $file.FullName; Content = $content }
    }
  }

  # Registry-modifying function patterns to look for
  $regWritePattern = '(Set-RegDword|Set-RegString|Set-RegQword|Set-RegExpandString|Set-RegMultiString|Set-RegBinary|Remove-RegValueIfExists|Remove-RegistryKeyIfExists)\s'

  It '<_.Name> wraps all registry-write calls in ShouldProcess guards' -ForEach $shouldProcessScripts {
    $file = $_
    $lines = $file.Content -split "`n"
    $unguarded = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]

      # Skip comment lines
      if ($line -match '^\s*#') { continue }

      # Check if this line contains a registry-write call
      if ($line -match $regWritePattern) {
        # Look backwards from this line to find the nearest enclosing
        # ShouldProcess guard. We check a window of preceding lines
        # for an open if-ShouldProcess block (brace counting).
        $foundGuard = $false
        $braceDepth = 0

        for ($j = $i; $j -ge 0 -and $j -ge ($i - 30); $j--) {
          $checkLine = $lines[$j]

          # Count closing braces (going backwards, these are "openings")
          $braceDepth += ([regex]::Matches($checkLine, '\}')).Count
          $braceDepth -= ([regex]::Matches($checkLine, '\{')).Count

          if ($checkLine -match 'ShouldProcess') {
            # The ShouldProcess guard should be at the same or enclosing scope
            if ($braceDepth -le 0) {
              $foundGuard = $true
              break
            }
          }
        }

        if (-not $foundGuard) {
          $lineNum = $i + 1
          $trimmed = $line.Trim()
          $unguarded += "Line ${lineNum}: $trimmed"
        }
      }
    }

    $unguarded | Should -BeNullOrEmpty -Because "All Set-Reg*/Remove-Reg* calls must be wrapped in `$PSCmdlet.ShouldProcess() guards"
  }
}
