#!/bin/bash
#
# pflash.sh -- prepare uboot images for pflash boot
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
  dd if=/dev/zero of=$PFLASH_IMG status=none bs=128K count=$((PFLASH_SIZE*8))
  [ -n "$KERNEL_IMAGE" ] && dd if=$KERNEL_IMAGE of=$PFLASH_IMG status=none conv=notrunc bs=128K
  [ -n "$ROOT_IMAGE" ] && dd if=$ROOT_IMAGE of=$PFLASH_IMG status=none conv=notrunc seek=$((KRN_SIZE*8)) bs=128K
  [ -n "$DTB_IMAGE" ] && dd if=$DTB_IMAGE of=$PFLASH_IMG status=none conv=notrunc seek=$(((KRN_SIZE+RDK_SIZE)*8)) bs=128K
  sync
fi
