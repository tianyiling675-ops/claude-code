# BSD Build Guide

## Table of Contents

- [FreeBSD](#freebsd)
- [OpenBSD](#openbsd)

## FreeBSD

### Dependencies

    sudo pkg install -y \
      git cmake pkgconf boost-libs glib qt6-base qt6-tools \
      sqlite3 taglib icu gdk-pixbuf2 sparsehash \
      gstreamer1 gstreamer1-plugins gstreamer1-plugins-good \
      kdsingleapplication alsa-lib pulseaudio \
      googletest

Optional:

    sudo pkg install -y \
      chromaprint libebur128 fftw3 libcdio libmtp libgpod

### Configure & Build

    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local
    cmake --build build --parallel $(sysctl -n hw.ncpu)
    sudo cmake --install build

### Notes

- Default prefix is `/usr/local` (FreeBSD convention)
- ALSA available via `alsa-lib` (OSS compatibility layer)
- D-Bus is available; MPRIS2 integration works
- PulseAudio supported for advanced audio routing

## OpenBSD

### Dependencies

    doas pkg_add git cmake pkgconf boost glib2 qt6-qtbase qt6-qttools \
      sqlite gstreamer1 gstreamer1-plugins-base \
      taglib icu4c gdk-pixbuf pulseaudio sparsehash \
      kdsingleapplication

Optional:

    doas pkg_add chromaprint libebur128 fftw3 libcdio libmtp libgpod

### Configure & Build

    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local
    cmake --build build --parallel $(sysctl -n hw.ncpuonline)
    doas cmake --install build

### Notes

- Uses `doas` instead of `sudo`
- Package names differ slightly from FreeBSD (e.g., `icu4c` vs `icu`)
- Memory-constrained systems may need to reduce parallelism (e.g., `--parallel 2`)
- sndio is the native audio system; PulseAudio available as alternative
