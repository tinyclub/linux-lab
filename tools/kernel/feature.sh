#!/bin/bash
#
# kernel-feature.sh -- Apply the available kernel features
#

XARCH=$1
BOARD=$2
LINUX=$3
KERNEL_SRC=$4
KERNEL_OUTPUT=$5
FEATURE="$6"

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

KFD_CORE=${TOP_DIR}/feature/linux/core

LINUX_BASE=${LINUX%.*}

MACH=$(basename $BOARD)

KFD_BOARD=${TOP_DIR}/boards/${BOARD}/feature/linux
KFD_BSP=${TOP_DIR}/boards/${BOARD}/bsp/feature/linux
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
        [ -f "$path/patch.$XARCH.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$XARCH.$MACH
        [ -f "$path/patch.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$MACH
        [ -f "$path/config" ] && cat $path/config >> ${KERNEL_OUTPUT}/.config
        [ -f "$path/config.$XARCH.$MACH" ] && cat $path/config.$XARCH.$MACH >> ${KERNEL_OUTPUT}/.config
        [ -f "$path/config.$MACH" ] && cat $path/config.$MACH >> ${KERNEL_OUTPUT}/.config

        # apply the patchset maintained by multiple xxx.patch
        for p in `find $path -type f -name "*.patch" | sort`
        do
            # Ignore some buggy patch via renaming it with suffix .ignore
            echo $p | grep -q .ignore$
            [ $? -eq 0 ] && continue

            echo $p | grep -q \.ignore/
            [ $? -eq 0 ] && continue

            [ -f "$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $p
        done #p
    done #f
done #d

for f in $FEATURE
do
    f=$(echo $f | tr 'A-Z' 'a-z')

    for d in $KFD_BOARD $KFD_BSP $KFD
    do
        for path in $d/$f $d/$f/$LINUX $d/$f/$LINUX_BASE
        do
            [ ! -d $path ] && continue
            echo "Appling feature: $f"

            [ -f "$path/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch
            [ -f "$path/patch.$XARCH.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$XARCH.$MACH
            [ -f "$path/patch.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$MACH
            [ -f "$path/config" ] && cat $path/config >> ${KERNEL_OUTPUT}/.config
            [ -f "$path/config.$XARCH.$MACH" ] && cat $path/config.$XARCH.$MACH >> ${KERNEL_OUTPUT}/.config
            [ -f "$path/config.$MACH" ] && cat $path/config.$MACH >> ${KERNEL_OUTPUT}/.config

            # apply the patchset maintained by multiple xxx.patch
            for p in `find $path -type f -name "*.patch" | sort`
            do
                # Ignore some buggy patch via renaming it with suffix .ignore
                echo $p | grep -q .ignore$
                [ $? -eq 0 ] && continue

                echo $p | grep -q \.ignore/
                [ $? -eq 0 ] && continue

                [ -f "$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $p
            done #p
        done #path
    done #d
done #f

exit 0
