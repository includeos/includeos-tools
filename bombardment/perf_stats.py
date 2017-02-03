#!/usr/bin/env python

import subprocess
import re
import sys
import signal
import threading


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
        self.failed = False
        self.target = target
        self.tot_requests = 0
        self.tot_replies = 0
        self.conn_rate = 0
        self.reply_rate_avg = 0
        self.shutdown_httperf_command = ('ssh {0} -q -o StrictHostKeyChecking=no -o '
                                         'UserKnownHostsFile=/dev/null "pkill httperf "').format(self.client)

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

    def run(self, rate=500, num_conns=5000, timeout=20, uri='index.html'):
        """Starts a run of the httperf command.

        Args:
        rate (int): Number of connections pr. second (default 500)
        num_conns (int): Total number of connections (default 5000)
        """

        command = ('ssh {0} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null '
                   '"httperf --hog --server {1} --uri /{5} --num-conns {2} --rate {3} --timeout {4}" '
                   ).format(self.client, self.target, num_conns, rate, timeout, uri)

        def target():
            # httperf command is run here
            self.process = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)
            self.process.wait()

        # Start httperf command in thread so that it can be canceled due to
        # timeout
        thread = threading.Thread(target=target)
        thread.start()
        thread.join(timeout)
        if thread.is_alive():
            # Kill local ssh command that started httperf
            self.process.send_signal(signal.SIGINT)

            # Kill remote httperf process
            subprocess.call(self.shutdown_httperf_command, shell=True)

            thread.join()
            self.failed = True
            return

        # Process output
        result = self.process.communicate()[0]
        regex = ("requests (?P<tot_requests>\S*) replies (?P<tot_replies>\S*) test(.|\n)*"
                 "Connection rate: (?P<conn_rate>\S*) conn/s (.|\n)*"
                 ".*replies/s]: min \S* avg (?P<reply_rate_avg>\S*) max")
        output = re.search(regex, result)

        self.failed = False
        self.tot_requests = float(output.group('tot_requests'))
        self.tot_replies = float(output.group('tot_replies'))
        self.conn_rate = float(output.group('conn_rate'))
        self.reply_rate_avg = float(output.group('reply_rate_avg'))

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

    results = {}
    results['average_conn_rate'] = 0
    results['average_reply_rate_avg'] = 0
    results['tot_requests'] = 0
    results['tot_replies'] = 0
    results['aggregate_conn_rate'] = 0
    results['average_conn_rate'] = 0
    results['aggregate_reply_rate'] = 0
    results['average_reply_rate_avg'] = 0

    for i, client in enumerate(clients):
        results['tot_requests'] += client.tot_requests
        results['tot_replies'] += client.tot_replies
        results['aggregate_conn_rate'] += client.conn_rate
        results['average_conn_rate'] = (results['average_conn_rate'] + client.conn_rate) / (i+1)
        results['aggregate_reply_rate'] += client.reply_rate_avg
        results['average_reply_rate_avg'] = (results['average_reply_rate_avg'] + client.reply_rate_avg) / (i+1)

    if not client.failed:
        results['percent_lost'] = (results['tot_requests'] - results['tot_replies']) / results['tot_requests'] * 100.0
    else:
        results['percent_lost'] = 100

    return results


if __name__ == '__main__':
    client = '10.10.10.132'
    client2 = '10.10.10.134'
    target = '10.10.10.137'
    rate = 200
    num_conns = 20000
    obj = Httperf(client, target)
    obj2 = Httperf(client2, target)
    x = [obj, obj2]
    y = [obj]
    y[0].run(rate, num_conns, timeout=3)
    print statcalc(y)


    #map(lambda y: y.run(rate, num_conns), x)
    #print statcalc(x)
