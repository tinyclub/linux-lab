#!/bin/bash
#
# images.sh -- prepare images for uboot
#

ROOT_IMAGE=$1
DTB_IMAGE=$2
KERNEL_IMAGE=$3
IMAGES_DIR=$4
UBOOT_IMAGE=$5
ROUTE_IP=$6
BOOTDEV=$7

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
if [ "${BOOTDEV}" == "sdcard" ]; then
  BOOT_CMD="bootcmd2"
else
  BOOT_CMD="bootcmd1"
fi

if [ -f "$UBOOT_IMAGE" ]; then
  ## Fix up tftp server ip
  sed -i -e "s/route=[0-9.]* /route=$ROUTE_IP /g" -ur $UBOOT_IMAGE
  sed -i -e "s/serverip [0-9.]*;/serverip $ROUTE_IP;/g" -ur $UBOOT_IMAGE
  ## Fix up boot command
  sed -i -e "s/run bootcmd[0-9]*;/run $BOOT_CMD;/g" -ur $UBOOT_IMAGE
fi

# Boot images from sdcard
##
## fatload mmc 0:0 0x60003000 uImage
## fatload mmc 0:0 0x60500000 dtb
## fatload mmc 0:0 0x60600000 ramdisk
##

SD_IMG=$IMAGES_DIR/sd.img
SD_DIR=$IMAGES_DIR/sd/
[ ! -f $SD_IMG ] && dd if=/dev/zero of=$SD_IMG bs=1024 count=$((10*1024))
[ -f $SD_IMG ] && mkfs.fat $SD_IMG
[ ! -d $SD_DIR ] && mkdir -p $SD_DIR
sudo mount $SD_IMG $SD_DIR
[ -n "$ROOT_IMAGE" -a "$ROOT_IMAGE" != "-" ] && sudo cp $ROOT_IMAGE $SD_DIR/ramdisk
[ -n "$DTB_IMAGE" -a "$DTB_IMAGE" != "-" ] && sudo cp $DTB_IMAGE $SD_DIR/dtb
[ -n "$KERNEL_IMAGE" -a "$KERNEL_IMAGE" != "-" ] && sudo cp $KERNEL_IMAGE $SD_DIR/uImage
sudo umount $SD_DIR
sync
