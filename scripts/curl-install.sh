#!/bin/bash
#
# This script downloads and installs the 'fastpull' CLI.
#
# Usage: curl -sSL https://raw.githubusercontent.com/YOUR_GITHUB_OWNER/YOUR_FASTPULL_REPO/main/scripts/curl-install.sh | bash
#
# You can customize the installation by setting environment variables:
#   - FASTPULL_REF: The git ref (branch, tag, commit) to install from (default: main).
#   - FASTPULL_PREFIX: The installation prefix (default: /usr/local).

set -e

# --- Configuration ---
GITHUB_REPO="YOUR_GITHUB_OWNER/YOUR_FASTPULL_REPO"
: "${FASTPULL_REF:=main}"
: "${FASTPULL_PREFIX:=/usr/local}"

# --- Helper Functions ---
_log_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

_log_info() {
    echo "[INFO] $1"
}

# --- Main Logic ---
main() {
    _log_info "Starting fastpull installation..."
    
    local download_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${FASTPULL_REF}/bin/fastpull"
    local install_path="${FASTPULL_PREFIX}/bin/fastpull"
    local temp_file
    temp_file=$(mktemp)

    _log_info "Downloading fastpull from ${download_url}..."
    if ! curl -fsSL "${download_url}" -o "${temp_file}"; then
        _log_error "Failed to download the script. Check the URL and your network connection."
    fi

    chmod +x "${temp_file}"

    _log_info "Installing to ${install_path}..."
    if [[ "$(id -u)" -ne 0 ]]; then
        _log_info "Sudo privileges required."
        sudo mv "${temp_file}" "${install_path}"
    else
        mv "${temp_file}" "${install_path}"
    fi

    _log_info "Installation complete!"
    _log_info "Run 'fastpull --help' to get started."
}

main "$@"
