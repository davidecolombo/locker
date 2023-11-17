#!/bin/bash
set -euxo pipefail
opt_path=/opt/locker
bin_alias=/bin/locker
sudo rm -rf ${opt_path}
sudo rm -rf ${bin_alias}
