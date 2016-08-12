#!/bin/bash

# Script that initializes and performs a long running stress test on a
# IncludeOS VM. 
# UDP burst
# ICMP flood (ping)
# httperf
BURST_SIZE=2000
RATE=200

# Launch VMs
# There will be one IncludeOS server running a http server.
# There will be two clients running trying to stress test the server.


# Initiate tests through the stress-clients
IP_IOS_SERVER=10.10.10.142
IP_STRESS_1=10.10.10.131 
IP_STRESS_2=10.10.10.133

function check_if_up {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'ping '"'$IP_TARGET'"' -c 1 > /dev/null 2>&1;
        '
    if [ $? -ne 0 ] 
        then
        echo "Ping did not receive a reply, exiting"
        exit 1
    fi


    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'wget '"'$IP_TARGET'"' > /dev/null 2>&1
        '
    if [ $? -ne 0 ]
        then
        echo "Wget did not download correctly, exiting"
        exit 1
    fi
}

function initiate_bombardment {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        './bombardment.py --burst_size '"'$BURST_SIZE'"' --rate '"'$RATE'"''
}

for i in $(seq 1 10);
do
    initiate_bombardment $IP_STRESS_1 $IP_IOS_SERVER &
    initiate_bombardment $IP_STRESS_2 $IP_IOS_SERVER 

    check_if_up $IP_STRESS_1 $IP_IOS_SERVER
    echo "LOOP: $i All good"
done


