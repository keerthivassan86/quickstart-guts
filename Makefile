
include constants

boot_keystone:
	heat stack-create -P name="keystone" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_181} -f "heat-templates/keystone.yaml" keystone

boot_guts:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/guts.yaml" gutsdev

boot_guts_dashboard:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/guts_dashboard.yaml" gutsdev

boot_okanbox:
	heat stack-create -P name="okanbox" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_204} -f "heat-templates/okanbox.yaml" okanbox

boot_devbox:
	heat stack-create -P name="devbox" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P keypair='cloud' -f "heat-templates/devbox.yaml" devbox
