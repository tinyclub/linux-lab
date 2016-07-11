#!/bin/bash
#
# install-docker-lab.sh -- need to run with sudo
#

TOP_DIR=$(dirname `readlink -f $0`)

cat ${TOP_DIR}/Dockerfile  | grep "^RUN " | cut -d' ' -f2- | sudo bash
