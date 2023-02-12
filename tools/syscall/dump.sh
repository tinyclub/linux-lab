#!/bin/bash
#
# dump.sh -- dump system call used
#

OBJDUMP=$1
BIN=$2
XARCH=$3

# Arch support, based on tools/include/nolibc/arch-<ARCH>.h
case $XARCH in
  riscv*)
    load_inc="li[[:space:]]*a7"
    scall_inc="ecall"
    num_pos=2
    ;;
  x86_64)
    load_inc="%rax|%eax"
    scall_inc="syscall"
    num_pos=1
    ;;
  *)
    echo "ERR: not supported"
    exit 1
    ;;
esac

# Parse used system call numbers
for num in $($OBJDUMP -d $BIN | egrep "$load_inc|$scall_inc" | egrep -B1 "$scall_inc" | egrep "$load_inc" | rev | cut -d ' ' -f1 | rev | cut -d ',' -f$num_pos | tr -d '$')
do
  echo $(($num))
done
