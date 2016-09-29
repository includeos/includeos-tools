#!/bin/bash

wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get update

sudo apt-get install puppet-agent
sudo apt-get install gcc-5 g++-5

sudo /opt/puppetlabs/bin/puppet apply ~/includeos-tools/puppet/test_client.pp
