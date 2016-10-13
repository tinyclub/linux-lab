#!/bin/bash
#
# kernel-feature.sh -- Apply the available kernel features
#

BOARD=$1
LINUX=$2
KERNEL_SRC=$3
KERNEL_OUTPUT=$4
FEATURE="$5"

TOP_DIR=$(cd $(dirname $0) && pwd)/../../

KFD_CORE=${TOP_DIR}/feature/linux/core/

LINUX_BASE=${LINUX%.*}

KFD_BOARD_BASE=${TOP_DIR}/machine/${BOARD}/feature/linux/${LINUX_BASE}/
KFD_BOARD=${TOP_DIR}/machine/${BOARD}/feature/linux/${LINUX}/

KFD_BASE=${TOP_DIR}/feature/linux/${LINUX_BASE}/
KFD=${TOP_DIR}/feature/linux/${LINUX}/

for d in $KFD_CORE $KFD_BOARD_BASE $KFD_BOARD $KFD_BASE $KFD_BASE $KFD
do
    for f in $FEATURE
    do
        f=$(echo $f | tr 'A-Z' 'a-z')
        [ -f "$d/$f/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $d/$f/patch
        [ -f "$d/$f/config" ] && cat $d/$f/config >> ${KERNEL_OUTPUT}/.config
        [ -f "$d/$f/config.$BOARD" ] && cat $d/$f/config.$BOARD >> ${KERNEL_OUTPUT}/.config
    done
done
