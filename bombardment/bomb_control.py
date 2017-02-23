#!/usr/bin/env python
import perf_stats as perfs
import sys
import urllib2

sys.path.insert(0, "../openstack_control")
import openstack_control as ostack

def target_active(target):
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

    # Create httperf object which deals with running httperf on external
    # machine
    obj = perfs.Httperf(client, target[0])

    # Config options for the test
    rate = 5000 # start rate
    start_rate_diff = 2000   # How much to start increasing rate by
    rate_diff = start_rate_diff # rate_diff is changed over time
    num_conn_multiplier = 10 # number of connections compared to rate
    timeout = 20
    percent_lost = 1    # Limit for when to fail the test
    retry_count = 0

    while True:
        if target_active(target):
            num_conns = rate * num_conn_multiplier  # New for every loop

            print "rate: {0}".format(rate)

            # Run the httperf test
            obj.run(rate, num_conns, timeout, target[1])
            x = [obj]

            # Check if too much is lost
            if perfs.statcalc(x)['percent_lost'] > percent_lost:
                # Calculate new rate
                rate -= rate_diff   # Subtract rate diff
                print "Rate subtract: -{0}".format(rate_diff)
                rate_diff = rate_diff/2 # Halve the rate_diff for next time
                if rate_diff < 70:
                    print "Now done. Final rate: {aggregate_conn_rate}".format(**perfs.statcalc(x))
                    break
            else:
                # Increase the rate if no packages are lost
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
    target = ['10.10.10.148', 'index.html']

    find_breaking_point(client2, target)


    """
    obj2 = perfs.Httperf(client2, target)
    x = [obj, obj2]

    map(lambda y: y.run(rate, num_conns), x)
    print perfs.statcalc(x)
    print "IncludeOS"
    #find_breaking_point(client, target)
    obj.run(100,1000)
    print
    print "IncludeOS 2"
    target = ['10.10.10.137', 'index.html']
    find_breaking_point(client2, target)
    print "nginx"
    target = ['10.10.10.138', 'output.txt']
    find_breaking_point(client2, target)
    """



if __name__ == '__main__':
    main()
