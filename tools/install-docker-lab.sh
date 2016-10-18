#!/bin/bash
#
# install-docker-lab.sh -- Build the docker image for the lab
#
# ref: https://docs.docker.com/engine/installation/linux/ubuntulinux/
#

TOP_DIR=$(cd $(dirname $0) && pwd)

IMAGE=$(< $TOP_DIR/lab-name)

lab_user=`dirname $IMAGE`
lab_name=`basename $IMAGE`

#Detect OS type
source $TOP_DIR/os-detection.sh

# Make sure docker is installed
which docker 2>&1 > /dev/null
[ $? -eq 1 ] && $TOP_DIR/install-docker.sh

# Prefer Pull the lab to Build the lab
docker search $lab_user | grep -q $lab_name
if [ $? -eq 0 ]; then
	docker pull $IMAGE
else
	if [ "$OS_TYPE" = "Linux" ]; then
		sudo docker build -t $IMAGE $TOP_DIR/
	else
		docker build -t $IMAGE $TOP_DIR/
	fi
fi

if [ "$OS_TYPE" = "Linux" ]; then
	# Note: Let docker without sudo
	docker_without_sudo=0
	groups $USER | grep -q docker
	[ $? -eq 0 ] && docker_without_sudo=1

	[ $docker_without_sudo -eq 1 ] && exit 0

	sudo usermod -aG docker $USER
	echo 'LOG: Please restart X or system to let docker work without sudo'
fi
