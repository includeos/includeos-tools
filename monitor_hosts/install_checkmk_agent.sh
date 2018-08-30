# COnfiguring check_mk agents in hosts

logger "Setting locale..."
echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile
source ~/.bash_profile

sudo apt-get install xinetd
wget http://mathias-kettner.de/download/check-mk-agent_1.2.4p5-2_all.deb
dpkg -i check-mk-agent_1.2.4p5-2_all.deb
check_mk_agent
logger "Checking port access: telnet-ing to port 6556"
telnet host-ip 6556
logger "writing server IP to check_mk file"
sed -i '42i    only_from = 192.168.0.8'
