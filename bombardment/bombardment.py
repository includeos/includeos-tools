#!/usr/bin/env python

import subprocess
import time
import re
import os
import sys
import argparse
import commands
from multiprocessing import Process, Pool, Queue

__location__ = os.path.realpath(
        os.path.join(os.getcwd(), os.path.dirname(__file__)))
print __location__
print os.path.join(__location__, '../openstack_control')
sys.path.append('../openstack_control')
import openstack_control

RATE = 700
BURST_SIZE = RATE * 10
HOST = "10.10.10.148"
STRESS_HOST_1 = "10.10.10.112"
STRESS_HOST_2 = "10.10.10.133"
SSH_HOST = [STRESS_HOST_1, STRESS_HOST_2]


def ICMP_flood(burst_size=BURST_SIZE):
    # Note: Ping-flooding requires sudo for optimal speed
    res = subprocess.call(["sudo", "ping", "-f", HOST, "-c", str(burst_size)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return res


# Fire a single burst of HTTP requests
def httperf(q, ssh_target=STRESS_HOST_1, burst_size=BURST_SIZE, rate=RATE, target=HOST):
    command = "ssh {0} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ' \
               httperf --hog --server {1} --num-conn {2} --rate {3} ' \
               ".format(ssh_target, target, str(burst_size), str(rate))
    res = commands.getstatusoutput(command)[1]  # Returns list, we want item 1
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

    q.put(results)
    return

def cleanup(ssh_target):
    """Will make sure no httperf processes are running on the ssh_host"""

    command = "ssh {0} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ' \
               pkill httperf '".format(ssh_target)
    commands.getstatusoutput(command)
    return


# Fire a single burst of ARP requests
def ARP_burst(burst_size = BURST_SIZE):
    # Note: Arping requires sudo, and we expect the bridge 'include0' to be present
    command = ["sudo", "arping", "-q", "-w", str(100), "-c", str(burst_size * 10), HOST]
    res = subprocess.check_output(command)
    return res

def print_results(res):
    """Print the results in a nicely formatted way"""
    print ("Loop: {4:.0f} \t"
           "Total requests: {0} \t"
           "Total replies: {1} \t"
           "Connection rate: {2:.1f} \t"
           "Reply rate avg: {3:.1f}".format(res['total_requests'],
                                        res['total_replies'],
                                        res['connection_rate'],
                                        res['reply_rate_avg'],
                                        res['total_number_of_loops'] / res['number_of_ssh_hosts']))

def deploy_ios(image_name, path):
    """ Deploys an image to openstack, launches a VM with that image and returns the ip as a string """

    vm_name = "bombardment_test"

    openstack_control.image_upload(image_name, path)
    openstack_control.vm_create(name = vm_name, image = image_name, flavor = "includeos.nano")
    return openstack_control.vm_status(vm_name)['network'][1]

def undeploy_ios(image_name):
    """ Removes an image from openstack """

    openstack_control.vm_delete("bombardment_test")
    openstack_control.image_delete(image_name)
    return

def main():

    parser = argparse.ArgumentParser(description="Start a bombardment")
    parser.add_argument("-r", "--rate", default="200", dest="rate", help="http packets pr. second to send")
    parser.add_argument("-b", "--burst_size", default="100000", dest="burst_size", help="Total number of packets to send")
    parser.add_argument("-l", "--loops", default=1, type=int, dest="loops", help="Number of loops to perform")
    parser.add_argument("-i", "--image", dest="image", help="Path to image to upload")
    args = parser.parse_args()


    image_name = os.path.basename(args.image)
    target_ip = deploy_ios(image_name, args.image)

    q = Queue() # Used to retrieve return values from the functions called in parallell
    p = {}      # Used to store the values from all the functions
    total_results = {'total_number_of_loops': 0,
                     'multiplier': 0,
                     'number_of_ssh_hosts': float(len(SSH_HOST)),
                     'total_connection_rate': 0,
                     'connection_rate': 0,
                     'reply_rate_avg': 0,
                     'total_replies': 0,
                     'total_requests': 0}
    timeout_value = float(args.burst_size) / float(args.rate) * 2
    print "timeout: {0}".format(timeout_value)
    while(args.loops > 0):
        for ip in SSH_HOST:
            p[ip] = Process(target=httperf, args=(q, ip, args.burst_size, args.rate, target_ip))
            p[ip].start()

        for ip in SSH_HOST:
            p[ip].join(timeout_value)
            if p[ip].is_alive():
                p[ip].terminate()
                print "Bombardment: Process on {0} timed out".format(ip)
                continue
            results = q.get()

            # Calculating loop
            total_results['total_number_of_loops'] += 1
            total_results['multiplier'] = total_results['total_number_of_loops'] / float(total_results['number_of_ssh_hosts'])

            # Connection rate calculations
            total_results['total_connection_rate'] += float(results['connection_rate'])
            total_results['connection_rate'] = total_results['total_connection_rate'] / total_results['multiplier']

            # TODO: Fix the reply rate average, now it only shows the last
            # value
            total_results['reply_rate_avg'] = float(results['reply_rate_avg'])

            total_results['total_replies'] += int(results['total_replies'])
            total_results['total_requests'] += int(results['total_requests'])
        args.loops -= 1
        print_results(total_results)

    for ip in SSH_HOST:
        cleanup(ip)

    undeploy_ios(image_name)


if __name__ == "__main__":
    main()
