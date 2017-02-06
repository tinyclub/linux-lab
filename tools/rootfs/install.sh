#!/bin/bash
#
# install.sh -- install extra packages to the rootfs target
#

TOP_DIR=$(cd $(dirname $0) && pwd)/../../

# The rootdir
ROOTDIR=$1
FILEMAP=$2

while read local target
do
	mkdir -p $ROOTDIR/$target

	echo "Copying $TOP_DIR/$local to $ROOTDIR/$target"

	cp -r $TOP_DIR/$local $ROOTDIR/$target

	chown $USER:$USER -R $ROOTDIR/$target

done < $FILEMAP
