#!/bin/bash
#
# update-lab-uid.sh
#

TOP_DIR=$(dirname `readlink -f $0`)

LAB_VNC_IDENTIFY=$TOP_DIR/.lab_identify_method

[ ! -f $LAB_VNC_IDENTIFY ] && echo password > $LAB_VNC_IDENTIFY

VNC_IDENTIFY=$(< $LAB_VNC_IDENTIFY)

if [ "$VNC_IDENTIFY" == "password" ]; then
	echo "LOG: Disable identify"
	echo nopass > $LAB_VNC_IDENTIFY
else
	echo "LOG: Enable identify with password"
	echo password > $LAB_VNC_IDENTIFY
fi
