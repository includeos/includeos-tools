#!/bin/bash

ovftool_location="/Applications/VMware OVF Tool/ovftool"
vcloud_address=""
username=""
org=""
vapp=""

file_to_upload=$1
if [ -z $file_to_upload ]; then
	echo No file supplied, exiting
	exit 1
fi

"$ovftool_location" --overwrite $file_to_upload "vcloud://$username@$vcloud_address:443?org=$org&vapp=$vapp"
