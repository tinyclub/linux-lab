#!/bin/bash
#
# pflash.sh -- prepare uboot images for pflash boot
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

ROOT_IMAGE=${U_ROOT_IMAGE}
DTB_IMAGE=${U_DTB_IMAGE}
KERNEL_IMAGE=${U_KERNEL_IMAGE}
IMAGES_DIR=${TFTPBOOT}

# Boot images from pflash
##
## cp 0x40000000 0x60003000 0x500000;
## cp 0x40500000 0x60900000 0x400000;
## cp 0x40900000 0x60500000 0x100000;
##

if [ "${BOOTDEV}" == "pflash" -o "${BOOTDEV}" == "flash" ]; then
  [ -f $PFLASH_IMG ] && rm -rf $PFLASH_IMG

  dd if=/dev/zero of=$PFLASH_IMG status=none bs=${PFLASH_BS}K count=$((PFLASH_SIZE * 1024 / PFLASH_BS))

  [ -n "$KERNEL_IMAGE" -a -f "$KERNEL_IMAGE" ] && dd if=$KERNEL_IMAGE of=$PFLASH_IMG status=none conv=notrunc bs=${PFLASH_BS}K
  [ -n "$ROOT_IMAGE" -a -f "$ROOT_IMAGE" ] && dd if=$ROOT_IMAGE of=$PFLASH_IMG status=none conv=notrunc seek=$((KRN_SIZE * 1024 / PFLASH_BS)) bs=${PFLASH_BS}K
  [ -n "$DTB_IMAGE" -a -f "$DTB_IMAGE" ] && dd if=$DTB_IMAGE of=$PFLASH_IMG status=none conv=notrunc seek=$(((KRN_SIZE+RDK_SIZE) * 1024 / PFLASH_BS)) bs=${PFLASH_BS}K

  #sync
  exit 0
fi
