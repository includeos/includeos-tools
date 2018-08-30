check_mk


1. getting started with Check_MK installation:

UBuntu 16.04 Package:

# wget https://mathias-kettner.de/support/1.4.0p16/check-mk-raw-1.4.0p16_0.xenial_amd64.deb
# apt-get install gdebi-core
# gdebi check-mk-raw-1.4.0p16_0.xenial_amd64.deb
# a2enmod proxy_http
# /etc/init.d/apache2 restart

Issues on xenial reference : https://stackoverflow.com/questions/45953923/omd-vs-ubuntu-install-issues

Rhel Server package:

# wget http://files.omdistro.org/releases/1.30/omd-1.30.rhel7.x86_64.rpm

# yum install –nogpgcheck omd-1.30.rhel7.x86_64.rpm


Reference: https://linuxtechlab.com/complete-monitoring-solution-install-omd-open-monitoring-distribution/


2. Creating monitoring site droplet:

Create site:


# omd create monitoring
# su - monitoring
# root@monitoring:/home/ubuntu# omd create monitoring

Adding /opt/omd/sites/monitoring/tmp to /etc/fstab.
Creating temporary filesystem /omd/sites/monitoring/tmp...OK
Restarting Apache...OK
Created new site monitoring with version 1.4.0p16.cre.

  The site can be started with omd start monitoring.
  The default web UI is available at http://monitoring.openstacklocal/monitoring/

  The admin user for the web applications is cmkadmin with password: wjX6bkta
  (It can be changed with 'htpasswd -m ~/etc/htpasswd cmkadmin' as site user.
)
  Please do a su - monitoring for administration of this site.

3. Adding the omd droplet as an agent

# wget http://mathias-kettner.de/download/check-mk-agent_1.2.4p5-2_all.deb
# dpkg -i check-mk-agent_1.2.4p5-2_all.deb
# check_mk_agent
# telnet localhost 6556

# vi /etc/xinetd.d/check_mk

  # configure the IP address(es) of server here:
  only_from      = 127.0.0.1
  # incase of server droplet add localhost, for other agents add your-omd-droplet-ip

$ service xinetd restart

4. Configuring Agents on other Hosts


- For Debian Hosts

# apt-get install xinetd
# wget http://mathias-kettner.de/download/check-mk-agent_1.2.4p5-2_all.deb
# dpkg -i check-mk-agent_1.2.4p5-2_all.deb
# check_mk_agent
# telnet localhost 6556

# vi /etc/xinetd.d/check_mk

  # configure the IP address(es) of your Nagios server here:
  only_from      = your-omd-droplet-ip

# service xinetd restart


- For Rhel Hosts

# yum install xinetd
# wget http://mathias-kettner.de/download/check_mk-agent-1.2.4p5-1.noarch.rpm
# yum install check_mk-agent-1.2.4p5-1.noarch.rpm
# vi /etc/xinetd.d/check_mk
# configure the IP address(es) of your Nagios server here:
only_from      = your-omd-droplet-ip

# service xinetd restart
