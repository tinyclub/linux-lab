#!/bin/sh
#
# stop.sh -- umount the hostshare directory from guest
#

SHARE_DIR="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharedir= | cut -d'=' -f2 | tr ',' ' ')"
SHARE_TAG="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharetag= | cut -d'=' -f2 | tr ',' ' ')"

# Must pass sharetag via command line?
[ -z "$SHARE_TAG" ] && exit 0

[ -z "$SHARE_DIR" ] && SHARE_DIR=/hostshare/

[ -d "$SHARE_DIR" ] && umount $SHARE_DIR
