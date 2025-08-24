<#  MakeFilteredZip.ps1
    Creates filtered_source.zip with the CORRECT folder structure:
      - app_core/**     (kept)
      - packages/**     (kept)
      - optional root files (README.md, LICENSE, firebase.json, .gitignore, etc.)
      - optional root scripts (*.ps1, *.bat, *.cmd)
      - (optional) Firebase secrets if -IncludeSecrets
    Excludes build/IDE clutter and backups (*.bak*).
    Strategy: stage a filtered copy, then zip that staged tree.
#>

[CmdletBinding()]
param(
  # Root of your repo; defaults to the folder where this script lives
  [string]$Root = $PSScriptRoot,

  # Include *.ps1/*.bat/*.cmd at repo root
  [switch]$IncludeScripts = $true,

  # Include google-services.json / GoogleService-Info.plist (off by default)
  [switch]$IncludeSecrets = $false
)

$ErrorActionPreference = 'Stop'

# ---- Paths ----
$Zip   = Join-Path $Root "filtered_source.zip"
$Stage = Join-Path $env:TEMP ("AppCore_ZipStage_{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Write-Host "Working dir: $Root"
Set-Location $Root

# ---- Sanity checks ----
if (-not (Test-Path ".\app_core"))  { throw "Missing app_core/ under $Root" }
if (-not (Test-Path ".\packages"))  { throw "Missing packages/ under $Root" }

# ---- Root files to include (if present) ----
$RootFiles = @(
  "README.md", "LICENSE", "firebase.json",
  ".gitignore", ".gitattributes",
  "analysis_options.yaml", "melos.yaml", ".editorconfig"
) | ForEach-Object { Join-Path $Root $_ } | Where-Object { Test-Path $_ }

# ---- Excludes ----
# Excluded directories (match anywhere in subtree)
$XD = @(
  ".git", ".dart_tool", "build", ".gradle", ".idea", ".vscode",
  "Pods", "DerivedData", ".symlinks",
  "Flutter\ephemeral", "ephemeral"
)

# Excluded file patterns
$XF = @(
  "*.bak*", "*.tmp", "*.log",
  "filtered_source.zip"
)

# ---- Clean previous zip ----
if (Test-Path $Zip) {
  Write-Host "Removing old zip: $Zip"
  Remove-Item $Zip -Force
}

# ---- Prepare staging dir ----
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Path $Stage | Out-Null

# ---- Helper to append robocopy args ----
function Add-RoboArgs {
  param([string[]]$Items, [string]$Switch)
  $args = @()
  foreach ($i in $Items) { $args += $Switch; $args += $i }
  return $args
}

# ---- Copy app_core/ into stage (filtered) ----
Write-Host "Staging: app_core/ -> $Stage\app_core"
$null = New-Item -ItemType Directory -Path (Join-Path $Stage "app_core") -Force
$rc = @("$Root\app_core", "$Stage\app_core", "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/R:1", "/W:1")
$rc += (Add-RoboArgs -Items $XD -Switch "/XD")
$rc += (Add-RoboArgs -Items $XF -Switch "/XF")
robocopy @rc | Out-Null

# ---- Copy packages/ into stage (filtered) ----
Write-Host "Staging: packages/ -> $Stage\packages"
$null = New-Item -ItemType Directory -Path (Join-Path $Stage "packages") -Force
$rc = @("$Root\packages", "$Stage\packages", "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/R:1", "/W:1")
$rc += (Add-RoboArgs -Items $XD -Switch "/XD")
$rc += (Add-RoboArgs -Items $XF -Switch "/XF")
robocopy @rc | Out-Null

# ---- Copy optional root files ----
foreach ($f in $RootFiles) {
  $leaf = Split-Path -Leaf $f
  Write-Host "Including root file: $leaf"
  Copy-Item $f -Destination (Join-Path $Stage $leaf) -Force
}

# ---- (Optional) include root scripts ----
if ($IncludeScripts) {
  $rootScripts = Get-ChildItem -Path $Root -File -Include *.ps1, *.bat, *.cmd -ErrorAction SilentlyContinue
  foreach ($s in $rootScripts) {
    Write-Host "Including script: $($s.Name)"
    Copy-Item $s.FullName -Destination (Join-Path $Stage $s.Name) -Force
  }
}

# ---- (Optional) include Firebase secrets ----
if ($IncludeSecrets) {
  $secretNames = @("google-services.json","GoogleService-Info.plist")
  $secrets = Get-ChildItem -Path (Join-Path $Root "app_core") -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $secretNames -contains $_.Name }
  foreach ($sec in $secrets) {
    $rel = $sec.FullName.Substring($Root.Length).TrimStart('\','/')
    $dest = Join-Path $Stage $rel
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    Write-Host "Including secret (per flag): $rel"
    Copy-Item $sec.FullName -Destination $dest -Force
  }
}

# ---- Sanity check: ensure app_core/lib/main.dart is present ----
$checkMain = Join-Path $Stage "app_core\lib\main.dart"
if (Test-Path $checkMain) {
  Write-Host "Verified: app_core\lib\main.dart found in stage."
} else {
  Write-Warning "WARNING: app_core\lib\main.dart NOT found in stage. (Check excludes and source tree.)"
}

# ---- Zip the staged tree (preserves hierarchy) ----
Write-Host "Zipping staged contents -> $Zip"

$items = @()
if (Test-Path (Join-Path $Stage 'app_core'))  { $items += (Join-Path $Stage 'app_core') }
if (Test-Path (Join-Path $Stage 'packages'))  { $items += (Join-Path $Stage 'packages') }

# include any root files/scripts we staged (README.md, LICENSE, .ps1, etc.)
$items += Get-ChildItem -Path $Stage -File | ForEach-Object { $_.FullName }

if (Test-Path $Zip) { Remove-Item $Zip -Force }
Compress-Archive -Path $items -DestinationPath $Zip -CompressionLevel Optimal

# ---- Cleanup stage ----
Write-Host "Cleaning up stage: $Stage"
Remove-Item $Stage -Recurse -Force

Write-Host "Done. ZIP created at: $Zip"
