#!/bin/bash

KERNEL_OUTPUT=$1
MODULE_PATH=$2

if [ -z "$MODULE_PATH" ]; then
  [ -d $KERNEL_OUTPUT ] && MODULE_DIRS="`find $KERNEL_OUTPUT -name "*.ko" | xargs -i dirname {}`"
else
  MODULE_DIRS=$MODULE_PATH
fi

for p in $MODULE_DIRS
do
  echo "Cleaning $p ..."
  cd $p
  rm -rf *.o .*.o.d *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers dio *.tmp *.log
done
