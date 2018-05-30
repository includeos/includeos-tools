
# installing gcc eversion 7.1 as needed

sudo add-apt-repository -y ppa:jonathonf/gcc-7.1
sudo apt-get update
sudo apt-get install -y gcc-7 g++-7

# installing httperf from source

sudo apt-get install -y autoconf
sudo apt-get install -y libtool
wget https://github.com/rtCamp/httperf/archive/master.zip
sudo apt-get install -y unzip
unzip master.zip
cd httperf-master
autoreconf -i
mkdir build
cd build
../configure
make
#sudo make install
sudo checkinstall # using checkinstall eases installation and uninstallation apps compiled from source.

# this output shows max no. of open descriptors
httperf -v | grep open
