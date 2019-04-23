# Build system
package { [ "cmake" , "make", "nasm", "libssl-dev", "libseccomp-dev", "gcc-multilib" ] :
  ensure => present,
}

# Compilers
package { [ "clang-6.0", "gcc-7", "g++-multilib" ] :
  ensure => present,
}

# Build arm
package { [ "gcc-aarch64-linux-gnu", "c++-aarch64-linux-gnu" ] :
  ensure => present,
}

# Test system dependencies
package { [ "qemu-system", "lcov", "grub2", "openjdk-8-jre-headless", "git" ] :
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

Exec { 'conan-config':
  command => 'conan config install https://github.com/includeos/conan_config.git',
  path => ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin","/usr/local/sbin"],
}
