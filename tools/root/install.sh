#!/bin/bash
#
# install.sh -- install extra packages to the rootfs target
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)
TOP_SRC=${TOP_DIR}/src

[ -z "$SYSTEM" ] && SYSTEM=$TOP_SRC/system
echo "LOG: SYSTEM: $SYSTEM"

# The rootdir
#ROOTDIR=$1
[ -z "$ROOTDIR" ] && echo "LOG: target ROOTDIR can not be empty" && exit 1
echo "LOG: ROOTDIR: $ROOTDIR"

for f in `find $SYSTEM -type f | sed -e "s%$SYSTEM%%g"`
do
    dest=`dirname $f`
    [ ! -d $ROOTDIR/$dest ] && mkdir -p $ROOTDIR/$dest
    cp --remove-destination $SYSTEM/$f $ROOTDIR/$f
done
