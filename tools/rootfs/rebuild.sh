#!/bin/bash
#
# rebuild.sh -- rebuild the rootfs
#

cd $ROOTDIR/ && find . \
	| sudo cpio -R $USER:$USER -H newc -o \
	| gzip -9 > ../rootfs.cpio.gz
