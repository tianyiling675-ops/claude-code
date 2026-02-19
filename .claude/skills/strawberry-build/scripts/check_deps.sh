#!/usr/bin/env bash
# Check Strawberry Music Player build dependencies for the current platform
# Supports: Debian/Ubuntu, Fedora, openSUSE, OpenMandriva, Mageia, macOS, FreeBSD, OpenBSD
# NOTE: This script requires Bash. For Windows MSVC builds, check dependencies manually.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

MISSING=()
OPTIONAL_MISSING=()

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "freebsd"* ]] || uname -s | grep -qi freebsd; then
        PLATFORM="freebsd"
    elif uname -s | grep -qi openbsd; then
        PLATFORM="openbsd"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw"* ]]; then
        PLATFORM="msys2"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|linuxmint|pop) PLATFORM="debian" ;;
            fedora|rhel|centos|rocky|alma) PLATFORM="fedora" ;;
            opensuse*|sles) PLATFORM="opensuse" ;;
            openmandriva) PLATFORM="openmandriva" ;;
            mageia) PLATFORM="mageia" ;;
            *) PLATFORM="linux-unknown" ;;
        esac
    else
        PLATFORM="unknown"
    fi
    echo -e "Detected platform: ${GREEN}${PLATFORM}${NC}"
}

check_cmd() {
    if command -v "$1" &>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC} $1"
        return 0
    else
        echo -e "  ${RED}[MISSING]${NC} $1"
        return 1
    fi
}

check_pkg() {
    if pkg-config --exists "$1" 2>/dev/null; then
        local ver
        ver=$(pkg-config --modversion "$1" 2>/dev/null || echo "?")
        echo -e "  ${GREEN}[OK]${NC} $1 ($ver)"
        return 0
    else
        echo -e "  ${RED}[MISSING]${NC} $1"
        return 1
    fi
}

check_required_tools() {
    echo ""
    echo "=== Required Build Tools ==="
    check_cmd cmake || MISSING+=("cmake")
    check_cmd git || MISSING+=("git")
    check_cmd pkg-config || check_cmd pkgconf || MISSING+=("pkg-config")

    if check_cmd g++; then
        true
    elif check_cmd clang++; then
        true
    elif check_cmd c++; then
        true
    else
        MISSING+=("c++ compiler (g++ or clang++)")
    fi

    check_cmd make || MISSING+=("make")
}

check_required_libs() {
    echo ""
    echo "=== Required Libraries ==="
    check_pkg glib-2.0 || MISSING+=("glib-2.0")
    check_pkg gobject-2.0 || MISSING+=("gobject-2.0")
    check_pkg sqlite3 || MISSING+=("sqlite3")
    check_pkg gstreamer-1.0 || MISSING+=("gstreamer-1.0")
    check_pkg gstreamer-base-1.0 || MISSING+=("gstreamer-base-1.0")
    check_pkg gstreamer-audio-1.0 || MISSING+=("gstreamer-audio-1.0")
    check_pkg gstreamer-app-1.0 || MISSING+=("gstreamer-app-1.0")
    check_pkg gstreamer-tag-1.0 || MISSING+=("gstreamer-tag-1.0")
    check_pkg gstreamer-pbutils-1.0 || MISSING+=("gstreamer-pbutils-1.0")
    check_pkg taglib || MISSING+=("taglib")
    check_pkg icu-uc || MISSING+=("icu-uc")
    check_pkg icu-i18n || MISSING+=("icu-i18n")
}

check_qt6() {
    echo ""
    echo "=== Qt6 ==="
    local qt_found=false
    for mod in Qt6Core Qt6Gui Qt6Widgets Qt6Network Qt6Sql Qt6Concurrent Qt6DBus; do
        if pkg-config --exists "$mod" 2>/dev/null; then
            local ver
            ver=$(pkg-config --modversion "$mod" 2>/dev/null || echo "?")
            echo -e "  ${GREEN}[OK]${NC} $mod ($ver)"
            qt_found=true
        else
            echo -e "  ${RED}[MISSING]${NC} $mod"
            MISSING+=("$mod")
        fi
    done
    if [[ "$qt_found" == false ]]; then
        echo -e "  ${YELLOW}[NOTE]${NC} Qt6 not found via pkg-config. It may still be available via CMake find_package."
    fi
}

