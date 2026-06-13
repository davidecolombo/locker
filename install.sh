#!/bin/bash
set -euo pipefail

opt_path=/opt/locker
bin_alias=/usr/local/bin/locker
skip_jre_download=false

for arg in "$@"; do
    case $arg in
        --skip-jre-download) skip_jre_download=true ;;
    esac
done

sudo mkdir -p "${opt_path}"
sudo cp ./dist/locker.jar "${opt_path}"
sudo cp ./dist/locker.sh  "${opt_path}"
if [ ! -f "${opt_path}/locker.dat" ]; then
    sudo touch "${opt_path}/locker.dat"
fi

sudo ln -sf "${opt_path}/locker.sh" "${bin_alias}"

sudo chmod 755 "${opt_path}"
sudo chmod 755 "${opt_path}/locker.sh"
sudo chmod 600 "${opt_path}/locker.dat"

# JRE — download from Adoptium if not already present
jre_dir="${opt_path}/jre"
if [ ! -x "${jre_dir}/bin/java" ] && [ "${skip_jre_download}" = false ]; then
    echo "Downloading Eclipse Temurin JRE 25..."
    arch=$(uname -m)
    case ${arch} in
        x86_64)  adoptium_arch=x64 ;;
        aarch64) adoptium_arch=aarch64 ;;
        *)        echo "Unsupported architecture: ${arch}"; exit 1 ;;
    esac
    jre_tmp=$(mktemp -d)
    curl -L "https://api.adoptium.net/v3/binary/latest/25/ga/linux/${adoptium_arch}/jre/hotspot/normal/eclipse" \
        -o "${jre_tmp}/jre.tar.gz"
    tar xzf "${jre_tmp}/jre.tar.gz" -C "${jre_tmp}"
    extracted=$(find "${jre_tmp}" -maxdepth 1 -mindepth 1 -type d | head -1)
    sudo mv "${extracted}" "${jre_dir}"
    rm -rf "${jre_tmp}"
    sudo chmod -R 755 "${jre_dir}"
    echo "JRE installed."
fi
