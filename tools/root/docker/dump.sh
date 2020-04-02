#!/bin/bash -e
#
# dump rootfs from running docker container
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#
# examples:
#
# $ tools/rootfs/docker/dump.sh container
#

TOP_DIR=$(cd $(dirname $0)/../../../ && pwd)
PREBUILT_FULLROOT=$TOP_DIR/prebuilt/fullroot

container=$1
sharedir=/linux-lab

[ -z "$container" ] && echo "Usage: $0 container_id" && exit 1

tmpdir=$(docker ps -q --filter=id=$container --format='{{.Image}}-{{.ID}}')
[ -z "$tmpdir" ] && exit "Usage: $0 container_id" && exit 1

tmpdir=$(echo $tmpdir | tr '/' '-' | tr ':' '-')
rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir

echo "LOG: Creating temporary rootdir: $rootdir"
mkdir -p $rootdir


# TODO: Check with docker inspect ?
# docker inspect 5067 -f "{{.HostConfig.Binds}}" | tr ' ' '\n' | grep -v /usr/bin
# ...
echo "LOG: Checking if $sharedir is mounted"
docker exec $container /bin/bash -c '[ ! -d '$sharedir' ]' \
    || (echo "LOG: $sharedir mounted, give up dumping..." && exit 1)

echo "LOG: Dump docker container to $rootdir"
sudo docker cp $container:/ $rootdir/

echo "LOG: Chroot into new rootfs"
sudo chroot $rootdir /bin/bash -c 'uname -a; cat /etc/issue; exit'
