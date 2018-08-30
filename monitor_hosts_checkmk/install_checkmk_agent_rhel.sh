# COnfiguring check_mk agents in hosts

logger "Setting locale..."
echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile
source ~/.bash_profile

sudo yum install xinetd
wget http://mathias-kettner.de/download/check_mk-agent-1.2.4p5-1.noarch.rpm
sudo yum install check_mk-agent-1.2.4p5-1.noarch.rpm
sudo check_mk_agent
logger "Checking port access: telnet-ing to port 6556"
telnet localhost 6556
echo "Reminder: Allow port 6556 for Igress"
logger "Writing server IP to check_mk file"
sed -i '42i    only_from = 192.168.0.8'  /etc/xinetd.d/check_mk
echo "Installing check_mk_agent completed"
