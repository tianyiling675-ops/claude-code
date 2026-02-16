@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
title MetaGPT Launcher
cd /d "%~dp0"

echo ============================================
echo   MetaGPT - One Click Launcher
echo ============================================
echo.

REM === Create runtime directory ===
if not exist "%~dp0runtime" mkdir "%~dp0runtime"

REM ============================================
REM  Step 1: Python Embedded (3.10 - best compat)
REM ============================================
set PYTHON_VERSION=3.10.11
set PYTHON_DIR=%~dp0runtime\python
set PYTHON_EXE=%PYTHON_DIR%\python.exe
set PTH_FILE=%PYTHON_DIR%\python310._pth

if exist "%PYTHON_EXE%" goto python_ok

echo [1/7] Downloading Python %PYTHON_VERSION% ...
curl -L --progress-bar -o "%~dp0runtime\python.zip" "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
if !errorlevel! neq 0 goto err_python
if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"
echo    Extracting...
powershell -Command "Expand-Archive -Path '%~dp0runtime\python.zip' -DestinationPath '%PYTHON_DIR%' -Force"
del "%~dp0runtime\python.zip" 2>nul

REM Enable pip: append "import site" to ._pth (only if not already there)
findstr /c:"import site" "%PTH_FILE%" >nul 2>&1
if !errorlevel! neq 0 echo import site>> "%PTH_FILE%"

echo    Installing pip...
curl -sL -o "%PYTHON_DIR%\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%PYTHON_EXE%" "%PYTHON_DIR%\get-pip.py" --quiet
del "%PYTHON_DIR%\get-pip.py" 2>nul

REM Install setuptools + wheel (needed for building some packages)
echo    Installing setuptools...
"%PYTHON_EXE%" -m pip install setuptools wheel --quiet

echo    [OK] Python %PYTHON_VERSION% installed
goto python_done

:err_python
echo [ERROR] Python download failed. Check your network.
pause
exit /b 1

:python_ok
echo [1/7] Python %PYTHON_VERSION% - OK

:python_done
echo.

REM ============================================
REM  Step 2: Node.js Portable
REM ============================================
set NODE_VERSION=20.11.1
set NODE_DIR=%~dp0runtime\node

if exist "%NODE_DIR%\node.exe" goto node_ok

echo [2/7] Downloading Node.js %NODE_VERSION% ...
curl -L --progress-bar -o "%~dp0runtime\node.zip" "https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip"
if !errorlevel! neq 0 goto err_node
if not exist "%NODE_DIR%" mkdir "%NODE_DIR%"
echo    Extracting...
powershell -Command "Expand-Archive -Path '%~dp0runtime\node.zip' -DestinationPath '%~dp0runtime\temp' -Force"
robocopy "%~dp0runtime\temp\node-v%NODE_VERSION%-win-x64" "%NODE_DIR%" /E /MOVE >nul 2>&1
rmdir /s /q "%~dp0runtime\temp" 2>nul
del "%~dp0runtime\node.zip" 2>nul
echo    [OK] Node.js %NODE_VERSION% installed
goto node_done

:err_node
echo [ERROR] Node.js download failed. Check your network.
pause
exit /b 1

:node_ok
echo [2/7] Node.js %NODE_VERSION% - OK

:node_done
set PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%PATH%
REM Set npm global prefix to portable node dir
call "%NODE_DIR%\npm.cmd" config set prefix "%NODE_DIR%" >nul 2>&1
echo.

REM ============================================
REM  Step 3: uv (fast Python package manager)
REM ============================================
set UV_EXE=%~dp0runtime\uv.exe

if exist "%UV_EXE%" goto uv_ok

echo [3/7] Downloading uv package manager...
curl -sL -o "%~dp0runtime\uv.zip" "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip"
if !errorlevel! neq 0 goto err_uv
powershell -Command "Expand-Archive -Path '%~dp0runtime\uv.zip' -DestinationPath '%~dp0runtime\uv-temp' -Force"
copy "%~dp0runtime\uv-temp\uv.exe" "%UV_EXE%" >nul 2>&1
rmdir /s /q "%~dp0runtime\uv-temp" 2>nul
del "%~dp0runtime\uv.zip" 2>nul
echo    [OK] uv installed
goto uv_done

:err_uv
echo [WARNING] uv download failed, will use pip as fallback.
goto uv_done

:uv_ok
echo [3/7] uv - OK

:uv_done
echo.

REM ============================================
REM  Step 4: pnpm + mermaid-cli
REM ============================================
where pnpm >nul 2>&1
if !errorlevel! equ 0 goto pnpm_ok

echo [4/7] Installing pnpm...
call "%NODE_DIR%\npm.cmd" install -g pnpm --quiet 2>nul
echo    [OK] pnpm installed

:pnpm_ok
echo [4/7] pnpm - OK

REM Install mermaid-cli (MetaGPT uses it for diagrams)
where mmdc >nul 2>&1
if !errorlevel! equ 0 goto mermaid_ok
echo    Installing mermaid-cli (for diagrams)...
call "%NODE_DIR%\npm.cmd" install -g @mermaid-js/mermaid-cli --quiet 2>nul

:mermaid_ok
echo.

REM ============================================
REM  Step 5: MetaGPT
REM ============================================
"%PYTHON_EXE%" -c "import metagpt" >nul 2>&1
if !errorlevel! equ 0 goto metagpt_ok

echo [5/7] Installing MetaGPT (this may take a few minutes)...

REM Try uv first (much faster, handles complex deps better)
if exist "%UV_EXE%" (
    echo    Using uv for fast installation...
    "%UV_EXE%" pip install metagpt --python "%PYTHON_EXE%"
    if !errorlevel! equ 0 goto metagpt_installed
    echo    uv failed, trying pip fallback...
)

REM Fallback: pip
"%PYTHON_EXE%" -m pip install metagpt
if !errorlevel! equ 0 goto metagpt_installed

REM Last resort: pip with --no-deps + manual core deps
echo    Standard install failed, trying minimal install...
"%PYTHON_EXE%" -m pip install metagpt --no-deps --quiet
"%PYTHON_EXE%" -m pip install openai anthropic pydantic typer fire aiohttp loguru rich tenacity tiktoken pyyaml networkx gitpython nbclient nbformat ipython ipykernel scikit-learn beautifulsoup4 lxml retry ta libcst socksio tqdm pandas --quiet
if !errorlevel! neq 0 goto err_metagpt

:metagpt_installed
echo    [OK] MetaGPT installed
goto metagpt_done

:err_metagpt
echo [ERROR] MetaGPT install failed. Check your network and retry.
pause
exit /b 1

:metagpt_ok
echo [5/7] MetaGPT - OK

:metagpt_done
echo.

REM ============================================
REM  Step 6: Gradio (WebUI)
REM ============================================
"%PYTHON_EXE%" -c "import gradio" >nul 2>&1
if !errorlevel! equ 0 goto gradio_ok

echo [6/7] Installing WebUI components...
if exist "%UV_EXE%" (
    "%UV_EXE%" pip install gradio pyyaml --python "%PYTHON_EXE%" --quiet
) else (
    "%PYTHON_EXE%" -m pip install gradio pyyaml --quiet
)
echo    [OK] WebUI installed

goto gradio_done

:gradio_ok
echo [6/7] WebUI - OK

:gradio_done
echo.

REM ============================================
REM  Step 7: Check config
REM ============================================
echo [7/7] Checking config...
set CONFIG_DIR=%USERPROFILE%\.metagpt
if exist "%CONFIG_DIR%\config2.yaml" goto config_ok
echo    First run - please set your API Key in the Settings tab.
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
