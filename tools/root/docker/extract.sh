#!/bin/bash -e
#
# extract rootfs from docker image
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#
# examples:
#
# $ tools/root/docker/extract.sh arm64v8/ubuntu aarch64
# $ tools/root/docker/extract.sh arm32v7/ubuntu arm
# $ tools/root/docker/extract.sh yangzewei2023/debian:loongarch64 loongarch64 loong64
#

TOP_DIR=$(cd $(dirname $0)/../../../ && pwd)
PREBUILT_FULLROOT=$TOP_DIR/prebuilt/fullroot

image=$1
# qemu arch
arch=$2
# platform arch to qemu
parch=$3

[ -z "$arch" ] && arch=`dirname $image | tr -d '.'`
[ -z "$parch" ] && parch=$arch

tmpdir=$(echo $image | tr '/' '-' | tr ':' '-')
rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir
qemu_user_static=/usr/bin/qemu-${arch}-static
user=`whoami`

[ -z "$image" -o -z "$arch" ] && echo "Usage: $0 image arch" && exit 1

which $qemu_user_static 2>&1 > /dev/null || (echo "LOG: Install qemu-user-static at first" && exit 1)

[ -z "$PULL" ] && PULL=1
if [ $PULL -eq 1 ]; then
    echo "LOG: Pulling $image"
    docker pull $image
fi

qemu_user_static=/usr/bin/qemu-${arch}-static
qemu_user_target=/usr/bin/qemu-${arch}
qemumap="-v $qemu_user_static:$qemu_user_static"
qemumap="$qemumap -v $qemu_user_static:$qemu_user_target"

mapping=" $qemumap "

echo "LOG: Running $image"
id=$(docker run -d --platform linux/$parch $mapping $image)

echo "LOG: Creating temporary rootdir: $rootdir"
mkdir -p $rootdir

echo "LOG: Extract docker image to $rootdir"
sudo docker cp $id:/ $rootdir/
sudo chown $user:$user -R $rootdir/

echo "LOG: Removing docker container"
docker rm -f $id

#echo "LOG: Removing docker image"
#docker image rm -f $image

echo "LOG: Chroot into new rootfs"
sudo chroot $rootdir /bin/sh -c 'uname -a; [ -f /etc/issue ] && cat /etc/issue; exit'
