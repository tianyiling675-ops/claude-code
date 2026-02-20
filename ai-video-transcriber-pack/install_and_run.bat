@echo off
title AI Video Transcriber

echo ============================================
echo   AI Video Transcriber 一键整合包
echo   AI 驱动的视频转录与智能摘要工具
echo ============================================
echo.

:: ============================================
:: 第一步：检测 Python 和 FFmpeg
:: ============================================

set "PYTHON_CMD="
set "NEED_RESTART=0"

:: 检测 Python（优先 py launcher，再 fallback python 命令）
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
    echo [提示] 未检测到 Python，正在为您自动安装 Python 3.11...
    echo        这需要大约 1-2 分钟，请耐心等待。
    echo.
    winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo [错误] 自动安装 Python 失败。
        echo 请手动去 https://www.python.org/downloads/ 下载安装。
        echo 安装时记得勾选最下面的 "Add Python to PATH"！
        echo 安装完成后，重新双击本程序。
        pause
        exit /b 1
    )
    echo.
    echo [完成] Python 安装成功！
    set "NEED_RESTART=1"
) else (
    echo [√] 已检测到 Python
    for /f "tokens=*" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo     %%v
)
echo.

:: 检测 FFmpeg
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [提示] 未检测到 FFmpeg（视频音频处理必需），正在为您自动安装...
    echo.
    winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo [错误] 自动安装 FFmpeg 失败。
        echo 请手动去 https://ffmpeg.org/download.html 下载安装，
        echo 并确保 ffmpeg.exe 所在目录已添加到系统 PATH 环境变量。
        echo 安装完成后，重新双击本程序。
        pause
        exit /b 1
    )
    echo.
    echo [完成] FFmpeg 安装成功！
    set "NEED_RESTART=1"
) else (
    echo [√] 已检测到 FFmpeg
)
echo.

:: 如果本次新安装了 Python 或 FFmpeg，需要重启才能生效
if "%NEED_RESTART%"=="1" (
    echo ================================================
    echo   刚刚安装了新的组件，需要重新启动才能生效。
    echo   请关闭此窗口，然后重新双击本程序。
    echo ================================================
    pause
    exit /b 0
)

:: ============================================
:: 第二步：下载项目文件（如果还没有）
:: ============================================

if not exist "start.py" (
    echo [1/4] 正在下载项目文件...
    echo.
    powershell -Command ^
        "Invoke-WebRequest -Uri 'https://github.com/wendy7756/AI-Video-Transcriber/archive/refs/heads/main.zip' -OutFile 'project.zip'; ^
         Expand-Archive -Path 'project.zip' -DestinationPath '.' -Force; ^
         Get-ChildItem 'AI-Video-Transcriber-main\*' | Move-Item -Destination '.' -Force; ^
         Remove-Item 'AI-Video-Transcriber-main' -Force -ErrorAction SilentlyContinue; ^
         Remove-Item 'project.zip' -Force"
    if not exist "start.py" (
        echo.
        echo [错误] 下载项目文件失败，请检查网络连接后重试。
        pause
        exit /b 1
    )
    echo       完成！
    echo.
) else (
    echo [1/4] 项目文件已存在，跳过下载
    echo.
)

:: ============================================
:: 第三步：创建虚拟环境并安装依赖
:: ============================================

if not exist "venv" (
    echo [2/4] 正在创建专属运行环境...
    %PYTHON_CMD% -m venv venv
    if errorlevel 1 (
        echo.
        echo [错误] 创建虚拟环境失败，请检查 Python 是否安装完整。
        pause
        exit /b 1
    )
    echo       完成！
    echo.
)

call venv\Scripts\activate.bat

echo [3/4] 正在安装依赖...
echo.
echo ================================================
echo   首次安装需要下载语音识别模型等依赖
echo   可能需要 5-10 分钟，请耐心等待
echo   请不要关闭此窗口！
echo ================================================
echo.

pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo [错误] 安装依赖失败。
    echo 可能的原因：
    echo   - 网络连接不稳定，请检查网络后重试
    echo   - 磁盘空间不足，请确保至少有 2GB 可用空间
    echo.
    echo 你可以重新双击本程序再试一次。
    pause
    exit /b 1
)

echo.
echo [√] 依赖安装完成！
echo.

:: ============================================
:: 第四步：配置 API Key 并启动
:: ============================================

echo [4/4] 准备启动...
echo.
echo ================================================
echo.
echo   关于 AI 摘要功能：
echo.
echo   本工具的视频转录功能（语音转文字）无需任何配置，
echo   开箱即用。
echo.
echo   但如果您想使用 AI 智能摘要功能，需要提供
echo   OpenAI API Key。没有 Key 也完全可以用，
echo   只是摘要功能不可用。
echo.
echo ================================================
echo.

set "OPENAI_API_KEY="
set /p "OPENAI_API_KEY=请输入 OpenAI API Key（没有的话直接按回车跳过）: "
echo.

if defined OPENAI_API_KEY (
    echo [√] 已设置 API Key，AI 摘要功能已启用
) else (
    echo [提示] 未设置 API Key，将以基础模式运行（仅转录，无摘要）
)
echo.

echo ================================================
echo   正在启动 AI Video Transcriber...
echo.
echo   正在打开浏览器... 如果没有自动打开，
echo   请手动访问：http://localhost:8000
echo.
echo   关闭此黑色窗口即可停止程序。
echo ================================================
echo.

start "" http://localhost:8000
python start.py

pause
