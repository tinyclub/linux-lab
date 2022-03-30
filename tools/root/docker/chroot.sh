#!/bin/bash -e
#
# chroot rootfs from docker image
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
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

if [ -d "$image" ]; then
    tmpdir=$(basename $image)
    rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir
else
    tmpdir=$(echo $image | tr '/' '-' | tr ':' '-')
    rootdir=$PREBUILT_FULLROOT/tmp/$tmpdir
fi

[ -z "$entry" ] && entry=/bin/bash

[ -z "$image" ] && echo "Usage: $0 image|rootdir [entrypoint]" && exit 1

# Build the entry running environment
entry_tmp=`mktemp`
entry_file=/usr/bin/`basename $entry_tmp`.entry.sh
mv $entry_tmp $rootdir/$entry_file

cat <<EOF > $rootdir/$entry_file
#!/bin/bash
mount -t sysfs none /sys
mount -t proc proc /proc
mount -t devtmpfs none /dev
mount -t tmpfs none /tmp

$entry

umount /tmp
umount /dev
umount /proc
umount /sys
rm $entry_file
EOF

chmod a+x $rootdir/$entry_file
entry=$entry_file

echo "LOG: Chroot into $rootdir"
sudo chroot $rootdir $entry
