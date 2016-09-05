
boot_keystone:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/keystone.yaml" gutsdev
