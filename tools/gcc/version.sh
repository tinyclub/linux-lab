#!/bin/bash
#
# version.sh -- get the real gcc version used currently
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

ccpath=$1
ccpre=$2

# Get current gcc version
ccver=$(/usr/bin/env PATH=$ccpath:$PATH ${ccpre}gcc --version | sed -ne '1{s/^.*) //pg}')

for i in $ccver ${ccver%.*} ${ccver%%.*}
do
	PATH=$ccpath:$PATH type ${ccpre}gcc-$i >/dev/null 2>&1
	[ $? -eq 0 ] && ccver=$i && break
done

echo $ccver
