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

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

# Kill old gdb and qemu if exists
CLEAN=$TOP_DIR/tools/testing/kill.sh

[ -n "$1" ] && BOARD=$1
[ -n "$2" ] && CASE=$2
[ -n "$3" ] && VERBOSE=$3
[ -n "$4" ] && FEATURE=$4
[ -n "$5" ] && MODULE=$5
[ -n "$6" ] && CFGS=$6
[ -n "$7" ] && ARGS=$7
[ -n "$8" ] && PREBUILT=$8
[ -n "$9" ] && DEBUG=$9

[ -z "$TIMEOUT" ] && TIMEOUT=50
[ -z "$CASE" ] && CASE="release"
[ -z "$FEATURE" ] && FEATURE=""
[ -z "$VERBOSE" ] && VERBOSE=0
[ -z "$MODULE" ] && MODULE=""
[ -z "$PREBUILT" ] && PREBUILT=0
[ -z "$DEBUG" ] && DEBUG=0

if [ -z "$BOARD" -a -f "$TOP_DIR/.board_config" ]; then
	BOARD=$(cat $TOP_DIR/.board_config)
fi

[ -z "$BOARD" ] && BOARD=all

if [ "$BOARD" = "all" ]; then
	unset BOARD
	BOARDS=`make list-board | grep -v ARCH | tr -d ':' | tr -d '[' | tr -d ']' | tr '\n' ' ' | tr -s ' '`
else
	BOARDS="$BOARD"
fi

if [ -n "$FEATURE" ]; then
	[ -n "$MODULE" ] && FEATURE="boot,module,$FEATURE"
else
	[ -n "$MODULE" ] && FEATURE="boot,module"
fi

_CASE="test"

case $CASE in
	kernel)
		PREPARE="kernel-full"
		;;
	kernel-release)
		PREPARE="kernel-all"
		PREBUILT=1
		;;
	root)
		PREPARE="root-full"
		;;
	root-release)
		PREPARE="root-all"
		PREBUILT=1
		;;
	qemu)
		PREPARE="qemu-full"
		;;
	qemu-release)
		PREPARE="qemu-all"
		PREBUILT=1
		;;
	uboot)
		PREPARE="uboot-full"
		;;
	uboot-release)
		PREPARE="uboot-all"
		PREBUILT=1
		;;
	module)
		;;
	base)
		PREPARE="uboot-full,kernel-full"
		;;
	base-release)
		PREPARE="uboot-all,kernel-all"
		PREBUILT=1
		;;
	core)
		PREPARE="uboot-full,kernel-full,root-full"
		;;
	core-release)
		PREPARE="uboot-all,kernel-all,root-all"
		PREBUILT=1
		;;
	full)
		PREPARE="uboot-full,kernel-full,root-full,qemu-full"
		;;
	full-release)
		PREPARE="uboot-all,kernel-all,root-all,qemu-all"
		PREBUILT=1
		;;
	debug)
		_CASE="boot-test"
		DEBUG=1
		;;
	boot)
		_CASE="boot-test"
		;;
	release)
		_CASE="boot-test"
		PREBUILT=1
		;;
	*)
		_CASE="boot-test"
		;;
esac

if [ $DEBUG -eq 1 ]; then
	_DEBUG=D=1
	#TEST_RD=/dev/ram0
fi

# Run for release, please issue: PREBUILT=1 ./run.sh boot
if [ $PREBUILT -eq 1 ]; then
	_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"
fi


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
echo -e "\n         debug: $DEBUG"
echo

sleep 2

for b in $BOARDS
do
	[ -z "$TEST_RD" ] && TEST_RD=/dev/nfs

	echo -e "\nBOARD: [ $b ]"
	echo -e "\n... [ $b ] $CASE START...\n"

	sleep 2

        if [ "$b" == "aarch64/raspi3" ]; then
		TEST_RD=/dev/ram0
	fi

	$CLEAN
	sleep 2

	make $CASE b=$b TIMEOUT=$TIMEOUT TEST_RD=$TEST_RD V=$VERBOSE PREPARE=$PREPARE FEATURE=$FEATURE $_PREBUILT $_DEBUG m=$MODULE $CFGS $ARGS
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
