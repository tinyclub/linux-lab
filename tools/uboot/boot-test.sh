#!/bin/bash -e
#
# boot-test.sh -- check uboot autoboot fails, if fails, will stop at uboot command line and eventually no kernel log output
#
# example:
#	$ tools/uboot/boot-test.sh versatilepb
#
# 	$ tools/uboot/boot-test.sh vexpress-a9
#
# this can be used to do tools/git/bisect.sh if uboot autoboot fails.
#

# get running board
board=$1
boot_timeout=$2

[ -z "$board" ] && echo "Usage: $0 versatilepb|vexpress-a9 [boot_timeout]" && exit 1

case $board in
  versatilepb)
	#fail_string="VersatilePB #"
	success_string="Booting Linux on"
	[ -z "$boot_timeout" ] && boot_timeout=10
	;;
  vexpress-a9)
	success_string="Booting Linux on"
	[ -z "$boot_timeout" ] && boot_timeout=10
	;;
	*)
	echo "ERR: $b: not support uboot currently, available boards: versatilepb, vexpress-a9" && exit 1
	;;
esac

boot_fail=1

make b=$board uboot-checkout
make b=$board uboot-patch
make b=$board uboot-defconfig
make b=$board uboot

log=`mktemp`
make b=$board M=512M boot V=1 XOPTS="-serial mon:file:$log" &
boot_pid=$!

sleep $boot_timeout

cat $log
grep --color=always "$success_string" $log && boot_fail=0

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
