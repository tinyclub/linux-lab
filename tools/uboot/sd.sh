#!/bin/bash
#
# sd.sh -- prepare uboot images for sd/mmc boot
#

ROOT_IMAGE=${U_ROOT_IMAGE}
DTB_IMAGE=${U_DTB_IMAGE}
KERNEL_IMAGE=${U_KERNEL_IMAGE}
IMAGES_DIR=${TFTPBOOT}
UBOOT_IMAGE=${BIMAGE}

# Boot images from sd/mmc
##
## fatload mmc 0:0 0x60003000 uImage
## fatload mmc 0:0 0x60500000 dtb
## fatload mmc 0:0 0x60600000 ramdisk
##
if [ "${BOOTDEV}" == "sdcard" -o "${BOOTDEV}" == "sd" -o "${BOOTDEV}" == "mmc" ]; then
  SD_DIR=${SD_IMG%.*}
  [ -f $SD_IMG ] && rm $SD_IMG
  [ ! -f $SD_IMG ] && dd if=/dev/zero of=$SD_IMG status=none bs=1M count=$((KRN_SIZE+RDK_SIZE+DTB_SIZE+2))
  [ -f $SD_IMG ] && mkfs.fat $SD_IMG
  [ ! -d $SD_DIR ] && mkdir -p $SD_DIR
  sudo mount $SD_IMG $SD_DIR
  [ -n "$ROOT_IMAGE" ] && sudo cp $ROOT_IMAGE $SD_DIR/ramdisk
  [ -n "$DTB_IMAGE" ] && sudo cp $DTB_IMAGE $SD_DIR/dtb
  [ -n "$KERNEL_IMAGE" ] && sudo cp $KERNEL_IMAGE $SD_DIR/uImage
  sudo umount $SD_DIR
  sync
fi
