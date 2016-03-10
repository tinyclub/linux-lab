#!/bin/bash
#
# start the linux 0.11 lab via docker with the shared source in $PWD/
#

docker_image=tinylab/tinylab.org
local_lab_dir=$PWD/
remote_lab_dir=/tinylab.org/

browser=chromium-browser
url=http://localhost

CONTAINER_ID=$(docker run -d -p 80:80 -v $local_lab_dir:$remote_lab_dir $docker_image)

docker logs $CONTAINER_ID | sed -n 1p

which $browser 2>&1>/dev/null \
    && ($browser $url 2>&1>/dev/null &) \
    && exit 0
