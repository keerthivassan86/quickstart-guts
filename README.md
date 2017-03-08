

## Ubuntu - 14.04

### Update & Upgrade
```
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
```

### Setup ubuntu cloud archive repo
```
sudo apt-get install -y ubuntu-cloud-keyring
sudo apt-add-repository 'deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main'
sudo apt-get update
```

### Setup MySQL
```
# Install MySQL
sudo apt-get install -y mariadb-server python-pymysql

# Chose a root password accordingly. We will use `rajalokan` as the root password.
PASSWORD=rajalokan
IP_ADDR=$(ifconfig eth0 | awk '/net addr/{print substr($2,6)}')

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
mysql_secure_installation

# Verify Mysql Installation
mysql -u root -p${PASSWORD} -e "SHOW DATABASES;"
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
```

### Setup RabbitMQ
```
# Install RabbitMQ
sudo apt-get install -y rabbitmq-server

# Add a user to rabbitmq and setup permission
sudo rabbitmqctl add_user openstack ${PASSWORD}
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Verify Installation
sudo rabbitmqctl list_users
Listing users ...
guest   [administrator]
openstack       []
```

### Setup Keystone

#### Install and configure Keystone
```
# Setup Database for Keystone
mysql -u root -p${PASSWORD} -e "CREATE DATABASE keystone;"
mysql -u root -p${PASSWORD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'rajalokan';"
mysql -u root -p${PASSWORD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'rajalokan';"

# Configure not to setup keystone while installing
sudo bash -c 'cat << EOF > /etc/init/keystone.override
manual
EOF'

# Install keystone & apache
sudo apt-get install -y keystone apache2 libapache2-mod-wsgi

# Use this keysotne.conf instead
sudo bash -c 'cat << EOF > /etc/keystone/keystone.conf
[DEFAULT]
log_dir = /var/log/keystone
admin_token = 1234567890

[database]
connection = mysql+pymysql://keystone:rajalokan@localhost/keystone

[token]
provider = fernet

[extra_headers]
Distribution = Ubuntu
EOF'
```

#### Sync DB and setup fernet
```
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
```

#### Configure Apache
```
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
```

#### Install python-openstackclient & setup credentials
```
sudo apt-get install -y python-openstackclient
export OS_TOKEN=1234567890
export OS_URL=http://${IP_ADDR}:35357/v3
export OS_IDENTITY_API_VERSION=3
```

#### Setup basic keystone
```
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
```

#### Verify keystone installation using openrc
```
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
```

### Option 1 - Setup Guts from Binary

#### Prepare Guts source
```
# Setup guts repo
sudo apt-add-repository 'deb [arch=amd64] http://guts.stackbuffet.com/deb/ trusty-updates/mitaka main'

sudo bash -c 'cat << EOF > /etc/apt/preferences
Package: *
Pin: origin "180.148.27.143"
Pin-Priority: 999
EOF'

sudo bash -c 'cat << EOF > /etc/apt/apt.conf.d/98stackbuffet
APT::Get::AllowUnauthenticated "true";
EOF'

sudo apt-get update
```

#### Create database and keystone entry for guts
```
mysql -u root -p${PASSWORD} -e "CREATE DATABASE guts;"
mysql -u root -p${PASSWORD} -e "GRANT ALL PRIVILEGES ON guts.* TO 'guts'@'localhost' IDENTIFIED BY 'rajalokan';"
mysql -u root -p${PASSWORD} -e "GRANT ALL PRIVILEGES ON guts.* TO 'guts'@'%' IDENTIFIED BY 'rajalokan';"

unset `env | grep OS_ | cut -d'=' -f1 | xargs` && env | grep OS_
source admin_openrc
openstack user create --domain default --password rajalokan guts
openstack role add --project service --user guts admin
openstack service create --name guts --description "OpenStack Migration Service" migration
openstack endpoint create --region RegionOne migration public http://${IP_ADDR}:7000/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne migration internal http://${IP_ADDR}:7000/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne migration admin http://${IP_ADDR}:87000/v1/%\(tenant_id\)s
```

#### Install and configure guts-api
```
sudo apt-get install -y guts-api

# Use this guts.conf instead
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
```

#### Sync db
```
sudo su -s /bin/sh -c "guts-manage db sync" guts
sudo service guts-api restart
```
#### Verify Guts API
```
guts list
guts source-list
guts service-list
```

#### Install and configure guts-scheduler
```
sudo apt-get install -y guts-scheduler guts-migration
```

#### Verify scheduler and migration services are up
```
guts service-list
```

#### Install and configure guts-dashboard
```
sudo apt-get install -y openstack-dashboard

# Change local_settings to use version 3.

sudo apt-get install -y guts-dashboard
```

### Option 2 - Setup Guts from Source
```
SERVICE=guts
sudo useradd --home-dir "/var/lib/$SERVICE" --create-home --system --shell /bin/false $SERVICE

#Create essential dirs
sudo mkdir -p /var/log/$SERVICE
sudo mkdir -p /etc/$SERVICE

#Set ownership of the dirs
sudo chown -R $SERVICE:$SERVICE /var/log/$SERVICE
sudo chown -R $SERVICE:$SERVICE /var/lib/$SERVICE
sudo chown $SERVICE:$SERVICE /etc/$SERVICE
```
# setup guts sudoers
```
sudo bash -c "cat << EOF > /etc/sudoers.d/guts_sudoers
Defaults:guts !requiretty
guts ALL = (root) NOPASSWD: /usr/local/bin/guts-rootwrap
EOF"
```

# setup_guts_database
mysql -u root -p${PASSWORD} << EOF
CREATE DATABASE guts;
GRANT ALL PRIVILEGES ON guts.* TO 'guts'@'localhost' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON guts.* TO 'guts'@'%' IDENTIFIED BY '${PASSWORD}';
EOF

# populate_keystone_guts
```
openstack user create --domain default --password ${PASSWORD} guts
openstack role add --project service --user guts admin
openstack service create --name guts --description "OpenStack Migration Service" migration
openstack endpoint create --region RegionOne migration public http://${IP_ADDR}:7000/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne migration internal http://${IP_ADDR}:7000/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne migration admin http://${IP_ADDR}:87000/v1/%\(tenant_id\)s
```


# install_guts_source
```
# Create stack directory and give permissions
STACK_DIR="/opt/stack"
sudo mkdir -p ${STACK_DIR} && sudo chown -R ${USER}:${USER} ${STACK_DIR}

# Clone and install guts
git clone https://github.com/aptira/guts.git ${STACK_DIR}/guts
sudo -H pip install -e ${STACK_DIR}/guts

# Copy configuration files to /etc/guts
cd ${STACK_DIR}/guts && sudo cp -R etc/* /etc/

# Clone and install python-gutsclient
git clone https://github.com/aptira/python-gutsclient.git ${STACK_DIR}/python-gutsclient
sudo -H pip install -e ${STACK_DIR}/python-gutsclient
```

# configure_guts
```
sudo bash -c "cat << EOF > /etc/guts/guts.conf
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
password = ${PASSWORD}
[database]
connection = mysql+pymysql://guts:${PASSWORD}@localhost/guts
[oslo_concurrency]
lock_path = /var/lib/guts
[oslo_messaging_rabbit]
rabbit_userid = openstack
rabbit_password = ${PASSWORD}
rabbit_host = 127.0.0.1
EOF"

# Populate database
sudo su -s /bin/sh -c "guts-manage db sync" guts
```
