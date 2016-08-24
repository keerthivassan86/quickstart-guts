#!/bin/bash


#set -o xtrace
# Keep track of the DevStack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Update
sudo apt-get update

# Upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

sudo apt-get install -y ubuntu-cloud-keyring
sudo apt-add-repository 'deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main'
sudo apt-get update

PASSWORD=rajalokan
IP_ADDR=$(ifconfig eth0 | awk '/net addr/{print substr($2,6)}')
echo "Your IP Address is : ${IP_ADDR}"

# Install mysql
echo "mariadb-server mysql-server/root_password password ${PASSWORD}" | sudo debconf-set-selections
echo "mariadb-server mysql-server/root_password_again password ${PASSWORD}" | sudo debconf-set-selections

sudo apt-get -y install mariadb-server python-pymysql

# Configure your mysql installation
sudo bash -c 'cat << EOF > /etc/mysql/conf.d/openstack.cnf
[mysqld]
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF'

# Restart and setup secure installation
sudo service mysql restart

# TODO: Automate this
# mysql_secure_installation

# Verify Mysql Installation
mysql -u root -p${PASSWORD} -e "SHOW DATABASES;"

### Setup RabbitMQ
sudo apt-get -y install rabbitmq-server

sudo rabbitmqctl add_user openstack ${PASSWORD}
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

sudo rabbitmqctl list_users

### Setup Keystone

mysql -u root -p${PASSWORD} << EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${PASSWORD}';
EOF


# Configure not to setup keystone while installing
sudo bash -c 'cat << EOF > /etc/init/keystone.override
manual
EOF'

# Install keystone & apache
sudo apt-get install -y keystone apache2 libapache2-mod-wsgi

# Use this keysotne.conf instead
sudo bash -c "cat << EOF > /etc/keystone/keystone.conf
[DEFAULT]
log_dir = /var/log/keystone
admin_token = 1234567890

[database]
connection = mysql+pymysql://keystone:rajalokan@localhost/keystone

[token]
provider = fernet

[extra_headers]
Distribution = Ubuntu
EOF"

#### Sync DB and setup fernet
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

sudo bash -c 'cat <<EOF > /etc/apache2/sites-available/keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
EOF'

sudo ln -s /etc/apache2/sites-available/keystone.conf /etc/apache2/sites-enabled
sudo service apache2 restart
sudo rm -f /var/lib/keystone/keystone.db

sudo apt-get install -y python-openstackclient

export OS_TOKEN=1234567890
export OS_URL=http://${IP_ADDR}:35357/v3
export OS_IDENTITY_API_VERSION=3

openstack user list
openstack service list
openstack service create --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne identity public http://${IP_ADDR}:5000/v3
openstack endpoint create --region RegionOne identity internal http://${IP_ADDR}:5000/v3
openstack endpoint create --region RegionOne identity admin http://${IP_ADDR}:35357/v3
openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password rajalokan admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password rajalokan demo
openstack role create user
openstack role add --project demo --user demo user

unset OS_TOKEN OS_URL

# Generate admin openrc
cat > /tmp/admin_openrc << EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=rajalokan
export OS_AUTH_URL=http://${IP_ADDR}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

source /tmp/admin_openrc
openstack user list && openstack service list

# Generate demo openrc
cat > /tmp/demo_openrc << EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=rajalokan
export OS_AUTH_URL=http://${IP_ADDR}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

unset `env | grep OS_ | cut -d'=' -f1 | xargs` && env | grep OS_

source /tmp/demo_openrc
openstack user list && openstack service list

### Glance


mysql -u root -p${PASSWORD} << EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${PASSWORD}';
EOF

openstack user create --domain default --password ${PASSWORD} glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image Service" image
openstack endpoint create --region RegionOne image public http://${IP_ADDR}:9292
openstack endpoint create --region RegionOne image internal http://${IP_ADDR}:9292
openstack endpoint create --region RegionOne image admin http://${IP_ADDR}:9292

sudo apt-get install -y glance

sudo bash -c "cat <<EOF > /etc/glance/glance-api.conf
[DEFAULT]

[database]
connection = mysql+pymysql://glance:${PASSWORD}@localhost/glance

[keystone_authtoken]
auth_uri = http://${IP_ADDR}:5000
auth_url = http://${IP_ADDR}:35357
memcached_servers = ${IP_ADDR}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = ${PASSWORD}

[paste_deploy]
flavor = keystone

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
EOF"

sudo bash -c "cat <<EOF > /etc/glance/glance-registry.conf
[DEFAULT]

[database]
connection = mysql+pymysql://glance:${PASSWORD}@localhost/glance

[keystone_authtoken]
auth_uri = http://${IP_ADDR}:5000
auth_url = http://${IP_ADDR}:35357
memcached_servers = ${IP_ADDR}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = ${PASSWORD}

EOF"

sudo su -s /bin/sh -c "glance-manage db_sync" glance

sudo service glance-registry restart
sudo service glance-api restart

openstack image list

wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img -O /tmp/cirros.img

openstack image create "cirros" --file /tmp/cirros.img --disk-format qcow2 --container-format bare --public
openstack image list


### Compute Service

