#!/bin/bash
# Usage: install-toolchains.sh <toolchains-file>
# Reads tarball-based toolchain entries from a file.
# Format: <name> <version> <url>
#
# Each toolchain is installed to /opt/toolchains/<name>-<version>/
# and its bin/ directory is added to PATH via /etc/profile.d/toolchains.sh.
# To activate in subsequent Dockerfile layers, set:
#   SHELL ["/bin/bash", "--login", "-c"]

set -euo pipefail

INSTALL_BASE=/opt/toolchains
PROFILE_SCRIPT=/etc/profile.d/toolchains.sh

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Usage: $0 <toolchains-file>" >&2
    exit 1
fi

mkdir -p "${INSTALL_BASE}"

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue

    read -r name version url <<< "$line"
    install_dir="${INSTALL_BASE}/${name}-${version}"

    echo ">>> Installing toolchain: ${name} ${version}"

    tmp_file=$(mktemp /tmp/toolchain-XXXXXX)
    curl -fsSL "${url}" -o "${tmp_file}"
    mkdir -p "${install_dir}"
    tar -xf "${tmp_file}" -C "${install_dir}" --strip-components=1
    rm "${tmp_file}"

    echo "export PATH=${install_dir}/bin:\$PATH" >> "${PROFILE_SCRIPT}"

    echo ">>> Installed: ${name} ${version} -> ${install_dir}"
done < "$1"
