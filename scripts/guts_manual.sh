#!/bin/bash

# Create database table
mysql -u root -p${PASSWORD} << EOF
CREATE DATABASE guts;
GRANT ALL PRIVILEGES ON guts.* TO 'guts'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON guts.* TO 'guts'@'%' IDENTIFIED BY '${PASSWORD}';
EOF

unset `env | grep OS_ | cut -d'=' -f1 | xargs` && env | grep OS_

source /home/ubuntu/admin_openrc


# Create keystone entries
openstack user create --domain default --password rajalokan guts
openstack role add --project service --user guts admin
openstack service create --name guts --description "OpenStack Migration Service" migration
openstack endpoint create --region RegionOne migration public http://${IP_ADDR}:7000/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne migration internal http://${IP_ADDR}:7000/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne migration admin http://${IP_ADDR}:87000/v1/%\(tenant_id\)s

# Create guts user and setup permissions


SERVICE="guts"
STACK_DIR="/opt/stack"
sudo addgroup --system guts
sudo adduser --system --home /var/lib/guts --ingroup guts --no-create-home --shell /bin/false guts

#sudo update-alternatives --config editor
sudo bash -c 'cat << EOF > /etc/sudoers.d/guts_sudoers
Defaults:guts !requiretty

guts ALL = (root) NOPASSWD: /usr/local/bin/guts-rootwrap
EOF'

#sudo useradd --home-dir /var/lib/$SERVICE --create-home --system --shell /bin/false $SERVICE
sudo mkdir -p /var/log/$SERVICE /etc/$SERVICE /tmp/virtio-tools /var/lib/guts
sudo apt-get install -y p7zip-full
sudo wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso -O /tmp/virtio-tools/virtio-win.iso
cd /tmp/virtio-tools && sudo 7z x /tmp/virtio-tools/virtio-win.iso  > /dev/null 2>&1;
sudo chown -R $SERVICE:$SERVICE /var/log/$SERVICE
sudo chown -R $SERVICE:$SERVICE /var/lib/$SERVICE
sudo chown $SERVICE:$SERVICE /etc/$SERVICE


# Clone source code
sudo mkdir -p /opt/stack \
    && sudo chown -R ubuntu:ubuntu /opt/stack \
    && git clone https://github.com/aptira/guts.git /opt/stack/guts \
    && git clone https://github.com/aptira/python-gutsclient.git /opt/stack/python-gutsclient \
    && git clone https://github.com/aptira/guts-dashboard.git /opt/stack/guts-dashboard

# Copy configurations
sudo cp -R ${STACK_DIR}/${SERVICE}/etc/* /etc/

# Create Virtualenv and Install Dependencies
mkvirtualenv guts \
    && cd ${STACK_DIR}/guts \
    && sudo -H pip install -r requirements.txt -e . \
    && cd ${STACK_DIR}/python-gutsclient \
    && sudo -H pip install -r requirements.txt -e .

# Configuration
sudo bash -c 'cat << EOF > /etc/guts/guts.conf
[DEFAULT]
osapi_migration_workers = 2
rpc_backend = rabbit
debug = True
auth_strategy = keystone

[keystone_authtoken]
auth_uri = http://localhost:5000
auth_url = http://localhost:35357
memcached_servers = localhost:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = guts
password = rajalokan

[database]
connection = mysql+pymysql://guts:rajalokan@localhost/guts

[oslo_concurrency]
lock_path = /var/lib/guts

[oslo_messaging_rabbit]
rabbit_userid = openstack
rabbit_password = rajalokan
rabbit_host = 127.0.0.1
EOF'

# Databse creation
sudo su -s /bin/sh -c "guts-manage db sync" guts

# Run Services
sudo su -s /bin/sh -c "guts-api" guts
guts list
guts source-list
guts service-list

sudo su -s /bin/sh -c "guts-scheduler" guts

sudo su -s /bin/sh -c "guts-migration" guts

sudo su -s /bin/sh -c "sudo apt-get update" guts
