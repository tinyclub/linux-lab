#!/bin/bash
#
# qemu/patch.sh -- Apply the available qemu patchs
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

BOARD=$1
QEMU=$2
QEMU_SRC=$3
QEMU_OUTPUT=$4

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

QEMU_BASE=${QEMU%.*}

QPD_BOARD_BASE=${TOP_DIR}/boards/${BOARD}/patch/qemu/${QEMU_BASE}/
QPD_BOARD=${TOP_DIR}/boards/${BOARD}/patch/qemu/${QEMU}/

QPD_BSP_BASE=${TOP_DIR}/boards/${BOARD}/bsp/patch/qemu/${QEMU_BASE}/
QPD_BSP=${TOP_DIR}/boards/${BOARD}/bsp/patch/qemu/${QEMU}/

QPD_BASE=${TOP_DIR}/patch/qemu/${QEMU_BASE}/
QPD=${TOP_DIR}/patch/qemu/${QEMU}/

for d in $QPD_BOARD_BASE $QPD_BOARD $QPD_BSP_BASE $QPD_BSP $QPD_BASE $QPD
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

        [ -f "$p" ] && patch -r- -N -l -d ${QEMU_SRC} -p1 < $p
    done
done
