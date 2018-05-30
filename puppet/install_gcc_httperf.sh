#!/bin/bash

# Set locales in /etc/default/locale file
echo "Setting locale..."
echo "# Locale settings
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile

locale-gen en_US.UTF-8

sudo dpkg-reconfigure locales

source ~/.bash_profile

# installing gcc eversion 7.1 as needed

sudo add-apt-repository -y ppa:jonathonf/gcc-7.1
sudo apt-get update
sudo apt-get install -y gcc-7 g++-7

#sudo apt-get install build-essential

# installing httperf from source

# cp -v /etc/skel/{.bashrc,.profile} $HOME

sudo apt-get install -y autoconf
sudo apt-get install -y libtool
sudo apt install libtool-bin
wget https://github.com/rtCamp/httperf/archive/master.zip
sudo apt-get install -y unzip
unzip master.zip
cd httperf-master
autoreconf -i
mkdir build
cd build
../configure
make
sudo make install

# this output shows max no. of open descriptors
httperf -v | grep open
