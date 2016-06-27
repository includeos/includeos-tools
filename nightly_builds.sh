#!/bin/bash

# Script that performs nightly builds of IncludeOS dev and master branches.
# 
# Deletes previous and launches a new VM
# Downloads and installs IncludeOS + dependencies
# Runs all tests
# Stops VM when done

BRANCH=$1	# Dev or master will be specified
VM_NAME='nightly_build_$BRANCH'

# Delete previous VM
./openstack_control.py --vm_delete $VM_NAME

# Launch new VM
./openstack_control.py --vm_create $VM_NAME

# Install dependencies
until ssh $IP_ADDRESS 'which git > /dev/null' > /dev/null 2>&1  # Repeats until correct
do
    ssh $IP_ADDRESS 'export PROJECT='"'$PROJECT'"'; sudo sh -c "echo 127.0.1.1 vm-$PROJECT >> /etc/hosts";
                     sudo apt-get update > /dev/null 2>&1;
                     sudo apt-get -y install git > /dev/null 2>&1;
                     sudo apt-get -y install arping > /dev/null 2>&1;
                     ' > /dev/null 2>&1
    sleep 2
done

