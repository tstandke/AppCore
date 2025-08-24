<#
  BuildRunApp.ps1
  ----------------
  Builds and runs a Flutter application on a connected Android emulator or device.
  Usage:
      .\BuildRunApp.ps1
      .\BuildRunApp.ps1 -Clean
      .\BuildRunApp.ps1 -ProjectDir "C:\path\to\flutter\project"
#>

param(
    [string]$ProjectDir = (Join-Path $PSScriptRoot "app_core"),
    [switch]$Clean
)

# Resolve and sanity check project path
$resolved = Resolve-Path -Path $ProjectDir -ErrorAction SilentlyContinue
if (-not $resolved) {
    Write-Host "ERROR: ProjectDir '$ProjectDir' does not exist." -ForegroundColor Red
    exit 1
}
$ProjectDir = $resolved.Path

# Verify pubspec.yaml
if (-not (Test-Path (Join-Path $ProjectDir "pubspec.yaml"))) {
    $fallback = Join-Path $PSScriptRoot "apps\mobile_admin_app"
    if (Test-Path (Join-Path $fallback "pubspec.yaml")) {
        Write-Host "No pubspec.yaml in '$ProjectDir'. Using '$fallback'." -ForegroundColor Yellow
        $ProjectDir = $fallback
    } else {
        Write-Host "ERROR: No pubspec.yaml found in '$ProjectDir' or fallback." -ForegroundColor Red
        exit 1
    }
}

# Ensure adb is available (append to PATH for this session)
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
if (Test-Path $adbPath) {
    if (-not ($env:PATH -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $adbPath })) {
        $env:PATH = "$adbPath;$env:PATH"
        Write-Host "Added adb path: $adbPath"
    }
} else {
    Write-Host "WARNING: adb path '$adbPath' not found. Ensure Android SDK is installed." -ForegroundColor Yellow
}

# Ensure flutter is available
try {
    & flutter --version | Out-Null
} catch {
    Write-Host "ERROR: The 'flutter' command could not be found. Ensure Flutter SDK is installed and added to PATH." -ForegroundColor Red
    exit 1
}

# Change to project dir
Push-Location $ProjectDir

# Optional clean
if ($Clean) {
    Write-Host "Running 'flutter clean'..." -ForegroundColor Cyan
    & flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: 'flutter clean' failed." -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Get dependencies
Write-Host "Running 'flutter pub get'..." -ForegroundColor Cyan
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: 'flutter pub get' failed." -ForegroundColor Red
    Pop-Location
    exit 1
}

# Run app
Write-Host "Launching Flutter app..." -ForegroundColor Cyan
& flutter run
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: 'flutter run' failed." -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
Write-Host "Flutter app launched successfully." -ForegroundColor Green
