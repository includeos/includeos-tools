#!/usr/bin/env python

import subprocess
import re
import sys
import signal

# Module import of openstack control script
"""
__location__ = os.path.realpath(
        os.path.join(os.getcwd(), os.path.dirname(__file__)))
sys.path.append('../openstack_control')
import openstack_control
"""



def signal_handler(signal, frame):
        print('Aborted. Will shut down all httperf processes')
        for client in Httperf.all_clients:
            command = 'ssh {0} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null " \
                       pkill httperf "'.format(client)
            subprocess.call(command, shell=True)
        sys.exit(0)
signal.signal(signal.SIGINT, signal_handler)


class Httperf():
    """ Contains all httperf related functions
    """

    all_clients = []    # Used for shutting down all process in case of SIGINT

    def __init__(self, client, target):
        """Initialize arguments

        Keyword arguments:
        client      -- IP to the client where httperf runs
        target      -- IP to the target getting tested
        rate        -- Number of connections pr. second (default 500)
        num_conns   -- Total number of connections (default 5000)
        """

        self.client = client
        self.all_clients.append(client)
        self.target = target
        self.tot_requests = 0
        self.tot_replies = 0
        self.conn_rate = 0
        self.reply_rate_avg = 0

    def __str__(self):
        """str function used for printing"""
        return ('Client: {x[client]}\n'
                'Target: {x[target]}\n'
                'tot_requests: {x[tot_requests]}\n'
                'tot_replies: {x[tot_replies]}\n'
                'conn_rate: {x[conn_rate]}\n'
                'reply_rate_avg: {x[reply_rate_avg]}\n'
                ).format(x=self.__dict__)

    def run(self, rate=500, num_conns=5000):
        """Starts a run of the httperf command

        Keyword arguments:
        rate        -- Number of connections pr. second (default 500)
        num_conns   -- Total number of connections (default 5000)
        """

        command = ('ssh {0} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null '
                   '"httperf --hog --server {1} --num-conns {2} --rate {3}" '
                   ).format(self.client, self.target, num_conns, rate)

        # Run the command
        result = subprocess.check_output(command, shell=True)

        # Process output
        regex = ("requests (?P<tot_requests>\S*) replies (?P<tot_replies>\S*) test(.|\n)*"
                 "Connection rate: (?P<conn_rate>\S*) conn/s (.|\n)*"
                 ".*replies/s]: min \S* avg (?P<reply_rate_avg>\S*) max")
        output = re.search(regex, result)

        self.tot_requests = output.group('tot_requests')
        self.tot_replies = output.group('tot_replies')
        self.conn_rate = output.group('conn_rate')
        self.reply_rate_avg = output.group('reply_rate_avg')

        return


if __name__ == '__main__':
    client = '10.10.10.133'
    target = '10.10.10.124'
    rate = 100
    num_conns = 2000
    obj = Httperf(client, target)
    obj.run(rate, num_conns)
    print obj

