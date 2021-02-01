#!/bin/sh
#
# start.sh -- mount the hostshare directory to guest
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

SHARE_TAG="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharetag= | cut -d'=' -f2 | tr ',' ' ')"
SHARE_DIR="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharedir= | cut -d'=' -f2 | tr ',' ' ')"

# Must pass sharetag via command line?
[ -z "$SHARE_TAG" ] && exit 0

echo
echo "Starting sharing ..."
echo

#[ -z "$SHARE_TAG" ] && SHARE_TAG=hostshare
[ -z "$SHARE_DIR" ] && SHARE_DIR=/hostshare/

[ ! -d $SHARE_DIR ] && mkdir -p $SHARE_DIR
mount -t 9p -o trans=virtio $SHARE_TAG $SHARE_DIR
