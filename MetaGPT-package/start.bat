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

if not exist "%PYTHON_EXE%" goto python_install

REM Python exists - but verify pip works (may be broken from previous run)
"%PYTHON_EXE%" -m pip --version >nul 2>&1
if !errorlevel! equ 0 goto python_ok
echo [1/6] Python found but pip broken, fixing...
goto fix_pth

:python_install
echo [1/6] Downloading Python %PYTHON_VERSION% ...
curl -L --progress-bar -o "%~dp0runtime\python.zip" "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
if !errorlevel! neq 0 goto err_python
if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"
echo    Extracting...
powershell -Command "Expand-Archive -Path '%~dp0runtime\python.zip' -DestinationPath '%PYTHON_DIR%' -Force"
del "%~dp0runtime\python.zip" 2>nul

:fix_pth
REM *** CRITICAL: Enable site-packages in embedded Python ***
REM The default ._pth has "#import site" (commented out).
REM Step A: Uncomment it using powershell regex
powershell -Command "if(Test-Path '%PTH_FILE%'){(Get-Content '%PTH_FILE%') -replace '^#import site','import site' | Set-Content '%PTH_FILE%'}"
REM Step B: If "import site" still not there as a whole line, append it
findstr /x /c:"import site" "%PTH_FILE%" >nul 2>&1
if !errorlevel! neq 0 echo import site>> "%PTH_FILE%"

REM Verify site-packages works
"%PYTHON_EXE%" -c "import site; print(site.getsitepackages())" >nul 2>&1
if !errorlevel! neq 0 goto err_python

echo    Installing pip...
curl -sL -o "%PYTHON_DIR%\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%PYTHON_EXE%" "%PYTHON_DIR%\get-pip.py"
if !errorlevel! neq 0 goto err_python
del "%PYTHON_DIR%\get-pip.py" 2>nul

REM Verify pip actually works
"%PYTHON_EXE%" -m pip --version >nul 2>&1
if !errorlevel! neq 0 goto err_python

echo    Installing setuptools...
"%PYTHON_EXE%" -m pip install --prefer-binary setuptools wheel
if !errorlevel! neq 0 goto err_python

echo    [OK] Python %PYTHON_VERSION% installed
goto python_done

:err_python
echo [ERROR] Python setup failed.
echo    Run clean.bat and try again.
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
REM  Step 4: Gradio WebUI (install FIRST)
REM ============================================
REM Install Gradio before MetaGPT deps to ensure Gradio's
REM dependency tree is set up correctly and not broken by
REM conflicting package versions from MetaGPT.

"%PYTHON_EXE%" -c "import gradio" >nul 2>&1
if !errorlevel! equ 0 goto gradio_ok

echo [4/6] Installing WebUI (Gradio)...
"%PYTHON_EXE%" -m pip install --prefer-binary gradio
if !errorlevel! neq 0 goto err_gradio

REM Verify Gradio import immediately after install
"%PYTHON_EXE%" -c "import gradio; print('    Gradio', gradio.__version__, '- OK')"
if !errorlevel! neq 0 (
    echo    [WARN] Gradio import failed, attempting reinstall...
    "%PYTHON_EXE%" -m pip install --prefer-binary --force-reinstall gradio
    "%PYTHON_EXE%" -c "import gradio" >nul 2>&1
    if !errorlevel! neq 0 goto err_gradio
)

echo    [OK] WebUI installed
goto gradio_done

:err_gradio
echo [ERROR] Gradio install failed.
echo    Showing error details:
"%PYTHON_EXE%" -c "import gradio"
pause
exit /b 1

:gradio_ok
echo [4/6] WebUI (Gradio) - OK

:gradio_done
echo.

REM ============================================
REM  Step 5: MetaGPT + Dependencies
REM ============================================
REM MetaGPT is installed with --no-deps to avoid pulling
REM conflicting versions. Then deps are installed manually
REM with version pins to avoid breaking Gradio.

