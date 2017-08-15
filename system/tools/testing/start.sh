#!/bin/sh
#
# start.sh -- start testing of a kernel feature
#

[ -r /etc/default/testing ] && . /etc/default/testing

# Get feature list from kernel command line
FEATURE="$(cat /proc/cmdline | tr ' ' '\n' | grep ^feature= | cut -d'=' -f2 | tr ',' ' ')"
FINISH="$(cat /proc/cmdline | tr ' ' '\n' | grep ^test_finish= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$FEATURE" ] && exit 0
[ -z "$FINISH" ] && FINISH="poweroff -d 5"

echo
echo "Starting testing ..."
echo

for f in $FEATURE
do
    echo
    echo "Testing feature: $f"
    echo

    [ -x ${TOOLS}/$f/test_guest.sh ] && ${TOOLS}/$f/test_guest.sh

    echo
done

echo
echo "Testing finished"
echo

echo "Running $FINISH"
eval $FINISH
