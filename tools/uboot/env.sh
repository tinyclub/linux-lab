#!/bin/bash
#
# env.sh -- edit uboot environment for prebuilt uboot images
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

ROOT_IMAGE=${U_ROOT_IMAGE}
DTB_IMAGE=${U_DTB_IMAGE}
KERNEL_IMAGE=${U_KERNEL_IMAGE}
BOOT_CMD=${U_BOOT_CMD}
IMAGES_DIR=${TFTPBOOT}
UBOOT_IMAGE=${BIMAGE}

# Save env to the last 1M of pflash
if [ -n "$ENV_IMG" ]; then
  [ ! -f $PFLASH_IMG ] && dd if=/dev/zero of=$PFLASH_IMG status=none bs=${PFLASH_BS}K count=$((PFLASH_SIZE * 1024 / PFLASH_BS))

  dd if=$ENV_IMG of=$PFLASH_IMG bs=1M seek=$ENV_OFFSET conv=notrunc status=none
fi
