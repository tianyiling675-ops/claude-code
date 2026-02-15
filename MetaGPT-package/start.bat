@echo off
chcp 65001 >nul 2>&1
title MetaGPT 一键启动器
cd /d "%~dp0"

echo ╔══════════════════════════════════════════════╗
echo ║         MetaGPT 一键启动整合包              ║
echo ║     多智能体协作框架 - 让AI帮你写代码       ║
echo ╚══════════════════════════════════════════════╝
echo.

REM ============================================
REM  第一步：安装/检查 Python 便携版
REM ============================================
set PYTHON_VERSION=3.11.9
set PYTHON_DIR=%~dp0runtime\python
set PYTHON="%PYTHON_DIR%\python.exe"
set PIP="%PYTHON_DIR%\python.exe" -m pip

if not exist "%PYTHON_DIR%\python.exe" (
    echo [1/6] 正在下载 Python %PYTHON_VERSION% 便携版...
    curl -L --progress-bar -o "%~dp0runtime\python.zip" "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
    if %errorlevel% neq 0 (
        echo [错误] Python 下载失败，请检查网络连接。
        pause
        exit /b 1
    )
    mkdir "%PYTHON_DIR%" 2>nul
    echo    正在解压...
    powershell -Command "Expand-Archive -Path '%~dp0runtime\python.zip' -DestinationPath '%PYTHON_DIR%' -Force"
    del "%~dp0runtime\python.zip"

    REM 启用 pip（嵌入版 Python 默认不支持 pip，需要手动开启）
    echo import site>> "%PYTHON_DIR%\python311._pth"
    echo    正在安装 pip...
    curl -sL -o "%PYTHON_DIR%\get-pip.py" https://bootstrap.pypa.io/get-pip.py
    %PYTHON% "%PYTHON_DIR%\get-pip.py" --quiet 2>nul
    del "%PYTHON_DIR%\get-pip.py" 2>nul
    echo    [完成] Python %PYTHON_VERSION% 已安装
) else (
    echo [1/6] Python %PYTHON_VERSION% 已存在，跳过
)
echo.

REM ============================================
REM  第二步：安装/检查 Node.js 便携版
REM ============================================
set NODE_VERSION=20.11.1
set NODE_DIR=%~dp0runtime\node

if not exist "%NODE_DIR%\node.exe" (
    echo [2/6] 正在下载 Node.js %NODE_VERSION% 便携版...
    curl -L --progress-bar -o "%~dp0runtime\node.zip" "https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip"
    if %errorlevel% neq 0 (
        echo [错误] Node.js 下载失败，请检查网络连接。
        pause
        exit /b 1
    )
    mkdir "%NODE_DIR%" 2>nul
    echo    正在解压...
    powershell -Command "Expand-Archive -Path '%~dp0runtime\node.zip' -DestinationPath '%~dp0runtime\temp' -Force"
    robocopy "%~dp0runtime\temp\node-v%NODE_VERSION%-win-x64" "%NODE_DIR%" /E /MOVE >nul 2>&1
    rmdir /s /q "%~dp0runtime\temp" 2>nul
    del "%~dp0runtime\node.zip"
    echo    [完成] Node.js %NODE_VERSION% 已安装
) else (
    echo [2/6] Node.js %NODE_VERSION% 已存在，跳过
)

set PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%PATH%
echo.

REM ============================================
REM  第三步：安装 pnpm 和 mermaid-cli
REM ============================================
if not exist "%NODE_DIR%\node_modules\pnpm" (
    echo [3/6] 正在安装 pnpm...
    call "%NODE_DIR%\npm.cmd" install -g pnpm --quiet 2>nul
    echo    [完成] pnpm 已安装
) else (
    echo [3/6] pnpm 已存在，跳过
)
echo.

REM ============================================
REM  第四步：安装 MetaGPT
REM ============================================
if not exist "%PYTHON_DIR%\Lib\site-packages\metagpt" (
    echo [4/6] 正在安装 MetaGPT（这可能需要几分钟）...
    %PIP% install --quiet metagpt
    if %errorlevel% neq 0 (
        echo [错误] MetaGPT 安装失败。
        echo    尝试重新安装...
        %PIP% install metagpt
        if %errorlevel% neq 0 (
            echo [错误] 安装失败，请检查网络连接后重试。
            pause
            exit /b 1
        )
    )
    echo    [完成] MetaGPT 已安装
) else (
    echo [4/6] MetaGPT 已存在，跳过
)
echo.

REM ============================================
REM  第五步：安装 WebUI 依赖（Gradio）
REM ============================================
if not exist "%PYTHON_DIR%\Lib\site-packages\gradio" (
    echo [5/6] 正在安装 WebUI 界面组件...
    %PIP% install --quiet "gradio>=4.0"
    echo    [完成] WebUI 组件已安装
) else (
    echo [5/6] WebUI 组件已存在，跳过
)
echo.

REM ============================================
REM  第六步：检查配置文件
REM ============================================
echo [6/6] 检查配置...
set CONFIG_DIR=%USERPROFILE%\.metagpt
if not exist "%CONFIG_DIR%\config2.yaml" (
    echo    [提示] 首次使用，将打开 WebUI 进行配置。
    echo    请在 WebUI 的"设置"页面配置你的 API Key。
) else (
    echo    配置文件已存在: %CONFIG_DIR%\config2.yaml
)
echo.

REM ============================================
REM  启动 WebUI
REM ============================================
echo ============================================
echo   正在启动 MetaGPT WebUI...
echo   浏览器将自动打开，如未打开请访问:
echo   http://localhost:7860
echo ============================================
echo.
echo   按 Ctrl+C 可停止程序
echo.

%PYTHON% "%~dp0webui.py"

echo.
echo MetaGPT 已停止运行。
pause
