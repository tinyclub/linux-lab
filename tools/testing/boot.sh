#!/bin/bash
#
# boot.sh -- test specified boards automatically
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

[ -z "$BOARDS" ] && BOARDS=`make list-board | grep -v ARCH | tr -d ':' | tr -d '[' | tr -d ']' | tr '\n' ' ' | tr -s ' '`
[ -z "$TEST_TIMEOUT" ] && TEST_TIMEOUT=40
[ -z "$TEST_PREBUILT" ] && TEST_PREBUILT="PBK=1 PBR=1 PBU=1 PBD=1 PBQ=1"

TEST_CASE="boot-test"
TEST_VERBOSE=1

PASS_BOARDS=""
FAIL_BOARDS=""

echo -e "\nRunning [$TEST_CASE]\n"
echo -e "\nTesting boards: $BOARDS"

sleep 2

for b in $BOARDS
do
	TEST_RD=/dev/nfs

	echo -e "\nBOARD: [ $b ]"
	echo -e "\n... [ $b ] $TEST_CASE START...\n"

	sleep 2

        if [ "$b" == "aarch64/raspi3" ]; then
		TEST_RD=/dev/ram0
	fi

	make $TEST_CASE b=$b TEST_TIMEOUT=$TEST_TIMEOUT TEST_RD=$TEST_RD V=$TEST_VERBOSE $TEST_PREBUILT

	if [ $? -eq 0 ]; then
		echo -e "\n... [ $b ] $TEST_CASE PASS...\n"
		PASS_BOARDS="${PASS_BOARDS} $b"
	else
		echo -e "\n... [ $b ] $TEST_CASE FAIL...\n"
		FAIL_BOARDS="${FAIL_BOARDS} $b"
	fi

	echo -e "\n... [ $b ] $TEST_CASE STOP...\n"
done

echo -e "\nFinished [$TEST_CASE]\n"

echo -e "\n.......... TEST REPORT..........\n"
echo -e "\nPASS: $PASS_BOARDS"
echo -e "\nFAIL: $FAIL_BOARDS"
echo
