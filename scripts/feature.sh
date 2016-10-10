#!/bin/bash

FEATURE="$1"
LINUX=$2
MACH=$3

TOP_DIR=$(dirname `readlink -f $0`)/../

function usage
{
	echo -e "Usage: $0 FEATURE LINUX MACH\n\n e.g. scripts/feature.sh kft v2.6.36 malta" && exit 0
}

[ -z "$FEATURE" ] && usage
[ -z "$MACH" ] && usage
[ -z "$LINUX" ] && usage

CORE_DIR=${TOP_DIR}/feature/linux/core/
LINUX_DIR=${TOP_DIR}/feature/linux/$LINUX/

for f in $FEATURE
do
    f=$(echo $f | tr 'A-Z' 'a-z')

    for f_env in $CORE_DIR/$f/env $CORE_DIR/$f/env.$MACH $LINUX_DIR/$f/env $LINUX_DIR/$f/env.$MACH
    do
	echo $f_env
        [ -f $f_env ] && export $(< $f_env)
    done
done

export MACH=$MACH LINUX=$LINUX FEATURE="$FEATURE"

make gcc

make kernel-checkout

make kernel-defconfig

make kernel-feature

make kernel-oldconfig

make kernel

make boot U=0
