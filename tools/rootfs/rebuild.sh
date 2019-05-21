#!/bin/bash
#
# rebuild.sh -- rebuild rootfs.cpio.gz from rootfs directly
#

[ -z "$ROOTDIR" ] && ROOTDIR=$1
[ -z "$ROOTDIR" ] && echo "Usage: $0 /path/to/rootdir" && exit 1

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")
FS_CPIO_GZ=${ROOTDIR}.cpio.gz

cd $ROOTDIR/ && find . \
	| sudo cpio -R $USER:$USER -H newc -o \
	| gzip -9 > ${FS_CPIO_GZ}
