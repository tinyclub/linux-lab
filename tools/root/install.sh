#!/bin/bash
#
# install.sh -- install extra packages to the rootfs target
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)
TOP_SRC=${TOP_DIR}/src

[ -z "$SYSTEM" ] && SYSTEM=$TOP_SRC/system

# Override in this order: src/system src/overlay $(BSP_ROOT)/overlay $(BSP_ROOT)/$(BUILDROOT)/overlay
for sys in $SYSTEM
do
  echo "LOG: SYSTEM: $sys"

  # The rootdir
  [ -z "$ROOTDIR" ] && echo "LOG: target ROOTDIR can not be empty" && exit 1
  echo "LOG: ROOTDIR: $ROOTDIR"

  # Copy everything, including devices (recreate)
  if [ -d "$sys" ]; then
    sudo rsync -au --devices $sys/* $ROOTDIR/
  fi
done
