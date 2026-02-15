@echo off
chcp 65001 >nul 2>&1
title {PROJECT_NAME} Launcher
cd /d "%~dp0"

echo ============================================
echo   {PROJECT_NAME} - One Click Launcher
echo ============================================
echo.

REM ============================================
REM  Step 1: Check/Install Runtime
REM ============================================
REM {RUNTIME_SETUP_SECTION}

REM ============================================
REM  Step 2: Install Dependencies
REM ============================================
REM {DEPS_INSTALL_SECTION}

REM ============================================
REM  Step 3: Launch Application
REM ============================================
echo Starting {PROJECT_NAME}...
echo.

REM {LAUNCH_SECTION}

REM ============================================
REM  Step 4: Open WebUI in Browser
REM ============================================
REM {BROWSER_OPEN_SECTION}

echo.
echo Press any key to exit...
pause >nul
