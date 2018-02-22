#!/bin/bash

num_clients=1
num_servers=0

# Delete old servers
openstack server delete --wait $(openstack server list -c ID --name "microlb.*" -f value)

# Create clients 
for i in $(seq 1 $num_clients); do
	openstack server create --flavor small --key-name master --image ubuntu16.04 microlb_client_$i
done

# Create servers 
for i in $(seq 1 $num_servers); do
	openstack server create --flavor small --key-name master --image ubuntu16.04 microlb_server_$i
done

# Wait for ips
num_clients=$((num_clients + num_servers))
until [ $(openstack server list -c Networks --name "microlb.*" -f value | cut -d " " -f 2 | sed '/^\s*$/d' | wc -l) -ge "$num_clients" ]; do
	echo "waiting for ips"
	sleep 5
done

# Install web server
for i in $(openstack server list --name "microlb_server.*" -c Networks -f value | cut -d " " -f 2); do
	((count = 100))
	while [[ $count -ne 0 ]] ; do
	    ssh -q ubuntu@$i exit
	    rc=$?
	    if [[ $rc -eq 0 ]] ; then
		((count = 1))
	    fi
	    ((count = count - 1))
	    echo count is $count for $i
	    sleep 1
	done
	scp -r * ubuntu@$i:.
	ssh ubuntu@$i '	curl -fsSL get.docker.com -o get-docker.sh; sh get-docker.sh;
			ip -4 addr show ens3 | grep -oP "(?<=inet\s)\d+(\.\d+){3}" > static-html-directory/ip.txt;
			sudo docker build -t some-content-nginx -f Dockerfile.nginx .;
			sudo docker run --name nginx -p 80:80 --rm -d some-content-nginx'
done

# Install client
for i in $(openstack server list --name "microlb_client.*" -c Networks -f value | cut -d " " -f 2); do
	((count = 100))
	while [[ $count -ne 0 ]] ; do
	    ssh -q ubuntu@$i exit
	    rc=$?
	    if [[ $rc -eq 0 ]] ; then
		((count = 1))
	    fi
	    ((count = count - 1))
	    echo count is $count for $i
	    sleep 1
	done
	scp -r * ubuntu@$i:.
	ssh ubuntu@$i '	wget https://github.com/loadimpact/k6/releases/download/v0.19.0/k6-v0.19.0-linux64.tar.gz;
			gunzip k6-v0.19.0-linux64.tar.gz; tar xvf k6-v0.19.0-linux64.tar;
		      '
done
