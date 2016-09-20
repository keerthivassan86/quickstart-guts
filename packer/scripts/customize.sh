#!/bin/bash
set -x
set -e

echo "Starting UP Instance Customization"
sudo apt-get -y update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
wget -L raw.githubusercontent.com/rajalokan/dotfiles/master/setup-workspace.sh -O /tmp/setup-workspace.sh && chmod +x /tmp/setup-workspace.sh && /tmp/setup-workspace.sh
echo "Customization done"
