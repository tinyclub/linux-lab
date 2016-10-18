#!/bin/bash
#
# install-docker-lab.sh -- need to run with sudo
#

TOP_DIR=$(cd $(dirname $0) && pwd)

#Detect OS type
source $TOP_DIR/os-detection.sh

if [ "$OS_TYPE" = "Linux" ]; then
	cat ${TOP_DIR}/Dockerfile  | grep "^RUN " | cut -d' ' -f2- | sudo bash
else
	echo "This script can only run on Linux"
fi