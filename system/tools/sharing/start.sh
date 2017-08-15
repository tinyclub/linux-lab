#!/bin/sh
#
# start.sh -- mount the hostshare directory to guest
#

SHARE_TAG="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharetag= | cut -d'=' -f2 | tr ',' ' ')"
SHARE_DIR="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharedir= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$SHARE_DIR" ] && SHARE_DIR=/hostshare/
[ -z "$SHARE_TAG" ] && SHARE_TAG=hostshare

[ ! -d $SHARE_DIR ] && mkdir -p $SHARE_DIR
mount -t 9p -o trans=virtio $SHARE_TAG $SHARE_DIR
