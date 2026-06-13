#!/bin/bash
set -euo pipefail

opt_path=/opt/locker
bin_alias=/usr/local/bin/locker

sudo rm -rf "${opt_path}"
sudo rm -f  "${bin_alias}"
