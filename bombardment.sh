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
IP_HOST=$1
IP_IOS_SERVER=$2

function ping_flood {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'sudo ping '"'$IP_TARGET'"' -f -c '"'$BURST_SIZE'"' | grep received
        ' > /dev/null 2>&1
    }

function httperf_flood {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'httperf --hog --server '"'$IP_TARGET'"' --num-conn '"'$BURST_SIZE'"' |
    grep Total
        ' > /dev/null 2>&1

    }

function arping_flood {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'sudo arping -w 100 -c '"'$BURST_SIZE'"' '"'$IP_TARGET'"' | grep received
        ' > /dev/null 2>&1
    }

ping_flood $IP_HOST $IP_IOS_SERVER
httperf_flood $IP_HOST $IP_IOS_SERVER
arping_flood $IP_HOST $IP_IOS_SERVER
