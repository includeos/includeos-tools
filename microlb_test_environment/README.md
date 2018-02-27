## Env variables
Please provide the following env variables
MB_MOTHERSHIP_HOST = Remote mothership to use
MB_MOTHERSHIP_USER = Remote mothership username
MB_MOTHERSHIP_PWD = Remote mothership password
MB_OPENSTACK_LOGIN = Username and ip to openstack cloud <username@ip>

These are in addition to the ones needed to use the openstack cli tool.

The following are set to defaults, but can be overridden:
MB_STARBASE_LOC = default: $INCLUDEOS_SRC/lib/uplink/starbase
MB_MOTHERSHIP_BIN = default: $GOPATH/github.com/includeos/mothership/mothership
