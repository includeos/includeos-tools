#!/bin/bash

echo -e ">>> Running Intrusive Test"

INCLUDEOS_SRC=${INCLUDEOS_SRC-~/IncludeOS}
INCLUDEOS_TOOLS=${INCLUDEOS_TOOLS-~/includeos-tools}
NAME=pull_request_intrusive
IMAGE_NAME=intrusive-snapshot
KEY_PAIR_NAME="pr_openstack"

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
	$INCLUDEOS_TOOLS/openstack_control/openstack_control.py --delete $NAME
	echo $errors
}
trap clean EXIT

echo Starting instance
IP="$($INCLUDEOS_TOOLS/openstack_control/openstack_control.py --create $NAME --flavor g1.small --image $IMAGE_NAME --key_pair "$KEY_PAIR_NAME")"
echo Instance started on IP: $IP

timeout=0
until ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP exit || [ "$timeout" -gt 30 ]
do
	sleep 1
	timeout=$((timeout+1))
done

if [ "$timeout" -gt 30 ]; then
	echo No connection made to instance, Exiting
	exit 1
fi

ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP '
		 export CC="clang-3.8"
		 export CXX="clang++-3.8"
		 export INCLUDEOS_SRC=~/workspace
		 export INCLUDEOS_PREFIX=~/workspace/IncludeOS_install

		 mkdir workspace; cd workspace
		 wget -q 10.10.10.125:8080/built.tar.gz
		 tar -zxf built.tar.gz

		 ~/includeos-tools/install/install_only_dependencies.sh
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
