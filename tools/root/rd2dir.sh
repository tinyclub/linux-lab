#!/bin/bash
#
# rd2dir.sh -- extract rootfs.cpio.gz to rootfs directory
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

[ -z "$INITRD" ] && INITRD=$1
[ -z "$ROOTDIR" ] && ROOTDIR=$2
[ -z "$INITRD" -o -z "$ROOTDIR" ] && echo "Usage: $0 initrd rootdir" && exit 1

_ROOTDIR=$(echo ${INITRD} | sed -e "s%.cpio.gz%%g" | sed -e "s%.cpio%%g")

FS_CPIO_GZ=${_ROOTDIR}.cpio.gz
CPIO_GZ=${_ROOTDIR}.cpio

mkdir -p ${ROOTDIR}
pushd ${ROOTDIR}

if [ -f ${FS_CPIO_GZ} ]; then
   gzip -cdkf ${FS_CPIO_GZ} | sudo cpio --quiet -idmv -R ${USER}:${USER} >/dev/null
elif [ -f ${FS_CPIO} ]; then
   sudo cpio --quiet -idmv -R ${USER}:${USER} < ${FS_CPIO} >/dev/null
fi

sudo chown ${USER}:${USER} -R ${ROOTDIR}
popd
