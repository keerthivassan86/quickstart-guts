#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Keystone host not passed. Please try again with keystone host as argument "
    exit 0
fi

KEYSTONE_HOST=$1

# Keep track of the DevStack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Update
sudo apt-get update

# Upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

sudo apt-get install -y openstack-dashboard

# Change local_settings to use version 3.
sudo bash -c 'cat << EOF >> /etc/openstack-dashboard/local_settings.py

OPENSTACK_API_VERSIONS = {
    "identity": 3
}
EOF'

sudo sed -i "s@^OPENSTACK_HOST.*@OPENSTACK_HOST = '${KEYSTONE_HOST}'@" local_settings.py

sudo service apache2 restart

sudo apt-add-repository 'deb [arch=amd64] http://guts.stackbuffet.com/deb/ trusty-updates/mitaka main'

sudo bash -c 'cat << EOF > /etc/apt/preferences
Package: *
Pin: origin "180.148.27.143"
Pin-Priority: 999
EOF'

sudo bash -c 'cat << EOF > /etc/apt/apt.conf.d/98stackbuffet
APT::Get::AllowUnauthenticated "true";
EOF'

sudo apt-get update

sudo apt-get install -y guts-dashboard
