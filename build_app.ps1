# ============================================================
# FIRE Calculator - Build Script
# Run this from PowerShell in the project folder:
#   Set-Location "F:\Training\FIRE Number"
#   .\build_app.ps1
# ============================================================

Write-Host "=== FIRE Calculator Build Script ===" -ForegroundColor Cyan

# 1. Get dependencies
Write-Host "`n[1/3] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: pub get failed" -ForegroundColor Red; exit 1 }

# 2. Build Windows exe
Write-Host "`n[2/3] Building Windows desktop app..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Windows exe built!" -ForegroundColor Green
    Write-Host "Location: build\windows\x64\runner\Release\fire_calculator.exe" -ForegroundColor Green
} else {
    Write-Host "WARNING: Windows build failed" -ForegroundColor Red
}

# 3. Build Android APK
Write-Host "`n[3/3] Building Android APK (debug)..." -ForegroundColor Yellow
flutter build apk --debug
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: APK built!" -ForegroundColor Green
    Write-Host "Location: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
} else {
    Write-Host "WARNING: Android build failed - check gradle.properties has kotlin.incremental=false" -ForegroundColor Red
}

Write-Host "`n=== Done! ===" -ForegroundColor Cyan
