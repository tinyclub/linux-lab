#!/bin/bash
#
# run.sh -- test specified boards automatically
#
# TODO:
#      1. test core features of boards
#      2. different boards should maintain a board feature list for specific linux version: nfsroot, 9pnet, graphic boot ...
#      3. all of the features should be tested, if possible, no regression
#
# Notes:
#      1. every release should pass this basic test
#      2. some boards may fail, should be fixed if possible, for example, raspi3 hang at reboot issued
#
# Known failures:
#
#      1. these boards hang after send 'poweroff' or 'reboot' command: aarch64/raspi3, arm/verstailpb, mipsel/malta
#

BOARDS=$1
CASE=$2
VERBOSE=$3
FEATURE=$4
MODULE=$5
CFGS=$6
ARGS=$7

[ -z "$BOARDS" ] && BOARDS=`make list-board | grep -v ARCH | tr -d ':' | tr -d '[' | tr -d ']' | tr '\n' ' ' | tr -s ' '`
[ -z "$TIMEOUT" ] && TIMEOUT=50
[ -z "$CASE" ] && CASE="boot"
[ -z "$FEATURE" ] && FEATURE=""
[ -z "$VERBOSE" ] && VERBOSE=0
[ -z "$MODULE"] && MODULE=""

case $CASE in
	kernel)
		CASE="test"
		PREPARE="kernel-full"
		;;
	root)
		CASE="test"
		PREPARE="root-full"
		;;
	qemu)
		CASE="test"
		PREPARE="qemu-full"
		;;
	uboot)
		CASE="test"
		PREPARE="uboot-full"
		;;
	base)
		CASE="test"
		PREPARE="uboot-full,kernel-full"
		;;
	core)
		CASE="test"
		PREPARE="uboot-full,kernel-full,root-full"
		;;
	all)
		CASE="test"
		PREPARE="kernel-full,root-full,qemu-full,uboot-full"
		;;
	boot)
		CASE="boot-test"
		PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	*)
		CASE="boot-test"
		PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
esac

PASS_BOARDS=""
FAIL_BOARDS=""

echo -e "\nRunning [$CASE]\n"
echo -e "\nTesting boards: $BOARDS"
echo
echo -e "\n       prepare: $PREPARE"
echo -e "\n  boot timeout: $TIMEOUT"
echo -e "\n       verbose: $VERBOSE"
echo -e "\n      prebuilt: $PREBUILT"
echo -e "\n      features: $FEATURE"
echo -e "\n       modules: $MODULE"
echo -e "\n          args: $ARGS"
echo -e "\n          cfgs: $CFGS"
echo

sleep 2

for b in $BOARDS
do
	TEST_RD=/dev/nfs

	echo -e "\nBOARD: [ $b ]"
	echo -e "\n... [ $b ] $CASE START...\n"

	sleep 2

        if [ "$b" == "aarch64/raspi3" ]; then
		TEST_RD=/dev/ram0
	fi

	make $CASE b=$b TIMEOUT=$TIMEOUT TEST_RD=$TEST_RD V=$VERBOSE PREPARE=$PREPARE FEATURE=$FEATURE $PREBUILT m=$MODULE $CFGS $ARGS

	if [ $? -eq 0 ]; then
		echo -e "\n... [ $b ] $CASE PASS...\n"
		PASS_BOARDS="${PASS_BOARDS} $b"
	else
		echo -e "\n... [ $b ] $CASE FAIL...\n"
		FAIL_BOARDS="${FAIL_BOARDS} $b"
	fi

	echo -e "\n... [ $b ] $CASE STOP...\n"
done

echo -e "\nFinished [$CASE]\n"

echo -e "\n.......... TEST REPORT..........\n"
echo -e "\nPASS: $PASS_BOARDS"
echo -e "\nFAIL: $FAIL_BOARDS"
echo
