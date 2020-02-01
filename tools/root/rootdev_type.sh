#!/bin/bash
#
# rootdev_type.sh -- get root type of a specified rootfs variable
#
# It is able to be: rootfs directory, rootfs initrd (cpio.gz, cpio), rootfs harddisk image (.img, .ext2, .ext4 ...)
#

ROOTDEV=$1

[ -z "$ROOTDEV" ] && echo "Usage: $0 rootdev" && exit 1

case $ROOTDEV in
    /dev/null)
       echo "rd,cpio.gz|cpio|dir"
       ;;
    /dev/ram*)
       echo "rd,cpio.gz|cpio"
       ;;
    /dev/*da|/dev/mmc*)
       echo "hd,.img|.ext*|.vfat|.f2fs|.cramfs|.uboot"
       ;;
    /dev/nfs)
       echo "dir,dir"
       ;;
    *)
       echo "ERR: $0: $ROOTDEV: not support yet." && exit 1
       ;;
esac
