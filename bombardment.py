#!/usr/bin/env python

import subprocess
import time
import re
import argparse
import commands
from multiprocessing import Process

RATE = 700
BURST_SIZE = RATE * 10
HOST = "10.10.10.142"
STRESS_HOST_1 = "10.10.10.131"
STRESS_HOST_2 = "10.10.10.133"
SSH_HOST = [STRESS_HOST_1, STRESS_HOST_2]


def ICMP_flood(burst_size=BURST_SIZE):
    # Note: Ping-flooding requires sudo for optimal speed
    res = subprocess.call(["sudo", "ping", "-f", HOST, "-c", str(burst_size)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return res


# Fire a single burst of HTTP requests
def httperf(ssh_target=STRESS_HOST_1, burst_size=BURST_SIZE, rate=RATE, target=HOST):
    print "in httperf"
    command = "ssh {0} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ' \
               httperf --hog --server {1} --num-conn {2} --rate {3} ' \
               ".format(ssh_target, target, str(burst_size), str(rate))
    res = commands.getstatusoutput(command)[1]  # Returns list, we want item 1
    print "command done"
    regex = ("requests (?P<tot_requests>\S*) replies (?P<tot_replies>\S*) test(.|\n)*"
             "Connection rate: (?P<conn_rate>\S*) conn/s (.|\n)*"
             ".*replies/s]: min \S* avg (?P<reply_rate_avg>\S*) max")
    output = re.search(regex, res)
    results = {
        "total_requests": output.group("tot_requests"),
        "total_replies": output.group("tot_replies"),
        "connection_rate": output.group("conn_rate"),
        "reply_rate_avg": output.group("reply_rate_avg")
    }

    print results
    return results


# Fire a single burst of ARP requests
def ARP_burst(burst_size = BURST_SIZE):
    # Note: Arping requires sudo, and we expect the bridge 'include0' to be present
    command = ["sudo", "arping", "-q", "-w", str(100), "-c", str(burst_size * 10), HOST]
    res = subprocess.check_output(command)
    return res


def main():

    parser = argparse.ArgumentParser(description="Start a bombardment")
    parser.add_argument("-r", "--rate", default="200", dest="rate", help="http packets pr. second to send")
    parser.add_argument("-b", "--burst_size", default="100000", dest="burst_size", help="Total number of packets to send")
    args = parser.parse_args()

    for ip in SSH_HOST:
        print ip
        Process(target=httperf, args=(ip, args.burst_size, args.rate)).start()



if __name__ == "__main__":
    main()
