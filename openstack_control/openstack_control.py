#!/usr/bin/env python

"""
Interfaces with openstack to start, stop, create and delete VM's
"""

import os
import sys
import ConfigParser
import argparse
import time
import subprocess
import glob     # Used for finding files in dir
from keystoneauth1.identity import v3
from keystoneauth1 import session
import novaclient.client
import glanceclient.v2.client as glclient

# Initiates the ConfigParser
location = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
Config = ConfigParser.ConfigParser()
Config.read(os.path.join(location, 'openstack_settings.conf'))

# Initiates the authentication used towards OpenStack
auth = v3.Password(auth_url=os.environ['OS_AUTH_URL'],
                   username=os.environ['OS_USERNAME'],
                   password=os.environ['OS_PASSWORD'],
                   project_name=os.environ['OS_PROJECT_NAME'],
                   user_domain_name=os.environ['OS_USER_DOMAIN_NAME'],
                   project_domain_name=os.environ['OS_PROJECT_DOMAIN_NAME'])
sess = session.Session(auth=auth)
nova = novaclient.client.Client(2, session=sess)
glance = glclient.Client('2', session=sess)


def vm_create(name,
              image=Config.get('Openstack', 'image'),
              key_pair=Config.get('Openstack', 'key_pair'),
              flavor=Config.get('Openstack', 'flavor'),
              network=Config.get('Openstack', 'network'),
              floating_ip=None):
    """ Creates a VM

    name = Name of VM
    image = Name of image file to use. (ubuntu14.04, ubuntu16.04)
    key_pair = Name of ssh key pair to inject into VM
    flavor = Resources to dedicate to VM (g1.small/g1.medium/g1.large)
    network = Name of network to connect to
    """

    nics = [{"net-id": nova.networks.find(label=network).id,
             "v4-fixed-ip": ''}]
    image = nova.images.find(name=image)
    flavor = nova.flavors.find(name=flavor)

    # Using key pair is not required if booting IncludeOS images
    if key_pair == 'IncludeOS':
        nova.servers.create(name,
                            image=image,
                            flavor=flavor,
                            nics=nics)
    else:
        nova.servers.create(name,
                            image=image,
                            flavor=flavor,
                            nics=nics,
                            key_name=key_pair)

    # Won't exit before the server is active
    status = ''
    while status != 'ACTIVE':
        try:
            status = vm_status(name)['status']
        except TypeError:
            continue
        time.sleep(1)

    # Will complete a ping before moving on
    for x in range(0, 10):
        try:
            ip = vm_status(name)['network'][1]
            with open(os.devnull, 'wb') as devnull:
                response = subprocess.check_call(['ping', '-c', '1', '-W', '3.0', ip],
                                                 stdout=devnull)
            if response == 0:
                if floating_ip:
                    associate_floating_ip(name, floating_ip)
                return
        except:
            continue
        time.sleep(0.5)

    print floating_ip

    print "Error: Instance did not respond to ping"
    sys.exit(1)


def vm_delete(name):
    """ Deletes a VM """

    while True:
        try:
            vm_id = vm_status(name)['id']   # Find vm ID
            vm_status(name)['server'].delete()
        except TypeError:
            return

        # Will not exit until vm is truely gone
        while True:
            try:
                vm_new_id = vm_status(name)['id']
                if vm_id is not vm_new_id:  # New vm with same name, but different ID
                    break
            except TypeError:
                break


def vm_status(name):
    """ Returns status of VM
        The following is returned as a dictionary:
        server      : Openstack server object
        id          : Id of server
        name        : Name of server
        status      : Server status, e.g. ACTIVE, BUILDING, DELETED, ERROR
        power_state : Will return 1 if running
        network     : Network info (network, ip as a tuple)
    """
    status_dict = {}

    # Find server
    options = {'name': '^{}$'.format(name)}
    server = nova.servers.list(search_opts=options)
    if not server:
        # print "No server found with the name: {0}".format(name)
        return
    server = server[0]
    status_dict['server'] = server
    server_info = server.to_dict()

    # ID
    status_dict['id'] = server_info['id']

    # Name
    status_dict['name'] = name

    # Find status
    status_dict['status'] = server_info['status']

    # Power state
    # If running will return 1
    status_dict['power_state'] = server_info['OS-EXT-STS:power_state']

    # Find IP
    networks = server_info['addresses']
    try:
        network_id = networks.keys()[0]
        ip = networks[network_id][0]['addr']
    except IndexError:
        # No networks defined
        network_id = ''
        ip = ''

    status_dict['network'] = (network_id, ip)

    return status_dict


def vm_stop(name):
    """ Stops a VM, will wait until it has finished stopping before returning
    """

    vm_info = vm_status(name)
    if vm_info['power_state'] == 1:
        # print "vm_stop: Will stop VM: {0}".format(name)
        vm_info['server'].stop()
        while vm_status(name)['power_state'] == 1:
            time.sleep(1)
    return


