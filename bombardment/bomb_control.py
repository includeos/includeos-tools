#!/usr/bin/env python
import perf_stats as perfs
import sys
import urllib2

sys.path.insert(0, "../openstack_control")
import openstack_control as ostack

def target_status(target):
    """ Finds the status of the target"""

    try:
        return_code = urllib2.urlopen('http://'+target[0]+'/'+target[1], timeout=2).getcode()
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

    obj = perfs.Httperf(client, target[0])

    rate = 2000
    start_rate_diff = 500
    rate_diff = start_rate_diff
    num_conn_multiplier = 10 # How many times the rate
    timeout = 1
    percent_lost = 1
    retry_count = 0

    while True:
        if target_status(target):
            num_conns = rate * num_conn_multiplier
            obj.run(rate, num_conns, timeout, target[1])
            x = [obj]

            # Check if too much is lost
            if perfs.statcalc(x)['percent_lost'] > percent_lost:
                print "More than {} percent lost".format(percent_lost)
                print "rate: {aggregate_conn_rate} wanted rate: {0}".format(rate, **perfs.statcalc(x))
                rate -= rate_diff
                rate_diff = rate_diff/2
                if rate_diff < 10:
                    print "Now done. Final rate: {aggregate_conn_rate}".format(**perfs.statcalc(x))
                    break
                print "New rate {}".format(rate)

            else:
                rate += rate_diff
        else:
            print "Target no longer responds"
            break

def main():
    """ Main function
    """

    client = '10.10.10.132'
    client2 = '10.10.10.134'
    target = [ostack.vm_status('bomb_target')['network'][1], 'index.html']
    #target = '10.10.10.138'
    rate = 200
    num_conns = 2000
    obj = perfs.Httperf(client, target)
    obj2 = perfs.Httperf(client2, target)
    x = [obj, obj2]
    """

    map(lambda y: y.run(rate, num_conns), x)
    print perfs.statcalc(x)
    """

    print "IncludeOS"
    find_breaking_point(client, target)
    print
    print "nginx"
    target = ['10.10.10.138', 'output.txt']
    find_breaking_point(client2, target)



if __name__ == '__main__':
    main()
