#!/bin/bash

echo -e ">>> Running Openstack Test"

INCLUDEOS_SRC=${INCLUDEOS_SRC-~/IncludeOS}
INCLUDEOS_TOOLS=${INCLUDEOS_TOOLS-~/includeos-tools}
NAME=pull_request_openstack

# Preemptive checks to see if there is openstack support
echo -e "\n\n>>> Checking if the required Openstack tools are installed"
errors=0
dpkg -l | grep nova > /dev/null 2>&1 || { echo "Nova is required"; errors=$((errors + 1)); }; 
if [ ! -f $INCLUDEOS_TOOLS/openstack_control/openstack_control.py ]; then
	echo "openstack_control.py is required"
   	errors=$((errors + 1))  
fi
if [ $errors -gt 0 ]; then
	echo You do not have the required programs for running the Openstack test, Exiting
	exit 1
fi

# Create trap to ensure clean up
function clean {
	echo -e "\n\n>>> Performing clean up"
	$INCLUDEOS_TOOLS/openstack_control/openstack_control.py --delete_image $NAME
	$INCLUDEOS_TOOLS/openstack_control/openstack_control.py --delete $NAME
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
$INCLUDEOS_TOOLS/openstack_control/openstack_control.py --upload_image $NAME --image_path ./build/IncludeOS_example.img

echo Starting instance
IP=$($INCLUDEOS_TOOLS/openstack_control/openstack_control.py --create pull_request_openstack --flavor includeos.nano --image $NAME)
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
