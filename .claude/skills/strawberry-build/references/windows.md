# Windows Build Guide

## Table of Contents

- [MinGW Build (MSYS2)](#mingw-build-msys2)
- [MSVC Build](#msvc-build)
- [NSIS Installer](#nsis-installer)
- [Common Issues](#common-issues)

## MinGW Build (MSYS2)

The helper scripts (`check_deps.sh`, `build.sh`) work in MSYS2/MinGW Bash environments.

### Prerequisites

Install MSYS2 from https://www.msys2.org, then in the MinGW64 shell:

    pacman -Syu
    pacman -S --noconfirm \
      mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake \
      mingw-w64-x86_64-boost mingw-w64-x86_64-glib2 \
      mingw-w64-x86_64-sqlite3 mingw-w64-x86_64-icu \
      mingw-w64-x86_64-qt6-base mingw-w64-x86_64-qt6-tools \
      mingw-w64-x86_64-taglib \
      mingw-w64-x86_64-gstreamer mingw-w64-x86_64-gst-plugins-base \
      mingw-w64-x86_64-gst-plugins-good \
      mingw-w64-x86_64-kdsingleapplication-qt6

Optional:

    pacman -S --noconfirm \
      mingw-w64-x86_64-chromaprint mingw-w64-x86_64-fftw \
      mingw-w64-x86_64-libebur128

For 32-bit builds, replace `x86_64` with `i686`.

### Configure & Build

    cmake -S . -B build -G "MinGW Makefiles" \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_WIN32_CONSOLE=OFF \
      -DENABLE_GIO=OFF \
      -DENABLE_AUDIOCD=OFF \
      -DENABLE_MTP=OFF \
      -DENABLE_GPOD=OFF
    cmake --build build --parallel $NUMBER_OF_PROCESSORS

## MSVC Build

**NOTE**: The Bash helper scripts do not support MSVC. Use cmake commands directly in PowerShell or Developer Command Prompt.

### Prerequisites

- Visual Studio 2022 with "Desktop development with C++" workload
- Qt 6.4+ for MSVC (via Qt online installer or vcpkg)
- GStreamer MSVC runtime + development SDK from https://gstreamer.freedesktop.org/download/

### PowerShell Build Commands

Open "Developer PowerShell for VS 2022":

    # Configure (x64)
    cmake -S . -B build -G "Visual Studio 17 2022" -A x64 `
      -DCMAKE_BUILD_TYPE=Release `
      -DCMAKE_PREFIX_PATH="C:\Qt\6.x.x\msvc2022_64" `
      -DENABLE_WIN32_CONSOLE=OFF `
      -DENABLE_GIO=OFF `
      -DENABLE_AUDIOCD=OFF `
      -DENABLE_MTP=OFF `
      -DENABLE_GPOD=OFF

    # Build
    cmake --build build --config Release --parallel $env:NUMBER_OF_PROCESSORS

    # Install (to staging directory for packaging)
    cmake --install build --config Release --prefix build\install

### ARM64 Build

    cmake -S . -B build -G "Visual Studio 17 2022" -A ARM64 `
      -DCMAKE_BUILD_TYPE=Release `
      -DCMAKE_PREFIX_PATH="C:\Qt\6.x.x\msvc2022_arm64"

## NSIS Installer

### Prerequisites

- NSIS 3.x: https://nsis.sourceforge.io
- For MinGW: `pacman -S mingw-w64-x86_64-nsis`

### Build Installer

After a successful build:

    makensis dist\windows\strawberry.nsi

The NSIS script (`dist/windows/strawberry.nsi.in`, configured by CMake) handles:
- DLL bundling (Qt6, GStreamer, MinGW/MSVC runtime)
- GStreamer plugins (50+ per variant)
- File type associations (.mp3, .flac, .ogg, .m4a, .wav, etc.)
- Tidal URL protocol handler
- Start menu shortcuts and uninstaller

Output: `strawberry-<version>-<arch>-setup.exe`

## Common Issues

**Missing DLLs at runtime**: Ensure Qt6 and GStreamer DLLs are in PATH or alongside the executable. Use `windeployqt` for Qt DLLs.

**GStreamer not found by CMake**: Set environment variables:

    set GSTREAMER_1_0_ROOT_MSVC_X86_64=C:\gstreamer\1.0\msvc_x86_64
    set PKG_CONFIG_PATH=C:\gstreamer\1.0\msvc_x86_64\lib\pkgconfig

**MSVC link errors**: Verify all dependencies (Qt, GStreamer, TagLib) are built with the same MSVC version and architecture.

**Qt6 not found**: Set `CMAKE_PREFIX_PATH` to point to the Qt6 MSVC directory (e.g., `C:\Qt\6.8.0\msvc2022_64`).
