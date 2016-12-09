#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Keystone host not passed. Please try again with keystone host as argument "
    exit 0
fi

KEYSTONE_HOST=$1
KEYSTONE_HOST="192.168.189.5"


mkvirtualenv horizon

STACK_DIR="/opt/stack"
HORIZON_DIR=${STACK_DIR}/horizon
sudo mkdir -p /opt/stack && sudo chown -R ubuntu:ubuntu ${STACK_DIR}
git clone https://github.com/openstack/horizon.git -b stable/mitaka ${HORIZON_DIR}
cd ${HORIZON_DIR} && sudo -H pip install -e .
mv ${HORIZON_DIR}/openstack_dashboard/local/local_settings.py.example ${HORIZON_DIR}/openstack_dashboard/local/local_settings.py

cat >> ${HORIZON_DIR}/openstack_dashboard/local/local_settings.py << EOF

OPENSTACK_API_VERSIONS = {
    "identity": 3
}
EOF

sudo sed -i "s@^OPENSTACK_HOST.*@OPENSTACK_HOST = '${KEYSTONE_HOST}'@" ${HORIZON_DIR}/openstack_dashboard/local/local_settings.py
cd ${HORIZON_DIR} && ./manage.py runserver 0.0.0.0:8888


GUTS_DASHBOARD_DIR=${STACK_DIR}/guts-dashboard
git clone https://github.com/aptira/guts-dashboard ${GUTS_DASHBOARD_DIR}
cd ${GUTS_DASHBOARD_DIR} && pip install -e .
git clone https://github.com/aptira/python-gutsclient ${STACK_DIR}/python-gutsclient
pip install -e ${STACK_DIR}/python-gutsclient
ln -s ${GUTS_DASHBOARD_DIR}/gutsdashboard/local/_50_guts.py ${HORIZON_DIR}/openstack_dashboard/local/enabled/_50_guts.py
ln -s ${GUTS_DASHBOARD_DIR}/gutsdashboard/local/_5010_guts_services.py ${HORIZON_DIR}/openstack_dashboard/local/enabled/_5010_guts_services.py
ln -s ${GUTS_DASHBOARD_DIR}/gutsdashboard/local/_5020_guts_resources.py ${HORIZON_DIR}/openstack_dashboard/local/enabled/_5020_guts_resources.py
ln -s ${GUTS_DASHBOARD_DIR}/gutsdashboard/local/_5030_guts_migrations.py ${HORIZON_DIR}/openstack_dashboard/local/enabled/_5030_guts_migrations.py
cd ${HORIZON_DIR} && ./manage.py runserver 0.0.0.0:8888


sudo apt-get -y install xclip
ssh-keygen -t rsa -f ~/.ssh/cloud.key -N ''
xclip -sel clip < ~/.ssh/cloud.key.pub
eval `ssh-agent -s`
ssh-add ~/.ssh/cloud.key
ssh ubuntu@192.168.189.5
