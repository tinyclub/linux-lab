#!/bin/bash
#
# install-docker.sh -- Build the docker image for the lab
#
# ref: https://docs.docker.com/engine/installation/linux/ubuntulinux/
#
TOP_DIR=$(cd $(dirname $0) && pwd)

#Detect OS type
source $TOP_DIR/os-detection.sh

if [ "$OS_TYPE" = "Linux" ]; then
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	version=`sed -n -e "/ main/p" /etc/apt/sources.list | grep -v ^# | head -1 | cut -d' ' -f3`
	sudo bash -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-'${version}' main" > /etc/apt/sources.list.d/docker.list'
	sudo apt-get -y update
	sudo apt-get -y install apt-transport-https ca-certificates
	sudo apt-get -y install bridge-utils
	sudo apt-get -y --force-yes install docker-engine
	sudo usermod -aG docker $USER

	# The --bip works like https://gist.github.com/ismell/6689836
	sudo sed -i -e "/DOCKER HACK START 578327498237/,/DOCKER HACK END 789527394722/d" /etc/default/docker
	sudo bash -c 'cat <<EOF >> /etc/default/docker
	# DOCKER HACK START 578327498237
	DOCKER_OPTS="\$DOCKER_OPTS --insecure-registry=registry.mirrors.aliyuncs.com"
	DOCKER_OPTS="\$DOCKER_OPTS --dns 8.8.8.8 --dns 8.8.4.4"
	DOCKER_OPTS="\$DOCKER_OPTS --bip=10.66.33.10/24"
	DOCKER_OPTS="\$DOCKER_OPTS --storage-opt dm.basesize=2G"
	# DOCKER HACK END 789527394722
	EOF'
	# Restart to make sure the above opts work
	sudo brctl delbr docker0
	sudo service docker restart
elif [ "$OS_TYPE" = "Windows" ]; then
	echo "Please install Docker Toolbox following this document https://docs.docker.com/toolbox/toolbox_install_windows/"
elif [ "$OS_TYPE" = "macOS" ]; then
	echo "Please install Docker Engine following this document https://docs.docker.com/engine/installation/mac/"
fi
