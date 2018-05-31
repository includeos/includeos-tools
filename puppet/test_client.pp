
package { "autoconf" :
        ensure => present,
}

exec{ "httperf-from-source" :
       path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
       command => "wget https://github.com/rtCamp/httperf/archive/master.zip; unzip master.zip; cd httperf-master; autoreconf -i; mkdir build && cd build; ../configure; make && make install",
       provider => 'shell',
       onlyif => "if [[ '$(httperf -v | grep open | cut -d '=' -f 2 | tr -d '[:space:]')' == 1024 ]]; then exit 0; else exit 1; fi;"
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

exec { "gcc" :
        path => ["/usr/bin/","/usr/sbin/","/bin","/sbin"],
        command => 'sudo add-apt-repository ppa:jonathonf/gcc-7.1 && sudo apt-get update && sudo apt-get install -y gcc-7 g++-7',
        provider => 'shell',
        onlyif => "if [[ '$(ls -l /usr/bin/gcc | grep gcc | cut -d ' ' -f 12)' != 'gcc-7.1' ]]; then exit 0 ; else exit 1; fi;",
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
