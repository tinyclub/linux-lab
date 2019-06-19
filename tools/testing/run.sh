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

[ -n "$1" ] && BOARDS=$1
[ -n "$2" ] && CASE=$2
[ -n "$3" ] && VERBOSE=$3
[ -n "$4" ] && FEATURE=$4
[ -n "$5" ] && MODULE=$5
[ -n "$6" ] && CFGS=$6
[ -n "$7" ] && ARGS=$7
[ -n "$8" ] && PREBUILT=$8

[ -z "$BOARDS" ] && BOARDS=`make list-board | grep -v ARCH | tr -d ':' | tr -d '[' | tr -d ']' | tr '\n' ' ' | tr -s ' '`
[ -z "$TIMEOUT" ] && TIMEOUT=50
[ -z "$CASE" ] && CASE="release"
[ -z "$FEATURE" ] && FEATURE=""
[ -z "$VERBOSE" ] && VERBOSE=0
[ -z "$MODULE" ] && MODULE=""
[ -z "$PREBUILT" ] && PREBUILT=0

if [ -n "$FEATURE" ]; then
  [ -n "$MODULE" ] && FEATURE="boot,module,$FEATURE"
else
  [ -n "$MODULE" ] && FEATURE="boot,module"
fi

[ "$CASE" == "release" ] && PREBUILT=1

# Run for release, please issue: PREBUILT=1 ./run.sh boot
if [ $PREBUILT -eq 1 ]; then
  _PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
fi

_CASE="test"

case $CASE in
	kernel)
		PREPARE="kernel-full"
		;;
	kernel-release)
		PREPARE="kernel-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	root)
		PREPARE="root-full"
		;;
	root-release)
		PREPARE="root-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	qemu)
		PREPARE="qemu-full"
		;;
	qemu-release)
		PREPARE="qemu-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	uboot)
		PREPARE="uboot-full"
		;;
	uboot-release)
		PREPARE="uboot-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	module)
		;;
	base)
		PREPARE="uboot-full,kernel-full"
		;;
	base-release)
		PREPARE="uboot-all,kernel-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	core)
		PREPARE="uboot-full,kernel-full,root-full"
		;;
	core-release)
		PREPARE="uboot-all,kernel-all,root-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	full)
		PREPARE="uboot-full,kernel-full,root-full,qemu-full"
		;;
	full-release)
		PREPARE="uboot-all,kernel-all,root-all,qemu-all"
		_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
		;;
	boot)
		_CASE="boot-test"
		;;
	release)
		_CASE="boot-test"
		;;
	*)
		_CASE="boot-test"
		;;
esac

# external case in this script
echo -e "\nRunning [$CASE $_CASE]\n"

# Internal case
CASE=$_CASE

PASS_BOARDS=""
FAIL_BOARDS=""

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

	make $CASE b=$b TIMEOUT=$TIMEOUT TEST_RD=$TEST_RD V=$VERBOSE PREPARE=$PREPARE FEATURE=$FEATURE $_PREBUILT m=$MODULE $CFGS $ARGS

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
