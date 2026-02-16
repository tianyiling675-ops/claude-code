@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
title MetaGPT Launcher
cd /d "%~dp0"

echo ============================================
echo   MetaGPT - One Click Launcher
echo   Multi-Agent Framework
echo ============================================
echo.

REM === Create runtime directory ===
if not exist "%~dp0runtime" mkdir "%~dp0runtime"

REM ============================================
REM  Step 1: Python Embedded
REM ============================================
set PYTHON_VERSION=3.11.9
set PYTHON_DIR=%~dp0runtime\python
set PYTHON_EXE=%PYTHON_DIR%\python.exe

if exist "%PYTHON_EXE%" goto python_ok
echo [1/6] Downloading Python %PYTHON_VERSION% ...
curl -L --progress-bar -o "%~dp0runtime\python.zip" "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
if !errorlevel! neq 0 (
    echo [ERROR] Python download failed. Check your network.
    pause
    exit /b 1
)
if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"
echo    Extracting...
powershell -Command "Expand-Archive -Path '%~dp0runtime\python.zip' -DestinationPath '%PYTHON_DIR%' -Force"
del "%~dp0runtime\python.zip" 2>nul

REM Enable pip for embedded Python
echo import site>> "%PYTHON_DIR%\python311._pth"
echo    Installing pip...
curl -sL -o "%PYTHON_DIR%\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%PYTHON_EXE%" "%PYTHON_DIR%\get-pip.py" --quiet
del "%PYTHON_DIR%\get-pip.py" 2>nul
echo    [OK] Python %PYTHON_VERSION% installed
goto python_done

:python_ok
echo [1/6] Python %PYTHON_VERSION% - already installed, skip

:python_done
echo.

REM ============================================
REM  Step 2: Node.js Portable
REM ============================================
set NODE_VERSION=20.11.1
set NODE_DIR=%~dp0runtime\node

if exist "%NODE_DIR%\node.exe" goto node_ok
echo [2/6] Downloading Node.js %NODE_VERSION% ...
curl -L --progress-bar -o "%~dp0runtime\node.zip" "https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip"
if !errorlevel! neq 0 (
    echo [ERROR] Node.js download failed. Check your network.
    pause
    exit /b 1
)
if not exist "%NODE_DIR%" mkdir "%NODE_DIR%"
echo    Extracting...
powershell -Command "Expand-Archive -Path '%~dp0runtime\node.zip' -DestinationPath '%~dp0runtime\temp' -Force"
robocopy "%~dp0runtime\temp\node-v%NODE_VERSION%-win-x64" "%NODE_DIR%" /E /MOVE >nul 2>&1
rmdir /s /q "%~dp0runtime\temp" 2>nul
del "%~dp0runtime\node.zip" 2>nul
echo    [OK] Node.js %NODE_VERSION% installed
goto node_done

:node_ok
echo [2/6] Node.js %NODE_VERSION% - already installed, skip

:node_done
set PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%PATH%
echo.

REM ============================================
REM  Step 3: pnpm
REM ============================================
where pnpm >nul 2>&1
if !errorlevel! equ 0 goto pnpm_ok
echo [3/6] Installing pnpm...
call "%NODE_DIR%\npm.cmd" install -g pnpm --quiet 2>nul
echo    [OK] pnpm installed
goto pnpm_done

:pnpm_ok
echo [3/6] pnpm - already installed, skip

:pnpm_done
echo.

REM ============================================
REM  Step 4: MetaGPT
REM ============================================
"%PYTHON_EXE%" -c "import metagpt" >nul 2>&1
if !errorlevel! equ 0 goto metagpt_ok
echo [4/6] Installing MetaGPT (this may take a few minutes)...
"%PYTHON_EXE%" -m pip install metagpt
if !errorlevel! neq 0 (
    echo [ERROR] MetaGPT install failed. Check your network and retry.
    pause
    exit /b 1
)
echo    [OK] MetaGPT installed
goto metagpt_done

:metagpt_ok
echo [4/6] MetaGPT - already installed, skip

:metagpt_done
echo.

REM ============================================
REM  Step 5: Gradio (WebUI)
REM ============================================
"%PYTHON_EXE%" -c "import gradio" >nul 2>&1
if !errorlevel! equ 0 goto gradio_ok
echo [5/6] Installing WebUI components...
"%PYTHON_EXE%" -m pip install --quiet "gradio>=4.0"
echo    [OK] WebUI components installed
goto gradio_done

:gradio_ok
echo [5/6] WebUI components - already installed, skip

:gradio_done
echo.

REM ============================================
REM  Step 6: Check config
REM ============================================
echo [6/6] Checking config...
set CONFIG_DIR=%USERPROFILE%\.metagpt
if exist "%CONFIG_DIR%\config2.yaml" goto config_ok
echo    First time use. Please configure your API Key in WebUI Settings tab.
goto config_done

:config_ok
echo    Config found: %CONFIG_DIR%\config2.yaml

:config_done
echo.

REM ============================================
REM  Launch WebUI
REM ============================================
echo ============================================
echo   Starting MetaGPT WebUI...
echo   Browser will open automatically.
echo   If not, visit: http://localhost:7860
echo ============================================
echo.
echo   Press Ctrl+C to stop
echo.

"%PYTHON_EXE%" "%~dp0webui.py"

echo.
echo MetaGPT stopped.
pause
