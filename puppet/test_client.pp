
package { "autoconf" :
        ensure => present,
}

package { "unzip" :
        ensure => present,
}


package { "make" :
        ensure => present,
}

package { "libtool" :
        ensure => present,
}

package { "libtool-bin" :
        ensure => present,
}

exec { "gcc" :
        path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
        command => 'sudo add-apt-repository ppa:jonathonf/gcc-7.1 && sudo apt-get update && sudo apt-get install -y gcc-7 g++-7',
        provider => 'shell',
#        onlyif => "if [[ '$(ls -l /usr/bin/gcc | grep gcc | cut -d ' ' -f 12)' != 'gcc-7.1' ]]; then exit 0 ; else exit 1; fi;",
}

notify { "gcc executed" :
        require => Exec["gcc"],
}

exec { "httperf-download" :
       path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
       command => 'wget https://github.com/rtCamp/httperf/archive/master.zip; unzip master.zip',
       provider => 'shell',
       # works only if httperf was previously installed.
       # onlyif => "if [[ '$(httperf -v | grep open | cut -d '=' -f 2 | tr -d '[:space:]')' == 1024 ]]; then exit 0; else exit 1; fi;"
}

exec { "autoreconf" :
       path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
       cwd => '/home/ubuntu/includeos-tools/puppet/httperf-master',
       command => 'autoreconf -i',
       provider => 'shell',
       require => Exec["httperf-download"],
}

file { "/home/ubuntu/includeos-tools/puppet/httperf-master/build" :
       ensure => 'directory',
}

exec { "exec-build-conf" :
       path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
       command => 'bash /home/ubuntu/includeos-tools/puppet/httperf-master/build/../configure',
       provider => 'shell',
}

exec { "make" :
       path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
       cwd => '/home/ubuntu/includeos-tools/puppet/httperf-master',
       command => 'make',
       provider => 'shell',
}

exec { "make-install" :
       path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
       cwd => '/home/ubuntu/includeos-tools/puppet/httperf-master',
       command => 'make install',
       provider => 'shell',
}

package { "arping" :
        ensure => present,
}

package { "python-jsonschema" :
        ensure => present,
}

package { "python-junit.xml" :
        ensure => present,
}

package { "dnsmasq" :
        ensure => present,
}

package { "python-psutil" :
        ensure => present,
}
package { "grub2" :
        ensure => present,
}
service { 'dnsmasq' :
        ensure => running,
        require => Package['dnsmasq'],
}
exec { "modify-dnsmasq" :
        path => "/opt/puppetlabs/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin",
        command => 'echo "interface=bridge43 \ndhcp-range=10.0.0.2,10.0.0.200,12h" >> /etc/dnsmasq.conf',
        unless => 'grep -q bridge43 /etc/dnsmasq.conf',
        notify => Service['dnsmasq'],
}
