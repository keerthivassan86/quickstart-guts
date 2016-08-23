#!/usr/bin/env bash


#set -o xtrace
# Keep track of the DevStack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Update
#sudo apt-get update

# Upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

sudo apt-get install -y ubuntu-cloud-keyring
sudo apt-add-repository 'deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main'
#sudo apt-get update

PASSWORD=rajalokan
IP_ADDR=$(ifconfig eth0 | awk '/net addr/{print substr($2,6)}')

# Install mysql
echo "mariadb-server mysql-server/root_password password ${PASSWORD}" | sudo debconf-set-selections
echo "mariadb-server mysql-server/root_password_again password ${PASSWORD}" | sudo debconf-set-selections

sudo apt-get -y install mariadb-server python-pymysql

# Configure your mysql installation
sudo bash -c "cat << EOF > /etc/mysql/conf.d/openstack.cnf
[mysqld]
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF"

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
sudo bash -c "cat << EOF > /etc/init/keystone.override
manual
EOF"

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

sudo bash -c "cat <<EOF > /etc/apache2/sites-available/keystone.conf
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
EOF"

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
cat > admin_openrc << EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=rajalokan
export OS_AUTH_URL=http://${IP_ADDR}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

source admin_openrc
openstack user list && openstack service list

# Generate demo openrc
cat > demo_openrc << EOF
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

source demo_openrc
openstack user list && openstack service list
