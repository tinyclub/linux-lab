#!/bin/sh
#
# test.sh -- test module, see Documentation/
#

MODULES="$(cat /proc/cmdline | tr ' ' '\n' | grep ^module= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$MODULES" ] && echo "LOG: no module specified" && exit 0

echo
echo "module: Starting testing: $MODULES ..."
echo

for m in $MODULES 
do

    modprobe $m
    sleep 1

    lsmod
    sleep 1

    rmmod $m

done

echo
echo "module: Stoping testing: $MODULES ..."
echo
