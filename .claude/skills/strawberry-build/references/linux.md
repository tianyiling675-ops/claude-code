# Linux Build Guide

## Table of Contents

- [Debian/Ubuntu Dependencies](#debianubuntu-dependencies)
- [Fedora Dependencies](#fedora-dependencies)
- [openSUSE Dependencies](#opensuse-dependencies)
- [OpenMandriva Dependencies](#openmandriva-dependencies)
- [Mageia Dependencies](#mageia-dependencies)
- [DEB Packaging](#deb-packaging)
- [RPM Packaging](#rpm-packaging)
- [Distribution-Specific Notes](#distribution-specific-notes)

## Debian/Ubuntu Dependencies

    sudo apt install -y \
      build-essential cmake gcc g++ git pkg-config gettext \
      libglib2.0-dev libboost-dev libsqlite3-dev libicu-dev \
      libasound2-dev libpulse-dev libtag1-dev \
      libxkbcommon-dev libsparsehash-dev \
      qt6-base-dev qt6-base-private-dev qt6-base-dev-tools \
      qt6-tools-dev qt6-tools-dev-tools qt6-l10n-tools \
      libkdsingleapplication-qt6-dev \
      libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
      gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
      gstreamer1.0-plugins-bad gstreamer1.0-alsa gstreamer1.0-pulseaudio

Optional packages:

    sudo apt install -y \
      libcdio-dev libgpod-dev libmtp-dev \
      libchromaprint-dev libfftw3-dev libebur128-dev

## Fedora Dependencies

    sudo dnf install -y @development-tools \
      cmake gcc-c++ git pkgconfig gettext \
      glib2-devel boost-devel sqlite-devel taglib-devel \
      libicu-devel libxkbcommon-devel sparsehash-devel \
      alsa-lib-devel pulseaudio-libs-devel \
      qt6-qtbase-devel qt6-qtbase-private-devel qt6-qttools-devel \
      qt6-linguist kdsingleapplication-qt6-devel \
      gstreamer1-devel gstreamer1-plugins-base-devel \
      gstreamer1-plugins-base gstreamer1-plugins-good

Optional packages:

    sudo dnf install -y \
      libcdio-devel libgpod-devel libmtp-devel \
      chromaprint-devel fftw-devel libebur128-devel \
      gtest-devel gmock-devel

## openSUSE Dependencies

    sudo zypper install -y \
      gcc gcc-c++ cmake git pkg-config gettext-tools \
      boost-devel alsa-devel libpulse-devel \
      glib2-devel sqlite3-devel taglib-devel \
      libicu-devel xkbcommon-devel sparsehash-devel \
      qt6-base-devel qt6-base-private-devel qt6-tools-devel \
      qt6-linguist-devel kdsingleapplication-qt6-devel \
      gstreamer-devel gstreamer-plugins-base-devel \
      gstreamer-plugins-base gstreamer-plugins-good

Optional packages:

    sudo zypper install -y \
      libcdio-devel libgpod-devel libmtp-devel \
      libchromaprint-devel fftw3-devel libebur128-devel \
      gtest gmock

## OpenMandriva Dependencies

    sudo dnf install -y \
      cmake gcc-c++ pkg-config git gettext \
      lib64boost-devel lib64glib2.0-devel lib64sqlite3-devel \
      lib64asound-devel lib64pulseaudio-devel \
      lib64taglib-devel lib64icu-devel lib64xkbcommon-devel \
      lib64qt6-base-devel lib64qt6-tools-devel \
      kdsingleapplication-devel sparsehash-devel \
      lib64gstreamer1.0-devel gst-plugins-base1.0-devel \
      gstreamer-plugins-base1.0 gstreamer-plugins-good1.0

Optional packages:

    sudo dnf install -y \
      lib64cdio-devel lib64gpod-devel lib64mtp-devel \
      lib64chromaprint-devel lib64ebur128-devel lib64fftw-devel \
      gtest-devel gmock-devel

## Mageia Dependencies

    sudo urpmi --auto \
      cmake gcc-c++ pkgconfig git gettext \
      lib64boost-devel lib64sqlite3-devel \
      lib64alsa2-devel lib64pulseaudio-devel \
      lib64taglib-devel lib64icu-devel lib64xkbcommon-devel \
      lib64qt6-base-devel lib64qt6-tools-devel \
      kdsingleapplication-devel sparsehash-devel \
      lib64gstreamer1.0-devel gstreamer-plugins-base1.0-devel \
      gstreamer-plugins-base1.0 gstreamer-plugins-good1.0

Optional packages:

    sudo urpmi --auto \
      lib64cdio-devel lib64gpod-devel lib64mtp-devel \
      lib64chromaprint-devel lib64ebur128-devel lib64fftw-devel

## DEB Packaging

Build DEB packages from the repository root:

    dpkg-buildpackage -b -d -uc -us -nc -j$(nproc)

Output: `../strawberry_*.deb`

The `debian/` directory in the repo contains: control, rules, changelog, copyright, and install files. These are maintained upstream and should not normally need modification.

## RPM Packaging

The spec file template is at `dist/unix/strawberry.spec.in`. CMake generates the final spec during configure.

    cmake -S . -B build
    rpmbuild -ba build/dist/unix/strawberry.spec

Set parallel jobs: `RPM_BUILD_NCPUS=4 rpmbuild -ba strawberry.spec`

## Distribution-Specific Notes

- **Debian Bookworm**: TagLib 2.0 may need backports or manual build from source
- **Ubuntu Noble (24.04)**: Qt 6.4+ available in main repos
- **Fedora 42+**: All dependencies available in standard repos
- **openSUSE Tumbleweed**: Rolling release, all deps always current
- **openSUSE Leap 15.x**: May need additional repos for Qt6 (e.g., KDE:Qt6 OBS repo)
- **Mageia 9**: May have older Qt6 versions; check availability
