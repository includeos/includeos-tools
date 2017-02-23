#!/bin/bash

# Script for creating the jenkins worker nodes on openstack


# Create names of hosts
number_of_nodes=7
node_prefix="pr-16-"
nodes=""

for i in `seq 1 $number_of_nodes`
do
	nodes="$nodes $node_prefix$i"
done

# Delete previous hosts
for node in $nodes
do
	~/includeos-tools/openstack_control/openstack_control.py --delete $node
done

# Create new hosts
ips=""
for node in $nodes
do
	ips="$ips `~/includeos-tools/openstack_control/openstack_control.py --create $node --flavor g1.small`" 
done

# Install required packages on hosts
for ip in $ips
do
	ssh ubuntu@$ip 'git clone https://github.com/mnordsletten/includeos-tools.git; ./includeos-tools/puppet/install_puppet_and_test_client.sh'
done
