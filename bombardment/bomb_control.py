#!/usr/bin/env python
import perf_stats as perfs
import sys
import urllib2

sys.path.insert(0, "../openstack_control")
import openstack_control as ostack

def target_status(target):
    """ Finds the status of the target"""

    try:
        return_code = urllib2.urlopen('http://'+target, timeout=2).getcode()
        return True
    except urllib2.URLError:
        # Timed out
        return False

def target_restart():
    """ Will restart the target """
    acorn_image = "acorn2012"
    # Stop previous target
    ostack.vm_stop("bomb_target")

    # Remove previous target
    ostack.vm_delete("bomb_target")

    # Start new target
    ostack.vm_create("bomb_target", image=acorn_image, flavor="includeos.micro", network="Private_IncludeOS", key_pair="IncludeOS")

    # Return new IP
    return ostack.vm_status("bomb_target")['network'][1]



def find_breaking_point(client, target):
    """ Will increase the intensity of the test
    """

    obj = perfs.Httperf(client, target)

    rate = 1500
    for test in range(10):
        if target_status(target):
            print "Running test ", test
            rate += 200
            num_conns = rate * 2
            obj.run(rate, num_conns)
            x = [obj]
            print perfs.statcalc(x)

def main():
    """ Main function
    """

    client = '10.10.10.132'
    client2 = '10.10.10.134'
    target = ostack.vm_status('bomb_target')['network'][1]
    rate = 200
    num_conns = 2000
    obj = perfs.Httperf(client, target)
    obj2 = perfs.Httperf(client2, target)
    x = [obj, obj2]
    """

    map(lambda y: y.run(rate, num_conns), x)
    print perfs.statcalc(x)
    """

    find_breaking_point(client, target)



if __name__ == '__main__':
    main()
