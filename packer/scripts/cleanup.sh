#!/bin/bash
set -x
set -e

# Debian based distros
if [ -f /etc/debian_version ]; then
    sudo apt-get -q -y autoremove
    sudo apt-get -q -y autoclean
    sudo apt-get -q -y clean all
fi

# RedHat based distros
if [ -f /etc/redhat-release ]; then
    # Clean yum/dnf
    if hash dnf 2>/dev/null; then
        dnf -y clean all
    else
        yum -y clean all
    fi
fi

# Remove cloud-init files
rm -fr /var/lib/cloud/*
