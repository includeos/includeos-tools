#!/usr/bin/env python

import subprocess
import re
import os
import sys
import argparse
from multiprocessing import Process, Queue

# Module import of openstack control script
"""
__location__ = os.path.realpath(
        os.path.join(os.getcwd(), os.path.dirname(__file__)))
sys.path.append('../openstack_control')
import openstack_control
"""


class httperf():
    """ Contains all httperf related functions
    """
    
    def __init__(self, client, target):
        """Initialize arguments
        
        Keyword arguments:
        client      -- IP to the client where httperf runs
        target      -- IP to the target getting tested
        rate        -- Number of connections pr. second (default 500)
        num_conns   -- Total number of connections (default 5000)
        """
        
        self.client = client
        self.target = target
        
    def __str__(self):
        """str function used for printing"""
        return ('Client: {x[client]}\n'
                'Target: {x[target]}\n'
                'Rate: {x[rate]}\n'
                'Num_conns: {x[num_conns]}\n'
                ).format(x=self.__dict__)
    
    def run(self, rate=500, num_conns=5000):
        """Starts a run of the httperf command
        
        Keyword arguments:
        rate        -- Number of connections pr. second (default 500)
        num_conns   -- Total number of connections (default 5000)
        """
        
        command = ('ssh {0} -q -o StrictKeyChecking=no -o UserKnownHostsFile=/dev/null '
                   '"httperf --hog --server {1} --num_conn {2} --rate {3}" '
                   ).format(self.client, self.target, num_conns, rate)
        
        # Run the command            
        result = subprocess.check_output(command)
        print result
        
                  
        
        

if __name__ == '__main__':
    client = '10.10.10.10'
    target = '11.11.11.11'
    rate = 1000
    num_conns = 5000
    obj = httperf(client, target)
    obj.run(rate, num_conns)