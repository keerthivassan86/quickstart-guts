
boot_vm:
	heat stack-create -e "heat-templates/local-env.yaml" -f "heat-templates/vm.yaml" trybox
