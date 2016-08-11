#!/bin/bash

# Script that performs nightly builds of IncludeOS dev and master branches.
# 
# Deletes previous and launches a new VM
# Downloads and installs IncludeOS + dependencies
# Runs all tests
# Stops VM when done

NAME=$1
BRANCH=$2	# Dev or master will be specified
VM_NAME=$1-$BRANCH
SKIP_TESTS=$3

# Delete previous VM
echo Deleting previous VM
./openstack_control.py --delete $VM_NAME

# Launch new VM
echo Launching new VM
IP_ADDRESS=`./openstack_control.py --create $VM_NAME`
echo "IP is : $IP_ADDRESS"

# Install dependencies
echo Installing dependencies
until ssh $IP_ADDRESS -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'which arping > /dev/null' > /dev/null 2>&1
do
ssh $IP_ADDRESS -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    'export PROJECT='"'$VM_NAME'"'; sudo sh -c "echo 127.0.1.1 $PROJECT >> /etc/hosts";
     sudo apt-get update > /dev/null 2>&1;
     sudo apt-get -y install git > /dev/null 2>&1;
     sudo apt-get -y install arping > /dev/null 2>&1;
     sudo apt-get -y install httperf > /dev/null 2>&1;
     sudo apt-get -y install python-pip > /dev/null 2>&1;
     export LC_CTYPE=C.UTF-8
     sudo pip install --upgrade pip;
     sudo pip install jsonschema;
     ' > /dev/null 2>&1
     sleep 4
done

# Run all tests
echo Running tests
ssh $IP_ADDRESS -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	'git clone https://github.com/hioa-cs/IncludeOS.git;
	 cd IncludeOS;
	 git checkout '"'$BRANCH'"';
	 ./install.sh;
	'

echo ">>> Will now run all the available tests"
ssh $IP_ADDRESS -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	'cd IncludeOS/test;
     sudo python test.py --skip_test '"'$SKIP_TESTS'"'
    '
