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
    # We don't care COMPAT mode, that mode should be disabled eventually for embedded system?
    scall_table="arch/riscv/kernel/syscall_table.c"
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

syscalls_used=""

# FIXME: The .rodata.syscalls may include the syscalls even not stripped later, ignore it currently
if [[ ! "$XARCH" =~ "riscv" ]]; then
  # A new section group has been added to nolibc to record the used system calls, the name and value have been encoded to the section name
  PGC=$BIN.p
  syscalls_used=$(cat $PGC | grep .rodata.syscall | sed -e "s/ '.rodata.syscall.\([^ ]*\)' /\n\1\n/g" | grep __NR_ | cut -d '.' -f2 | bc -l)

  # Get out the syscalls stripped
  syscalls_stripped=$(cat $PGC | grep .text.*sys_ | sed -e "s/ '.text.sys_\([^ ]*\)' /\n\1\n/g")
fi

# Dump out used system calls with objdump
# FIXME: this may not work well for the syscall number may be far from the system call instruction while optimization enabled
for num in $($OBJDUMP -d $BIN | egrep "$load_ins|$scall_ins" | egrep -B$bak_pos "$scall_ins" | egrep "$load_ins" | rev | cut -d ' ' -f1 | rev | cut -d ',' -f$num_pos | sort -u -g | tr -d '$')
do
  # echo $(($num))
  syscalls_used="$syscalls_used $(($num))"
done

# Remove duplicated
syscalls_used=$(echo $syscalls_used | tr ' ' '\n' | sort -u -g)

if [[ ! "$XARCH" =~ "riscv" ]]; then
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

else

  syscall_map=$(mktemp)

  cat << __EOF__ | $GCC $INC -xc - -E | grep -v '^#' | tr '\n' ' ' | sed -e 's/, */\n/g' | tr -d ' ' > $syscall_map
#define __SYSCALL(nr, call)    syscall[\$((nr))] = #call,
#include <asm/unistd.h>
__EOF__

  . $syscall_map

fi

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

# Exit
exit 0
