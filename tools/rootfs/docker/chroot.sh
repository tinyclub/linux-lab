#!/bin/bash -e
#
# chroot rootfs from docker image
#
# examples:
#
# $ tools/rootfs/docker/chroot.sh arm64v8/ubuntu /bin/bash
# $ tools/rootfs/docker/chroot.sh arm32v7/ubuntu /bin/bash
#

TOP_DIR=$(cd $(dirname $0)/../../../ && pwd)
PREBUILT_FULLROOT=$TOP_DIR/prebuilt/fullroot

image=$1
entry=$2
tmpdir=$(echo $image | tr '/' '-' | tr ':' '-')
rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir
[ -z "$entry" ] && entry=/bin/bash

[ -z "$image" ] && echo "Usage: $0 image [entrypoint]" && exit 1

echo "LOG: Chroot into $rootdir"
sudo chroot $rootdir $entry
