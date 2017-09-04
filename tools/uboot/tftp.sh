#!/bin/bash
#
# tftp.sh -- prepare uboot images for tftp boot
#

ROOT_IMAGE=${U_ROOT_IMAGE}
DTB_IMAGE=${U_DTB_IMAGE}
KERNEL_IMAGE=${U_KERNEL_IMAGE}
IMAGES_DIR=${TFTPBOOT}

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
