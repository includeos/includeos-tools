#!/usr/bin/env python
import perf_stats as perfs

def increase_intensity(client):
    """ Will increase the intensity of the test
    """

    obj = perfs.Httperf(client, '10.10.10.135')

    rate = 1500
    for test in range(5):
        rate += 100
        num_conns = rate * 2
        obj.run(rate, num_conns)
        x = [obj]
        print perfs.statcalc(x)

def main():
    """ Main function
    """

    client = '10.10.10.132'
    client2 = '10.10.10.134'
    target = '10.10.10.135'
    rate = 200
    num_conns = 2000
    obj = perfs.Httperf(client, target)
    obj2 = perfs.Httperf(client2, target)
    x = [obj, obj2]
    """

    map(lambda y: y.run(rate, num_conns), x)
    print perfs.statcalc(x)
    """

    increase_intensity(client)



if __name__ == '__main__':
    main()
