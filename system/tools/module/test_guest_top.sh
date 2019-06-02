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

    echo
    echo "module: Starting testing module: $m"
    echo

    echo
    echo "module: modprobe $m"
    echo
    modprobe $m
    sleep 1

    echo
    echo "module: lsmod $m"
    echo
    lsmod
    sleep 1

done
