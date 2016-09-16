
include constants

boot_keystone:
	heat stack-create -P name="keystone" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_181} -f "heat-templates/keystone.yaml" keystone

boot_guts:
	heat stack-create -P name="guts" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -f "heat-templates/guts.yaml" guts

boot_guts_dashboard:
	heat stack-create -P name="gdashboard" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -f "heat-templates/guts_dashboard.yaml" guts_dashboard

boot_guts_source:
	heat stack-create -P name="gsource" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P keypair='cloud' -f "heat-templates/guts_source.yaml" guts_source

boot_okanbox:
	heat stack-create -P name="okanbox" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_204} -f "heat-templates/okanbox.yaml" okanbox

boot_playbox:
	heat stack-create -P name="playbox" -P image=${IMAGE} -P network=${NETWORK_ALOK} -P subnet=${SUBNET_ALOK} -P security_group=${SEC_GRP_ALOK} -P floating_ip=${FLOATING_IP_163} -f "heat-templates/playbox.yaml" playbox
