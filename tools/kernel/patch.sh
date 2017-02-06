#!/bin/bash
#
# kernel-patch.sh -- Apply the available kernel patchs
#

MACH=$1
LINUX=$2
KERNEL_SRC=$3
KERNEL_OUTPUT=$4

TOP_DIR=$(dirname `readlink -f $0`)/../../

KFD_CORE=${TOP_DIR}/patch/linux/core/

LINUX_BASE=${LINUX%.*}

KFD_MACH_BASE=${TOP_DIR}/machine/${MACH}/patch/linux/${LINUX_BASE}/
KFD_MACH=${TOP_DIR}/machine/${MACH}/patch/linux/${LINUX}/

KFD_BASE=${TOP_DIR}/patch/linux/${LINUX_BASE}/
KFD=${TOP_DIR}/patch/linux/${LINUX}/

for d in $KFD_MACH_BASE $KFD_MACH $KFD_BASE $KFD_BASE $KFD
do
    echo $d
    [ ! -d $d ] && continue
    for p in `ls $d`
    do
        echo $p
        [ -f "$d/$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $d/$p
    done
done

