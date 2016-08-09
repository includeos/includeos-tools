#!/bin/bash

# Script that initializes and performs a long running stress test on a
# IncludeOS VM. 
# UDP burst
# ICMP flood (ping)
# httperf
BURST_SIZE=1000

# Launch VMs
# There will be one IncludeOS server running a http server.
# There will be two clients running trying to stress test the server.


# Initiate tests through the stress-clients
IP_IOS_SERVER=10.10.10.132
IP_STRESS_1=10.10.10.131 
IP_STRESS_2=10.10.10.133

function ping_flood {
    IP_HOST=$1
    IP_TARGET=$2
    echo "Ping: "

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'sudo ping '"'$IP_TARGET'"' -f -c '"'$BURST_SIZE'"' | grep received
        '
    }

function httperf_flood {
    IP_HOST=$1
    IP_TARGET=$2
    echo "httperf: "

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'httperf --hog --server '"'$IP_TARGET'"' --num-conn '"'$BURST_SIZE'"' |
    grep Total
        '

    }

function arping_flood {
    IP_HOST=$1
    IP_TARGET=$2
    echo "arping: "

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'sudo arping -w 100 -c '"'$BURST_SIZE'"' '"'$IP_TARGET'"' | grep received
        '
    }


function check_if_up {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'ping '"'$IP_TARGET'"' -c 1 > /dev/null 2>&1
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

for HOST in $IP_STRESS_1 $IP_STRESS_2
do
    ping_flood $HOST $IP_IOS_SERVER
    httperf_flood $HOST $IP_IOS_SERVER
    arping_flood $HOST $IP_IOS_SERVER

    check_if_up $HOST $IP_IOS_SERVER
    echo "It's up"
done

