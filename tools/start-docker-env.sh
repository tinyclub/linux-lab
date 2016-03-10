#!/bin/bash
#
# start the linux 0.11 lab via docker with the shared source in $PWD/
#

docker_image=tinylab/tinylab.org
local_lab_dir=$PWD/
remote_lab_dir=/tinylab.org/

browser=chromium-browser
vnc_port=6080
web_port=4000
url=http://localhost:$vnc_port/vnc.html
pwd=ubuntu

CONTAINER_ID=$(docker run -d -p $vnc_port:$vnc_port -p $web_port:$web_port -v $local_lab_dir:$remote_lab_dir $docker_image)

docker logs $CONTAINER_ID | sed -n 1p

which $browser 2>&1>/dev/null \
    && ($browser $url 2>&1>/dev/null &) \
    && echo "please login with password: $pwd" && exit 0

echo "Usage: Please open $url with password: $pwd"
