#!/bin/bash
#
# showterm.sh -- install showterm for command line recording
#

sudo apt-get -y update
sudo apt-get install -y curl
sudo sh -c 'curl showterm.io/showterm > /usr/bin/showterm'
sudo chmod a+x /usr/bin/showterm
