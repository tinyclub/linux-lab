#!/bin/bash
#
# launch.sh -- test a kernel feature of a specified kernel version on a specified board automatically
#
# Usage: tools/testing/launch.sh FEATURE LINUX BOARD
#
#  e.g.: tools/testing/launch.sh kft v2.6.36 malta
#

FEATURE="$1"
LINUX=$2
BOARD=$3
K=$4

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

function usage
{
	echo -e "Usage: $0 FEATURE LINUX BOARD\n\n e.g. tools/testing/launch.sh kft v2.6.36 malta" && exit 0
}

[ -z "$FEATURE" ] && usage
[ -z "$BOARD" ] && usage
[ -z "$LINUX" ] && usage

# Access environment variables
# Usage:
#
#  e.g. ./tools/testing/launch.sh debug,module v4.0 rlk4.0/virt module=oops_test MODULE=oops
#  e.g. ./tools/testing/launch.sh module v4.0 rlk4.0/virt module=oops_test,rcu_test MODULE=oops,rcu,krng,stp,llc TEST_FINISH="echo"
#
# module: module directory list
# MODULE: module name list
#
for v in $(echo $@ | tr ' ' '\n' | grep =)
do
    export $v
done

[ -n "$module" -o "$MODULE" ] && FEATURE=$FEATURE",module"
[ -z "$K" ] && K=1
[ -z "$U" ] && U=0

CORE_DIR=${TOP_DIR}/feature/linux/core/
FEATURE="$(echo $FEATURE | tr ',' ' ')"
MODULE="$(echo $MODULE | tr ',' ' ')"
module="$(echo $module | tr ',' ' ')"

for f in $FEATURE
do
    f=$(echo $f | tr 'A-Z' 'a-z')
    LINUX_DIR=${TOP_DIR}/feature/linux/$f/$LINUX/

    for f_env in $CORE_DIR/$f/env $CORE_DIR/$f/env.$BOARD $LINUX_DIR/env $LINUX_DIR/env.$BOARD
    do
	echo $f_env
        [ -f $f_env ] && export $(< $f_env)
    done
done

export board=$BOARD U=$U LINUX=$LINUX FEATURE="$FEATURE" MODULE="$MODULE"
eval `make env | grep ROOTDIR | tr -d ' '`

if [ "x$K" == "x1" ]; then
    make gcc
    make kernel-checkout
    make kernel-patch
    make kernel-defconfig
    make kernel-feature
    make kernel-oldconfig
    make kernel V=$V
fi

# Make sure the testing framework is installed
# system/: etc/default/testing, tools/testing/start.sh, tools/FEATURE/test.sh
make rootdir

echo $FEATURE | grep -q module
if [ $? -eq 0 ]; then
    make module M=
    make module-install M=

    for m in $module
    do
        echo "Building module: $m"
        make module module=$m
        make module-install module=$m
    done
fi

make root-install

# TODO: host prepare for testing
for f in $FEATURE
do
    test_host_before=${TOP_DIR}/system/tools/$f/test_host_before.sh
    [ -x $test_host_before ] && $test_host_before
done

# TODO: To transfer data easier, ROOTDEV=/dev/nfs is preferable, data is stored in $ROOTDIR
make test

# TODO: host prepare for testing
for f in $FEATURE
do
    test_host_after=${TOP_DIR}/system/tools/$f/test_host_after.sh
    [ -x $test_host_after ] && $test_host_after $ROOTDIR
done
