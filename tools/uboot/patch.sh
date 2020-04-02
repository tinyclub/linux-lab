#!/bin/bash
#
# uboot/patch.sh -- Apply the available uboot patchs
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

BOARD=$1
UBOOT=$2
UBOOT_SRC=$3
UBOOT_OUTPUT=$4

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

UBOOT_BASE=${UBOOT%.*}

UPD_BOARD_BASE=${TOP_DIR}/boards/${BOARD}/patch/uboot/${UBOOT_BASE}/
UPD_BOARD=${TOP_DIR}/boards/${BOARD}/patch/uboot/${UBOOT}/

UPD_BSP_BASE=${TOP_DIR}/boards/${BOARD}/bsp/patch/uboot/${UBOOT_BASE}/
UPD_BSP=${TOP_DIR}/boards/${BOARD}/bsp/patch/uboot/${UBOOT}/

UPD_BASE=${TOP_DIR}/patch/uboot/${UBOOT_BASE}/
UPD=${TOP_DIR}/patch/uboot/${UBOOT}/

for d in $UPD_BOARD_BASE $UPD_BOARD $UPD_BSP_BASE $UPD_BSP $UPD_BASE $UPD
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

        [ -f "$p" ] && patch -r- -N -l -d ${UBOOT_SRC} -p1 < $p
    done
done
