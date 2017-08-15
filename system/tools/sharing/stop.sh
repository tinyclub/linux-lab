#!/bin/sh
#
# stop.sh -- umount the hostshare directory from guest
#

SHARE_DIR="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharedir= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$SHARE_DIR" ] && SHARE_DIR=/hostshare/

[ -d "$SHARE_DIR" ] && umount $SHARE_DIR
