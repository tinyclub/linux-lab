#!/bin/bash -e
#
# boot-fail.sh -- check uboot autoboot fails, if fails enter into uboot command line
#
# example:
#	$ tools/uboot/boot-fail.sh versatilepb
#
# 	$ tools/uboot/boot-fail.sh vexpress-a9
#
# this can be used to do tools/git/bisect.sh if uboot autoboot fails.
#

# get running board
board=$1
boot_timeout=$2

[ -z "$board" ] && echo "ERR: $0 versatilepb|vexpress-a9 [boot_timeout]" && exit 1

case $board in
  versatilepb)
	fail_string="VersatilePB #"
	[ -z "$boot_timeout" ] && boot_timeout=10
	;;
  vexpress-a9)
	fail_string="VExpress#"
	[ -z "$boot_timeout" ] && boot_timeout=10
	;;
	*)
	echo "ERR: $b: not support uboot currently, available boards: versatilepb, vexpress-a9" && exit 1
	;;
esac

boot_fail=0

make b=$board uboot-checkout
make b=$board uboot-patch
make b=$board uboot-defconfig
make b=$board uboot

log=`mktemp`
make b=$board M=512M boot XOPTS="-serial mon:file:$log" &
boot_pid=$!

sleep $boot_timeout

cat $log
grep --color=always "$fail_string" $log && boot_fail=1

rm $log
#echo $$ $boot_pid
kill -9 $boot_pid
sudo pkill qemu-system

if [ $boot_fail -eq 1 ]; then
	echo "ERR: Uboot boot fails on $board, waited for $boot_timeout seconds."
else
	echo "LOG: Uboot boot success on $board, checked for $boot_timeout seconds."
fi

exit $boot_fail
