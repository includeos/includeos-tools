#!/bin/bash

# Script that creates microlb test environment and launches the tests
# Initialize variables:
infrastructure=0
while getopts "h?iv" opt; do
    case "$opt" in
    h|\?)
        printf "%s\n" "Options:"\
                "-i infrastructure: Build infrastructure as well"\
                "-v verbose: Verbose output"
        exit 0
        ;;
    i)  infrastructure=1
        ;;
    v)  set -x
        ;;
    esac
done

num_clients=1
num_servers=1
openstack_address=${MB_OPENSTACK_LOGIN?}
starbaseLocation=${MB_STARBASE_LOC:-"$INCLUDEOS_SRC/lib/uplink/starbase"}
mothershipBin=${MB_MOTHERSHIP_BIN:-$GOPATH/src/github.com/includeos/mothership/mothership}
mothershipHost=${MB_MOTHERSHIP_HOST:-localhost}
mothershipUsername=${MB_MOTHERSHIP_USER?}
mothershipPassword=${MB_MOTHERSHIP_PWD?}

echo loc: $starbaseLocation
echo bin: $mothershipBin
echo host: $mothershipHost
echo user: $mothershipUsername
echo pwd: $mothershipPassword
echo openstack: $openstack_address



# 1. Create the infrastructure
if [ $infrastructure -eq 1 ]; then
    printf "\n##### Creating infrastructure #####\n"
    ssh $openstack_address "mkdir -p microlb_test_files"
    scp -r * $openstack_address:microlb_test_files/
    ssh $openstack_address "source ~/friend.includeos-openrc.sh;
             cd microlb_test_files; ./infrastructure.sh $num_clients $num_servers"
fi

# 2. Launch a starbase which connects to mothership.includeos.org
printf "\n##### Launching Starbase #####\n"
rm $starbaseLocation/nacl.txt* || echo no old nacl.txt files found
cp starbase_files/* $starbaseLocation
$mothershipBin build-local $starbaseLocation
$mothershipBin launch --hypervisor openstack $starbaseLocation/build/starbase.img
starbaseName=starbase.img-$OS_USERNAME

# 3. Gather info about starbase
# Get all mac addresses, it will have 3
printf "\n##### Getting info about starbase #####\n"
macAddresses=$(openstack port list --server $starbaseName -c "MAC Address" -f value)
numAddresses=($macAddresses)
until [[ "${#numAddresses[@]}" -eq "3" ]]; do
  macAddresses=$(openstack port list --server $starbaseName -c "MAC Address" -f value)
  numAddresses=($macAddresses)
  sleep 1
done
echo macs: $macAddresses
# Loop over all mac addresses until one of them has connected to mothership. That mac is the uplink
match=0
until [ "$match" -eq "1" ]; do
  while read -r mac; do
    $mothershipBin --host $mothershipHost --username $mothershipUsername --password $mothershipPassword inspect-instance $mac 2>&1 > /dev/null
    if [ "$?" -eq "0" ]; then
      echo match detected, mothership has registered $mac
      macAddress=$mac
      match=1
    fi
  done <<< "$macAddresses"
  echo Not connected to Mothership yet
  sleep 2
done

serverIp=$(openstack server list --name "microlb_server.*" -c Networks -f value | cut -d " " -f 2)

# 4. Build microlb
printf "\n##### Building Microlb #####\n"
cp microLB_files/* $starbaseLocation
sed -i -e 's/10.0.0.1/'"$serverIp"'/g' $starbaseLocation/nacl.txt
$INCLUDEOS_PREFIX/bin/boot -b $starbaseLocation
microlb_sha=$(shasum $starbaseLocation/build/starbase | cut -d " " -f 1)
$mothershipBin --host $mothershipHost --username $mothershipUsername --password $mothershipPassword \
  push-image $starbaseLocation/build/starbase

# 5. Deploy microlb
printf "\n##### Deploying microLB #####\n"
$mothershipBin --host $mothershipHost --username $mothershipUsername --password $mothershipPassword \
  deploy $macAddress $microlb_sha

# 6. Print instance output
printf "\n##### Instance output #####\n"
$mothershipBin --host $mothershipHost --username $mothershipUsername --password $mothershipPassword \
  inspect-instance $macAddress
