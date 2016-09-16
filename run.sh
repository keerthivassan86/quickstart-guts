#!/bin/bash

if [[ $# -gt 1 ]]; then
    echo "Invalid Args"
fi

#set -o xtrace

# Keep track of the root directory
TOP_DIR=$(cd $(dirname "$0") && pwd)
OPT_DIR="/opt"
SCRIPTS_DIR=${TOP_DIR}/scripts
CONFIG_DIR=${TOP_DIR}/configs
OPENRC_DIR="${OPT_DIR}/openrc"
STACK_DIR="${OPT_DIR}/stack"


PASSWORD=rajalokan
IP_ADDR=$(ifconfig eth0 | awk '/net addr/{print substr($2,6)}')

function update_and_upgrade {
    update_and_upgrade
}

function common {
    update_and_upgrade

    source ${SCRIPTS_DIR}/common
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

function guts_source {
    keystone

    source ${SCRIPTS_DIR}/guts
    setup_guts_source
}

function guts_dashboard {
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
"playbox")
    update_and_upgrade
    ;;
"keystone")
    keystone
    ;;
"guts")
    guts
    ;;
"guts_dashboard")
    guts_dashboard
    ;;
"horizon")
    horizon
    ;;
"guts_source")
    guts_source
    ;;
*)
    echo "Nothing"
    ;;
esac

exit 0
