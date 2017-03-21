#!/bin/bash

echo -e ">>> Running source build test"

INCLUDEOS_SRC=${INCLUDEOS_SRC-~/IncludeOS}
INCLUDEOS_TOOLS=${INCLUDEOS_TOOLS-~/includeos-tools}
NAME=build_source_instance

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

# Boot new instance
echo Booting new intance
IP=$($INCLUDEOS_TOOLS/openstack_control/openstack_control.py --create $NAME --flavor g1.large)
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

# Download necessary tools on remote machine
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP '
	export CC=clang-3.8
	export CXX=clang++-3.8
	export INCLUDEOS_SRC=~/IncludeOS
	export INCLUDEOS_PREFIX=~/IncludeOS_install
	export binutils_version='"'$binutils_version'"' 
	export newlib_version='"'$newlib_version'"' 
	export gcc_version='"'$gcc_version'"' 
	export clang_version='"'$clang_version'"' 
	export LLVM_TAG='"'$LLVM_TAG'"'
	export num_jobs="-j"

	git clone https://github.com/mnordsletten/IncludeOS.git
	cd IncludeOS/etc
	git checkout bundle_creation
	./create_binary_bundle.sh
'
