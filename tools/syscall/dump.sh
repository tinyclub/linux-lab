#!/bin/bash
#
# dump.sh -- dump system call used
#

BIN=$1
XARCH=$2
KSRC=$3
CCPRE=$4

OBJDUMP=${CCPRE}objdump
GCC=${CCPRE}gcc

# Arch support, based on tools/include/nolibc/arch-<ARCH>.h
case $XARCH in
  riscv*)
    load_inc="li[[:space:]]*a7"
    scall_inc="ecall"
    num_pos=2
    scall_table="arch/riscv/kernel/syscall_table.c"
    compat_scall_table="arch/riscv/kernel/compat_syscall_table.c"
    ;;
  x86_64)
    load_inc="%rax|%eax"
    scall_inc="syscall"
    num_pos=1
    scall_table="arch/x86/entry/syscall_64.c"
    ;;
  *)
    echo "ERR: not supported"
    exit 1
    ;;
esac

scall_ni="kernel/sys_ni.c"

# Parse used system call numbers
syscalls_used=""
for num in $($OBJDUMP -d $BIN | egrep "$load_inc|$scall_inc" | egrep -B1 "$scall_inc" | egrep "$load_inc" | rev | cut -d ' ' -f1 | rev | cut -d ',' -f$num_pos | tr -d '$')
do
  # echo $(($num))
  syscalls_used="$syscalls_used $(($num))"
done

# Generate new syscall table
syscall_map=$(mktemp)
compat_syscall_map=$(mktemp)

if [[ "$XARCH" =~ "riscv" ]]; then
  cat << __EOF__ | $GCC -xc - -E | grep -v '^#' | tr '\n' ' ' | sed -e 's/, */\n/g' | tr -d ' ' > $syscall_map
#define __SYSCALL(nr, call)	syscall[\$((nr))] = #call,
#include <asm/unistd.h>
__EOF__

  cat << __EOF__ | $GCC -xc - -E | grep -v '^#' | tr '\n' ' ' | sed -e 's/, */\n/g' | tr -d ' ' > $compat_syscall_map
#define __SYSCALL_COMPAT
#define __SYSCALL(nr, call)	syscall[\$((nr))] = #call,
#include <asm/unistd.h>
__EOF__

else
  # Only test for x86
  cat << __EOF__ | $GCC -xc - -E -dM | grep "#define __NR_" | sed -e 's/#define *__NR_\(.*\) \(.*\)/syscall[$((\2))]="\1"/g;s/__NR_//g' > $syscall_map
#include <asm/unistd.h>
__EOF__

  # TODO: add compat specific map
  compat_syscall_map=$syscall_map
fi

# Update the system call table file
for table in $scall_table $compat_scall_table
do
 sed -i -e "/LINUX LAB INSERT START/,/LINUX LAB INSERT END/d" $KSRC/$table
 if [ "$table" = "$scall_table" ]; then
   . $syscall_map
 else
   . $compat_syscall_map
 fi

 case $XARCH in
  riscv*)
    sed -i -e '/unistd.h>/i// LINUX LAB INSERT START' $KSRC/$table
    sed -i -e '/unistd.h>/{s%^// *%%g;s%^%// %g}' $KSRC/$table

    for s in $syscalls_used
    do
      sed -i -e '/unistd.h>/i\\t'[$s]' = '${syscall[$s]}',' $KSRC/$table
    done

    sed -i -e '/unistd.h>/i// LINUX LAB INSERT END' $KSRC/$table

    ;;
  x86_64)
    ;;
  *)
    echo "ERR: not supported"
    exit 1
    ;;
 esac
done

# Update kernel/sys_ni.c? not necessary
update_scall_ni=0

if [ $update_scall_ni -eq 1 ]; then
 sed -i -e "/LINUX LAB INSERT START/,/LINUX LAB INSERT END/d" $KSRC/$scall_ni
 echo "// LINUX LAB INSERT START" >> $KSRC/$scall_ni

 for f in ${syscall[*]}
 do
  matched=0
  [ "x$f" = "xsys_ni_syscall" ] && continue

  _f=$(echo $f | sed -e 's/^sys_//g')
  for s in $syscalls_used
  do
    if [ ${syscall[$s]} = "$f" ]; then
      matched=1
    fi
  done
  if [ $matched -eq 0 ]; then
    echo "COND_SYSCALL($_f);" >> $KSRC/$scall_ni
    echo "COND_SYSCALL_COMPAT($_f);" >> $KSRC/$scall_ni
  fi
 done

 echo "// LINUX LAB INSERT END" >> $KSRC/$scall_ni
fi
