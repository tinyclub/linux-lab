#!/bin/bash
#
# feature.sh -- test a kernel feature of a specified kernel version on a specified board automatically
#
# Usage: scripts/feature.sh FEATURE LINUX BOARD
#
#  e.g.: scripts/feature.sh kft v2.6.36 malta
#

FEATURE="$1"
LINUX=$2
BOARD=$3
V=$4

TOP_DIR=$(dirname `readlink -f $0`)/../

function usage
{
	echo -e "Usage: $0 FEATURE LINUX BOARD\n\n e.g. scripts/feature.sh kft v2.6.36 malta" && exit 0
}

[ -z "$FEATURE" ] && usage
[ -z "$BOARD" ] && usage
[ -z "$LINUX" ] && usage

CORE_DIR=${TOP_DIR}/feature/linux/core/
LINUX_DIR=${TOP_DIR}/feature/linux/$LINUX/

for f in $FEATURE
do
    f=$(echo $f | tr 'A-Z' 'a-z')

    for f_env in $CORE_DIR/$f/env $CORE_DIR/$f/env.$BOARD $LINUX_DIR/$f/env $LINUX_DIR/$f/env.$BOARD
    do
	echo $f_env
        [ -f $f_env ] && export $(< $f_env)
    done
done

export board=$BOARD LINUX=$LINUX FEATURE="$FEATURE"
eval `make env | grep ROOTDIR | tr -d ' '`

make gcc

make kernel-checkout

make kernel-defconfig

make kernel-feature

make kernel-oldconfig

make kernel V=$V

# Make sure the testing framework is installed
# system/: etc/default/testing, tools/testing/start.sh, tools/FEATURE/test.sh
make root-install

make root-rebuild

# TODO: host prepare for testing
for f in $FEATURE
do
    test_host_before=${TOP_DIR}/system/tools/$f/test_host_before.sh
    [ -x $test_host_before ] && $test_host_before
done

# TODO: To transfer data easier, ROOTDEV=/dev/nfs is preferable, data is stored in $ROOTDIR
make boot U=0 EXT_CMDLINE=feature=$(echo $FEATURE | tr ' ' ',') ROOTDEV=/dev/nfs

# TODO: host prepare for testing
for f in $FEATURE
do
    test_host_after=${TOP_DIR}/system/tools/$f/test_host_after.sh
    [ -x $test_host_after ] && $test_host_after $ROOTDIR
done
