#!/bin/bash
#
# version.sh -- get the real gcc version used currently
#

ccpre=$1
ccpath=$2
ccver=$(/usr/bin/env PATH=$ccpath:$PATH ${ccpre}gcc --version | head -1 | sed -e 's% ([^)]*)%%g' | cut -d ' ' -f2)

for i in $ccver ${ccver%.*} ${ccver%%.*}
do
	/usr/bin/env PATH=$ccpath:$PATH which ${ccpre}gcc-$i >/dev/null 2>&1
	[ $? -eq 0 ] && ccver=$i && break
done

echo $ccver
