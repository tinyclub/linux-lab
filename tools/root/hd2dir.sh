#!/bin/bash
#
# hd2dir.sh hrootfs rootdir -- harddisk fs image to directory, not mount
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

[ -z "$HROOTFS" ] && HROOTFS=$1
[ -z "$ROOTDIR" ] && ROOTDIR=$2

[ -z "${HROOTFS}" -o "${ROOTDIR}" ] && echo "Usage: $0 rootfs rootdir" && exit 1

[ -z "${USER}" ] && USER=$(whoami)

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")

[ ! -f ${HROOTFS} ] && echo "Usage: ${HROOTFS} not exists" && exit 1

[ -d ${ROOTDIR} ] && rm -rf ${ROOTDIR}

mkdir -p ${ROOTDIR}.tmp
sudo mount ${HROOTFS} ${ROOTDIR}.tmp

cp -ar ${ROOTDIR}.tmp ${ROOTDIR}

sudo chown ${USER}:${USER} -R ./
#sync
sudo umount ${ROOTDIR}.tmp
