# Openstack Control
This script let's you easily interact with openstack. You can:
- Upload or remove images
- Create or delete virtual machines running on openstack

## Quick reference guide
- In order to upload an image named `example` located at `~/ex.img`
```bash
./openstack_control.py --upload_image example --image_path ~/ex.img
```

- To create an image based on this newly uploaded image running on an easily acessed IP 
```bash
./openstack_control.py --create new_vm --image example --flavor includeos.nano --network FloatingPool01 
```

## Command line arguments

```
positional arguments:
  name                  Name of the VM

optional arguments:
  -h, --help            show this help message and exit
  --image IMAGE         Name of Openstack image to use
  --key_pair KEY_PAIR   Name of key pair to use
  --flavor FLAVOR       Name of flavor to use
  --network NETWORK     Name of network to connect to
  --image_path IMAGE_PATH
                        Path to image to upload
  --status              Return status of VM
  --create              Creates a new VM
  --delete              Delete the VM
  --start               Start the VM
  --stop                Stop the VM
  --upload_image        Create an image
  --delete_image        Delete an image
  ```
