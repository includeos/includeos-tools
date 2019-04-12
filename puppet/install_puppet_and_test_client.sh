#!/bin/bash

FILE="$1"

wget https://apt.puppet.com/puppet6-release-bionic.deb
sudo dpkg -i puppet6-release-bionic.deb
sudo apt-get update

sudo apt-get -y install puppet

sudo puppet apply ~/includeos-tools/puppet/$FILE
