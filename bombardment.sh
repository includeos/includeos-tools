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

ssh $IP_STRESS_1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    'sudo ping '"'$IP_IOS_SERVER'"' -f -c '"'$BURST_SIZE'"'
    '

ssh $IP_STRESS_1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    'httperf --hog --server '"'$IP_IOS_SERVER'"' --num-conn '"'$BURST_SIZE'"'
    '

