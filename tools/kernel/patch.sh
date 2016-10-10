#!/bin/bash
#
# kernel-patch.sh -- Apply the available kernel patchs
#

BOARD=$1
LINUX=$2
KERNEL_SRC=$3
KERNEL_OUTPUT=$4

TOP_DIR=$(dirname `readlink -f $0`)/../../

KFD_CORE=${TOP_DIR}/patch/linux/core/

LINUX_BASE=${LINUX%.*}

KFD_BOARD_BASE=${TOP_DIR}/machine/${BOARD}/patch/linux/${LINUX_BASE}/
KFD_BOARD=${TOP_DIR}/machine/${BOARD}/patch/linux/${LINUX}/

KFD_BASE=${TOP_DIR}/patch/linux/${LINUX_BASE}/
KFD=${TOP_DIR}/patch/linux/${LINUX}/

for d in $KFD_BOARD_BASE $KFD_BOARD $KFD_BASE $KFD_BASE $KFD
do
    [ ! -d $d ] && continue

    for p in `ls $d`
    do
        [ -f "$d/$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $d/$p
    done
done

