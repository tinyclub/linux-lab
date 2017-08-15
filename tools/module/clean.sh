#!/bin/bash

KERNEL_OUTPUT=$1
MODULE_PATH=$2

if [ -z "$MODULE_PATH" ]; then
  MODULE_DIRS="`find $KERNEL_OUTPUT -name "*.ko" | xargs -i dirname {}`"
else
  MODULE_DIRS=$MODULE_PATH
fi

for p in $MODULE_DIRS
do
  cd $p
  rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers dio *.tmp *.log
done
