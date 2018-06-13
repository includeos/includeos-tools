#!/bin/bash

echo "Setting locale..."
echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile
source ~/.bash_profile

wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get update

sudo apt-get install puppet-agent

sudo /opt/puppetlabs/bin/puppet apply --debug ~/includeos-tools/puppet/test_client.pp
