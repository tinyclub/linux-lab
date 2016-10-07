#!/bin/bash
#
# open-docker-lab.sh -- open the docker lab via a browser
#

TOP_DIR=$(dirname `readlink -f $0`)

IMAGE=$(< $TOP_DIR/lab-name)

LAB_HOST_NAME=$TOP_DIR/.lab_host_name

lab_host="localhost"
[ -f $LAB_HOST_NAME ] && lab_host=$(< $LAB_HOST_NAME)
lab_name=`basename $IMAGE`

LAB_LOCAL_PORT=$TOP_DIR/.lab_local_port
LAB_VNC_PWD=$TOP_DIR/.lab_login_pwd

WEB_BROWSER=$1
[ -z "$WEB_BROWSER" ] && WEB_BROWSER=chromium-browser
which $WEB_BROWSER 2>&1 >/dev/null
[ $? -eq 1 ] && WEB_BROWSER=firefox

# Get login port
local_port=6080
[ -f $LAB_LOCAL_PORT ] && local_port=$(< $LAB_LOCAL_PORT)

# Get vnc page
url=http://$lab_host:$local_port/vnc.html

# Get login password
pwd=ubuntu
[ -f $LAB_VNC_PWD ] && pwd=$(< $LAB_VNC_PWD)

# Create local shotcut on Desktop
LAB_DESKTOP_SHORTCUT=~/Desktop/${lab_name}.desktop
if [ -d ~/Desktop ]; then
    echo '#!/usr/bin/env xdg-open' > $LAB_DESKTOP_SHORTCUT
    if [ "$WEB_BROWSER" == "chromium-browser" ]; then
        icon=chromium-browser.png
    else
        icon=firefox.png
    fi
    cat $TOP_DIR/lab.desktop | sed "s%Exec=.*%Exec=$WEB_BROWSER $url%g" | sed "s%terminator.png%$icon%g">> $LAB_DESKTOP_SHORTCUT
    chmod a+x $LAB_DESKTOP_SHORTCUT
fi

which $WEB_BROWSER 2>&1>/dev/null \
    && ($WEB_BROWSER $url 2>&1>/dev/null &) \
    && echo "Please login $url with password: $pwd"
