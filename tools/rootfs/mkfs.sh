#!/bin/bash
#
# mkfs.sh rootdir fstype
#

ROOTDIR=$1
FSTYPE=$2

[ -z "${FSTYPE}" ] && FSTYPE=ext2

[ -z "${USER}" ] && USER=$(whoami)

ROOTFS=${ROOTDIR}/../rootfs.${FSTYPE}

if [ -f ${ROOTDIR}/../rootfs.cpio.gz ]; then
  ROOTFS_SIZE=`ls -s ${ROOTDIR}/../rootfs.cpio.gz | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 5))
else
  ROOTFS_SIZE=`ls -s ${ROOTDIR}/../rootfs.cpio | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 2))
fi

echo $ROOTFS_SIZE

dd if=/dev/zero of=${ROOTFS} bs=1024 count=$ROOTFS_SIZE
yes | mkfs.${FSTYPE} ${ROOTFS}

mkdir -p ${ROOTDIR}

sudo mount ${ROOTFS} ${ROOTDIR}

pushd ${ROOTDIR}
[ -f ../rootfs.cpio.gz ] && gunzip -kf ../rootfs.cpio.gz
sudo cpio --quiet -idmv -R ${USER}:${USER} < ../rootfs.cpio 2>&1 >/dev/null
chown ${USER}:${USER} -R ./
sync
popd

sudo umount ${ROOTDIR}
