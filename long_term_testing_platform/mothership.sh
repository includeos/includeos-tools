#!/bin/bash
set +x

$HOME/mothership/mothership-linux-amd64 -T \
--host mothership.includeos.org \
--username $MOTHERSHIP_CREDS_USR \
--password $MOTHERSHIP_CREDS_PSW "$@"
