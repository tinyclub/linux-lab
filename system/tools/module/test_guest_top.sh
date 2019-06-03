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

    m_args=$(eval echo \$${m}_args)
    echo
    echo "module: modprobe $m $m_args"
    echo
    modprobe $m $m_args &
    sleep 1

    echo
    echo "module: lsmod $m"
    echo
    lsmod
    sleep 1

done
