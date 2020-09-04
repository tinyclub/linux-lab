#!/bin/bash
#
# rootfs/patch.sh -- Apply the available rootfs patchs
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

BOARD=$1
BUILDROOT=$2
ROOT_SRC=$3
ROOT_OUTPUT=$4

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)
TOP_SRC=${TOP_DIR}/src

RPD_BOARD=${TOP_DIR}/boards/${BOARD}/patch/buildroot/${BUILDROOT}/

RPD_BSP=${TOP_DIR}/boards/${BOARD}/bsp/patch/buildroot/${BUILDROOT}/

RPD=${TOP_SRC}/patch/buildroot/${BUILDROOT}/

for d in $RPD_BOARD $RPD_BSP $RPD
do
    echo $d
    [ ! -d $d ] && continue

    for p in `find $d -type f -name "*.patch" | sort`
    do
        # Ignore some buggy patch via renaming it with suffix .ignore
        echo $p | grep -q .ignore$
        [ $? -eq 0 ] && continue

        echo $p | grep -q \.ignore/
        [ $? -eq 0 ] && continue

        [ -f "$p" ] && patch -r- -N -l -d ${ROOT_SRC} -p1 < $p
    done
done
