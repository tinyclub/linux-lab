#!/bin/bash
#
# update-submodules.sh -- use mirror site for git submodules
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#
# Note: the modules listed below must be mirrored via mirror.sh before run this update script.
#
# $ grep testfloat -ur qemu-src/scripts/
# qemu/scripts/archive-source.sh:submodules="dtc slirp ui/keycodemapdb tests/fp/berkeley-softfloat-3 tests/fp/berkeley-testfloat-3"
#
# This script only test for qemu v4.1.1, it may work for qemu >= v4.1.1, if it not work, please modify .gitmodule manually

GITMODULES=$1
MIRROR_TAG=$2

[ -z "$MIRROR_TAG" ] && MIRROR_TAG=tinylab

grep -q $MIRROR_TAG $GITMODULES
if [ $? -ne 0 ]; then
   sed -i -e "s%https://git.qemu.org/git/qemu-%https://gitee.com/$MIRROR_TAG/qemu-%g" $GITMODULES
   sed -i -e "s%https://git.qemu.org/git/%https://gitee.com/$MIRROR_TAG/qemu-%g" $GITMODULES
fi
