#!/bin/bash
#
# kernel-feature.sh -- Apply the available kernel features
#

MACH=$1
LINUX=$2
KERNEL_SRC=$3
KERNEL_OUTPUT=$4
FEATURE="$5"

TOP_DIR=$(dirname `readlink -f $0`)/../../

KFD_CORE=${TOP_DIR}/feature/linux/core/

LINUX_BASE=${LINUX%.*}

KFD_MACH_BASE=${TOP_DIR}/machine/${MACH}/feature/linux/${LINUX_BASE}/
KFD_MACH=${TOP_DIR}/machine/${MACH}/feature/linux/${LINUX}/

KFD_BASE=${TOP_DIR}/feature/linux/${LINUX_BASE}/
KFD=${TOP_DIR}/feature/linux/${LINUX}/

for d in $KFD_CORE $KFD_MACH_BASE $KFD_MACH $KFD_BASE $KFD_BASE $KFD
do
    for f in $FEATURE
    do
        f=$(echo $f | tr 'A-Z' 'a-z')
        [ -f "$d/$f/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $d/$f/patch
        [ -f "$d/$f/config" ] && cat $d/$f/config >> ${KERNEL_OUTPUT}/.config
        [ -f "$d/$f/config.$(MACH)" ] && cat $d/$f/config.$(MACH) >> ${KERNEL_OUTPUT}/.config
    done
done