check_optional_libs() {
    echo ""
    echo "=== Optional Libraries ==="
    check_pkg alsa || OPTIONAL_MISSING+=("alsa (ALSA audio)")
    check_pkg libpulse || OPTIONAL_MISSING+=("libpulse (PulseAudio)")
    check_pkg libcdio || OPTIONAL_MISSING+=("libcdio (Audio CD)")
    check_pkg libmtp || OPTIONAL_MISSING+=("libmtp (MTP devices)")
    check_pkg libgpod-1.0 || OPTIONAL_MISSING+=("libgpod (iPod support)")
    check_pkg libchromaprint || OPTIONAL_MISSING+=("libchromaprint (audio fingerprinting)")
    check_pkg fftw3 || OPTIONAL_MISSING+=("fftw3 (moodbar)")
    check_pkg libebur128 || OPTIONAL_MISSING+=("libebur128 (loudness normalization)")
}

suggest_install() {
    if [[ ${#MISSING[@]} -eq 0 ]]; then
        return
    fi
    echo ""
    echo "=== Install Suggestion ==="
    case "$PLATFORM" in
        debian)
            echo "  sudo apt install cmake g++ git pkg-config \\"
            echo "    qt6-base-dev qt6-base-dev-tools qt6-tools-dev \\"
            echo "    libglib2.0-dev libboost-dev libsqlite3-dev libicu-dev \\"
            echo "    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \\"
            echo "    libtag1-dev libkdsingleapplication-qt6-dev"
            ;;
        fedora)
            echo "  sudo dnf install cmake gcc-c++ git pkgconfig \\"
            echo "    qt6-qtbase-devel qt6-qttools-devel \\"
            echo "    glib2-devel boost-devel sqlite-devel taglib-devel icu-devel \\"
            echo "    gstreamer1-devel gstreamer1-plugins-base-devel \\"
            echo "    kdsingleapplication-qt6-devel"
            ;;
        opensuse)
            echo "  sudo zypper install cmake gcc-c++ git pkg-config \\"
            echo "    qt6-base-devel qt6-tools-devel \\"
            echo "    glib2-devel boost-devel sqlite3-devel taglib-devel icu-devel \\"
            echo "    gstreamer-devel gstreamer-plugins-base-devel \\"
            echo "    kdsingleapplication-qt6-devel"
            ;;
        macos)
            echo "  brew install cmake pkg-config boost glib sqlite icu4c taglib \\"
            echo "    gstreamer gst-plugins-base qt@6 kdsingleapplication"
            ;;
        freebsd)
            echo "  sudo pkg install cmake pkgconf git gcc boost-libs glib qt6-base \\"
            echo "    qt6-tools sqlite3 gstreamer1 gstreamer1-plugins taglib \\"
            echo "    kdsingleapplication"
            ;;
        openbsd)
            echo "  doas pkg_add cmake pkgconf git gcc boost glib2 qt6-qtbase \\"
            echo "    qt6-qttools sqlite gstreamer1 gstreamer1-plugins-base taglib \\"
            echo "    kdsingleapplication"
            ;;
        *)
            echo "  Please install the missing dependencies using your system package manager."
            ;;
    esac
}

print_summary() {
    echo ""
    echo "========================================="
    echo "           DEPENDENCY SUMMARY"
    echo "========================================="

    if [[ ${#MISSING[@]} -eq 0 ]]; then
        echo -e "${GREEN}All required dependencies are installed!${NC}"
    else
        echo -e "${RED}Missing required dependencies (${#MISSING[@]}):${NC}"
        for dep in "${MISSING[@]}"; do
            echo -e "  ${RED}-${NC} $dep"
        done
        suggest_install
    fi

    if [[ ${#OPTIONAL_MISSING[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Missing optional dependencies (${#OPTIONAL_MISSING[@]}):${NC}"
        for dep in "${OPTIONAL_MISSING[@]}"; do
            echo -e "  ${YELLOW}-${NC} $dep"
        done
    fi

    echo ""
    if [[ ${#MISSING[@]} -eq 0 ]]; then
        echo -e "${GREEN}Ready to build Strawberry!${NC}"
        return 0
    else
        echo -e "${RED}Please install missing dependencies before building.${NC}"
        return 1
    fi
}

main() {
    echo "Checking Strawberry Music Player build dependencies..."
    echo ""
    detect_os
    check_required_tools
    check_required_libs
    check_qt6
    check_optional_libs
    print_summary
}

main "$@"
