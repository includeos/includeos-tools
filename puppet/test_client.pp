# Build system
package { [ "cmake" , "make", "nasm", "libssl-dev" ] :
  ensure => present,
}

# Compilers
package { [ "clang-6.0", "gcc-7", "g++-multilib" ] :
  ensure => present,
}

# Test system dependencies
package { [ "qemu-system", "lcov" ] :
  ensure => present,
}

# Test tools
package { [ "arping", "httperf", "hping3", "iperf3", "dnsmasq", "dosfstools", "xorriso" ] :
        ensure => present,
}

package { [ "python3-pip", "python3-setuptools", "python3-dev" ] :
  ensure => present,
}

$pip_packages = [ "wheel", "jsonschema", "conan", "psutil", "ws4py" ]
package { $pip_packages :
  ensure => present,
  provider => pip3,
}

service { 'dnsmasq' :
        ensure => running,
        require => Package['dnsmasq'],
}

# This requires the bridge to be configured
exec { "modify-dnsmasq" :
        path => "/opt/puppetlabs/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin",
        command => 'echo "interface=bridge43 \ndhcp-range=10.0.0.2,10.0.0.200,12h\nport=0" >> /etc/dnsmasq.conf',
        unless => 'grep -q bridge43 /etc/dnsmasq.conf',
        notify => Service['dnsmasq'],
}

# Deps that we wish to get rid of
package { "net-tools" :
        ensure => present,
}
package { "subprocess32" :
  ensure => present,
  provider => pip3,
}
# Only need python2 until memdisk.py is ported to python3
package { "python" :
  ensure => present,
}
