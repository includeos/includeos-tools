
git clone https://github.com/staiyeba/includeos-tools.git
cd includeos-tools/puppet
./install_puppet_and_test_client.sh
git clone https://github.com/hioa-cs/IncludeOS.git
cd IncludeOS
export INCLUDEOS_SRC=~/IncludeOS
export INCLUDEOS_PREFIX=~/IncludeOS_install
export CC=clang-5.0
export CXX=clang++-5.0
export num_jobs=-j 1
export INCLUDEOS_ENABLE_TEST=OFF
./install.sh
