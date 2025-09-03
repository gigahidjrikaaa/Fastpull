#!/bin/bash
#
# Installs development dependencies for fastpull.
# Requires sudo privileges.

set -e

echo "Installing development dependencies: shellcheck, shfmt, bats..."

if ! command -v apt-get &>/dev/null;
then
    echo "This script currently only supports Debian-based systems (apt-get)."
    exit 1
fi

sudo apt-get update
sudo apt-get install -y shellcheck

# Install shfmt
if ! command -v shfmt &>/dev/null;
then
    echo "Installing shfmt..."
    VERSION="v3.4.3"
    OS="linux"
    ARCH="amd64"
    sudo curl -sSL "https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_${OS}_${ARCH}" -o /usr/local/bin/shfmt
    sudo chmod +x /usr/local/bin/shfmt
fi

# Install bats
if ! command -v bats &>/dev/null;
then
    echo "Installing bats..."
    sudo apt-get install -y bats
fi

echo "Development dependencies installed successfully."
