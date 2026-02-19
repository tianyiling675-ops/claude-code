# macOS Build Guide

## Table of Contents

- [Prerequisites](#prerequisites)
- [Dependencies via Homebrew](#dependencies-via-homebrew)
- [CMake Configuration](#cmake-configuration)
- [Building](#building)
- [DMG Packaging](#dmg-packaging)
- [Code Signing](#code-signing)
- [Architecture Notes](#architecture-notes)

## Prerequisites

- macOS 12.0+ (Monterey or later)
- Xcode command line tools: `xcode-select --install`
- Homebrew: https://brew.sh

## Dependencies via Homebrew

Required:

    brew install cmake pkg-config boost glib sqlite icu4c taglib \
      gstreamer gst-plugins-base gst-plugins-good \
      qt@6 kdsingleapplication

Optional:

    brew install chromaprint libebur128 fftw libcdio libmtp

## CMake Configuration

    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_BUNDLE=ON \
      -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)"

If ICU is not found:

    -DICU_ROOT=$(brew --prefix icu4c)

If Boost is not found:

    -DBOOST_ROOT=$(brew --prefix boost)

Sparkle auto-updater (optional):

    -DENABLE_SPARKLE=ON

## Building

    cmake --build build --parallel $(sysctl -n hw.logicalcpu)

## DMG Packaging

    make -C build dmg

Output: `build/strawberry-<version>.dmg`

The DMG creation uses `dist/macos/Info.plist.in` template. When `USE_BUNDLE=ON`, all dependencies are bundled into the .app bundle.

## Code Signing

For distribution outside the App Store, sign the app and DMG:

    codesign --force --deep --sign "Developer ID Application: <IDENTITY>" build/strawberry.app
    codesign --force --sign "Developer ID Application: <IDENTITY>" build/strawberry-*.dmg

Notarization:

    xcrun notarytool submit build/strawberry-*.dmg --apple-id <EMAIL> --team-id <TEAM>
    xcrun stapler staple build/strawberry-*.dmg

## Architecture Notes

- Intel (x86_64) and Apple Silicon (arm64) are both supported
- Universal binary: `-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"`
- Min deployment target: `-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0`
- Homebrew paths differ: `/usr/local` (Intel) vs `/opt/homebrew` (Apple Silicon)
