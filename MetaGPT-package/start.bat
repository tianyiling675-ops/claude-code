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
REM  Step 1: Python Embedded (3.10)
REM ============================================
set PYTHON_VERSION=3.10.11
set PYTHON_DIR=%~dp0runtime\python
set PYTHON_EXE=%PYTHON_DIR%\python.exe
set PTH_FILE=%PYTHON_DIR%\python310._pth

if exist "%PYTHON_EXE%" goto python_ok

echo [1/6] Downloading Python %PYTHON_VERSION% ...
curl -L --progress-bar -o "%~dp0runtime\python.zip" "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
if !errorlevel! neq 0 goto err_python
if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"
echo    Extracting...
powershell -Command "Expand-Archive -Path '%~dp0runtime\python.zip' -DestinationPath '%PYTHON_DIR%' -Force"
del "%~dp0runtime\python.zip" 2>nul

REM Enable pip (only append once)
findstr /c:"import site" "%PTH_FILE%" >nul 2>&1
if !errorlevel! neq 0 echo import site>> "%PTH_FILE%"

echo    Installing pip...
curl -sL -o "%PYTHON_DIR%\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%PYTHON_EXE%" "%PYTHON_DIR%\get-pip.py" --quiet
del "%PYTHON_DIR%\get-pip.py" 2>nul

echo    Installing setuptools...
"%PYTHON_EXE%" -m pip install setuptools wheel --quiet

echo    [OK] Python %PYTHON_VERSION% installed
goto python_done

:err_python
echo [ERROR] Python download failed. Check your network.
pause
exit /b 1

:python_ok
echo [1/6] Python %PYTHON_VERSION% - OK

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
echo [2/6] Node.js %NODE_VERSION% - OK

:node_done
set PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%PATH%
call "%NODE_DIR%\npm.cmd" config set prefix "%NODE_DIR%" >nul 2>&1
echo.

REM ============================================
REM  Step 3: pnpm + mermaid-cli
REM ============================================
where pnpm >nul 2>&1
if !errorlevel! equ 0 goto pnpm_ok

echo [3/6] Installing pnpm...
call "%NODE_DIR%\npm.cmd" install -g pnpm --quiet 2>nul
echo    [OK] pnpm installed

:pnpm_ok
echo [3/6] pnpm - OK

where mmdc >nul 2>&1
if !errorlevel! equ 0 goto mermaid_ok
echo    Installing mermaid-cli (for diagrams)...
call "%NODE_DIR%\npm.cmd" install -g @mermaid-js/mermaid-cli --quiet 2>nul

:mermaid_ok
echo.

REM ============================================
REM  Step 4: MetaGPT
REM  Use pip --no-deps to skip resolution, then
REM  install core deps separately (avoids
REM  resolution-too-deep error)
REM ============================================
"%PYTHON_EXE%" -c "import metagpt" >nul 2>&1
if !errorlevel! equ 0 goto metagpt_ok

echo [4/6] Installing MetaGPT...

echo    Installing metagpt package...
"%PYTHON_EXE%" -m pip install metagpt --no-deps
if !errorlevel! neq 0 goto err_metagpt

echo    Installing core dependencies (1/3)...
"%PYTHON_EXE%" -m pip install "pydantic>=2.5.3" openai anthropic httpx tenacity aiohttp pyyaml loguru rich typer fire tiktoken
if !errorlevel! neq 0 goto err_metagpt

echo    Installing core dependencies (2/3)...
"%PYTHON_EXE%" -m pip install networkx gitpython beautifulsoup4 lxml tqdm pandas libcst socksio retry ta nbclient nbformat ipython ipykernel
if !errorlevel! neq 0 goto err_metagpt

echo    Installing core dependencies (3/3)...
"%PYTHON_EXE%" -m pip install scikit-learn redis boto3 zhipuai connexion qdrant-client lancedb selenium webdriver-manager
if !errorlevel! neq 0 echo    [WARNING] Some optional deps failed, continuing...

echo    [OK] MetaGPT installed
goto metagpt_done

:err_metagpt
echo [ERROR] MetaGPT install failed. Check your network and retry.
pause
exit /b 1

:metagpt_ok
echo [4/6] MetaGPT - OK

:metagpt_done
echo.

REM ============================================
REM  Step 5: Gradio (WebUI)
REM ============================================
"%PYTHON_EXE%" -c "import gradio" >nul 2>&1
if !errorlevel! equ 0 goto gradio_ok

echo [5/6] Installing WebUI components...
"%PYTHON_EXE%" -m pip install gradio pyyaml
if !errorlevel! neq 0 goto err_gradio
echo    [OK] WebUI installed
goto gradio_done

:err_gradio
echo [ERROR] Gradio install failed.
pause
exit /b 1

:gradio_ok
echo [5/6] WebUI - OK

:gradio_done
echo.

REM ============================================
REM  Step 6: Check config
REM ============================================
echo [6/6] Checking config...
set CONFIG_DIR=%USERPROFILE%\.metagpt
if exist "%CONFIG_DIR%\config2.yaml" goto config_ok
echo    First run - please set your API Key in the Settings tab.
goto config_done

:config_ok
echo    Config found: %CONFIG_DIR%\config2.yaml

:config_done
echo.

REM === Final verification ===
"%PYTHON_EXE%" -c "import metagpt; import gradio" >nul 2>&1
if !errorlevel! neq 0 goto err_final
goto launch

:err_final
echo [ERROR] Installation incomplete.
echo    Run clean.bat first, then start.bat again.
pause
exit /b 1

:launch
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
