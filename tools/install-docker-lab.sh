#!/bin/bash
#
# install-docker-lab.sh -- Build the docker image for the lab
#
# ref: https://docs.docker.com/engine/installation/linux/ubuntulinux/
#

TOP_DIR=$(dirname `readlink -f $0`)

IMAGE=$(< $TOP_DIR/lab-name)

lab_user=`dirname $IMAGE`
lab_name=`basename $IMAGE`

# Make sure docker is installed
which docker 2>&1 > /dev/null
[ $? -eq 1 ] && $TOP_DIR/install-docker.sh

# Prefer Pull the lab to Build the lab
docker search $lab_user | grep -q $lab_name
if [ $? -eq 0 ]; then
	docker pull $IMAGE
else
	sudo docker build -t $IMAGE $TOP_DIR/
fi
# Note: Let docker without sudo
docker_without_sudo=0
groups $USER | grep -q docker
[ $? -eq 0 ] && docker_without_sudo=1

[ $docker_without_sudo -eq 1 ] && exit 0

sudo usermod -aG docker $USER

sure='n'
read -p 'LOG: Restart X to let docker work without sudo (Y/n): ' sure
[ "$sure" = 'Y' -o "$sure" = 'y' ] && sudo pkill X
