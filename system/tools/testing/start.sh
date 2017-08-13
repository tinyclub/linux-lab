#!/bin/sh
#
# start.sh -- start testing of a kernel feature
#

[ -r /etc/default/testing ] && . /etc/default/testing

# Get feature list from kernel command line
FEATURE="$(cat /proc/cmdline | tr ' ' '\n' | grep ^feature= | cut -d'=' -f2 | tr ',' ' ')"
[ -z "$FEATURE" ] && exit 0

echo
echo "Starting testing ..."
echo

for f in $FEATURE
do
    echo
    echo "Testing feature: $f"
    echo

    ${TOOLS}/$f/test_guest.sh

    echo
done

echo

echo "Stop testing through poweroff the machine in 5 seconds ..."
poweroff -d 5
