#!/bin/bash
#
# kernel-patch.sh -- Apply the available kernel patchs
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
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

KPD_ROOT=${TOP_SRC}/patch/linux/
[ -x "$KPD_ROOT/patch.sh" ] && $KPD_ROOT/patch.sh $KERNEL_SRC

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

        if [ $? -ne 0 ]; then
            grep -iq "GIT binary patch" $p
            [ $? -eq 0 ] && pushd ${KERNEL_SRC} && git apply -p1 < $p && popd
        fi
    done

    [ -x "$d/patch.sh" ] && $d/patch.sh $KERNEL_SRC
done
