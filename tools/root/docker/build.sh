#!/bin/bash
#
# build.sh -- build docker image from rootfs
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

TOP_DIR=$(cd $(dirname $0)/../../../ && pwd)
PREBUILT_FULLROOT=$TOP_DIR/prebuilt/fullroot

image_name=$1
root_dir=$2

build_dir=$PREBUILT_FULLROOT/build/
root_dir=$(basename $root_dir)
root_tmpdir=$PREBUILT_FULLROOT/tmp/$root_dir

[ -z "$image_name" -o -z "$root_dir" ] && echo "Usage: $0 image_name root_dir" && exit 1

echo "LOG: Copy $root_tmpdir to $build_dir"
sudo cp -r $root_tmpdir $build_dir/

echo "LOG: building $image_name"
sudo docker build --build-arg ROOTDIR=$root_dir -t $image_name --no-cache $build_dir

echo "LOG: Remove $root_dir from $build_dir"
sudo rm -rf $build_dir/$root_dir
