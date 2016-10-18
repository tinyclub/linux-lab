#!/bin/bash
#
# open-docker-lab.sh -- open the docker lab via a browser
#

TOP_DIR=$(cd $(dirname $0) && pwd)

IMAGE=$(< $TOP_DIR/lab-name)

LAB_HOST_NAME=$TOP_DIR/.lab_host_name

lab_host="localhost"
[ -f $LAB_HOST_NAME ] && lab_host=$(< $LAB_HOST_NAME)
lab_name=`basename $IMAGE`

LAB_LOCAL_PORT=$TOP_DIR/.lab_local_port
LAB_VNC_PWD=$TOP_DIR/.lab_login_pwd

#Detect OS type
source $TOP_DIR/os-detection.sh

# Get login port
local_port=6080
[ -f $LAB_LOCAL_PORT ] && local_port=$(< $LAB_LOCAL_PORT)

# Get vnc page
# Docker Toolbox can not use "localhost" to visit pages in container
if [[ "$(docker info | sed -n 's/Kernel Version: //p')" = *boot2docker ]]; then
	url=http://$(docker-machine ip default):$local_port/vnc.html
else
	url=http://$lab_host:$local_port/vnc.html
fi

# Get login password
pwd=ubuntu
[ -f $LAB_VNC_PWD ] && pwd=$(< $LAB_VNC_PWD)

if [ "$OS_TYPE" = "Linux" ]; then
    WEB_BROWSER=$1
    [ -z "$WEB_BROWSER" ] && WEB_BROWSER=chromium-browser
    which $WEB_BROWSER 2>&1 >/dev/null
    [ $? -eq 1 ] && WEB_BROWSER=firefox

    # Create local shotcut on Desktop for Linux
    LAB_DESKTOP_SHORTCUT=~/Desktop/${lab_name}.desktop
    if [ -d ~/Desktop ]; then
        echo '#!/usr/bin/env xdg-open' > $LAB_DESKTOP_SHORTCUT
        if [ "$WEB_BROWSER" == "chromium-browser" ]; then
            icon=chromium-browser.png
        else
            icon=firefox.png
        fi
        cat $TOP_DIR/lab.desktop | sed "s%Exec=.*%Exec=$WEB_BROWSER $url%g" | sed "s%lxterminal.xpm%$icon%g">> $LAB_DESKTOP_SHORTCUT
        chmod a+x $LAB_DESKTOP_SHORTCUT

        # Open url
        which $WEB_BROWSER 2>&1>/dev/null \
        && ($WEB_BROWSER $url 2>&1>/dev/null &)
    fi
elif [ "$OS_TYPE" = "Windows" ]; then
    openwith $url 2>&1>/dev/null
elif [ "$OS_TYPE" = "macOS" ]; then
    open $url 2>&1>/dev/null
fi

echo "Please login $url with password: $pwd"