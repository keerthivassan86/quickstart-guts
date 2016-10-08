#!/bin/bash
set -x
set -e

# Debian based distros
if [ -f /etc/debian_version ]; then
    echo "Starting UP Instance Customization"
    sudo apt-get -y update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
    wget -L raw.githubusercontent.com/rajalokan/dotfiles/master/setup-workspace.sh -O /tmp/setup-workspace.sh && chmod +x /tmp/setup-workspace.sh && /tmp/setup-workspace.sh
    echo "Customization done"
fi


# RedHat based distros
if [ -f /etc/redhat-release ]; then
    echo "Starting UP Instance Customization"
    sudo yum -y update && sudo yum install -y git vim
    wget https://raw.githubusercontent.com/rajalokan/dotfiles/master/setup-workspace.sh -O /tmp/setup-workspace.sh && sudo chmod +x /tmp/setup-workspace.sh && /tmp/setup-workspace.sh
    echo "Customization done"
fi
