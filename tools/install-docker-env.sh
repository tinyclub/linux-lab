#!/bin/bash
#
# need to run with sudo
#

image_name=tinylab/tinylab.org

TOP_DIR=$(dirname `readlink -f $0`)

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
version=`sed -n -e "/main$/p" /etc/apt/sources.list | head -1 | cut -d' ' -f3`
echo "deb https://apt.dockerproject.org/repo ubuntu-${version} main" > /etc/apt/sources.list.d/docker.list
apt-get -y update
apt-get -y install docker-engine
# For tools/post
apt-get -y install rake
usermod -aG docker $USER

docker build -t $image_name $TOP_DIR/../

echo "Note: To let docker work without sudo, please restart the X session."

# pkill X
