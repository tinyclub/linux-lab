#!/bin/sh
#
# start.sh -- start testing of a kernel feature
#

[ -r /etc/default/testing ] && . /etc/default/testing

# Get feature list from kernel command line
FEATURE="$(cat /proc/cmdline | tr ' ' '\n' | grep ^feature= | cut -d'=' -f2 | tr ',' ' ')"
FINISH="$(cat /proc/cmdline | tr ' ' '\n' | grep ^test_finish= | cut -d'=' -f2 | tr ',' ' ')"
REBOOT="$(cat /proc/cmdline | tr ' ' '\n' | grep ^reboot= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$FEATURE" ] && exit 0
[ -z "$FINISH" ] && FINISH=$FINISH_ACTION

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

if [ -n "$REBOOT" ]; then
    if [ ! -f "$REBOOT_COUNT" ]; then
        reboot_count=0
        echo "Rebooting in progress, current: $reboot_count, total: $REBOOT."
        echo $reboot_count > $REBOOT_COUNT
    else
        reboot_count=`cat $REBOOT_COUNT`
        let reboot_count=$reboot_count+1
        if [ $reboot_count -ge $REBOOT ]; then
            echo "Rebooting finished, total times: $reboot_count."
            rm $REBOOT_COUNT
            FINISH=$FINISH_ACTION
        else
            echo "Rebooting in progress, current: $reboot_count, total: $REBOOT."
            echo $reboot_count > $REBOOT_COUNT
        fi
    fi
fi

echo
echo "Testing finished: Running '$FINISH' ..."
echo

eval $FINISH