mysql -u root -p${PASSWORD} << EOF
CREATE DATABASE nova_api;
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${PASSWORD}';
EOF


openstack user create --domain default --password ${PASSWORD} nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute Service" compute
openstack endpoint create --region RegionOne compute public http://${IP_ADDR}:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://${IP_ADDR}:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://${IP_ADDR}:8774/v2.1/%\(tenant_id\)s

sudo apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler

sudo bash -c "cat <<EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = ${IP_ADDR}
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
enabled_apis = osapi_compute,metadata
rpc_backend = rabbit
auth_strategy = keystone

[keystone_authtoken]
auth_uri = http://${IP_ADDR}:5000
auth_url = http://${IP_ADDR}:35357
memcached_servers = ${IP_ADDR}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = ${PASSWORD}

[api_database]
connection = mysql+pymysql://nova:${PASSWORD}@localhost/nova_api

[database]
connection = mysql+pymysql://nova:${PASSWORD}@localhost/nova

[oslo_messaging_rabbit]
rabbit_host = ${IP_ADDR}
rabbit_userid = openstack
rabbit_password = ${PASSWORD}

[vnc]
vncserver_listen = ${IP_ADDR}
vncserver_proxyclient_address = ${IP_ADDR}

[glance]
api_servers = http://${IP_ADDR}:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

EOF"

sudo su -s /bin/sh -c "nova-manage api_db sync" nova
sudo su -s /bin/sh -c "nova-manage db sync" nova

sudo service nova-api restart
sudo service nova-consoleauth restart
sudo service nova-scheduler restart
sudo service nova-conductor restart
sudo service nova-novncproxy restart


sudo apt-get install nova-compute

# Switch to QEMU
sudo service nova-compute restart

openstack compute service list

### Neutron
mysql -u root -p${PASSWORD} << EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '${PASSWORD}';
EOF

openstack user create --domain default --password ${PASSWORD} neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking Service" network
openstack endpoint create --region RegionOne network public http://${IP_ADDR}:9696
openstack endpoint create --region RegionOne network internal http://${IP_ADDR}:9696
openstack endpoint create --region RegionOne network admin http://${IP_ADDR}:9696

sudo apt-get install -y neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent

sudo bash -c "cat <<EOF > /etc/neutron/neutron.conf
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

[keystone_authtoken]
auth_uri = http://${IP_ADDR}:5000
auth_url = http://${IP_ADDR}:35357
memcached_servers = ${IP_ADDR}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = ${PASSWORD}

[oslo_messaging_rabbit]
rabbit_host = ${IP_ADDR}
rabbit_userid = openstack
rabbit_password = ${PASSWORD}

[database]
connection = mysql+pymysql://neutron:${PASSWORD}@localhost/neutron

[nova]
auth_url = http://${IP_ADDR}:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = ${PASSWORD}

EOF"

sudo bash -c "cat <<EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security

[ml2_type_flat]
flat_networks = provider

[ml2_type_vxlan]
vni_ranges = 1:1000

[securitygroup]
enable_ipset = True

EOF"

sudo bash -c "cat << EOF > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[linux_bridge]
physical_interface_mappings = provider:eth0

[vxlan]
enable_vxlan = True
local_ip = ${IP_ADDR}
l2_population = True

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver]

EOF"

sudo bash -c "cat << EOF > /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
external_network_bridge =

EOF"


sudo bash -c "cat << EOF > /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True

EOF"


## Configure compute node
sudo apt-get install -y neutron-linuxbridge-agent

sudo bash -c "cat <<EOF >> /etc/nova/nova.conf

[neutron]
uri = http://${IP_ADDR}:9696
auth_url = http://${IP_ADDR}:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = ${PASSWORD}

EOF"

sudo service nova-compute restart

sudo service neutron-linuxbridge-agent restart


sudo bash -c "cat << EOF > /etc/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_ip = ${IP_ADDR}
metadata_proxy_shared_secret = 1234567890

EOF"

sudo bash -c "cat << EOF >> /etc/nova/nova.conf
service_metadata_proxy = True
metadata_proxy_shared_secret = 1234567890
EOF"

sudo su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

sudo service nova-api restart

sudo service neutron-server restart
sudo service neutron-linuxbridge-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-metadata-agent restart

sudo service neutron-l3-agent restart


# Run few commands
openstack user list
openstack keypair list
ssh-keygen -t rsa -f ~/.ssh/cloud.key -N ''
openstack keypair create --public-key ~/.ssh/cloud.key.pub osid
openstack keypair list

openstack security group rule list default
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --src-ip 0.0.0.0/0 --dst-port 22 default
openstack security group rule list default

openstack network create --share public
neutron subnet-create --allocation-pool start=192.168.167.151,end=192.168.167.200 --dns-nameserver '8.8.8.8' public 192.168.167.0/24
openstack network create --share private
neutron subnet-create private 10.0.0.0/24

openstack server create --image cirros --flavor m1.tiny --security-group default --key-name osid --nic "net-id=$(openstack network show -f value -c id private)" trybox01
openstack server list
openstack ip floating add $(openstack ip floating create -f value -c ip public) trybox01

## Setup Dashboard


##
