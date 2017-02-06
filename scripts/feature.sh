#!/bin/bash

FEATURE=$1
LINUX=$2
MACH=$3

function usage
{
	echo -e "Usage: $0 FEATURE LINUX MACH\n\n e.g. scripts/feature.sh KFT v2.6.36 malta" && exit 0
}

[ -z "$FEATURE" ] && usage
[ -z "$MACH" ] && usage
[ -z "$LINUX" ] && usage

make MACH=$MACH

LINUX=$LINUX make env-save

make kernel-checkout

make kernel-defconfig

FEATURE="$FEATURE" make kernel-feature

make kernel-oldconfig

make kernel

make boot ROOTDEV=/dev/nfs
