#!/bin/bash
# Usage: install-packages.sh <packages-file>
# Reads package names from a file (one per line, # for comments)
# and installs them in a single layer with cache cleanup.

set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Usage: $0 <packages-file>" >&2
    exit 1
fi

mapfile -t packages < <(grep -v '^\s*#' "$1" | grep -v '^\s*$')

if [ "${#packages[@]}" -eq 0 ]; then
    echo "No packages found in $1" >&2
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends "${packages[@]}"
apt-get clean
rm -rf /var/lib/apt/lists/*
