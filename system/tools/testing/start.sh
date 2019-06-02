#!/bin/sh
#
# start.sh -- start testing of a kernel feature
#

[ -r /etc/default/testing ] && . /etc/default/testing

# Get feature list from kernel command line

#
# Skip: a.yy=b, rw ...
#
# Keep: test_case=ls\ /root    test_case="ls /root,echo hello world"
#
eval "$(cat /proc/cmdline | tr ' ' '\n' | egrep -v '\..*=|^$' | tr '\n' ' ' | tr '=' '\n' | sed -e '/["\\]/!s/\(.*\) [a-zA-Z_]\{1,\} \(.*\)/\1 \2/g' | tr '\n' '=')"

FEATURE="$feature"
CASE="$test_case"
BEGIN="$test_begin"
END="$test_end"
FINISH="$test_finish"
REBOOT="$reboot"

[ -z "$FEATURE" -a -z "$CASE" -a -z "$REBOOT" ] && exit 0
[ -z "$BEGIN" ] && BEGIN=$BEGIN_ACTION
[ -z "$END" ] && END=$END_ACTION
[ -z "$FINISH" ] && FINISH=$FINISH_ACTION

echo
echo "Starting testing ..."
echo

echo
echo "Testing begin: Running \"$BEGIN\" ..."
echo

eval $BEGIN

oldIFS=$IFS
IFS=","

for f in $FEATURE
do
    echo
    echo "Testing feature (top part): $f"
    echo

    [ -x ${TOOLS}/$f/test_guest.sh ] && ${TOOLS}/$f/test_guest.sh
    [ -x ${TOOLS}/$f/test_guest_top.sh ] && ${TOOLS}/$f/test_guest_top.sh

    echo
done

for c in $CASE
do
    echo
    echo "Testing case: \"$c\""
    echo

    eval $c

    echo

done

for f in $FEATURE
do
    echo
    echo "Testing feature (bottom part): $f"
    echo

    [ -x ${TOOLS}/$f/test_guest_bottom.sh ] && ${TOOLS}/$f/test_guest_bottom.sh

    echo
done

IFS=$oldIFS

echo
echo "Testing end: Running \"$END\" ..."
echo

eval $END

echo

if [ -n "$REBOOT" ]; then
    FINISH=$REBOOT_ACTION
    if [ ! -f "$REBOOT_COUNT" ]; then
        reboot_count=0
        echo "Rebooting in progress, current: $reboot_count, total: $REBOOT."
        echo $reboot_count > $REBOOT_COUNT
    else
        reboot_count=`cat $REBOOT_COUNT`
        let reboot_count=$reboot_count+1
        if [ $reboot_count -ge $REBOOT ]; then
            echo "Rebooting finish, total times: $reboot_count."
            rm $REBOOT_COUNT
            FINISH=$POWEROFF_ACTION
        else
            echo "Rebooting in progress, current: $reboot_count, total: $REBOOT."
            echo $reboot_count > $REBOOT_COUNT
        fi
    fi
fi

echo
echo "Testing finish: Running \"$FINISH\" ..."
echo

eval $FINISH
