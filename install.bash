#!/bin/bash
#
# Contains steps used to set-up the Jenkins/Docker CI server.
#
# See: https://pixhawk.org/dev/ros/sitl_ci_setup
#
# Updates:
# 20150303: switched to AUFS (https://github.com/PX4/containers/issues/6)
#

sudo apt-get update

# A few directories
# > Build artifacts and images go into one place so we can move this onto another storage device if necessary
sudo mkdir -p /build/docker
sudo mkdir -p /build/jenkins
sudo chmod 700 /build/docker

# Install Java, only headless runtime
sudo apt-get install default-jre-headless

# Install Tomcat
# > not necessary, using jenkins standalone
#sudo apt-get install tomcat7

# Install Apache (as proxy)
sudo apt-get install apache2

# Install Jenkins
# > https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo "deb http://pkg.jenkins-ci.org/debian binary/" > /etc/apt/sources.list.d/jenkins-ci.list'
sudo apt-get update
sudo apt-get install jenkins

sudo service jenkins stop
sudo chown jenkins /build/jenkins
sudo chgrp jenkins /build/jenkins
sudo sed -i.orig "s/#\?JENKINS_HOME=.*/JENKINS_HOME=\\/build\\/jenkins/" /etc/default/jenkins
sudo sh -c 'echo JAVA_ARGS=\"\$JAVA_ARGS -Xmx256m -XX:MaxPermSize=128m\" >> /etc/default/jenkins'
sudo service jenkins start
sudo rm -r /var/lib/jenkins

# Configure proxy
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2dissite 000-default
sudo cp jenkins.site /etc/apache2/sites-available/jenkins.conf
sudo a2ensite jenkins
sudo apache2ctl restart

# Install Docker
# > http://docs.docker.com/installation/ubuntulinux/#docker-maintained-package-installation
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install lxc-docker

sudo sh -c 'echo DOCKER_OPTS=\"\${DOCKER_OPTS} -H unix:///var/run/docker.sock -g /build/docker\" >> /etc/default/docker'
sudo service docker restart
sudo rm -r /var/lib/docker

# Allow Jenkins to execute Docker
sudo usermod -a -G docker jenkins


##############################################################################
# Update: switched to AUFS
sudo apt-get  install linux-image-extra-`uname -r` aufs-tools
sudo service docker restart

# Update 2015-06-13: let Jenkins change permissions in workspace
## script
sudo sh -c 'echo chown -R jenkins * >> /build/jenkins/workspace/fix_permissions.sh'
sudo chown jenkins /build/jenkins/workspace/fix_permissions.sh
sudo chmod 544 /build/jenkins/workspace/fix_permissions.sh

## /etc/sudoers
sudo sh -c 'echo jenkins    ALL = NOPASSWD: /build/jenkins/workspace/fix_permissions.sh >> /etc/sudoers'

# Update 2016-04-20: updated Docker
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo rm /etc/apt/sources.list.d/docker.list
sudo sh -c "echo deb https://apt.dockerproject.org/repo ubuntu-trusty main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install docker-engine
