#!/bin/sh
#
# test.sh -- test module, see Documentation/
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

MODULES="$(cat /proc/cmdline | tr ' ' '\n' | grep ^module= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$MODULES" ] && echo "LOG: no module specified" && exit 0

for m in $MODULES
do

    echo
    echo "module: rmmod $m"
    echo
    rmmod -f $m &
    sleep 1

    echo
    echo "module: Stoping testing module: $m"
    echo

done

echo
echo "module: Stoping testing: $MODULES ..."
echo
