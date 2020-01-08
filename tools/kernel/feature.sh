#!/bin/bash
#
# kernel-feature.sh -- Apply the available kernel features
#

ARCH=$1
XARCH=$2
BOARD=$3
LINUX=$4
KERNEL_SRC=$5
KERNEL_OUTPUT=$6
FEATURE="$7"

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

        echo "$path"

        echo "Downloading feature: $f"
        [ -x "$path/download.sh" ] && $path/download.sh

        echo "Appling feature: $f"

        [ -f "$path/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch
        [ -f "$path/patch.$XARCH.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$XARCH.$MACH
        [ -f "$path/patch.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$MACH
        [ -f "$path/config" ] && cat $path/config >> ${KERNEL_OUTPUT}/.config
        [ -f "$path/config.$XARCH.$MACH" ] && cat $path/config.$XARCH.$MACH >> ${KERNEL_OUTPUT}/.config
        [ -f "$path/config.$MACH" ] && cat $path/config.$MACH >> ${KERNEL_OUTPUT}/.config

        # apply the patchset maintained by multiple xxx.patch
        patchset="`find $path $MAXDEPTH -type f -name "*.patch" | sort`"

        for p in $patchset
        do
            # Ignore some buggy patch via renaming it with suffix .ignore
            echo $p | grep -q .ignore$
            [ $? -eq 0 ] && continue

            echo $p | grep -q \.ignore/
            [ $? -eq 0 ] && continue

            [ -f "$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $p
        done #p

        echo "Patching more: $f"
        [ -x "$path/patch.sh" ] && $path/patch.sh $ARCH $KERNEL_SRC

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

            echo "Downloading feature: $f"
            [ -x "$path/download.sh" ] && $path/download.sh

            echo "Appling feature: $f"

            [ -f "$path/patch" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch
            [ -f "$path/patch.$XARCH.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$XARCH.$MACH
            [ -f "$path/patch.$MACH" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $path/patch.$MACH
            [ -f "$path/config" ] && cat $path/config >> ${KERNEL_OUTPUT}/.config
            [ -f "$path/config.$XARCH.$MACH" ] && cat $path/config.$XARCH.$MACH >> ${KERNEL_OUTPUT}/.config
            [ -f "$path/config.$MACH" ] && cat $path/config.$MACH >> ${KERNEL_OUTPUT}/.config

            # apply the patchset maintained by multiple xxx.patch
            MAXDEPTH=""
            [ $d/$f == $path ] && MAXDEPTH=" -maxdepth 1 "
            patchset="`find $path $MAXDEPTH -type f -name "*.patch" | sort`"

            for p in $patchset
            do
                # echo $p

                # Ignore some buggy patch via renaming it with suffix .ignore
                echo $p | grep -q .ignore$
                [ $? -eq 0 ] && continue

                echo $p | grep -q \.ignore/
                [ $? -eq 0 ] && continue

                [ -f "$p" ] && patch -r- -N -l -d ${KERNEL_SRC} -p1 < $p
            done #p

            echo "Patching more: $f"
            [ -x "$path/patch.sh" ] && $path/patch.sh $ARCH $KERNEL_SRC

        done #path
    done #d
done #f

exit 0
