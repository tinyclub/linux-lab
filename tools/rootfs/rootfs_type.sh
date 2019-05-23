#!/bin/bash
#
# rootfs_type.sh -- get root type of a specified rootfs variable
#
# It is able to be: rootfs directory, rootfs initrd (cpio.gz, cpio), rootfs harddisk image (.img, .ext2, .ext4 ...)
#

ROOTFS=$1

[ -z "$ROOTFS" ] && echo "Usage: $0 rootfs" && exit 1

# Strip ending "/" if exists
ROOTFS=$(echo ${ROOTFS} | sed -e "s%/$%%g")

# Check the other formats
if [ -f ${ROOTFS} ]; then
  echo ${ROOTFS} | grep -q "\.cpio.gz$" && echo "rd,${ROOTFS},.cpio.gz" && exit 0
  echo ${ROOTFS} | grep -q "\.cpio.uboot$" && echo "rd,${ROOTFS},.cpio.uboot" && exit 0
  echo ${ROOTFS} | grep -q "\.cpio$" && echo "rd,${ROOTFS},.cpio" && exit 0

  fstype=`file $(readlink -f ${ROOTFS}) | sed -e "s%.*\(\.ext2\|\.ext4\|\.ext3\|\.f2fs\|\.cramfs\|\.img\).*%\1%g"`
  echo "hd,${ROOTFS},$fstype"
elif [ -d ${ROOTFS} -a -d ${ROOTFS}/bin -a ${ROOTFS}/etc ]; then
# Check rootfs directory at first
  echo "dir,${ROOTFS}"
  exit 0
elif [ -d ${ROOTFS}/rootfs -a -d ${ROOTFS}/rootfs/bin -a ${ROOTFS}/rootfs/etc ]; then
  echo "dir,${ROOTFS}/rootfs"
  exit 0
else
  echo "ERR: $0: ${ROOTFS}: not invalid or not exists"
  exit 1
fi
