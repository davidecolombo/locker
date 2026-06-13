#!/bin/bash
set -euo pipefail

opt_path=/opt/locker
bin_alias=/usr/local/bin/locker

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
