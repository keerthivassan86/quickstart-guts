#!/bin/bash

if [[ $# -gt 1 ]]; then
    echo "Invalid Args"
fi

#set -o xtrace

# Keep track of the root directory
TOP_DIR=$(cd $(dirname "$0") && pwd)
SCRIPTS_DIR=${TOP_DIR}/scripts
CONFIG_DIR=${TOP_DIR}/configs
OPENRC_DIR="/opt/openrc"


PASSWORD=rajalokan
IP_ADDR=$(ifconfig eth0 | awk '/net addr/{print substr($2,6)}')

function common {
    source ${SCRIPTS_DIR}/common

    update_and_upgrade
    install_cloud_keyring
    install_mysql
    install_rabbitmq
    install_clients
}

function keystone {
    # Setup common services
    common

    source ${SCRIPTS_DIR}/keystone
    setup_keystone
}

function guts {
    # Setup Keystone
    keystone

    source ${SCRIPTS_DIR}/guts
    setup_guts
}

function horizon {
    echo "Settings up MySQL + RabbitMQ + Keystone + Horizon"

    source ${SCRIPTS_DIR}/horizon
    setup_horizon
}

function guts-dashboard {
    echo "Settings up MySQL + RabbitMQ + Keystone + Horizon + Guts + Guts-dashboard"

    guts
    horizon

    source ${SCRIPTS_DIR}/guts-dashboard
    setup_guts_dashboard
}

case ${1} in
"keystone")
    keystone
    ;;
"horizon")
    horizon
    ;;
"guts")
    guts
    ;;
"guts-dashboard")
    guts-dashboard
    ;;
*)
    echo "Nothing"
    ;;
esac

exit 0
