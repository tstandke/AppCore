<#
  CompareSplash.ps1
  Compares splash/logo-related files between an original source ZIP and the current repo.
  Optionally produces a restore patch ZIP with only the changed files (original versions).

  Examples:
    .\CompareSplash.ps1 -OriginalZip "C:\Users\Tim\Downloads\mobile_admin_app-source-20250817-174504.zip"
    .\CompareSplash.ps1 -OriginalZip "C:\Users\Tim\Downloads\mobile_admin_app-source-20250817-174504.zip" -MakeRestorePatch
#>

[CmdletBinding()]
param(
  # Path to the original source ZIP (the good state you want to return to)
  [Parameter(Mandatory=$true)]
  [string]$OriginalZip,

  # Current repo root (defaults to the folder where this script lives)
  [string]$CurrentRoot = $PSScriptRoot,

  # If set, creates a patch ZIP with original versions of files that differ
  [switch]$MakeRestorePatch
)

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Ok  ($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host "WARN: $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "ERROR: $m" -ForegroundColor Red }

try { $OriginalZip = (Resolve-Path $OriginalZip).Path } catch { Err "OriginalZip not found."; exit 1 }
try { $CurrentRoot = (Resolve-Path $CurrentRoot).Path } catch { Err "CurrentRoot not found."; exit 1 }

# Extract original ZIP to temp
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("orig_" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($OriginalZip, $tmp)
} catch {
  Err ("Failed to extract OriginalZip: {0}" -f $_.Exception.Message)
  exit 2
}

# List of repo-relative paths/patterns to compare (Android + iOS + assets)
$checkPatterns = @(
  # Android native splash backgrounds & styles
  "apps/mobile_admin_app/android/app/src/main/res/drawable/launch_background.xml",
  "apps/mobile_admin_app/android/app/src/main/res/drawable-v21/launch_background.xml",
  "apps/mobile_admin_app/android/app/src/main/res/values/styles.xml",
  "apps/mobile_admin_app/android/app/src/main/res/values-night/styles.xml",

  # Android mipmap icons (ic_launcher/app_icon across all densities)
  "apps/mobile_admin_app/android/app/src/main/res/mipmap-*/ic_launcher.png",
  "apps/mobile_admin_app/android/app/src/main/res/mipmap-*/app_icon.png",
  "apps/mobile_admin_app/android/app/src/main/res/mipmap-*/ic_launcher.webp",
  "apps/mobile_admin_app/android/app/src/main/res/mipmap-*/app_icon.webp",

  # Flutter asset (as per your pubspec)
  "apps/mobile_admin_app/assets/icon/app_icon.png",

  # iOS launch/storyboard & icons (if present)
  "apps/mobile_admin_app/ios/Runner/Base.lproj/LaunchScreen.storyboard",
  "apps/mobile_admin_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/*",
  "apps/mobile_admin_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/*"
)

# Helper for expanding glob patterns under a base
function Resolve-Under($base, $pattern) {
  $full = Join-Path $base $pattern
  Get-ChildItem -Path $full -Recurse -File -ErrorAction SilentlyContinue
}

$results = @()
$toPatch = @()

foreach ($pat in $checkPatterns) {
  $origMatches   = Resolve-Under -base $tmp         -pattern $pat
  $currMatches   = Resolve-Under -base $CurrentRoot -pattern $pat

  # union by repo-relative path so we compare path-for-path
  $allRepoRel = @{}
  foreach ($f in $origMatches) {
    $rel = $f.FullName.Substring($tmp.Length).TrimStart('\','/')
    $allRepoRel[$rel] = $true
  }
  foreach ($f in $currMatches) {
    $rel = $f.FullName.Substring($CurrentRoot.Length).TrimStart('\','/')
    $allRepoRel[$rel] = $true
  }

  foreach ($rel in $allRepoRel.Keys) {
    $origPath = Join-Path $tmp $rel
    $curPath  = Join-Path $CurrentRoot $rel

    $origExists = Test-Path $origPath
    $curExists  = Test-Path $curPath

    if (-not $origExists -and -not $curExists) { continue }

    if ($origExists -and $curExists) {
      $h1 = (Get-FileHash -Algorithm SHA256 -Path $origPath).Hash
      $h2 = (Get-FileHash -Algorithm SHA256 -Path $curPath ).Hash
      $same = ($h1 -eq $h2)
      $results += [pscustomobject]@{
        Status    = $(if ($same) {"IDENTICAL"} else {"DIFFERENT"})
        Path      = $rel
        Original  = $origPath
        Current   = $curPath
      }
      if (-not $same) { $toPatch += $rel }
    }
    elseif ($origExists -and -not $curExists) {
      $results += [pscustomobject]@{
        Status    = "MISSING_IN_CURRENT"
        Path      = $rel
        Original  = $origPath
        Current   = $null
      }
      $toPatch += $rel
    }
    elseif (-not $origExists -and $curExists) {
      $results += [pscustomobject]@{
        Status    = "EXTRA_IN_CURRENT"
        Path      = $rel
        Original  = $null
        Current   = $curPath
      }
    }
  }
}

# Print a concise report
Write-Host ""
Write-Host "==== Splash/Icon Diff Report ====" -ForegroundColor Cyan
$groups = $results | Group-Object Status
foreach ($g in $groups) {
  Write-Host ("{0}: {1}" -f $g.Name, $g.Count)
}
Write-Host ""

# If you want, list the differences
$diffs = $results | Where-Object { $_.Status -ne "IDENTICAL" }
if ($diffs) {
  Write-Host "Changed / Missing files:" -ForegroundColor Yellow
  $diffs | Select-Object Status, Path | Sort-Object Status, Path | Format-Table -AutoSize
} else {
  Ok "All splash/icon files match the original."
}

# Optionally build a restore patch
if ($MakeRestorePatch -and $toPatch.Count -gt 0) {
  $stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
  $patchZip = Join-Path $CurrentRoot ("patch_restore_native_splash-" + $stamp + ".zip")
  if (Test-Path $patchZip) { Remove-Item $patchZip -Force }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $tmpSel = Join-Path $tmp ("sel_" + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmpSel | Out-Null

  foreach ($rel in ($toPatch | Select-Object -Unique)) {
    $src = Join-Path $tmp $rel
    if (Test-Path $src) {
      $dst = Join-Path $tmpSel $rel
      $dstDir = Split-Path $dst -Parent
      if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
      Copy-Item -LiteralPath $src -Destination $dst -Force
    }
  }

  # Create the patch ZIP
  [IO.Compression.ZipFile]::CreateFromDirectory($tmpSel, $patchZip)
  Remove-Item $tmpSel -Recurse -Force -ErrorAction SilentlyContinue
  Ok ("Created restore patch: {0}" -f $patchZip)
}

# Cleanup
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
