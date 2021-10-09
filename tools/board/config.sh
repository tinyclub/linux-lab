#!/bin/bash
#
# config.sh -- configure board variables
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>

VS=$1
Makefile=$2
LINUX=$3

V=$(echo $1 | cut -d'=' -f1)
_V=$(echo $V | sed -e "s/\[/\\\[/g;s/\]/\\\]/g")
S=$(echo $1 | cut -d'=' -f2-)

# Ignore BOARD setting
for v in BOARD board b B
do
  [ "x$V" == "x$v" ] && exit 0
done

GCC_Makefile=${Makefile}.gcc
ROOT_Makefile=${Makefile}.root
NETD_Makefile=${Makefile}.net
LINUX_Makefile=${Makefile}.linux_${LINUX}

# Makefile.linux_vX.Y.Z > Makefile.gcc > Makefile

# echo "LOG: Config Variable: ($V, $_V)"
# echo "LOG: Config Value: $S"

m=${Makefile}
if [ "$V" != "LINUX" -a -f ${LINUX_Makefile} ]; then
  m=${LINUX_Makefile}
else
  for x in GCC ROOT NET
  do
    echo "$V" | grep -q "^$x"
    if [ $? -eq 0 ]; then
      _m=$(eval echo \${${x}_Makefile})
      [ -f $_m ] && m=$_m && break
    fi
  done
fi

#echo "LOG: Save to:" $m
touch $m

[ "$V" == "$_V" ] && _V="$V[\t ?:=]"

grep -v "^#" $m | grep -q "$_V"
if [ $? -eq 0 ]; then
  if [ -n "$S" ]; then
    echo "$m: $V := $S"
    sed -i -e "s%^\($_V[\t:? ]*=[ ]*\).*%\1$S%g" $m
  else
    echo "$m: Clear $V"
    sed -i -e "/^\($_V[\t:? ]*=[ ]*\).*/d" $m
  fi
else
  if [ -n "$S" ]; then
    echo "$m: $V := $S"
    echo "$V := $S" >> $m
  fi
fi
