#!/bin/bash

# Identifying disto type
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_IDS=$ID_LIKE
    VERSION=$VERSION_ID
    EXACT_ID=$ID
else
    echo "ERROR: Unable to read /etc/os-release file. Exiting."
    exit 1
fi
PKG_MGR="apt"
for DISTRO_ID in $DISTRO_IDS
do
    if [ "${DISTRO_ID}" = "centos" ] || [ "${DISTRO_ID}" = "rhel" ] || [ "${DISTRO_ID}" = "fedora" ]; then
        PKG_MGR="yum"
    fi
done
    echo "================================================"
    echo "Updating ${PKG_MGR} package..."
    echo "================================================"
    sudo ${PKG_MGR} update -y

if ! docker --version; then
    echo "================================================"
    echo "Installing Docker package..."
    echo "================================================"
            sudo ${PKG_MGR} install docker -y
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo setfacl --modify user:$USER:rw /var/run/docker.sock
fi
    echo "================================================"
    echo "Installing Docker-compose package..."
    echo "================================================"
if ! docker-compose -version; then
            sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-Linux-x86_64 | sudo tee /usr/local/bin/docker-compose > /dev/null
            sudo chmod +x /usr/local/bin/docker-compose
            sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
            sudo docker-compose --version
fi
    echo "================================================"
    echo "Setting up JenkinsMaster..."
    echo "================================================"
            docker volume create jenkinsdata
            docker volume create jenkinslogs
            mkdir $HOME/jenkinsmaster
            cd $HOME/jenkinsmaster

cat <<EOF > docker-compose.yaml
version: '2.1'

services:
  # Jenkins Master
  jenkins:
    image: jenkins/jenkins:latest
    container_name: jenkins
    hostname: jenkins
    ports:
     - "8080:8080"
    volumes:
      - jenkinsdata:/var/jenkins_home
      - jenkinslogs:/var/log
      - /var/run/docker.sock:/var/run/docker.sock
    labels:
      service: "jenkins-master"
    restart: unless-stopped
volumes:
  jenkinsdata:
    external: true
  jenkinslogs:
    external: true

EOF
        #mv docker-compose.yaml $HOME/jenkinsnew/
        docker-compose up -d
        docker ps
        echo "Jenkins Master and Slave is running..."
		sleep 15
        sudo docker logs jenkins | grep initialAdminPassword
        echo "Use this password to Login in Jenkins..."
		
		sudo -u root docker pull jenkins/jenkins:latest
		sudo -u root docker tag jenkins/jenkins:latest jenkins-slave:latest

