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
    # Setup common services + keystone + guts
    keystone

    source ${SCRIPTS_DIR}/guts
    setup_guts
}

function guts-dashboard {
    # Setup common services + keystone + guts + horizon + guts-dashboard
    guts
    horizon

    source ${SCRIPTS_DIR}/guts-dashboard
    setup_guts_dashboard
}

function horizon {
    # Setup horizon
    source ${SCRIPTS_DIR}/horizon
    setup_horizon
}



case ${1} in
"keystone")
    keystone
    ;;
"guts")
    guts
    ;;
"guts-dashboard")
    guts-dashboard
    ;;
"horizon")
    horizon
    ;;
*)
    echo "Nothing"
    ;;
esac

exit 0
