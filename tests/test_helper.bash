#!/usr/bin/env bash

# Mock external commands to avoid network calls and sudo
# This is a very basic form of mocking.

# Mock curl
curl() {
    echo "Mocked curl call with args: $@" >&2
    if [[ "$1" == *"/releases/latest"* ]]; then
        echo '{ "tag_name": "v2.300.0", "assets": [ { "name": "actions-runner-linux-x64-2.300.0.tar.gz", "browser_download_url": "https://example.com/runner.tar.gz" } ] }'
    elif [[ "$1" == *"/zen"* ]]; then
        echo "Mocked Zen"
    fi
}

# Mock sudo
sudo() {
    echo "Mocked sudo call with command: $@" >&2
    # Execute the command without sudo
    "$@"
}

# Mock systemctl
systemctl() {
    echo "Mocked systemctl call with args: $@" >&2
    return 0
}

# Mock jq
jq() {
    # A very dumb mock for jq
    if [[ "$2" == *".browser_download_url"* ]]; then
        echo "https://example.com/runner.tar.gz"
    elif [[ "$2" == *".tag_name"* ]]; then
        echo "v2.300.0"
    else
        command jq "$@"
    fi
}
