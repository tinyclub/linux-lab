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
    loongarch64/virt \
    riscv64/virt \
    riscv32/virt \
    s390x/s390-ccw-virtio"

# Allow user test a target board
boards=$1

# Allow pass nolibc_inc via environment
[ -z "$nolibc_inc" ] && nolibc_inc=sysroot
[ -z "$nolibc_timeout" ] && nolibc_timeout=10
[ -z "$nolibc_run" ] && nolibc_run=1

while [ -z "$boards" ]
do
    echo "LOG: Available boards for nolibc testing:"
    echo
    echo all $def_boards | tr ' ' '\n' | cat -n
    echo

    read -p "LOG: Choose one or more for nolibc test? " boardnumbers

    [ "$boardnumbers" == "1" ] && boards=all && break

    boardnumbers="$(echo $boardnumbers | tr ',' ' ' | tr ';' ' ')"
    for n in $boardnumbers
    do
        sednp="${n}p;$sednp"
    done
    boards=$(echo all $def_boards | tr ' ' '\n' | sed -n "$sednp")
    [ -z "$boards" ] && echo "Please choose a valid board number in the list."
done

[ "$boards" == "all" ] && boards="$def_boards"

TEST_LOGDIR=${TOP_DIR}/logging/nolibc
TEST_LOGFILE=${TEST_LOGDIR}/nolibc-test.log
mkdir -p $TEST_LOGDIR

rm -rf $TEST_LOGFILE

function get_arch
{
    local board="$1"
    echo $board | cut -d'/' -f1 | sed -e 's/mips.*/mips/g;s/s390.*/s390/g;s/riscv.*/riscv/g;s/ppc.*/powerpc/g;s/loongarch.*/loongarch/g'
}

function get_arch_file
{
    local arch="$1"
    echo ${TOP_DIR}/src/linux-stable/tools/include/nolibc/arch-$arch.h
}

function get_board_logfile
{
    local board="$(echo $1 | tr '/' '-')"
    echo $TEST_LOGDIR/$board-nolibc-test.log
}

function print_line
{
    echo "=====================================================================" | tee -a $TEST_LOGFILE
}

for b in $boards
do
    arch=$(get_arch $b)
    arch_file=$(get_arch_file $arch)

    # Allow skip the running
    if [ $nolibc_run -ne 1 ]; then
        break
    fi

    print_line
    if [ -f "$arch_file" ]; then
        echo "LOG: running nolibc test for $b" | tee -a $TEST_LOGFILE
        print_line

        BOARD_LOGFILE=$(get_board_logfile $b)
        rm -rf $BOARD_LOGFILE
        make test f=nolibc nolibc_inc=$nolibc_inc DEVMODE=1 TEST_PREPARE=$nolibc_prepare TEST_TIMEOUT=$nolibc_timeout b=$b | tee -a $BOARD_LOGFILE
        cat $BOARD_LOGFILE | col -bp >> $TEST_LOGFILE

        # Parse and report it, based on src/linux-stable/tools/testing/selftests/nolibc/Makefile
        print_line
        echo "LOG: testing report for $b:" | tee -a $TEST_LOGFILE
        echo
        awk '/\[OK\][\r]*$$/{p++} /\[FAIL\][\r]*$$/{f++;print} /\[SKIPPED\][\r]*$$/{s++;print} \
             END{ printf("\n%d test(s) passed, %d skipped, %d failed.\n", p, s, f); \
             printf("See all results in %s\n", ARGV[1]) }' $BOARD_LOGFILE | tee -a $TEST_LOGFILE

    else
        echo "LOG: current nolibc doesn't support $b" | tee -a $TEST_LOGFILE
    fi
done

echo
echo "LOG: testing summary:"
echo

echo -e "arch/board\tresult"

for b in $boards
do
    arch=$(get_arch $b)
    arch_file=$(get_arch_file $arch)

    if [ -f "$arch_file" ]; then
        BOARD_LOGFILE=$(get_board_logfile $b)
        printf "%-8s\t" $b
        awk '/\[OK\][\r]*$$/{p++} /\[FAIL\][\r]*$$/{f++} /\[SKIPPED\][\r]*$$/{s++} \
             END{ printf("%d test(s) passed, %d skipped, %d failed.", p, s, f); \
             printf(" See all results in %s\n", ARGV[1]) }' $BOARD_LOGFILE
    else
        echo -e "$b\tnot supported"
    fi
done

echo
echo "LOG: see all results for all boards in $TEST_LOGFILE"
echo
