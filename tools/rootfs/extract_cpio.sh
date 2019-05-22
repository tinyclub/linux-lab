#!/bin/bash
#
# extract_cpio.sh -- extract rootfs.cpio.gz to rootfs directly
#

[ -z "$ROOTDIR" ] && ROOTDIR=$1
[ -z "$ROOTDIR" ] && echo "Usage: $0 /path/to/rootdir" && exit 1

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")

FS_CPIO_GZ=${ROOTDIR}.cpio.gz

mkdir -p ${ROOTDIR}

pushd ${ROOTDIR}

gzip -cdkf ${FS_CPIO_GZ} | sudo cpio -idmv -R ${USER}:${USER} >/dev/null 2>&1

chown ${USER}:${USER} -R ${ROOTDIR}

popd
