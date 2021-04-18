#!/bin/bash
#
# rd2hd.sh initrd hrootfs fstype -- convert initrd to harddisk image
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#
# initrd should be xxx.cpio.gz or xxx.cpio
#

[ -z "$INITRD" ] && INITRD=$1
[ -z "$HROOTFS" ] && HROOTFS=$1
[ -z "$FSTYPE" ] && FSTYPE=$2

[ -z "${INITRD}" -o -z "${HROOTFS}" ] && echo "Usage: $0 initrd hrootfs fstype" && exit 1

[ -z "${FSTYPE}" ] && FSTYPE=ext2

[ -z "${USER}" ] && USER=$(whoami)

ROOTDIR=$(echo ${HROOTFS} | sed -e "s%.${FSTYPE}.*%%g")

FS_CPIO_GZ=${ROOTDIR}.cpio.gz
FS_CPIO=${ROOTDIR}.cpio

# Calculate the size
if [ -f ${FS_CPIO_GZ} ]; then
  ROOTFS_SIZE=`ls -s ${FS_CPIO_GZ} | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 10))
else
  ROOTFS_SIZE=`ls -s ${FS_CPIO} | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 4))
fi

ROOTFS_SIZE=$(( (${ROOTFS_SIZE} / 1024 + 1) * 1024 ))
echo "LOG: Rootfs size: $ROOTFS_SIZE (kilo bytes)"

# Create the file system image
truncate -s $((ROOTFS_SIZE * 1024)) ${HROOTFS}
yes | mkfs.${FSTYPE} ${HROOTFS}

# Copy content to the fs image
mkdir -p ${ROOTDIR}.tmp
sudo mount ${HROOTFS} ${ROOTDIR}.tmp
pushd ${ROOTDIR}.tmp

if [ -f ${FS_CPIO_GZ} ]; then
   gzip -cdkf ${FS_CPIO_GZ} | sudo cpio --quiet -idmv -R ${USER}:${USER} >/dev/null 2>&1
elif [ -f ${FS_CPIO} ]; then
   sudo cpio --quiet -idmv -R ${USER}:${USER} < ${FS_CPIO} >/dev/null 2>&1
fi

sudo chown ${USER}:${USER} -R ./

#sync
popd
sudo umount ${ROOTDIR}.tmp
rm -rf ${ROOTDIR}.tmp
