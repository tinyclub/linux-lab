#!/bin/bash
#
# kernel-patch.sh -- Apply the available kernel patchs
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

BOARD=$1
LINUX=$2
KERNEL_SRC=$3
KERNEL_OUTPUT=$4

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)
TOP_SRC=${TOP_DIR}/src

KPD_BOARD=${TOP_DIR}/boards/${BOARD}/patch/linux/${LINUX}/
KPD_BSP=${TOP_DIR}/boards/${BOARD}/bsp/patch/linux/${LINUX}/
KPD=${TOP_SRC}/patch/linux/${LINUX}/

LINUX_BASE=${LINUX%.*}
if [ $LINUX_BASE != $LINUX ]; then
  KPD_BOARD_BASE=${TOP_DIR}/boards/${BOARD}/patch/linux/${LINUX_BASE}/
  KPD_BSP_BASE=${TOP_DIR}/boards/${BOARD}/bsp/patch/linux/${LINUX_BASE}/
  KPD_BASE=${TOP_SRC}/patch/linux/${LINUX_BASE}/
fi

for d in $KPD_BOARD_BASE $KPD_BOARD $KPD_BSP_BASE $KPD_BSP $KPD_BASE $KPD
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

        [ -f "$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $p
    done
done
