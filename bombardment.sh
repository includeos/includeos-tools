#!/bin/bash

# Script that initializes and performs a long running stress test on a
# IncludeOS VM. 
# UDP burst
# ICMP flood (ping)
# httperf
BURST_SIZE=70000
RATE=700

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
        'sudo ping '"'$IP_TARGET'"' -f -c '"'$BURST_SIZE'"' 
        ' > /dev/null 2>&1
    }

function httperf_flood {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'httperf --hog --server '"'$IP_TARGET'"' --num-conn '"'$BURST_SIZE'"' --rate '"'$RATE'"'
        ' > /dev/null 2>&1

    }

function arping_flood {
    IP_HOST=$1
    IP_TARGET=$2

    ssh $IP_HOST -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        'sudo arping -w 100 -c '"'$BURST_SIZE'"' '"'$IP_TARGET'"' 
        ' > /dev/null 2>&1
    }

ping_flood $IP_HOST $IP_IOS_SERVER
httperf_flood $IP_HOST $IP_IOS_SERVER
arping_flood $IP_HOST $IP_IOS_SERVER
