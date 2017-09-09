#!/bin/bash
#
# env.sh -- edit uboot environment for prebuilt uboot images
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

  dd if=$ENV_IMG of=$PFLASH_IMG bs=1M seek=$((PFLASH_SIZE-1)) conv=notrunc status=none
fi
