#!/bin/bash
#
# install.sh: Installs the 'fastpull' CLI to /usr/local/bin.
#

set -e

INSTALL_DIR="/usr/local/bin"
SOURCE_FILE="bin/fastpull"

echo "Installing 'fastpull' to ${INSTALL_DIR}..."

if [[ ! -f "${SOURCE_FILE}" ]]; then
    echo "ERROR: Source file not found at '${SOURCE_FILE}'. Run this script from the project root."
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script requires sudo to install to ${INSTALL_DIR}."
    sudo cp "${SOURCE_FILE}" "${INSTALL_DIR}/fastpull"
    sudo chmod +x "${INSTALL_DIR}/fastpull"
else
    cp "${SOURCE_FILE}" "${INSTALL_DIR}/fastpull"
    chmod +x "${INSTALL_DIR}/fastpull"
fi

echo
echo "Successfully installed 'fastpull'!"
echo "Run 'fastpull --help' to get started."
