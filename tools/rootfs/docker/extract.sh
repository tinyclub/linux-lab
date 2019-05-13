#!/bin/bash -e
#
# extract rootfs from docker image
#
# examples:
#
# $ tools/rootfs/docker/extract.sh arm64v8/ubuntu aarch64
# $ tools/rootfs/docker/extract.sh arm32v7/ubuntu arm
#

TOP_DIR=$(cd $(dirname $0)/../../../ && pwd)
PREBUILT_FULLROOT=$TOP_DIR/prebuilt/fullroot

image=$1
arch=$2
tmpdir=$(echo $image | tr '/' '-' | tr ':' '-')
rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir
qemu_user_static=/usr/bin/qemu-$arch-static

[ -z "$image" -o -z "$arch" ] && echo "Usage: $0 image arch" && exit 1

which $qemu_user_static 2>&1 > /dev/null || (echo "LOG: Install qemu-user-static at first" && exit 1)

[ -z "$PULL" ] && PULL=1
if [ $PULL -eq 1 ]; then
    echo "LOG: Pulling $image"
    docker pull $image
fi

echo "LOG: Running $image"
id=$(docker run -d -v $qemu_user_static:$qemu_user_static $image)

echo "LOG: Creating temporary rootdir: $rootdir"
mkdir -p $rootdir

echo "LOG: Extract docker image to $rootdir"
sudo docker cp $id:/ $rootdir/

echo "LOG: Removing docker container"
docker rm -f $id

#echo "LOG: Removing docker image"
#docker image rm -f $image

echo "LOG: Chroot into new rootfs"
sudo chroot $rootdir /bin/bash -c 'uname -a; cat /etc/issue; exit'
