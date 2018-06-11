
# Set locales in /etc/default/locale file
echo "Setting locale..."
echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile
source ~/.bash_profile

echo "getting tools for includeos"
git clone https://github.com/staiyeba/includeos-tools.git
cd includeos-tools/puppet
echo "Installing puppet and other necessary tools"
./install_puppet_and_test_client.sh
echo "Getting includeos repo"
git clone https://github.com/hioa-cs/IncludeOS.git
cd IncludeOS
git checkout dev
echo "Checking out to branch: dev"
echo "Exporting required variables"
export INCLUDEOS_SRC=~/IncludeOS
export INCLUDEOS_PREFIX=~/IncludeOS_install
export CC=clang-5.0
export CXX=clang++-5.0
export num_jobs=-"j 4"
export INCLUDEOS_ENABLE_TEST=OFF
export PATH=$PATH:$INCLUDEOS_PREFIX/bin
#export PATH=$PATH:/home/ubuntu/IncludeOS_install/bin
echo "Installing IncludeOS ... "
./install.sh
