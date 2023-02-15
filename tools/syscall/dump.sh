#!/bin/bash
#
# dump.sh -- dump system calls used
#

BIN=$1
XARCH=$2
KSRC=$3
INC="$4"
CCPRE=$5

READELF=${CCPRE}readelf
OBJDUMP=${CCPRE}objdump
GCC=${CCPRE}gcc

# Arch support, based on tools/include/nolibc/arch-<ARCH>.h
case $XARCH in
  riscv*)
    load_ins="li[[:space:]]*a7"
    scall_ins="ecall"
    bak_pos=1
    num_pos=2
    ;;
  mipsel)
    load_ins="li[[:space:]]*v0"
    scall_ins="syscall"
    bak_pos=1
    num_pos=2
    ;;
  x86_64)
    load_ins="%rax|%eax"
    scall_ins="syscall"
    bak_pos=1
    num_pos=1
    ;;
  *)
    echo "ERR: not supported"
    exit 1
    ;;
esac

# FIXME: Parse used system call numbers, this doesn't work when the code is optimized, the 'system call number' will not be always passed near the 'system call instruction'
# TODO: This should be fixed up manually or use another method instead, such as system call tracing?
# TODO: Add a new section to record the used system calls in nolibc itself, dump that section instead is better
syscalls_used=""

# These must be true, but may include some not stripped
OBJ=$BIN.o
syscalls_num=$($OBJDUMP -d -j .rodata.syscalls $OBJ | sed -n -e '/.rodata.syscalls/,/^$/{/.rodata.syscalls/!{/^$/!{p}}}' | tr -d -c '[0-9a-zA-Z \t\n]' | tr '\t' ' ' | tr -s ' ' | cut -d ' ' -f3 | sed -e 's/^0*//g' | awk '{printf("0x%s\n",$0);}')
for num in $syscalls_num
do
  # echo $(($num))
  syscalls_used="$syscalls_used $(($num))"
done

# Get out the syscalls stripped
PGC=$BIN.p
syscalls_stripped=$(cat $PGC | grep .text.*sys_ | sed -e "s/ '.text.sys_\([^ ]*\)' /\n\1\n/g")

for num in $($OBJDUMP -d $BIN | egrep "$load_ins|$scall_ins" | egrep -B$bak_pos "$scall_ins" | egrep "$load_ins" | rev | cut -d ' ' -f1 | rev | cut -d ',' -f$num_pos | sort -u -g | tr -d '$')
do
  # echo $(($num))
  syscalls_used="$syscalls_used $(($num))"
done

# Remove duplicated
syscalls_used=$(echo $syscalls_used | tr ' ' '\n' | sort -u -g)

# Convert system call numbers to system call functions
_syscall_macros=$(mktemp)
  syscall_refs=$(mktemp)
 syscall_macros=$(mktemp)
    syscall_map=$(mktemp)

cat << __EOF__ | $GCC $INC -xc - -E -dM | grep "#define __NR" > $_syscall_macros
#include <unistd.h>
__EOF__

# Move the referenced macros at the header to make sure the later ones execute normally
refmacros=$(cat $_syscall_macros | egrep "__NR[0-9]*_[^ ]*$| \(__NR[0-9]*_[^ ]*" | cut -d ' ' -f3 | tr -d '(' | sort -u | tr '\n' ' ' | sed -e 's/ $//g' | tr ' ' '|')

cat $_syscall_macros | egrep "^#define ($refmacros)" | sed -e 's/#define __NR[0-9]*_\([^ ]*\) /\1=/g' > $syscall_refs

# Dump out the pure macros
cat $_syscall_macros | egrep -v "^#define ($refmacros)" > $syscall_macros

# Convert macros to a system call map
cat $syscall_macros | sed -e 's/#define __NR[0-9]*_\([^ ]*\) \(.*\)/syscall[$((\2))]="\1"/g;s/__NR_//g' >> $syscall_map

# Mapping it
. $syscall_refs
. $syscall_map

# Get the names
for s in $syscalls_used
do
  n=${syscall[$s]}
  [ -z "$n" ] && continue
  echo $syscalls_stripped | tr ' ' '\n' | grep -q "^$n$"
  [ $? -eq 0 ] && continue
  echo $s $n
done

# Remove tmp files
rm -rf $_syscall_macros $syscall_refs $syscall_macros $syscall_map

exit 0
