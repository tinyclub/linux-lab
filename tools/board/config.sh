#!/bin/bash

VS=$1
Makefile=$2

V=$(echo $1 | cut -d'=' -f1)
S=$(echo $1 | cut -d'=' -f2-)

grep -v "^#" $Makefile | grep -q $V
if [ $? -eq 0 ]; then
  sed -i -e "s%^\($V.*=[ ]*\).*%\1$S%g" $Makefile
else
  echo "$V ?= $S" >> $Makefile
fi
