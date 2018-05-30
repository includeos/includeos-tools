#!/bin/bash

wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get update

sudo apt-get install puppet-agent

./install_gcc_httperf.sh

sudo /opt/puppetlabs/bin/puppet apply ~/includeos-tools/puppet/test_client.pp
