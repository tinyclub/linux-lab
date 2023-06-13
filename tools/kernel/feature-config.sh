#!/bin/bash
#
# feature-config.sh -- Apply the available kernel features
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

ARCH=$1
XARCH=$2
BOARD=$3
LINUX=$4
KERNEL_SRC=$5
KERNEL_OUTPUT=$6
FEATURE="$7"

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)
TOP_SRC=${TOP_DIR}/src

KFD_CORE=${TOP_SRC}/feature/linux/core

LINUX_BASE=${LINUX%.*}

MACH=$(basename $BOARD)

KFD_BOARD=${TOP_DIR}/boards/${BOARD}/feature/linux
KFD_BSP=${TOP_DIR}/boards/${BOARD}/bsp/feature/linux
KFD=${TOP_SRC}/feature/linux
FEATURE="$(echo $FEATURE | tr ',' ' ')"

MT="${TOP_DIR}/tools/kernel/merge_config.sh -m -y -O ${KERNEL_OUTPUT} ${KERNEL_OUTPUT}/.config"

for d in $KFD_CORE
do
    for f in $FEATURE
    do
        f=$(echo $f | tr 'A-Z' 'a-z')

        path=$d/$f
        [ ! -d $path ] && continue

        echo "$path"

        echo "Applying feature: $f"

        configfiles=""
        for c in $path/config $path/config.$XARCH.$MACH $path/config.$MACH
        do
            [ -f "$c" ] && configfiles="$configfiles $c"
        done

        [ -n "$configfiles" ] && $MT $configfiles
    done #f
done #d

for f in $FEATURE
do
    f=$(echo $f | tr 'A-Z' 'a-z')

    for d in $KFD_BOARD $KFD_BSP $KFD
    do
        for path in $d/$f/$LINUX_BASE $d/$f/$LINUX $d/$f
        do
            [ ! -d $path ] && continue

            echo "$path"

            echo "Applying feature: $f"

            configfiles=""
            for c in $path/config $path/config.$XARCH.$MACH $path/config.$MACH
            do
                [ -f "$c" ] && configfiles="$configfiles $c"
            done

            [ -n "$configfiles" ] && $MT $configfiles
        done #path
    done #d
done #f

exit 0
