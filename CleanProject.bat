@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Clean generated / temporary files without touching source code.

REM Run from the repo root (same folder as this .bat)
cd /d "%~dp0"

echo =====================================================
echo  Cleaning workspace: %cd%
echo  This will remove generated caches, builds and zips
echo  It will NOT touch: apps\, lib\, packages\, pubspec.*
echo =====================================================
echo.

REM --- Root-level generated folders ---
if exist ".dart_tool"              rmdir /s /q ".dart_tool"
if exist "build"                   rmdir /s /q "build"
if exist ".idea"                   rmdir /s /q ".idea"
if exist ".backups"                rmdir /s /q ".backups"

REM --- App-level generated folders (for each app under apps\*) ---
for /d %%D in ("apps\*") do (
  if exist "%%~fD\.dart_tool"         rmdir /s /q "%%~fD\.dart_tool"
  if exist "%%~fD\build"              rmdir /s /q "%%~fD\build"
  if exist "%%~fD\android\build"      rmdir /s /q "%%~fD\android\build"
  if exist "%%~fD\android\app\build"  rmdir /s /q "%%~fD\android\app\build"
)

REM --- Common scratch / archive files (safe to remove) ---
del /q "android12_splash_fix.zip" 2>nul
del /q "hummerred_splash_patch.zip" 2>nul
del /q "splash_ic_launcher_patch.zip" 2>nul
del /q "filtered_source.zip" 2>nul
del /q "mobile_admin_app-source-*.zip" 2>nul
del /q "patch_restore_native_splash-*.zip" 2>nul

REM --- Backup & scratch text files (safe to remove) ---
del /q "*.bak-*" 2>nul
del /q "project_files.txt" 2>nul
del /q "look.dat" 2>nul

REM --- Flutter-generated plugin deps (safe to remove, will regen) ---
del /q ".flutter-plugins-dependencies" 2>nul

echo.
echo ✅ Cleanup complete.
echo If you run into build issues, try:
echo   flutter pub get
echo   flutter clean
echo   flutter run -v
echo.
endlocal
exit /b 0
