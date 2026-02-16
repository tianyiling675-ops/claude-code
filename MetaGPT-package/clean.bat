@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

echo ============================================
echo   MetaGPT - Clean Runtime
echo   This will delete all downloaded runtimes
echo   and installed packages, then you can
echo   re-run start.bat for a fresh install.
echo ============================================
echo.
echo Press any key to clean, or close this window to cancel.
pause >nul

if exist "%~dp0runtime" (
    echo Cleaning runtime...
    rmdir /s /q "%~dp0runtime"
    echo [OK] Runtime cleaned.
) else (
    echo Nothing to clean.
)

echo.
echo Done. Run start.bat to reinstall.
pause
