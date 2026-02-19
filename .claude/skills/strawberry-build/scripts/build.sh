#!/usr/bin/env bash
# Unified build script for Strawberry Music Player
# Supports: Linux, macOS, FreeBSD, OpenBSD, MSYS2/MinGW
# NOTE: This script requires Bash. For Windows MSVC builds, use cmake commands
#       directly in PowerShell/Developer Command Prompt. See references/windows.md.
set -euo pipefail

# Auto-detect CPU cores
detect_cores() {
    if command -v nproc &>/dev/null; then
        nproc
    elif command -v sysctl &>/dev/null; then
        sysctl -n hw.logicalcpu 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4
    elif [[ -n "${NUMBER_OF_PROCESSORS:-}" ]]; then
        echo "$NUMBER_OF_PROCESSORS"
    else
        echo 4
    fi
}

# Defaults
BUILD_TYPE="Release"
BUILD_DIR="build"
INSTALL_PREFIX=""
PARALLEL=$(detect_cores)
PACKAGE=false
CMAKE_EXTRA_ARGS=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build Strawberry Music Player from source.

Options:
  --type TYPE        Build type: Release (default) or Debug
  --build-dir DIR    Build directory (default: build)
  --prefix PATH      Install prefix (default: platform-specific)
  --parallel N       Parallel jobs (default: auto-detected = $PARALLEL)
  --package          Create distribution package after build
  --minimal          Disable optional features for minimal build
  -h, --help         Show this help

Examples:
  $(basename "$0")                          # Standard release build
  $(basename "$0") --type Debug             # Debug build
  $(basename "$0") --parallel 8 --package   # Build with 8 jobs + package
  $(basename "$0") --minimal                # Minimal build, fewer deps
EOF
    exit 0
}

parse_args() {
    local MINIMAL=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type) BUILD_TYPE="$2"; shift 2 ;;
            --build-dir) BUILD_DIR="$2"; shift 2 ;;
            --prefix) INSTALL_PREFIX="$2"; shift 2 ;;
            --parallel) PARALLEL="$2"; shift 2 ;;
            --package) PACKAGE=true; shift ;;
            --minimal) MINIMAL=true; shift ;;
            -h|--help) usage ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [[ "$MINIMAL" == true ]]; then
        CMAKE_EXTRA_ARGS+=" -DENABLE_AUDIOCD=OFF -DENABLE_MTP=OFF -DENABLE_GPOD=OFF"
        CMAKE_EXTRA_ARGS+=" -DENABLE_MOODBAR=OFF -DENABLE_EBUR128=OFF"
        CMAKE_EXTRA_ARGS+=" -DENABLE_SONGFINGERPRINTING=OFF -DENABLE_DISCORD_RPC=OFF"
    fi
}

detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        [[ -z "$INSTALL_PREFIX" ]] && INSTALL_PREFIX="/usr/local"
        # Auto-detect Homebrew Qt6 path
        local qt_prefix
        qt_prefix=$(brew --prefix qt@6 2>/dev/null || echo "")
        if [[ -n "$qt_prefix" ]]; then
            CMAKE_EXTRA_ARGS+=" -DCMAKE_PREFIX_PATH=$qt_prefix"
        fi
        CMAKE_EXTRA_ARGS+=" -DUSE_BUNDLE=ON"
    elif [[ "$OSTYPE" == "freebsd"* ]] || uname -s | grep -qi freebsd; then
        PLATFORM="freebsd"
        [[ -z "$INSTALL_PREFIX" ]] && INSTALL_PREFIX="/usr/local"
    elif uname -s | grep -qi openbsd; then
        PLATFORM="openbsd"
        [[ -z "$INSTALL_PREFIX" ]] && INSTALL_PREFIX="/usr/local"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw"* ]]; then
        PLATFORM="msys2"
        [[ -z "$INSTALL_PREFIX" ]] && INSTALL_PREFIX="/mingw64"
        CMAKE_EXTRA_ARGS+=" -G 'MinGW Makefiles'"
        CMAKE_EXTRA_ARGS+=" -DENABLE_WIN32_CONSOLE=OFF -DENABLE_GIO=OFF"
        CMAKE_EXTRA_ARGS+=" -DENABLE_AUDIOCD=OFF -DENABLE_MTP=OFF -DENABLE_GPOD=OFF"
    else
        PLATFORM="linux"
        [[ -z "$INSTALL_PREFIX" ]] && INSTALL_PREFIX="/usr"
    fi
}

configure() {
    echo "Configuring (${BUILD_TYPE})..."
    eval cmake -S . -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DBUILD_WERROR=OFF \
        $CMAKE_EXTRA_ARGS
}

build() {
    echo "Building with $PARALLEL parallel jobs..."
    cmake --build "$BUILD_DIR" --parallel "$PARALLEL"
}

package() {
    echo "Packaging for $PLATFORM..."
    case "$PLATFORM" in
        linux)
            if [[ -f /etc/debian_version ]] || command -v dpkg-buildpackage &>/dev/null; then
                dpkg-buildpackage -b -d -uc -us -nc -j"$PARALLEL"
                echo "DEB package created in parent directory."
            elif command -v rpmbuild &>/dev/null; then
                rpmbuild -ba "$BUILD_DIR/dist/unix/strawberry.spec"
                echo "RPM package created."
            else
                echo "No packaging tool found. Use 'sudo cmake --install $BUILD_DIR' to install."
            fi
            ;;
        macos)
            make -C "$BUILD_DIR" dmg
            echo "DMG created in $BUILD_DIR/"
            ;;
        msys2)
            if command -v makensis &>/dev/null; then
                makensis dist/windows/strawberry.nsi
                echo "NSIS installer created."
            else
                echo "NSIS not found. Install with: pacman -S mingw-w64-x86_64-nsis"
            fi
            ;;
        freebsd|openbsd)
            echo "No automated packaging for $PLATFORM. Use: sudo cmake --install $BUILD_DIR"
            ;;
    esac
}

main() {
    parse_args "$@"
    detect_platform

    echo "========================================="
    echo " Strawberry Music Player Build"
    echo "========================================="
    echo " Platform:  $PLATFORM"
    echo " Type:      $BUILD_TYPE"
    echo " Prefix:    $INSTALL_PREFIX"
    echo " Jobs:      $PARALLEL"
    echo " Build dir: $BUILD_DIR"
    echo " Package:   $PACKAGE"
    echo "========================================="
    echo ""

    configure
    echo ""
    build

    if [[ "$PACKAGE" == true ]]; then
        echo ""
        package
    fi

    echo ""
    echo "Build complete! To install: sudo cmake --install $BUILD_DIR"
}

main "$@"
