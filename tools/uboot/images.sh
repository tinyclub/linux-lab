#!/bin/bash
#
# images.sh -- prepare images for uboot
#

ROOT_IMAGE=$1
DTB_IMAGE=$2
KERNEL_IMAGE=$3
IMAGES_DIR=$4

[ -n "$ROOT_IMAGE" -a "$ROOT_IMAGE" != "-" ] && cp $ROOT_IMAGE $IMAGES_DIR/ramdisk
[ -n "$DTB_IMAGE" -a "$DTB_IMAGE" != "-" ] && cp $DTB_IMAGE $IMAGES_DIR/dtb
[ -n "$KERNEL_IMAGE" -a "$KERNEL_IMAGE" != "-" ] && cp $KERNEL_IMAGE $IMAGES_DIR/uImage
