#!/bin/bash
#
# nolibc.sh -- test nolibc for all of the supported boards
#
# Usage: nolibc.sh [board]
#

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

def_boards="\
    arm/versatilepb \
    arm/vexpress-a9 \
    arm/virt \
    aarch64/virt \
    ppc/g3beige \
    ppc/ppce500 \
    ppc64le/pseries \
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

    old_arch_file=${TOP_DIR}/src/linux-stable/tools/include/nolibc/arch-$arch.h
    new_arch_file=${TOP_DIR}/src/linux-stable/tools/include/nolibc/$arch/sys.h
    if [ -f $old_arch_file ]; then
      echo $old_arch_file;
    else
      echo $new_arch_file;
    fi
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
        make bsp-outdir b=$b
        make bsp -t b=$b
        make test f=nolibc nolibc_inc=$nolibc_inc DEVMODE=1 TEST_PREPARE=$nolibc_prepare TEST_TIMEOUT=$nolibc_timeout b=$b | tee -a $BOARD_LOGFILE
        cat $BOARD_LOGFILE | col -bp >> $TEST_LOGFILE

        # Parse and report it, based on src/linux-stable/tools/testing/selftests/nolibc/Makefile
        print_line
        echo "LOG: testing report for $b:" | tee -a $TEST_LOGFILE
        echo
	awk '/\[OK\][\r]*$$/{p++} /\[FAIL\][\r]*$$/{if (!f) printf("\n"); f++; print} /\[SKIPPED\][\r]*$$/{s++;print} \
             END{ printf("\n%d test(s): %3d passed, %3d skipped, %3d failed.\n", p+s+f, p, s, f); \
             printf("\nSee all results in %s\n", ARGV[1]) }' $BOARD_LOGFILE | tee -a $TEST_LOGFILE

    else
        echo "LOG: current nolibc doesn't support $b" | tee -a $TEST_LOGFILE
    fi
done

echo
echo "LOG: testing summary:"
echo

max_len=0
for b in $boards
do
    len=$(echo -n $b | wc -c)
    if [ $len -gt $max_len ]; then
        max_len=$len
    fi
done

if [ $max_len -lt 12 ]; then
    max_len=12
fi

printf "%${max_len}s | result\n" "arch/board"
printf "%${max_len}s-|------------\n" "-----------"

for b in $boards
do
    arch=$(get_arch $b)
    arch_file=$(get_arch_file $arch)

    if [ -f "$arch_file" ]; then
        BOARD_LOGFILE=$(get_board_logfile $b)
        printf "%${max_len}s | " $b
        if [ -f $BOARD_LOGFILE ]; then
            awk '/\[OK\][\r]*$$/{p++} /\[FAIL\][\r]*$$/{f++} /\[SKIPPED\][\r]*$$/{s++} \
                 END{ printf("%3d test(s): %3d passed, %3d skipped, %3d failed => status: ", p+s+f, p, s, f); \
                 if (f) printf("failure."); else if (s) printf("warning."); else printf("success.");; \
                 printf(" See all results in %s\n", ARGV[1]) }' $BOARD_LOGFILE
        else
            printf "no test log found\n"
        fi
    else
        printf "%${max_len}s | not supported\n" "$b"
    fi
done

echo
echo "LOG: see all results for all boards in $TEST_LOGFILE"
echo
