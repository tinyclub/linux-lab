#!/bin/bash -e
#
# run rootfs from docker image
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
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
qemu_user_static=/usr/bin/qemu-${arch}-static
qemu_user_target=/usr/bin/qemu-${arch}
qemumap="-v $qemu_user_static:$qemu_user_static"
qemumap="$qemumap -v $qemu_user_static:$qemu_user_target"

# Enable sharing /linux-lab by default, to extrat container, please disable with SHARE=0
[ -z "$SHARE" ] && SHARE=0
[ $SHARE -eq 1 ] && sharemap="-v $TOP_DIR:/linux-lab"

mapping=" $qemumap $sharemap "

[ -z "$image" -o -z "$arch" ] && echo "Usage: $0 image arch" && exit 1

which $qemu_user_static 2>&1 > /dev/null || (echo "LOG: Install qemu-user-static at first" && exit 1)

[ -z "$PULL" ] && PULL=0
if [ $PULL -eq 1 ]; then
    echo "LOG: Pulling $image"
    docker pull $image
fi

echo "LOG: Running $image"
docker run -it $mapping $image
