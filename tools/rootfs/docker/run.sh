#!/bin/bash -e
#
# run rootfs from docker image
#
# examples:
#
# $ tools/rootfs/docker/run.sh arm64v8/ubuntu aarch64
# $ tools/rootfs/docker/run.sh arm32v7/ubuntu arm
#

TOP_DIR=$(cd $(dirname $0)/../../../ && pwd)
PREBUILT_FULLROOT=$TOP_DIR/prebuilt/fullroot

image=$1
arch=$2
tmpdir=$(echo $image | tr '/' '-' | tr ':' '-')
rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir
qemu_user_static=/usr/bin/qemu-$arch-static
entry=/bin/bash

[ -z "$image" -o -z "$arch" ] && echo "Usage: $0 image arch" && exit 1

which $qemu_user_static 2>&1 > /dev/null
[ $? -ne 0 ] && echo "LOG: Install qemu-user-static at first" && exit 1

echo "LOG: Pulling $image"
docker pull $image

echo "LOG: Running $image"
docker run -it -v $qemu_user_static:$qemu_user_static $image $entry
