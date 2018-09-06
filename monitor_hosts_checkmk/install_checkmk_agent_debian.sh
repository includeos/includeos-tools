# COnfiguring check_mk agents in hosts

logger "Setting locale..."
echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8">>~/.bash_profile
source ~/.bash_profile

sudo apt-get install xinetd -y
wget http://mathias-kettner.de/download/check-mk-agent_1.2.4p5-2_all.deb
sudo dpkg -i check-mk-agent_1.2.4p5-2_all.deb
sudo check_mk_agent
logger "Checking port access: telnet-ing to port 6556"
telnet localhost 6556
echo "Reminder: Allow port 6556 for Igress"
logger "Writing server IP to check_mk file"
sudo sed -i '42i    only_from = 192.168.0.8'  /etc/xinetd.d/check_mk
echo "Installing check_mk_agent completed"
