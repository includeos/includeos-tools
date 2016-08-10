#!/bin/bash

# Install necessary packages for running the IncludeOS tests

sudo echo 127.0.0.1 $HOSTNAME >> /etc/hosts

sudo apt-get update
sudo apt-get install -y httperf arping python-pip
sudo pip install jsonschema
