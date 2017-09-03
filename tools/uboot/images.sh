#!/bin/bash
#
# images.sh -- prepare images for uboot
#

ROOT_IMAGE=${U_ROOT_IMAGE}
DTB_IMAGE=${U_DTB_IMAGE}
KERNEL_IMAGE=${U_KERNEL_IMAGE}
IMAGES_DIR=${TFTPBOOT}
UBOOT_IMAGE=${BIMAGE}

# Boot images from tftpboot
##
## CONFIG_BOOTCOMMAND
##
## set ipaddr 10.66.33.104;
## set serverip 10.66.33.3;
## set bootargs 'route=10.66.33.3 console=tty0 console=ttyAMA0 root=/dev/mmcblk0';
## tftpboot 0x60003000 uImage; tftpboot 0x60500000 dtb; bootm 0x60003000 - 0x60500000
##
[ -n "$ROOT_IMAGE" -a "$ROOT_IMAGE" != "-" ] && cp $ROOT_IMAGE $IMAGES_DIR/ramdisk
[ -n "$DTB_IMAGE" -a "$DTB_IMAGE" != "-" ] && cp $DTB_IMAGE $IMAGES_DIR/dtb
[ -n "$KERNEL_IMAGE" -a "$KERNEL_IMAGE" != "-" ] && cp $KERNEL_IMAGE $IMAGES_DIR/uImage

## Get bootcommand
if [ "${BOOTDEV}" == "pflash" -o "${BOOTDEV}" == "flash" ]; then
  BOOT_CMD="bootcmd3"
elif [ "${BOOTDEV}" == "sdcard" -o "${BOOTDEV}" == "sd" -o "${BOOTDEV}" == "mmc" ]; then
  BOOT_CMD="bootcmd2"
else
  BOOT_CMD="bootcmd1"
fi

if [ -f "$UBOOT_IMAGE" ]; then
  ## Fix up tftp server ip
  sed -i -e "s/route=[0-9.]* /route=$ROUTE /g" -ur $UBOOT_IMAGE
  sed -i -e "s/serverip [0-9.]*;/serverip $ROUTE;/g" -ur $UBOOT_IMAGE
  ## Fix up boot command
  sed -i -e "s/run bootcmd[0-9]*;/run $BOOT_CMD;/g" -ur $UBOOT_IMAGE
fi

# Boot images from sdcard
##
## fatload mmc 0:0 0x60003000 uImage
## fatload mmc 0:0 0x60500000 dtb
## fatload mmc 0:0 0x60600000 ramdisk
##
if [ "${BOOTDEV}" == "sdcard" -o "${BOOTDEV}" == "sd" -o "${BOOTDEV}" == "mmc" ]; then
  SD_DIR=${SD_IMG%.*}
  [ ! -f $SD_IMG ] && dd if=/dev/zero of=$SD_IMG bs=1M count=$((KRN_SIZE+RDK_SIZE+DTB_SIZE+2))
  [ -f $SD_IMG ] && mkfs.fat $SD_IMG
  [ ! -d $SD_DIR ] && mkdir -p $SD_DIR
  sudo mount $SD_IMG $SD_DIR
  [ -n "$ROOT_IMAGE" -a "$ROOT_IMAGE" != "-" ] && sudo cp $ROOT_IMAGE $SD_DIR/ramdisk
  [ -n "$DTB_IMAGE" -a "$DTB_IMAGE" != "-" ] && sudo cp $DTB_IMAGE $SD_DIR/dtb
  [ -n "$KERNEL_IMAGE" -a "$KERNEL_IMAGE" != "-" ] && sudo cp $KERNEL_IMAGE $SD_DIR/uImage
  sudo umount $SD_DIR
  sync
fi

# Boot images from pflash
##
## cp 0x40000000 0x60003000 0x500000;
## cp 0x40500000 0x60900000 0x400000;
## cp 0x40900000 0x60500000 0x100000;
##

if [ "${BOOTDEV}" == "pflash" -o "${BOOTDEV}" == "flash" ]; then
  dd if=/dev/zero of=$PFLASH_IMG bs=1M count=$PFLASH_SIZE
  [ -n "$KERNEL_IMAGE" -a "$KERNEL_IMAGE" != "-" ] && dd if=$KERNEL_IMAGE of=$PFLASH_IMG conv=notrunc bs=1M
  [ -n "$ROOT_IMAGE" -a "$ROOT_IMAGE" != "-" ] && dd if=$ROOT_IMAGE of=$PFLASH_IMG conv=notrunc seek=$KRN_SIZE bs=1M
  [ -n "$DTB_IMAGE" -a "$DTB_IMAGE" != "-" ] && dd if=$DTB_IMAGE of=$PFLASH_IMG conv=notrunc seek=$((KRN_SIZE+RDK_SIZE)) bs=1M
  sync
fi
