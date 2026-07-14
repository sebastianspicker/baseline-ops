#requires -version 5.1
<#
.SYNOPSIS
Archive validation and extraction helpers for 10-SupportBundle-Parser.ps1.
#>
function Ensure-ExtractedWorkDir {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ZipPath,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ExtractRoot,
    [Parameter()][switch]$Force
  )
  # The extraction directory deliberately has no stable name. A stable directory
  # can retain files from a different archive, including after a failed extraction.
  $maxEntries = 2048
  # Refuse an oversized container before either hashing or opening it.  The
  # uncompressed limits below protect extraction; this limit protects the
  # validation path itself from an arbitrarily large archive.
  $maxArchiveBytes = 256MB
  $maxEntryBytes = 128MB
  $maxTotalBytes = 512MB
  $maxCompressionRatio = 100
  $dest = $null
  try {
    if ($Force.IsPresent) { Write-Verbose 'ForceExtract requested; a fresh extraction directory is always used.' }
    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) { return $null }
    $zipItem = Get-Item -LiteralPath $ZipPath -Force -ErrorAction Stop
    if ($zipItem.Length -gt $maxArchiveBytes) {
      throw "ZIP archive exceeds $maxArchiveBytes bytes."
    }
    Test-NoReparsePointAncestor -Path $zipItem.FullName
    [System.IO.Directory]::CreateDirectory($ExtractRoot) | Out-Null
    Test-NoReparsePointAncestor -Path ([System.IO.Path]::GetFullPath($ExtractRoot))
    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    $archiveStream = [System.IO.File]::Open($zipItem.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
      $archive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList @($archiveStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
      try {
        $entries = Get-ValidatedZipEntries -Archive $archive -MaxEntries $maxEntries -MaxEntryBytes $maxEntryBytes -MaxTotalBytes $maxTotalBytes -MaxCompressionRatio $maxCompressionRatio
        $archiveHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipItem.FullName -ErrorAction Stop).Hash.Substring(0, 16).ToLowerInvariant()
        $safeBaseName = ($zipItem.BaseName -replace '[^A-Za-z0-9._-]', '_')
        $dest = Join-Path $ExtractRoot ("{0}-{1}-{2}" -f $safeBaseName, $archiveHash, [guid]::NewGuid().ToString('N'))
        [System.IO.Directory]::CreateDirectory($dest) | Out-Null
        Set-AdminOnlyDirectoryAcl -Path $dest
        Test-NoReparsePointAncestor -Path $dest
        [Int64]$extractedTotal = 0
        foreach ($entryInfo in $entries) {
          $targetPath = Join-Path $dest ($entryInfo.CanonicalPath -replace '/', [string][System.IO.Path]::DirectorySeparatorChar)
          if ($entryInfo.IsDirectory) {
            [System.IO.Directory]::CreateDirectory($targetPath) | Out-Null
            Test-NoReparsePointAncestor -Path $targetPath
            continue
          }
          $parent = Split-Path -Path $targetPath -Parent
          [System.IO.Directory]::CreateDirectory($parent) | Out-Null
          Test-NoReparsePointAncestor -Path $parent
          $entryStream = $entryInfo.Entry.Open()
          try {
            $output = [System.IO.File]::Open($targetPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
              $buffer = New-Object byte[] 81920
              [Int64]$written = 0
              while (($read = $entryStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $written += $read
                if ($written -gt $maxEntryBytes -or $written -gt $entryInfo.Entry.Length) { throw "ZIP entry exceeded its validated size: $($entryInfo.CanonicalPath)" }
                $output.Write($buffer, 0, $read)
              }
              if ($written -ne $entryInfo.Entry.Length) { throw "ZIP entry size changed while extracting: $($entryInfo.CanonicalPath)" }
              $extractedTotal += $written
              if ($extractedTotal -gt $maxTotalBytes) { throw "ZIP extracted content exceeds $maxTotalBytes bytes." }
            } finally { $output.Dispose() }
          } finally { $entryStream.Dispose() }
        }
      } finally { $archive.Dispose() }
    } finally { $archiveStream.Dispose() }
    return $dest
  }
  catch {
    if ($dest -and (Test-Path -LiteralPath $dest -PathType Container)) { Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Warning ("Failed to safely extract ZIP: {0} ({1})" -f (ConvertTo-SafeDisplayPath $ZipPath), $_.Exception.Message)
    return $null
  }
}
function Test-NoReparsePointAncestor {
  [CmdletBinding()]
  param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
  $current = [System.IO.Path]::GetFullPath($Path)
  while ($current) {
    if (Test-Path -LiteralPath $current) {
      $attributes = [System.IO.File]::GetAttributes($current)
      if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse-point path component is not permitted: $current" }
    }
    $parent = Split-Path -Path $current -Parent
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) { break }
    $current = $parent
  }
}
function Set-AdminOnlyDirectoryAcl {
  [CmdletBinding()]
  param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
  if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) { return }
  $security = New-Object System.Security.AccessControl.DirectorySecurity
  $security.SetAccessRuleProtection($true, $false)
  $inheritance = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
  $propagation = [System.Security.AccessControl.PropagationFlags]::None
  foreach ($sidValue in @('S-1-5-18', 'S-1-5-32-544')) {
    $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sidValue
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList @($sid, [System.Security.AccessControl.FileSystemRights]::FullControl, $inheritance, $propagation, [System.Security.AccessControl.AccessControlType]::Allow)
    [void]$security.AddAccessRule($rule)
  }
  [System.IO.Directory]::SetAccessControl($Path, $security)
}
function Get-ValidatedZipEntries {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.IO.Compression.ZipArchive]$Archive,
    [Parameter(Mandatory)][Int32]$MaxEntries,
    [Parameter(Mandatory)][Int64]$MaxEntryBytes,
    [Parameter(Mandatory)][Int64]$MaxTotalBytes,
    [Parameter(Mandatory)][Int32]$MaxCompressionRatio
  )
  if ($Archive.Entries.Count -gt $MaxEntries) { throw "ZIP has more than $MaxEntries entries." }
  $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  $files = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  $allPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  $result = New-Object System.Collections.Generic.List[object]
  [Int64]$total = 0
  foreach ($entry in $Archive.Entries) {
    $rawName = $entry.FullName
    if ([string]::IsNullOrWhiteSpace($rawName) -or $rawName -match '[\x00-\x1f\x7f]') { throw 'ZIP entry has an empty or control-character path.' }
    $normalName = $rawName -replace '\\', '/'
    if ([System.IO.Path]::IsPathRooted($normalName) -or $normalName.StartsWith('/') -or $normalName -match '^[A-Za-z]:') { throw "ZIP entry has a rooted path: $rawName" }
    $isDirectory = $normalName.EndsWith('/')
    $parts = @($normalName.TrimEnd('/').Split('/'))
    if ($parts.Count -eq 0 -or @($parts | Where-Object { [string]::IsNullOrWhiteSpace($_) -or $_ -eq '.' -or $_ -eq '..' }).Count -gt 0) { throw "ZIP entry has a traversal or empty path component: $rawName" }
    foreach ($part in $parts) {
      # Windows treats ':' as an alternate-data-stream separator and silently
      # normalizes trailing spaces/dots.  Either behavior could make two ZIP
      # entries target the same extracted object.
      if ($part.Contains(':') -or $part.EndsWith(' ') -or $part.EndsWith('.')) {
        throw "ZIP entry has an unsafe Windows path component: $rawName"
      }
      $deviceBase = $part.Split('.')[0]
      if ($deviceBase -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
        throw "ZIP entry uses a reserved Windows device name: $rawName"
      }
    }
    $canonical = [string]::Join('/', $parts)
    if (-not $seen.Add($canonical)) { throw "ZIP contains a duplicate canonical path: $canonical" }
    [void]$allPaths.Add($canonical)
    if (-not $isDirectory) {
      if ($entry.Length -gt $MaxEntryBytes) { throw "ZIP entry exceeds $MaxEntryBytes bytes: $canonical" }
      $total += $entry.Length
      if ($total -gt $MaxTotalBytes) { throw "ZIP uncompressed content exceeds $MaxTotalBytes bytes." }
      if (($entry.CompressedLength -eq 0 -and $entry.Length -gt 0) -or ($entry.CompressedLength -gt 0 -and ($entry.Length / [double]$entry.CompressedLength) -gt $MaxCompressionRatio)) { throw "ZIP compression ratio exceeds $MaxCompressionRatio:1: $canonical" }
      [void]$files.Add($canonical)
    }
    [void]$result.Add([pscustomobject]@{ Entry = $entry; CanonicalPath = $canonical; IsDirectory = $isDirectory })
  }
  foreach ($filePath in $files) {
    foreach ($path in $allPaths) {
      if ($path.StartsWith($filePath + '/', [System.StringComparison]::OrdinalIgnoreCase)) { throw "ZIP contains a file/directory conflict: $filePath" }
    }
  }
  # Do not wrap a generic list in @(...): PowerShell 7.5 raises an incompatible collection conversion error.
  return $result.ToArray()
}
