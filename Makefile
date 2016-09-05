
boot_keystone:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/keystone.yaml" gutsdev

boot_guts:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/guts.yaml" gutsdev

boot_guts_dashboard:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/guts_dashboard.yaml" gutsdev