"%PYTHON_EXE%" -c "import metagpt" >nul 2>&1
if !errorlevel! equ 0 goto metagpt_ok

echo [5/6] Installing MetaGPT...

echo    Installing metagpt package (no-deps)...
"%PYTHON_EXE%" -m pip install --prefer-binary metagpt --no-deps
if !errorlevel! neq 0 goto err_metagpt

echo    Creating semantic_kernel stub...
REM MetaGPT 0.8.2 _compat.py does: from semantic_kernel.orchestration import sk_function
REM This is only for side-effects (Windows asyncio event loop fix), not actual usage.
REM The original requirement was semantic-kernel==0.4.3.dev0 (old dev pre-release),
REM which conflicts with modern packages. A minimal stub satisfies the import.
"%PYTHON_EXE%" -c "import site,os;sp=site.getsitepackages()[0];b=os.path.join(sp,'semantic_kernel');o=os.path.join(b,'orchestration');os.makedirs(o,exist_ok=True);[open(os.path.join(*p),'a').close() for p in [(b,'__init__.py'),(o,'__init__.py'),(o,'sk_function.py')]];print('    [OK] semantic_kernel stub created')"

echo    Installing core dependencies (1/3)...
REM Pin numpy<2 - MetaGPT 0.8.x requires numpy<2.0
REM Pin websocket-client - MetaGPT 0.8.x requires ~=1.8.0
"%PYTHON_EXE%" -m pip install --prefer-binary "pydantic>=2.5.3" "numpy<2" openai anthropic httpx tenacity aiohttp pyyaml loguru rich typer fire tiktoken "websocket-client>=1.8.0,<1.9.0"
if !errorlevel! neq 0 goto err_metagpt

echo    Installing core dependencies (2/3)...
"%PYTHON_EXE%" -m pip install --prefer-binary networkx gitpython beautifulsoup4 lxml tqdm "pandas<2.2" libcst socksio retry ta nbclient nbformat ipython ipykernel
if !errorlevel! neq 0 goto err_metagpt

echo    Installing optional dependencies (3/3)...
"%PYTHON_EXE%" -m pip install --prefer-binary scikit-learn --quiet 2>nul
"%PYTHON_EXE%" -m pip install --prefer-binary redis --quiet 2>nul
"%PYTHON_EXE%" -m pip install --prefer-binary boto3 --quiet 2>nul
"%PYTHON_EXE%" -m pip install --prefer-binary selenium webdriver-manager --quiet 2>nul
"%PYTHON_EXE%" -m pip install --prefer-binary zhipuai --quiet 2>nul

echo    [OK] MetaGPT installed
goto metagpt_done

:err_metagpt
echo [ERROR] MetaGPT install failed. Check your network and retry.
pause
exit /b 1

:metagpt_ok
echo [5/6] MetaGPT - OK

:metagpt_done
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
echo Verifying installation...

REM Re-verify Gradio after MetaGPT deps install (deps may have broken it)
"%PYTHON_EXE%" -c "import gradio; print('  Gradio', gradio.__version__)" 2>nul
if !errorlevel! neq 0 (
    echo [WARN] MetaGPT deps broke Gradio. Repairing...
    "%PYTHON_EXE%" -m pip install --prefer-binary --force-reinstall gradio
    "%PYTHON_EXE%" -c "import gradio; print('  Gradio', gradio.__version__)" 2>nul
    if !errorlevel! neq 0 goto err_gradio_verify
)

REM Check metagpt (non-critical for WebUI launch - just warn)
"%PYTHON_EXE%" -c "import metagpt" 2>nul
if !errorlevel! neq 0 goto warn_metagpt
goto verify_done

:err_gradio_verify
echo [ERROR] Gradio not working. Showing error details:
"%PYTHON_EXE%" -c "import gradio"
echo.
echo Try running clean.bat then start.bat again.
pause
exit /b 1

:warn_metagpt
echo [WARN] MetaGPT import has issues, but WebUI can still start.
echo        You may see errors when generating projects.
echo.

:verify_done
echo All good!
echo.

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
