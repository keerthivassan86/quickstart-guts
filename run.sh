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


function common {
    source ${SCRIPTS_DIR}/common
    update_and_upgrade
}

function openstack_common {
    source ${SCRIPTS_DIR}/openstack_common
    install_cloud_keyring
    install_mysql
    install_rabbitmq
    install_clients
}

function keystone {
    source ${SCRIPTS_DIR}/keystone
    setup_keystone
}

function glance {
    source ${SCRIPTS_DIR}/glance
    setup_glance
}

function nova {
    source ${SCRIPTS_DIR}/nova
    setup_nova
}

function neutron {
    source ${SCRIPTS_DIR}/neutron
    setup_neutron
}

function guts {
    source ${SCRIPTS_DIR}/guts
    setup_guts
}

function guts_source {
    source ${SCRIPTS_DIR}/guts
    setup_guts_source
}

function horizon {
    source ${SCRIPTS_DIR}/horizon
    setup_horizon
}

function guts_dashboard {
    source ${SCRIPTS_DIR}/guts-dashboard
    setup_guts_dashboard
}

function devstack {
    source ${SCRIPTS_DIR}/devstack
    setup_devstack
}


case ${1} in
"playbox")
    common
    ;;
"keystone")
    common
    openstack_common
    keystone
    ;;
"guts")
    common
    openstack_common
    keystone
    guts
    ;;
"guts_source")
    common
    openstack_common
    keystone
    guts_source
    ;;
"guts_dashboard")
    common
    openstack_common
    keystone
    guts
    horizon
    guts_dashboard
    ;;
"aio")
    common
    openstack_common
    keystone
    glance
    nova
    neutron
    horizon
    ;;
"devstack")
    common
    devstack
    ;;
*)
    echo "Nothing to deploy"
    ;;
esac

exit 0
