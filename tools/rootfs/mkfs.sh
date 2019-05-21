#!/bin/bash
#
# mkfs.sh rootdir fstype
#

ROOTDIR=$1
FSTYPE=$2

[ -z "${ROOTDIR}" ] && echo "Usage: $0 rootdir fstype" && exit 1

[ -z "${FSTYPE}" ] && FSTYPE=ext2

[ -z "${USER}" ] && USER=$(whoami)

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")

ROOTFS=${ROOTDIR}.${FSTYPE}
FS_CPIO_GZ=${ROOTDIR}.cpio.gz
FS_CPIO=${ROOTDIR}.cpio

# Convert to cpio.gz from directory
if [ -d ${ROOTDIR} -a -d ${ROOTDIR}/bin -a -d ${ROOTDIR}/etc ]; then
  # sync with directory content ??
  [ ! -f ${FS_CPIO_GZ} ] && rm ${FS_CPIO_GZ}
  cd ${ROOTDIR} && find . | sudo cpio -R $USER:$USER -H newc -o | gzip -9 > ${FS_CPIO_GZ}
fi

# Calculate the size
if [ -f ${FS_CPIO_GZ} ]; then
  ROOTFS_SIZE=`ls -s ${FS_CPIO_GZ} | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 5))
else
  ROOTFS_SIZE=`ls -s ${FS_CPIO} | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 2))
fi

ROOTFS_SIZE=$(( (${ROOTFS_SIZE} / 1024 + 1) * 1024 ))
echo $ROOTFS_SIZE

# Create the file system image
dd if=/dev/zero of=${ROOTFS} bs=1024 count=$ROOTFS_SIZE
yes | mkfs.${FSTYPE} ${ROOTFS}

mkdir -p ${ROOTDIR}.tmp

sudo mount ${ROOTFS} ${ROOTDIR}.tmp

pushd ${ROOTDIR}.tmp
[ -f ${FS_CPIO_GZ} ] && gunzip -kf ${FS_CPIO_GZ}
sudo cpio --quiet -idmv -R ${USER}:${USER} < ${FS_CPIO} >/dev/null 2>&1
sudo chown ${USER}:${USER} -R ./
sync
popd

sudo umount ${ROOTDIR}.tmp
