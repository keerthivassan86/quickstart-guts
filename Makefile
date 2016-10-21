
include constants

list:
	openstack stack list

boot_uplaybox:
	heat stack-create -P image=${U1404} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/playbox.yaml" playbox

boot_cplaybox:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/playbox.yaml" playbox

boot_ukeystone:
	heat stack-create -P image=${U1404} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/keystone.yaml" keystone

boot_ckeystone:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/keystone.yaml" keystone

boot_uguts:
	heat stack-create -P image=${U1404} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/guts.yaml" guts

boot_cguts:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/guts.yaml" guts

boot_uguts_dashboard:
	heat stack-create -P image=${U1404} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/guts_dashboard.yaml" guts_dashboard

boot_cguts_dashboard:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/guts_dashboard.yaml" guts_dashboard

boot_uokanstack:
	heat stack-create -P image=${U1404} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_181} -f "heat-templates/okanstack.yaml" okanstack

boot_cokanstack:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_181} -f "heat-templates/okanstack.yaml" okanstack

boot_uaio:
	heat stack-create -P image=${U1404} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/aio.yaml" aio

boot_caio:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} \
	-P security_group=${SEC_GRP_ALOK} -f "heat-templates/aio.yaml" aio

boot_udevstack:
	heat stack-create -P image=${U1404} -P network=${NETWORK_DEVSTACK} -P subnet=${SUBNET_OKANSTACK} \
	-P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_181} \
	-f "heat-templates/devstack.yaml" devstack

boot_cdevstack:
	heat stack-create -P image=${CENTOS7} -P network=${NETWORK_DEVSTACK} -P subnet=${SUBNET_OKANSTACK} \
	-P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_181} \
	-f "heat-templates/devstack.yaml" devstack

build_u1404:
	cd packer && ./packer build -var-file u1404_variables.json u1404.json

build_centos7:
	cd packer && ./packer build -var-file centos7_variables.json centos7.json
