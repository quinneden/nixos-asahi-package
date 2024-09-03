#!/bin/sh
# SPDX-License-Identifier: MIT

# Truncation guard
if true; then
    set -e

    if [ ! -e /System ]; then
        echo "You appear to be running this script from Linux or another non-macOS system."
        echo "Asahi Linux can only be installed from macOS (or recoveryOS)."
        exit 1
    fi

    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    export VERSION_FLAG=https://cdn.asahilinux.org/installer/latest
    export INSTALLER_BASE=https://cdn.asahilinux.org/installer
    export INSTALLER_DATA=https://qeden.systems/data/installer_data.json

    # TMP="$(mktemp -d)"
    TMP=/tmp/asahi-install

    cd "$(dirname "$0")"

    echo
    echo "Bootstrapping installer:"

    if [ -e "$TMP" ]; then
        sudo rm -rf "$TMP"
    fi

    mkdir -p "$TMP"
    cd "$TMP"

    echo "  Checking version..."

    PKG_VER="$(curl --no-progress-meter -L "$VERSION_FLAG")"
    echo "  Version: $PKG_VER"

    PKG="installer-$PKG_VER.tar.gz"

    echo "  Downloading..."

    curl --no-progress-meter -L -o "$PKG" "$INSTALLER_BASE/$PKG"
    curl --no-progress-meter -L -O "$INSTALLER_DATA"

    echo "  Extracting..."

    tar xf "$PKG"

    echo "  Initializing..."
    echo

    if [ "$USER" != "root" ]; then
        echo "The installer needs to run as root."
        echo "Please enter your sudo password if prompted."
        exec caffeinate -dis sudo -E ./install.sh "$@"
    else
        exec caffeinate -dis ./install.sh "$@"
    fi
fi
