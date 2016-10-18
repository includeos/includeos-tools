#!/usr/bin/env python

import subprocess
import re
import sys
import signal


def signal_handler(signal, frame):
    """Used for handling cleanup if the program is aborted
    """

    print('Aborted. Will shut down all httperf processes')
    for client in Httperf.all_clients:
        command = ('ssh {0} -q -o StrictHostKeyChecking=no -o '
                   'UserKnownHostsFile=/dev/null "pkill httperf "').format(client)
        subprocess.call(command, shell=True)
    sys.exit(0)
signal.signal(signal.SIGINT, signal_handler)


class Httperf():
    """Contains all httperf related functions for running on an external machine.
    """

    all_clients = []    # Used for shutting down all process in case of SIGINT

    def __init__(self, client, target):
        """Initialize arguments.

        Args:
        client (str): IP to the client where httperf runs
        target (str): IP to the target getting tested
        rate (int): Number of connections pr. second (default 500)
        num_conns (int): Total number of connections (default 5000)
        """

        self.client = client
        self.all_clients.append(client)
        self.target = target
        self.tot_requests = 0
        self.tot_replies = 0
        self.conn_rate = 0
        self.reply_rate_avg = 0

    def __str__(self):
        """str function used for printing
        """

        return ('Client: {x[client]}\n'
                'Target: {x[target]}\n'
                'tot_requests: {x[tot_requests]}\n'
                'tot_replies: {x[tot_replies]}\n'
                'conn_rate: {x[conn_rate]}\n'
                'reply_rate_avg: {x[reply_rate_avg]}\n'
                ).format(x=self.__dict__)

    def run(self, rate=500, num_conns=5000):
        """Starts a run of the httperf command.

        Args:
        rate (int): Number of connections pr. second (default 500)
        num_conns (int): Total number of connections (default 5000)
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

    def is_running(self):
        """Check the status of the running command on the external machine

        Returns:
        True: If there is an httperf command running
        False: If no httperf command is running
        """

        command = ('ssh {0} -q -o StrictHostKeyChecking=no -o '
                   'UserKnownHostsFile=/dev/null "pgrep httperf "').format(self.client)

        if subprocess.call(command, stdout=subprocess.PIPE, shell=True) == 0:
            return True
        else:
            return False
            
            
            

def statcalc(clients):
    """Calculates aggregate statistics from the list of supplied Httperf objects.
    
    Args:
    clients (list[Httperf]): The Httperf objects to calculate statistics from
    
    Returns:
    ..............
    """
    
    num_clients = len(clients)
    average_conn_rate = 0
    average_reply_rate_avg = 0
    
    for i, client in enumerate(clients):
        tot_requests += client.tot_requests
        tot_replies += client.tot_replies
        aggregate_conn_rate += client.conn_rate
        average_conn_rate = (average_conn_rate + client.conn_rate) / i
        aggregate_reply_rate += client.reply_rate_avg 
        average_reply_rate_avg = (average_reply_rate_avg + client.reply_rate_avg) / i
        
    
        
        

if __name__ == '__main__':
    client = '10.10.10.133'
    target = '10.10.10.124'
    rate = 100
    num_conns = 2000
    obj = Httperf(client, target)
    # obj.run(rate, num_conns)
    print obj.is_running()
