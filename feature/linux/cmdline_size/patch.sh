#!/bin/bash
#
# patch.sh -- increase COMMAND_LINE_SIZE to big enough: 4096?
#

ARCH=$1
KERNEL_SRC=$2

[ -z "$CL_SIZE" ] && CL_SIZE=4096

for d in $KERNEL_SRC/arch/$ARCH/include $KERNEL_SRC/include/asm-$ARCH $KERNEL_SRC/include/asm-generic
do
  if [ -d $d ]; then
    find $d -name "setup.h" | xargs -i sed -i -e "s%#define[ \t]*COMMAND_LINE_SIZE[ \t]*[0-9]*%#define COMMAND_LINE_SIZE $CL_SIZE%g" {} 
  fi
done
