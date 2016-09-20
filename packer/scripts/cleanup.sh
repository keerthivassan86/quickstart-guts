#!/bin/bash
set -x
set -e

sudo apt-get -q -y autoremove
sudo apt-get -q -y autoclean
sudo apt-get -q -y clean all
