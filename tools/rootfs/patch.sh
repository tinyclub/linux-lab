#!/bin/bash
#
# rootfs/patch.sh -- Apply the available rootfs patchs
#

BOARD=$1
BUILDROOT=$2
ROOT_SRC=$3
ROOT_OUTPUT=$4

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

RPD_BOARD=${TOP_DIR}/boards/${BOARD}/patch/buildroot/${BUILDROOT}/

RPD=${TOP_DIR}/patch/buildroot/${BUILDROOT}/

for d in $RPD_BOARD $RPD
do
    echo $d
    [ ! -d $d ] && continue

    for p in `ls $d`
    do
        # Ignore some buggy patch via renaming it with suffix .ignore
        echo $p | grep -q .ignore$
        [ $? -eq 0 ] && continue

        [ -f "$d/$p" ] && patch -r- -N -l -d ${ROOT_SRC} -p1 < $d/$p
    done
done
