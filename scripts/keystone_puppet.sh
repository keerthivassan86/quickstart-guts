#!/usr/bin/env bash

# ``aio_puppet.sh`` is an opinionated OpenStack installation for quickly setting up
# GUTS - A Workload Migration Engine using puppet.

#sudo apt-get -y update
#sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt-get -y install puppet
#sudo puppet module install puppetlabs/apt
sudo touch /etc/puppet/hiera.yaml
sudo puppet apply guts.pp
