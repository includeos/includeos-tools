#!/bin/bash

echo -e ">>> Running Intrusive Test"

INCLUDEOS_SRC=${INCLUDEOS_SRC-~/IncludeOS}
INCLUDEOS_TOOLS=${INCLUDEOS_TOOLS-~/includeos-tools}
NAME=intrusive_test_nightly
IMAGE_NAME=ubuntu16.04
KEY_PAIR_NAME="pipe_openstack"

# Prepend random string to the end of name
NAME=$NAME-$(date | shasum | cut -d " " -f 1)

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
	openstack server delete $NAME 
	echo $errors
}
trap clean EXIT

echo Starting instance
openstack server create --image $IMAGE_NAME --flavor small --key-name $KEY_PAIR_NAME $NAME --wait
IP=$(openstack server list -c Networks -f value --name $NAME | cut -d " " -f 2)
echo Instance started on IP: $IP

timeout=0
until ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP exit || [ "$timeout" -gt 60 ]
do
	sleep 1
	timeout=$((timeout+1))
done

if [ "$timeout" -gt 60 ]; then
	echo No connection made to instance, Exiting
	exit 1
fi

ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP '
    export WORKSPACE=$PWD
    export INCLUDEOS_SRC=$WORKSPACE
    export INCLUDEOS_PREFIX=$WORKSPACE/IncludeOS_install
    export CC=clang-5.0
    export CXX=clang++-5.0
    export num_jobs="-j 4"
    export INCLUDEOS_ENABLE_TEST=OFF

	git clone https://github.com/hioa-cs/IncludeOS.git
	cd IncludeOS
	git checkout dev
	./install.sh -y 

	cd test
	./testrunner.py -t intrusive'

errors=$?
# Exit
if [ $errors -gt 0 ]; then
    echo -e "\nERROR: Intrusive tests did not pass"
else
    echo -e "\nPASS: Intrusive tests successful"
fi
exit $errors
