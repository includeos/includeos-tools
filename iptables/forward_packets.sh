#!/bin/bash

# Script for forwarding packets from IncludeOS running on a nested qemu interface
# Verified to work on ubuntu 16.04
# Make sure ip forwarding is enabled by running: sysctl -w net.ipv4.ip_forward=1
# An in production iptables setup should have a default policy --drop for all chains

OUTWARD_FACING_INTERFACE=ens3
BRIDGE_INTERFACE=bridge43
INCLUDEOS_IP=10.0.0.42

# Clear iptables
sudo iptables -t nat -F

# Masks the source address, necessary for NAT to work
sudo iptables -t nat -A POSTROUTING -o $OUTWARD_FACING_INTERFACE -j MASQUERADE

# Sets the packets coming from bridge43 to be natted, these are packets going out
sudo iptables -t nat -A PREROUTING -i $BRIDGE_INTERFACE -p udp -m udp

# Allow incoming connection, this uses DNAT
# Make sure to add to FORWARD chain if --drop has been specified
sudo iptables -t nat -A PREROUTING -i $OUTWARD_FACING_INTERFACE -p tcp -m tcp --dport 8080 -j DNAT --to-destination $INCLUDEOS_IP:80
