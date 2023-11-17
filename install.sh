#!/bin/bash
set -euxo pipefail
opt_path=/opt/locker
bin_alias=/bin/locker
sudo mkdir -p ${opt_path}
sudo cp ./dist/locker.jar ${opt_path}
sudo cp ./dist/locker.sh ${opt_path}
sudo touch "${opt_path}/locker.dat"
echo "${opt_path}/locker.sh \"\$@\"" | sudo tee ${bin_alias}
sudo chmod -R 755 ${opt_path}
sudo chmod -R 777 "${opt_path}/locker.dat"
sudo chmod 755 ${bin_alias}
