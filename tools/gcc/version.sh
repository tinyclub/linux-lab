#!/bin/bash
#
# version.sh -- get the real gcc version used currently
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

ccver=$1
ccpath=$2
ccpre=$3

# Get current gcc version
_ccver=$(/usr/bin/env PATH=$ccpath:$PATH ${ccpre}gcc --version | sed -ne '1{s/^.*) //pg}')

for i in $_ccver ${_ccver%.*} ${_ccver%%.*}
do
	PATH=$ccpath:$PATH type ${ccpre}gcc-$i >/dev/null 2>&1
	[ $? -eq 0 ] && _ccver=$i && break
done

if [ -n "$ccver" ]; then
  if [ -n "$_ccver" -a "$ccver" != "$_ccver" ]; then
    if [ ! -f $ccpath/${ccpre}gcc-$ccver ]; then
      ccver=$_ccver
    fi
  fi
else
  ccver=$_ccver
fi

echo $ccver
