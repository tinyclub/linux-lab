#!/bin/bash
#
# env.sh -- edit uboot environment for prebuilt uboot images
#

ROOT_IMAGE=${U_ROOT_IMAGE}
DTB_IMAGE=${U_DTB_IMAGE}
KERNEL_IMAGE=${U_KERNEL_IMAGE}
IMAGES_DIR=${TFTPBOOT}
UBOOT_IMAGE=${BIMAGE}

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
