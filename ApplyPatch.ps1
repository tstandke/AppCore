<#
  ApplyPatch.ps1
  Applies a patch ZIP (containing only changed files with their relative paths)
  to the project root. By default, TargetDir = the folder where this script lives.

  Usage:
    .\ApplyPatch.ps1 -PatchZip "C:\Users\Tim\Downloads\YourPatch.zip" -BackupExisting
    .\ApplyPatch.ps1 -PatchZip "C:\...\YourPatch.zip" -DryRun
#>

[CmdletBinding()]
param(
  [string]$TargetDir = $PSScriptRoot,
  [string]$PatchZip,
  [switch]$DryRun,
  [switch]$BackupExisting
)

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "WARN: $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "ERROR: $m" -ForegroundColor Red }

if (-not $PatchZip) {
  Write-Host "Usage: .\ApplyPatch.ps1 -PatchZip `"C:\Users\Tim\Downloads\YourPatch.zip`" [-BackupExisting] [-DryRun]" -ForegroundColor Yellow
  exit 1
}

try   { $TargetDir = (Resolve-Path $TargetDir).Path } catch { Write-Err "TargetDir not found."; exit 1 }
try   { $PatchZip  = (Resolve-Path $PatchZip).Path }  catch { Write-Err "PatchZip not found.";  exit 1 }

Write-Info "TargetDir: $TargetDir"
Write-Info "PatchZip : $PatchZip"

# Verify we're at the repo root (must have pubspec.yaml under app_core/ or packages/)
$pubspecs = Get-ChildItem -Path $TargetDir -Recurse -Filter "pubspec.yaml" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '(\\|/)(app_core|packages)(\\|/)' }
if (-not $pubspecs -or $pubspecs.Count -eq 0) {
  Write-Err "No 'pubspec.yaml' found under app_core\ or packages\. Aborting to avoid applying in the wrong folder."
  exit 2
}

# Extract patch to temp
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("patch_" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($PatchZip, $tmp)
} catch {
  Write-Err ("Failed to extract ZIP: {0}" -f $_.Exception.Message)
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  exit 3
}

# Optional backups
$timestamp = (Get-Date -Format "yyyyMMddHHmmss")
$backupRoot = $null
if ($BackupExisting) {
  $backupRoot = Join-Path $TargetDir (".backups\" + $timestamp)
  New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
  Write-Info "Backups  : $backupRoot"
}

# Apply each file from zip into TargetDir, preserving relative paths
$files = Get-ChildItem -Path $tmp -Recurse -File
if (-not $files) {
  Write-Warn "Patch contained no files."
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  exit 0
}

$updated = 0
foreach ($f in $files) {
  # Relative path inside the extracted tree
  $rel  = $f.FullName.Substring($tmp.Length).TrimStart('\','/')
  $dest = Join-Path $TargetDir $rel
  $destDir = Split-Path $dest -Parent

  Write-Info "Update: $rel"
  if ($DryRun) { continue }

  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }

  if ($BackupExisting -and (Test-Path $dest)) {
    $relForBackup = $dest.Substring($TargetDir.Length).TrimStart('\','/')
    $bakPath = Join-Path $backupRoot $relForBackup
    $bakDir  = Split-Path $bakPath -Parent
    if (-not (Test-Path $bakDir)) {
      New-Item -ItemType Directory -Path $bakDir -Force | Out-Null
    }
    try {
      Copy-Item -LiteralPath $dest -Destination $bakPath -Force
    } catch {
      Write-Warn ("Backup failed for {0}: {1}" -f $rel, $_.Exception.Message)
    }
  }

  Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
  $updated++
}

# Clean up
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==================== RESULT ====================" -ForegroundColor Green
Write-Host ("Updated files : {0}" -f $updated)
if ($BackupExisting -and $updated -gt 0) {
  Write-Host ("Backups saved : {0}" -f $backupRoot)
}
Write-Host "==============================================="

exit 0
