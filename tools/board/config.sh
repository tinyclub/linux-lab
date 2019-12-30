#!/bin/bash

VS=$1
Makefile=$2

V=$(echo $1 | cut -d'=' -f1)
_V=$(echo $V | sed -e "s/\[/\\\[/g;s/\]/\\\]/g")
S=$(echo $1 | cut -d'=' -f2-)

grep -v "^#" $Makefile | grep -q "$_V"
if [ $? -eq 0 ]; then
  sed -i -e "s%^\($_V[^\[]*=[ ]*\).*%\1$S%g" $Makefile
else
  echo "$V ?= $S" >> $Makefile
fi