def vm_start(name):
    """ Starts a VM, will wait until it has finished booting before returning
    """
    vm_info = vm_status(name)
    if vm_info['power_state'] != 1:
        # print "vm_start: Will start VM: {0}".format(name)
        vm_info['server'].start()
        while vm_status(name)['power_state'] != 1:
            time.sleep(1)
    return


def image_upload(name, imagefile):
    """ Will upload an image using glance. Will overwrite existing images
        with the same name. """

    # Starts with a check for existing images with the same name.
    try:
        # Try to delete the image
        image_delete(name)
    except novaclient.exceptions.NotFound:
        # Continue if it did not exist
        pass

    with open(imagefile) as fimage:
        image = glance.images.create(name=name, disk_format="raw", container_format="bare", hw_disk_bus="ide")
        glance.images.upload(image.id, fimage, 'rb')


def image_delete(name):
    """ Will delete the specified image """
    image = nova.images.find(name=name)
    glance.images.delete(image.id)


def associate_floating_ip(name, ip=Config.get('Openstack', 'instant_floating')):
    """ Will associate a floating ip with an instance name.

    Args:
        name: Name of the instance to associate with
        ip: Floating ip to assign, gets default from config

    Returns:
        None
    """
    server = vm_status(name)['server']
    server.add_floating_ip(ip)
    return


def instant():
    """ Looks for necessary files in current directory, uploads image and starts service with the name of the folder """

    # Check for necessary files, image
    if glob.glob("./*img"):
        image_path = glob.glob("./*img")[0]
    else:
        print "No Image found in current directory"
        sys.exit(1)

    service_name = os.path.abspath(".").split("/")[-1]
    print "name: {0}  image: {1}".format(service_name, image_path)

    # Upload image, overwriting existing ones
    image_upload(service_name, image_path)

    # Delete image with the same name
    vm_delete(service_name)

    # Start service
    vm_create(service_name, image=service_name, flavor="includeos.micro", network="Private_IncludeOS", key_pair="IncludeOS")

    # Associate floating ip
    associate_floating_ip(service_name)

    # Return name of service
    return service_name


def main():

    parser = argparse.ArgumentParser(description="Lets you create, start, \
                                     stop and delete Openstack VM's")

    parser.add_argument("name", nargs='?', help="Name of the VM")
    parser.add_argument("--image", default=Config.get('Openstack', 'image'),
                        help="Name of Openstack image to use")
    parser.add_argument("--key_pair",
                        default=Config.get('Openstack', 'key_pair'),
                        help="Name of key pair to use")
    parser.add_argument("--flavor",
                        default=Config.get('Openstack', 'flavor'),
                        help="Name of flavor to use")
    parser.add_argument("--network",
                        default=Config.get('Openstack', 'network'),
                        help="Name of network to connect to")
    parser.add_argument("--image_path",
                        default=Config.get('Openstack', 'image_path'),
                        help="Path to image to upload")
    parser.add_argument("--floating_ip", action='store', nargs='?',
                        const=Config.get('Openstack', 'floating_ip'),
                        default=None,
                        help="Will associate with a floating ip")

    # Calling functions
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--status", action="store_const",
                       const=vm_status, dest="cmd",
                       help="Return status of VM")
    group.add_argument("--create", action="store_const",
                       const=vm_create, dest="cmd",
                       help="Creates a new VM")
    group.add_argument("--instant", action="store_const",
                       const=instant, dest="cmd",
                       help="Creates a new VM")
    group.add_argument("--delete", action="store_const",
                       const=vm_delete, dest="cmd",
                       help="Delete the VM")
    group.add_argument("--start", action="store_const",
                       const=vm_start, dest="cmd",
                       help="Start the VM")
    group.add_argument("--stop", action="store_const",
                       const=vm_stop, dest="cmd",
                       help="Stop the VM")
    group.add_argument("--upload_image", action="store_const",
                       const=image_upload, dest="cmd",
                       help="Create an image")
    group.add_argument("--delete_image", action="store_const",
                       const=image_delete, dest="cmd",
                       help="Delete an image")

    args = parser.parse_args()
    if args.cmd is None:
        # args.parse_args(['-h'])
        parser.print_help()
    elif args.cmd is vm_create:
        args.cmd(args.name, image=args.image, flavor=args.flavor,
                 key_pair=args.key_pair, network=args.network,
                 floating_ip=args.floating_ip)
        print vm_status(args.name)['network'][1]
    elif args.cmd is vm_status:
        status = vm_status(args.name)
        if status:
            for stat in status:
                print "{0}: {1}".format(stat, status[stat])
        else:
            print "No vm with the name {} found".format(args.name)
    elif args.cmd is image_upload:
        image_upload(args.name, args.image_path)
    elif args.cmd is instant:
        service_name = instant()
        print vm_status(service_name)['network'][1]
    else:
        args.cmd(args.name)

    return

if __name__ == '__main__':
    main()
