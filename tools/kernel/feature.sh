#!/bin/bash
#
# kernel-feature.sh -- Apply the available kernel features
#

BOARD=$1
LINUX=$2
KERNEL_SRC=$3
KERNEL_OUTPUT=$4
FEATURE="$5"

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

KFD_CORE=${TOP_DIR}/feature/linux/core

LINUX_BASE=${LINUX%.*}

KFD_BOARD=${TOP_DIR}/boards/${BOARD}/feature/linux
KFD=${TOP_DIR}/feature/linux
FEATURE="$(echo $FEATURE | tr ',' ' ')"

for d in $KFD_CORE
do
    for f in $FEATURE
    do
        f=$(echo $f | tr 'A-Z' 'a-z')

        path=$d/$f
        [ ! -d $path ] && continue
        echo "Appling feature: $f"

        [ -f "$path/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch
        [ -f "$path/config" ] && cat $path/config >> ${KERNEL_OUTPUT}/.config
        [ -f "$path/config.$BOARD" ] && cat $path/config.$BOARD >> ${KERNEL_OUTPUT}/.config
    done
done

for f in $FEATURE
do
    f=$(echo $f | tr 'A-Z' 'a-z')

    for d in $KFD_BOARD $KFD
    do
        for path in $d/$f/$LINUX $d/$f/$LINUX_BASE
        do
            [ ! -d $path ] && continue
            echo "Appling feature: $f"

            [ -f "$path/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch
            [ -f "$path/config" ] && cat $path/config >> ${KERNEL_OUTPUT}/.config
            [ -f "$path/config.$BOARD" ] && cat $path/config.$BOARD >> ${KERNEL_OUTPUT}/.config
        done
    done
done

exit 0
