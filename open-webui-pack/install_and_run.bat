@echo off
title Open WebUI

echo ============================================
echo   Open WebUI 一键整合包
echo   一个类似 ChatGPT 的本地 AI 对话平台
echo ============================================
echo.

:: ============================================
:: 第一步：检测 Python 3.11
:: ============================================

set "PYTHON_CMD="

:: 优先尝试 py launcher（支持多版本共存）
py -3.11 --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=py -3.11"
    goto :python_ok
)

:: fallback：检查 python 命令是否为 3.11
for /f "tokens=2 delims= " %%v in ('python --version 2^>nul') do (
    echo %%v | findstr /b "3.11" >nul
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
        goto :python_ok
    )
)

:: 没有找到 Python 3.11，尝试自动安装
echo [提示] 未检测到 Python 3.11，正在为您自动安装...
echo        这需要大约 1-2 分钟，请耐心等待。
echo.
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
    echo.
    echo [错误] 自动安装 Python 3.11 失败。
    echo.
    echo 请手动安装 Python 3.11：
    echo   1. 打开 https://www.python.org/downloads/release/python-3110/
    echo   2. 下载 Windows installer (64-bit)
    echo   3. 安装时务必勾选最下面的 "Add Python to PATH"
    echo   4. 安装完成后，重新双击本程序
    echo.
    pause
    exit /b 1
)

echo.
echo [完成] Python 3.11 安装成功！
echo        请关闭此窗口，然后重新双击本程序启动。
echo.
pause
exit /b 0

:python_ok
echo [√] 已检测到 Python 3.11
for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo     %%v
echo.

:: ============================================
:: 第二步：创建虚拟环境
:: ============================================

if not exist "venv" (
    echo [1/3] 正在创建专属运行环境...
    %PYTHON_CMD% -m venv venv
    if errorlevel 1 (
        echo.
        echo [错误] 创建虚拟环境失败，请检查 Python 3.11 是否安装完整。
        pause
        exit /b 1
    )
    echo       完成！
    echo.
)

:: 激活虚拟环境
call venv\Scripts\activate.bat

:: ============================================
:: 第三步：安装 Open WebUI
:: ============================================

echo [2/3] 正在安装 Open WebUI...
echo.
echo ================================================
echo   首次安装需要下载约 500MB 的依赖文件
echo   可能需要 5-10 分钟，请耐心等待
echo   请不要关闭此窗口！
echo ================================================
echo.

pip install open-webui
if errorlevel 1 (
    echo.
    echo [错误] 安装 Open WebUI 失败。
    echo.
    echo 可能的原因：
    echo   - 网络连接不稳定，请检查网络后重试
    echo   - 磁盘空间不足，请确保至少有 2GB 可用空间
    echo.
    echo 你可以重新双击本程序再试一次。
    pause
    exit /b 1
)

echo.
echo [√] Open WebUI 安装完成！
echo.

:: ============================================
:: 第四步：打印使用引导 & 启动
:: ============================================

echo [3/3] 正在启动 Open WebUI...
echo.
echo ================================================
echo.
echo   浏览器打开后，您需要先注册一个本地管理员账号，
echo   然后配置 AI 模型来源才能开始对话：
echo.
echo   方式一：使用 OpenAI API
echo     → 点击左下角头像 → 管理员面板 → 设置
echo     → 找到"连接(Connections)"，填入您的 API Key
echo.
echo   方式二：使用本地 Ollama（免费）
echo     → 先去 https://ollama.com 下载安装 Ollama
echo     → 运行 Ollama 后，Open WebUI 会自动识别
echo     → 在 Open WebUI 里选择模型即可对话
echo.
echo ================================================
echo.
echo   正在打开浏览器... 如果没有自动打开，
echo   请手动访问：http://localhost:8080
echo.
echo   关闭此黑色窗口即可停止程序。
echo.
echo ================================================
echo.

:: 先打开浏览器，再启动服务（延迟 3 秒让服务有时间启动）
start "" http://localhost:8080
open-webui serve

pause
