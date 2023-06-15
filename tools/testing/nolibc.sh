#!/bin/bash
#
# nolibc.sh -- test nolibc for all of the supported boards
#
# Usage: nolibc.sh [board]
#

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

def_boards="arm/vexpress-a9 \
    aarch64/virt \
    ppc/g3beige \
    i386/pc \
    x86_64/pc \
    mipsel/malta \
    riscv64/virt \
    riscv32/virt \
    s390x/s390-ccw-virtio"

# Allow user test a target board
boards=$1

while [ -z "$boards" ]
do
    echo "LOG: Available boards for nolibc testing:"
    echo
    echo $def_boards | tr ' ' '\n' | cat -n
    echo

    read -p "LOG: Choose one or more for nolibc test? " boardnumbers

    boardnumbers="$(echo $boardnumbers | tr ',' ' ' | tr ';' ' ')"
    for n in $boardnumbers
    do
        sednp="${n}p;$sednp"
    done
    boards=$(echo $def_boards | tr ' ' '\n' | sed -n "$sednp")
    [ -z "$boards" ] && echo "Please choose a valid board number in the list."
done

[ "$boards" == "all" ] && boards="$def_boards"

TEST_LOGDIR=${TOP_DIR}/logging
TEST_LOGFILE=${TEST_LOGDIR}/nolibc.log
mkdir -p $TEST_LOGDIR

rm -rf $TEST_LOGFILE

for b in $boards
do
    arch=$(echo $b | cut -d'/' -f1 | sed -e 's/mips.*/mips/g;s/s390.*/s390/g;s/riscv.*/riscv/g;s/ppc.*/powerpc/g')
    arch_file=${TOP_DIR}/src/linux-stable/tools/include/nolibc/arch-$arch.h

    echo "=====================================================================" | tee -a $TEST_LOGFILE
    if [ -f "$arch_file" ]; then
        echo "LOG: running nolibc test for $b" | tee -a $TEST_LOGFILE
        echo "=====================================================================" | tee -a $TEST_LOGFILE

        ARCH_LOGFILE=$TEST_LOGDIR/$arch-nolibc.log
        rm -rf $ARCH_LOGFILE
        time make test f=nolibc DEVMODE=1 TEST_TIMEOUT=10 b=$b | col -bp | tee -a $ARCH_LOGFILE
        cat $ARCH_LOGFILE >> $TEST_LOGFILE

        # Parse and report it, based on src/linux-stable/tools/testing/selftests/nolibc/Makefile
        echo "=====================================================================" | tee -a $TEST_LOGFILE
        echo "LOG: testing report for $b:" | tee -a $TEST_LOGFILE
	echo
        awk '/\[OK\][\r]*$$/{p++} /\[FAIL\][\r]*$$/{f++;print} /\[SKIPPED\][\r]*$$/{s++;print} \
             END{ printf("\n%d test(s) passed, %d skipped, %d failed.\n", p, s, f); \
             printf("See all results in %s\n", ARGV[1]) }' $ARCH_LOGFILE | tee -a $TEST_LOGFILE

    else
        echo "LOG: current nolibc doesn't support $b" | tee -a $TEST_LOGFILE
    fi
done

echo
echo "LOG: see all results for all boards in $TEST_LOGFILE"
echo
