#! /bin/bash

# Requires a directory /home/ubuntu/jenkins to be present

sudo docker pull jenkins
sudo docker stop jenkins_includeos
sudo docker rm jenkins_includeos
sudo docker run --name jenkins_includeos \
			-d \
		   	-v /home/ubuntu/jenkins:/var/jenkins_home \
		   	--restart=unless-stopped \
			-p 443:8443 \
			-e JAVA_OPTS=-Duser.timezone=Europe/Oslo \
			jenkins \
			--httpPort=-1 \
			--httpsPort=8443 \
			--httpsKeyStore=/var/jenkins_home/keys/jenkins2.jks \
			--httpsKeyStorePassword=jenkins
