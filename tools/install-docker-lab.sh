#!/bin/bash
#
# install-docker-lab.sh -- Build the docker image for the lab
#
# ref: https://docs.docker.com/engine/installation/linux/ubuntulinux/
#

TOP_DIR=$(dirname `readlink -f $0`)

IMAGE=$(< $TOP_DIR/lab-name)

docker_without_sudo=0
groups $USER | grep -q docker
[ $? -eq 0 ] && docker_without_sudo=1

# Make sure docker is installed
which docker 2>&1 > /dev/null
if [ $? -eq 1 ]; then
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    version=`sed -n -e "/ main/p" /etc/apt/sources.list | grep -v ^# | head -1 | cut -d' ' -f3`
    sudo bash -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-'${version}' main" > /etc/apt/sources.list.d/docker.list'
    sudo apt-get -y update
    sudo apt-get -y install apt-transport-https ca-certificates
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

fi

# Build the lab
sudo docker build -t $IMAGE $TOP_DIR/

# Note: Let docker without sudo, please restart X.
[ $docker_without_sudo -eq 1 ] && exit 0

sure='n'
read -p 'LOG: Restart X to let docker work without sudo (Y/n): ' sure
[ "$sure" = 'Y' -o "$sure" = 'y' ] && sudo pkill X
