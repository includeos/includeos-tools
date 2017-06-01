#!/bin/bash

echo -e ">>> Running Openstack Test"

INCLUDEOS_SRC=${INCLUDEOS_SRC-~/IncludeOS}
INCLUDEOS_TOOLS=${INCLUDEOS_TOOLS-~/includeos-tools}
NAME=pull_request_openstack

# Preemptive checks to see if there is openstack support
echo -e "\n\n>>> Checking if the required Openstack tools are installed"
errors=0
which openstack > /dev/null 2>&1 || { echo "Openstack cli is required"; errors=$((errors + 1)); }; 
if [ $errors -gt 0 ]; then
	echo You do not have the required programs for running the Openstack test, Exiting
	exit 1
fi

# Create trap to ensure clean up
function clean {
	echo -e "\n\n>>> Performing clean up"
	openstack server delete $NAME --wait
	openstack image delete $NAME
	echo $errors
}
trap clean EXIT


# Upload image based on demo service
echo -e "\n\n>>> Creating IncludeOS instance on Openstack"
cd $INCLUDEOS_SRC/examples/demo_service
mkdir -p build
pushd build
output=`cmake .. 2>&1` || echo "$output"
output=`make 2>&1` || echo "$output"
popd 

echo Uploading image to openstack
openstack image create --file ./build/IncludeOS_example.img --property hw_disk_bus=ide $NAME

echo Starting instance
openstack server create --image $NAME --flavor tiny $NAME --wait
IP=$(openstack server list -c Networks -f value --name $NAME | cut -d " " -f 2)
echo Instance started on IP: $IP
sleep 1

# Test ping towards instance
echo -e "\n\n>>> Testing Host"
errors=0	# Keep track of errors
output=`ping -c 5 $IP 2>&1` || { echo -e "Ping:\n$output\n"; errors=$((errors + 1)); }; 
output=`curl -S --connect-timeout 5 $IP 2>&1` || { echo -e "Curl:\n$output"; errors=$((errors +1)); }; 

# Exit
if [ $errors -gt 0 ]; then
	echo -e "\nERROR: Openstack instance did not pass all the tests"
else
	echo -e "\nPASS: Openstack deployment successful"
fi
exit $errors
