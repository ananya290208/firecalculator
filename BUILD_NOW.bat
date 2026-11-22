@echo off
echo ============================================
echo   FIRE Calculator - Build for Windows
echo ============================================
echo.

cd /d "F:\Training\FIRE Number"

echo [Step 1] Getting packages...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: flutter pub get failed!
    pause
    exit /b 1
)

echo.
echo [Step 2] Building Windows app (takes 3-5 minutes)...
call flutter build windows --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo   SUCCESS! App built successfully.
    echo ============================================
    echo.
    echo Location:
    echo   F:\Training\FIRE Number\build\windows\x64\runner\Release\fire_calculator.exe
    echo.
    echo Opening the app now...
    start "" "F:\Training\FIRE Number\build\windows\x64\runner\Release\fire_calculator.exe"
) else (
    echo.
    echo ERROR: Build failed. Check the output above.
)

pause
