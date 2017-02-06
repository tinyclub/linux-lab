#!/bin/bash

FEATURE="$1"
LINUX=$2
MACH=$3

TOP_DIR=$(dirname `readlink -f $0`)/../

function usage
{
	echo -e "Usage: $0 FEATURE LINUX MACH\n\n e.g. scripts/feature.sh KFT v2.6.36 malta" && exit 0
}

[ -z "$FEATURE" ] && usage
[ -z "$MACH" ] && usage
[ -z "$LINUX" ] && usage

for feature in $FEATURE
do
	FEATURE_ENV=${TOP_DIR}/feature/core/${feature}/env.${MACH}
	[ -f $FEATURE_ENV ] && source $FEATURE_ENV

	FEATURE_ENV=${TOP_DIR}/feature/linux/${LINUX}/${feature}/env.${MACH}
	[ -f $FEATURE_ENV ] && source $FEATURE_ENV
done

export MACH=$MACH LINUX=$LINUX FEATURE="$FEATURE" GCC=$GCC

make gcc

make kernel-checkout

make kernel-defconfig

make kernel-feature

make kernel-oldconfig

make kernel

make boot U=0
