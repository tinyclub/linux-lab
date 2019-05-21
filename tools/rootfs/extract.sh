#!/bin/bash
#
# extract.sh -- extract rootfs.cpio.gz to rootfs directly
#

[ -z "$ROOTDIR" ] && ROOTDIR=$1
[ -z "$ROOTDIR" ] && echo "Usage: $0 /path/to/rootdir" && exit 1

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")

FS_CPIO_GZ=${ROOTDIR}.cpio.gz
FS_CPIO=${ROOTDIR}.cpio

mkdir -p ${ROOTDIR}

pushd ${ROOTDIR}

gunzip -kf ${FS_CPIO_GZ}
sudo cpio -idmv -R ${USER}:${USER} < ${FS_CPIO} >/dev/null 2>&1
chown ${USER}:${USER} -R ${ROOTDIR}

popd
