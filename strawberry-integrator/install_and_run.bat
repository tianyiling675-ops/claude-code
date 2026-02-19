@echo off
chcp 65001 >nul
title Strawberry 音乐播放器 - 一键安装启动器
color 0A

echo ╔══════════════════════════════════════════════════╗
echo ║                                                  ║
echo ║    Strawberry 音乐播放器 - 一键安装启动器        ║
echo ║                                                  ║
echo ║    一款免费开源的高品质音乐播放器                ║
echo ║    支持 FLAC / MP3 / AAC 等几乎所有音乐格式     ║
echo ║                                                  ║
echo ╚══════════════════════════════════════════════════╝
echo.

:: ============================================================
:: 第一步：检查 MSYS2 是否已安装
:: （MSYS2 是在 Windows 上编译 Linux 开源软件的工具）
:: ============================================================

echo [检查中] 正在检测您的电脑环境...
echo.

:: 检查是否已经编译过（有现成的程序直接启动）
if exist "strawberry\build\strawberry.exe" (
    echo [发现] 检测到已编译好的 Strawberry，直接启动！
    echo.
    start "" "strawberry\build\strawberry.exe"
    goto :end
)

if exist "C:\msys64\usr\bin\bash.exe" (
    echo [OK] 已检测到 MSYS2，继续...
    goto :has_msys2
)

if exist "D:\msys64\usr\bin\bash.exe" (
    echo [OK] 已检测到 MSYS2（D盘），继续...
    set "MSYS2_DIR=D:\msys64"
    goto :has_msys2
)

:: MSYS2 未安装，尝试用 winget 安装
echo [提示] 您的电脑上还没有安装 MSYS2（编译工具）。
echo        正在尝试自动安装，这需要大约 3-5 分钟...
echo.

winget install -e --id MSYS2.MSYS2 --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
    echo.
    echo ╔══════════════════════════════════════════════════╗
    echo ║  自动安装 MSYS2 失败，请手动安装：              ║
    echo ║                                                  ║
    echo ║  1. 打开浏览器，访问：https://www.msys2.org     ║
    echo ║  2. 点击页面上的下载按钮                        ║
    echo ║  3. 双击下载的文件，一路点"下一步"安装          ║
    echo ║     （安装路径保持默认 C:\msys64 即可）          ║
    echo ║  4. 安装完成后，重新双击本程序                   ║
    echo ╚══════════════════════════════════════════════════╝
    pause
    exit /b 1
)

echo.
echo [完成] MSYS2 安装成功！
echo.

:has_msys2

:: 确定 MSYS2 路径
if not defined MSYS2_DIR (
    if exist "C:\msys64\usr\bin\bash.exe" (
        set "MSYS2_DIR=C:\msys64"
    ) else if exist "D:\msys64\usr\bin\bash.exe" (
        set "MSYS2_DIR=D:\msys64"
    ) else (
        echo [错误] 找不到 MSYS2 安装目录，请确认已正确安装。
        pause
        exit /b 1
    )
)

:: ============================================================
:: 第二步：使用 MSYS2 安装编译所需的工具和库
:: ============================================================

echo ╔══════════════════════════════════════════════════╗
echo ║  [1/4] 正在安装编译工具和依赖库...              ║
echo ║        （首次运行需要下载约 500MB，请耐心等待） ║
echo ╚══════════════════════════════════════════════════╝
echo.

:: 写入自动化脚本
set "SCRIPT_PATH=%~dp0_build_strawberry.sh"

(
echo #!/bin/bash
echo set -e
echo.
echo echo "=== 更新软件包数据库 ==="
echo pacman -Sy --noconfirm
echo.
echo echo "=== 安装编译工具链和依赖 ==="
echo pacman -S --noconfirm --needed \
echo   mingw-w64-x86_64-toolchain \
echo   mingw-w64-x86_64-cmake \
echo   mingw-w64-x86_64-boost \
echo   mingw-w64-x86_64-glib2 \
echo   mingw-w64-x86_64-sqlite3 \
echo   mingw-w64-x86_64-icu \
echo   mingw-w64-x86_64-qt6-base \
echo   mingw-w64-x86_64-qt6-tools \
echo   mingw-w64-x86_64-taglib \
echo   mingw-w64-x86_64-gstreamer \
echo   mingw-w64-x86_64-gst-plugins-base \
echo   mingw-w64-x86_64-gst-plugins-good \
echo   mingw-w64-x86_64-kdsingleapplication-qt6 \
echo   mingw-w64-x86_64-chromaprint \
echo   mingw-w64-x86_64-fftw \
echo   git
echo.
echo WORK_DIR="$(cygpath -u '%~dp0')"
echo cd "$WORK_DIR"
echo.
echo echo "=== 下载 Strawberry 源代码 ==="
echo if [ ! -d "strawberry" ]; then
echo   git clone --recursive https://github.com/strawberrymusicplayer/strawberry.git
echo else
echo   echo "源代码已存在，跳过下载。"
echo fi
echo.
echo cd strawberry
echo.
echo echo "=== 开始编译（这一步需要较长时间，请耐心等待）==="
echo cmake -S . -B build -G "MinGW Makefiles" \
echo   -DCMAKE_BUILD_TYPE=Release \
echo   -DENABLE_WIN32_CONSOLE=OFF \
echo   -DENABLE_GIO=OFF \
echo   -DENABLE_AUDIOCD=OFF \
echo   -DENABLE_MTP=OFF \
echo   -DENABLE_GPOD=OFF
echo.
echo cmake --build build --parallel $(nproc^)
echo.
echo echo ""
echo echo "========================================="
echo echo "  编译完成！"
echo echo "========================================="
) > "%SCRIPT_PATH%"

:: 用 MSYS2 MinGW64 环境执行脚本
echo 正在启动编译环境...（黑色窗口中的英文是正常的编译过程）
echo.

"%MSYS2_DIR%\msys2_shell.cmd" -mingw64 -defterm -no-start -here -c "bash '%SCRIPT_PATH%'"

if errorlevel 1 (
    echo.
    echo ╔══════════════════════════════════════════════════╗
    echo ║  [错误] 编译过程中出现了问题。                  ║
    echo ║                                                  ║
    echo ║  可能的原因：                                    ║
    echo ║  - 网络连接不稳定（下载依赖失败）               ║
    echo ║  - 磁盘空间不足（需要约 2GB 可用空间）          ║
    echo ║                                                  ║
    echo ║  您可以重新双击本程序再试一次。                  ║
    echo ║  如果问题持续，请截图此窗口内容并寻求帮助。     ║
    echo ╚══════════════════════════════════════════════════╝
    pause
    exit /b 1
)

:: ============================================================
:: 第三步：启动 Strawberry
:: ============================================================

echo.
echo ╔══════════════════════════════════════════════════╗
echo ║                                                  ║
echo ║  安装完成！正在启动 Strawberry 音乐播放器...    ║
echo ║                                                  ║
echo ║  之后您可以：                                    ║
echo ║  - 再次双击本程序来启动（会秒开，不用再编译）   ║
echo ║  - 或直接运行 strawberry\build\strawberry.exe   ║
echo ║                                                  ║
echo ╚══════════════════════════════════════════════════╝
echo.

if exist "strawberry\build\strawberry.exe" (
    start "" "strawberry\build\strawberry.exe"
) else (
    echo [提示] 没有找到编译好的程序文件，编译可能没有完全成功。
    echo        请重新双击本程序再试一次。
)

:end

:: 清理临时脚本
if exist "%SCRIPT_PATH%" del "%SCRIPT_PATH%"

pause
