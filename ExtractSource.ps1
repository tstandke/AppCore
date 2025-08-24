# ExtractSource.ps1  — create filtered_source.zip for the new AppCore layout

# ----- SETTINGS -----
$RootDir   = "C:\GCP-Management\AppCore"
$ZipPath   = Join-Path $RootDir "filtered_source.zip"

# Directories we want to include (subject to excludes)
$DirInclude = @(
  "app_core",      # your Flutter app (new location)
  "packages"       # local Dart/Flutter packages
)

# File names we ALWAYS include (wherever they are)
$AlwaysIncludeNames = @(
  "pubspec.yaml","pubspec.lock","analysis_options.yaml","melos.yaml",
  "CMakeLists.txt","settings.gradle","build.gradle","Podfile","Package.swift",
  "firebase.json","LICENSE","README.md",".gitignore",".gitattributes"
)

# File extensions we include (common code/config/media)
$IncludeExt = @(
  ".dart",".yaml",".yml",".json",".gradle",".kts",".properties",
  ".xml",".plist",".entitlements",".xcconfig",
  ".kt",".java",".swift",".mm",".m",".h",".hpp",".c",".cc",".cpp",
  ".html",".css",".js",".ts",".svg",".png",".jpg",".jpeg",".webp",
  ".ttf",".otf",".ico",
  ".md",".txt",".sh",".bat",".cmd",".ps1",".psm1",
  ".cmake",".cfg"
)

# Regex excludes (directories/files to skip)
$ExcludeRegex = @(
  '(^|\\)\.git(\\|$)',                 # .git/
  '(^|\\)\.dart_tool(\\|$)',           # .dart_tool/
  '(^|\\)build(\\|$)',                 # build/
  '(^|\\)\.gradle(\\|$)',              # .gradle/
  '(^|\\)\.idea(\\|$)',                # .idea/
  '(^|\\)\.vscode(\\|$)',              # .vscode/
  '(^|\\)node_modules(\\|$)',          # node_modules/
  '(^|\\)Pods(\\|$)',                  # iOS Pods/
  '(^|\\)DerivedData(\\|$)',           # Xcode DerivedData/
  '(^|\\)\.android\\Flutter\\ephemeral', # Flutter ephemeral
  '\.iml$',                            # IntelliJ module files
  '\.bak.*$',                          # backup files like *.bak-20250817...
  'filtered_source\.zip$'              # this zip
)

# ----- COLLECT FILES -----
Set-Location $RootDir

$allFiles = Get-ChildItem -Recurse -File
$includeRel = New-Object System.Collections.Generic.List[string]
$skippedRel = New-Object System.Collections.Generic.List[string]

foreach ($f in $allFiles) {
  $rel = $f.FullName.Substring($RootDir.Length).TrimStart('\','/')
  $relNorm = $rel -replace '/', '\'
  $name = $f.Name
  $ext  = $f.Extension.ToLowerInvariant()

  # Exclude by regex patterns
  if ($ExcludeRegex | Where-Object { $relNorm -match $_ }) {
    $skippedRel.Add($rel)
    continue
  }

  # Always-include names (regardless of ext), e.g. pubspec.yaml
  if ($AlwaysIncludeNames -contains $name) {
    $includeRel.Add($rel)
    continue
  }

  # Only include files inside app_core/ or packages/ trees
  if ($relNorm -like "app_core\*" -or $relNorm -like "packages\*") {
    # And only with allowed extensions (to avoid build junk)
    if ($IncludeExt -contains $ext) {
      $includeRel.Add($rel)
    } else {
      $skippedRel.Add($rel)
    }
    continue
  }

  # Everything else at repo root or other dirs is skipped by default
  $skippedRel.Add($rel)
}

# Deduplicate and sort
$includeRel = $includeRel | Sort-Object -Unique

# ----- CREATE ZIP -----
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

# Compress-Archive wants paths; pass relative -> keeps folder structure
Compress-Archive -Path $includeRel -DestinationPath $ZipPath -CompressionLevel Optimal

"Included: $($includeRel.Count) files"
"Skipped:  $($skippedRel.Count) files"
"ZIP: $ZipPath"
