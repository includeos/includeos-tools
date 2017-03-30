#!/bin/bash

# Perform quick installation of dependencies

export INCLUDEOS_SRC=${INCLUDEOS_SRC:-~/IncludeOS}

read_linux_release() {
    LINE=`grep "^ID=" /etc/os-release`
    echo "${LINE##*=}"
}
# Used when calling the install dependency script
SYSTEM=`uname -s`
RELEASE=$([ $SYSTEM = "Darwin" ] && echo `sw_vers -productVersion` || read_linux_release)

# Install build requirements
$INCLUDEOS_SRC/etc/install_build_requirements.sh -s $SYSTEM -r $RELEASE -d all

# Install network bridge
$INCLUDEOS_SRC/etc/scripts/create_bridge.sh

# Install python package
if [ -f $INCLUDEOS_SRC/etc/install_vmrunner.sh ]; then
    $INCLUDEOS_SRC/etc/install_vmrunner.sh
fi
