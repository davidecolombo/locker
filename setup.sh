#!/bin/bash
set -euo pipefail

opt_path=/opt/locker
bin_alias=/usr/local/bin/locker
temp_dir=$(mktemp -d)

cleanup() { rm -rf "${temp_dir}"; }
trap cleanup EXIT

echo "Fetching latest locker release..."
release=$(curl -sf "https://api.github.com/repos/davidecolombo/locker/releases/latest")
jar_url=$(echo "${release}" | grep -o '"browser_download_url": *"[^"]*locker\.jar"' | grep -o 'https://[^"]*')
sh_url=$(echo "${release}"  | grep -o '"browser_download_url": *"[^"]*locker\.sh"'  | grep -o 'https://[^"]*')

if [ -z "${jar_url}" ]; then echo "Release asset locker.jar not found. Publish a GitHub release first."; exit 1; fi
if [ -z "${sh_url}"  ]; then echo "Release asset locker.sh not found. Publish a GitHub release first.";  exit 1; fi

tag=$(echo "${release}" | grep -o '"tag_name": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
echo "Downloading locker ${tag}..."
curl -sL "${jar_url}" -o "${temp_dir}/locker.jar"
curl -sL "${sh_url}"  -o "${temp_dir}/locker.sh"

echo "Downloading bundled JRE 25..."
arch=$(uname -m)
case ${arch} in
    x86_64)
        jre_url="https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jre/hotspot/normal/eclipse" ;;
    aarch64|arm64)
        jre_url="https://api.adoptium.net/v3/binary/latest/25/ga/linux/aarch64/jre/hotspot/normal/eclipse" ;;
    armv7l|armv6l|arm)
        # Temurin ships no 32-bit ARM build for Java 25; fall back to BellSoft Liberica.
        jre_url=$(curl -sf "https://api.bell-sw.com/v1/liberica/releases?version-feature=25&os=linux&arch=arm&bitness=32&package-type=tar.gz&bundle-type=jre&fields=downloadUrl" \
            | grep -o '"downloadUrl":"[^"]*"' | head -1 | grep -o 'https://[^"]*')
        if [ -z "${jre_url}" ]; then
            echo "No 32-bit ARM JRE 25 is available to bundle. Use a 64-bit OS or install Java 25 manually."; exit 1
        fi ;;
    *)
        echo "Unsupported architecture: ${arch}"; exit 1 ;;
esac
curl -L "${jre_url}" -o "${temp_dir}/jre.tar.gz"
tar xzf "${temp_dir}/jre.tar.gz" -C "${temp_dir}"
extracted=$(find "${temp_dir}" -maxdepth 1 -mindepth 1 -type d | head -1)
mv "${extracted}" "${temp_dir}/jre"

echo "Installing to ${opt_path}..."
sudo mkdir -p "${opt_path}"
sudo cp "${temp_dir}/locker.jar" "${opt_path}"
sudo cp "${temp_dir}/locker.sh"  "${opt_path}"
sudo cp -r "${temp_dir}/jre"     "${opt_path}"
if [ ! -f "${opt_path}/locker.dat" ]; then
    sudo touch "${opt_path}/locker.dat"
fi

sudo ln -sf "${opt_path}/locker.sh" "${bin_alias}"
sudo chmod 755 "${opt_path}"
sudo chmod 755 "${opt_path}/locker.sh"
sudo chmod -R 755 "${opt_path}/jre"
sudo chmod 600 "${opt_path}/locker.dat"

echo ""
echo "locker ${tag} installed. Run: locker --decrypt your-key"
