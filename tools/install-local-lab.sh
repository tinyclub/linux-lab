#!/bin/bash
#
# install-docker-lab.sh -- need to run with sudo
#

TOP_DIR=$(cd $(dirname $0) && pwd)

cat ${TOP_DIR}/Dockerfile  | grep "^RUN " | cut -d' ' -f2- | sudo bash
