@echo off
title AI Video Transcriber

echo ============================================
echo   AI Video Transcriber - One-Click Installer
echo   Video Transcription and AI Summary Tool
echo ============================================
echo.

:: ============================================
:: Step 1: Check Python, Git, and FFmpeg
:: ============================================

set "PYTHON_CMD="
set "NEED_RESTART=0"

:: Check Python (try py launcher first, then fallback to python)
py -3 --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=py -3"
    goto :python_found
)

python --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2 delims= " %%v in ('python --version 2^>nul') do (
        echo %%v | findstr /b "3." >nul
        if not errorlevel 1 (
            set "PYTHON_CMD=python"
        )
    )
)

:python_found
if not defined PYTHON_CMD (
    echo [INFO] Python not found. Installing Python 3.11 automatically...
    echo        This may take 1-2 minutes, please wait.
    echo.
    winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to install Python automatically.
        echo Please download and install manually from https://www.python.org/downloads/
        echo IMPORTANT: Check "Add Python to PATH" during installation!
        echo After installation, double-click this file again.
        pause
        exit /b 1
    )
    echo.
    echo [OK] Python installed successfully!
    set "NEED_RESTART=1"
) else (
    echo [OK] Python detected
    for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo     %%v
)
echo.

:: Check Git
git --version >nul 2>&1
if errorlevel 1 (
    echo [INFO] Git not found. Installing Git automatically...
    echo.
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to install Git automatically.
        echo Please download and install manually from https://git-scm.com/downloads
        echo After installation, double-click this file again.
        pause
        exit /b 1
    )
    echo.
    echo [OK] Git installed successfully!
    set "NEED_RESTART=1"
) else (
    echo [OK] Git detected
)
echo.

:: Check FFmpeg
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [INFO] FFmpeg not found (required for audio/video processing). Installing...
    echo.
    winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to install FFmpeg automatically.
        echo Please download and install manually from https://ffmpeg.org/download.html
        echo Make sure ffmpeg.exe is added to your system PATH.
        echo After installation, double-click this file again.
        pause
        exit /b 1
    )
    echo.
    echo [OK] FFmpeg installed successfully!
    set "NEED_RESTART=1"
) else (
    echo [OK] FFmpeg detected
)
echo.

:: If anything was just installed, need to restart for PATH to take effect
if "%NEED_RESTART%"=="1" (
    echo ================================================
    echo   New components were installed. A restart is
    echo   needed for changes to take effect.
    echo   Please close this window and double-click
    echo   this file again.
    echo ================================================
    pause
    exit /b 0
)

:: ============================================
:: Step 2: Clone project repository
:: ============================================

if not exist "AI-Video-Transcriber" (
    echo [1/4] Cloning project repository...
    echo.
    git clone https://github.com/wendy7756/AI-Video-Transcriber.git
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to clone repository. Please check your network connection.
        pause
        exit /b 1
    )
    echo.
    echo       Done!
    echo.
) else (
    echo [1/4] Project already exists, skipping clone
    echo.
)

cd AI-Video-Transcriber

:: ============================================
:: Step 3: Create virtual environment and install dependencies
:: ============================================

if not exist "venv" (
    echo [2/4] Creating virtual environment...
    %PYTHON_CMD% -m venv venv
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to create virtual environment. Please check Python installation.
        pause
        exit /b 1
    )
    echo       Done!
    echo.
)

call venv\Scripts\activate.bat

echo [3/4] Installing dependencies...
echo.
echo ================================================
echo   First-time setup needs to download speech
echo   recognition models and other packages.
echo   This may take 5-10 minutes, please wait.
echo   Do NOT close this window!
echo ================================================
echo.

pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to install dependencies.
    echo Possible causes:
    echo   - Unstable network connection, please check and retry
    echo   - Insufficient disk space, at least 2GB free space required
    echo.
    echo You can double-click this file to try again.
    pause
    exit /b 1
)

echo.
echo [OK] All dependencies installed!
echo.

:: ============================================
:: Step 4: Configure API Key and launch
:: ============================================

echo [4/4] Preparing to launch...
echo.
echo ================================================
echo.
echo   About AI Summary Feature:
echo.
echo   Video transcription (speech-to-text) works
echo   out of the box, no configuration needed.
echo.
echo   However, to use the AI-powered summary
echo   feature, you need an OpenAI API Key.
echo   Without a Key, the tool still works fine
echo   for basic transcription.
echo.
echo ================================================
echo.

set "OPENAI_API_KEY="
set /p "OPENAI_API_KEY=Enter your OpenAI API Key (or press Enter to skip): "
echo.

if defined OPENAI_API_KEY (
    echo [OK] API Key set. AI summary feature enabled.
) else (
    echo [INFO] No API Key set. Running in basic mode (transcription only, no summary).
)
echo.

echo ================================================
echo   Starting AI Video Transcriber...
echo.
echo   Opening browser... If it does not open
echo   automatically, please visit:
echo   http://localhost:8000
echo.
echo   Close this window to stop the application.
echo ================================================
echo.

start "" http://localhost:8000
python start.py

pause
