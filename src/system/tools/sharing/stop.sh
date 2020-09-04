#!/bin/sh
#
# stop.sh -- umount the hostshare directory from guest
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

SHARE_DIR="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharedir= | cut -d'=' -f2 | tr ',' ' ')"
SHARE_TAG="$(cat /proc/cmdline | tr ' ' '\n' | grep ^sharetag= | cut -d'=' -f2 | tr ',' ' ')"

# Must pass sharetag via command line?
[ -z "$SHARE_TAG" ] && exit 0

echo
echo "Stopping sharing ..."
echo

[ -z "$SHARE_DIR" ] && SHARE_DIR=/hostshare/

[ -d "$SHARE_DIR" ] && umount $SHARE_DIR
