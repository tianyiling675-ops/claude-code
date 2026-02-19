---
name: strawberry-build
description: Build, package, and deploy the Strawberry Music Player (C++17/Qt6/CMake). Use when the user wants to compile Strawberry from source, install its dependencies, configure CMake options, create distribution packages (DEB, RPM, DMG, NSIS), or troubleshoot build failures. Covers Linux (Debian, Ubuntu, Fedora, openSUSE, Mageia, OpenMandriva), macOS, Windows (MinGW, MSVC), FreeBSD, and OpenBSD.
---

# Strawberry Music Player Build

Build, package, and deploy Strawberry Music Player from source.

**IMPORTANT**: Before proceeding, first confirm the user's operating system and distribution. Then read ONLY the relevant platform reference file:

- **Debian/Ubuntu or RPM-based Linux** -> Read references/linux.md
- **macOS** -> Read references/macos.md
- **Windows (MinGW or MSVC)** -> Read references/windows.md
- **FreeBSD / OpenBSD** -> Read references/bsd.md

Do NOT load all reference files. Only load the one matching the user's platform.

## Quick Start

    git clone --recursive https://github.com/strawberrymusicplayer/strawberry.git
    cd strawberry
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build --parallel $(nproc)
    sudo cmake --install build

## Build Workflow

1. Confirm user's OS and distribution
2. Install platform dependencies (read the matching reference file above)
3. Clone repository with `--recursive` (has git submodules)
4. Configure with CMake
5. Build
6. Package (optional)

## Core Dependencies

| Dependency | Min Version | Purpose |
|---|---|---|
| CMake | 3.13+ | Build system |
| C++17 compiler | GCC 8+ / Clang 7+ / MSVC 2019+ | Compilation |
| Qt | 6.4.0+ | GUI framework |
| GStreamer | 1.0 | Audio playback engine |
| TagLib | 2.0+ | Audio metadata read/write |
| SQLite | 3.9+ | Database |
| Boost | any | Utility library |
| ICU | any | Unicode / i18n |
| GLib / GObject | 2.0 | C utility library |
| KDSingleApplication | 1.1.0+ | Single-instance enforcement |

## CMake Configuration

### Common Options

    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DBUILD_WERROR=OFF

### Feature Toggles

All optional features are auto-detected. Override with `-DENABLE_<FEATURE>=ON|OFF`:

| Option | Default | Description |
|---|---|---|
| BUILD_WERROR | OFF | Treat warnings as errors |
| USE_BUNDLE | ON (macOS/Win) | Bundle dependencies in package |
| ENABLE_WIN32_CONSOLE | OFF | Show console on Windows Release |
| INSTALL_TRANSLATIONS | OFF | Install translation files |
| ENABLE_ALSA | auto | ALSA audio (Linux) |
| ENABLE_PULSE | auto | PulseAudio support |
| ENABLE_DBUS | auto | D-Bus integration (Unix) |
| ENABLE_AUDIOCD | auto | Audio CD support (libcdio) |
| ENABLE_MTP | auto | MTP device support |
| ENABLE_GPOD | auto | iPod support (libgpod) |
| ENABLE_MOODBAR | auto | Moodbar visualization (FFTW3) |
| ENABLE_EBUR128 | auto | Loudness normalization |
| ENABLE_SONGFINGERPRINTING | auto | Chromaprint fingerprinting |
| ENABLE_SUBSONIC | auto | Subsonic streaming |
| ENABLE_TIDAL | auto | Tidal streaming |
| ENABLE_SPOTIFY | auto | Spotify streaming |
| ENABLE_QOBUZ | auto | Qobuz streaming |
| ENABLE_SPARKLE | auto | Sparkle updates (macOS) |
| ENABLE_DISCORD_RPC | auto | Discord Rich Presence |

### Minimal Build (fewest dependencies)

    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_AUDIOCD=OFF \
      -DENABLE_MTP=OFF \
      -DENABLE_GPOD=OFF \
      -DENABLE_MOODBAR=OFF \
      -DENABLE_EBUR128=OFF \
      -DENABLE_SONGFINGERPRINTING=OFF \
      -DENABLE_DISCORD_RPC=OFF

## Building

Standard:

    cmake --build build --parallel $(nproc)

Windows MSVC (PowerShell):

    cmake --build build --config Release --parallel $env:NUMBER_OF_PROCESSORS

## Packaging Overview

| Platform | Command | Output |
|---|---|---|
| Debian/Ubuntu | `dpkg-buildpackage -b -d -uc -us -nc -j$(nproc)` | `../strawberry_*.deb` |
| RPM distros | `rpmbuild -ba build/dist/unix/strawberry.spec` | RPM package |
| macOS | `make -C build dmg` | `build/strawberry-*.dmg` |
| Windows | `makensis dist/windows/strawberry.nsi` | `strawberry-*-setup.exe` |

See the platform-specific reference for detailed packaging instructions.

## Troubleshooting

### CMake cannot find Qt6

Set `CMAKE_PREFIX_PATH` to the Qt6 installation:

    cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/qt6

### TagLib not found

Requires TagLib 2.0+. Older distros may ship 1.x. Build from source if needed:

    git clone https://github.com/taglib/taglib.git && cd taglib
    cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON
    cmake --build build --parallel $(nproc) && sudo cmake --install build

### GStreamer plugin errors at runtime

Install additional plugin packages:
- Required: `gstreamer1.0-plugins-base`, `gstreamer1.0-plugins-good`
- Recommended: `gstreamer1.0-plugins-bad`, `gstreamer1.0-plugins-ugly`
- Audio output: `gstreamer1.0-alsa`, `gstreamer1.0-pulseaudio`

### Missing git submodules

Always clone with `--recursive`. If already cloned:

    git submodule update --init --recursive

## Helper Scripts

This skill includes Bash helper scripts. They support Linux, macOS, BSD, and MSYS2/MinGW. For Windows MSVC builds, use cmake commands directly in PowerShell (see references/windows.md).

**Dependency check** - verify build dependencies are installed:

    bash scripts/check_deps.sh

**Unified build** - configure, build, and optionally package:

    bash scripts/build.sh                          # Standard release build
    bash scripts/build.sh --type Debug             # Debug build
    bash scripts/build.sh --parallel 8 --package   # Build + package
    bash scripts/build.sh --minimal                # Minimal dependencies

Run `bash scripts/build.sh --help` for all options.
