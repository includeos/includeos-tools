
/* package { "httperf" :
        ensure => present,
} */

exec{ "httperf_from_source" :
       path => "/home/ubuntu",
       command => "wget https://github.com/rtCamp/httperf/archive/master.zip && unzip master.zip; cd httperf-master; autoreconf -i; mkdir build && cd build; ../configure; make && make install",
       unless => 'httperf -v | grep open',
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
package { "g++" :
        ensure => present,
}
package { "g++-multilib" :
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
