#!/bin/bash
#
# config.sh -- configure uboot for kernel boot on specific boards
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#
# Example: ./config.sh 127.168.1.3 127.168.1.1 /dev/ram - 0x7fc0 - - include/configs/versatile.h

_CONFIG_DIR=$1
_CONFIG_FILE=$2
CONFIG_FILE=$1/$2

KERNEL_IMG=uImage
RAMDISK_IMG=ramdisk
DTB_IMG=dtb

# Core configuration

## boot from tftp
TFTP_KERNEL="tftpboot $KRN_ADDR $KERNEL_IMG;"
[ "$RDK_ADDR" != "-" ] && TFTP_RAMDISK="tftpboot $RDK_ADDR $RAMDISK_IMG;"
[ "$DTB_ADDR" != "-" ] && TFTP_DTB="tftpboot $DTB_ADDR $DTB_IMG;"

IPADDR="set ipaddr $IP;"
SERVERIP="set serverip $ROUTE;"
BOOTARGS="set bootargs '"$(echo -n "$CMDLINE" | sed 's%"%\\\\"%g')"';"
TFTPS="$TFTP_KERNEL $TFTP_RAMDISK $TFTP_DTB"
[ "$DTB_ADDR" == "-" ] && DTB_ADDR=""
BOOTM="bootm $KRN_ADDR $RDK_ADDR $DTB_ADDR"

BOOT_TFTP="$IPADDR $SERVERIP $BOOTARGS $TFTPS $BOOTM"

## boot from sdcard/mmc
FATLOAD_KERNEL="fatload mmc 0:0 $KRN_ADDR $KERNEL_IMG;"
[ "$RDK_ADDR" != "-" ] && FATLOAD_RAMDISK="fatload mmc 0:0 $RDK_ADDR $RAMDISK_IMG;"
[ "$DTB_ADDR" != "-" ] && FATLOAD_DTB="fatload mmc 0:0 $DTB_ADDR $DTB_IMG;"
FATLOADS="$FATLOAD_KERNEL $FATLOAD_RAMDISK $FATLOAD_DTB"

BOOT_SDCARD="$BOOTARGS $FATLOADS $BOOTM"

## boot from pflash, for the image offset, see tools/uboot/images.sh
function _size16b() { size=$1; echo -n 0x$(echo "obase=16;$size" | bc); }
function _size16b_m() { size=$1; echo $(_size16b $((size*1024*1024))); }

_KRN_SIZE=$(_size16b_m $KRN_SIZE)
_RDK_SIZE=$(_size16b_m $RDK_SIZE)
_DTB_SIZE=$(_size16b_m $DTB_SIZE)

KERNEL_BASE=$PFLASH_BASE
RAMDISK_BASE=$(_size16b $((PFLASH_BASE + _KRN_SIZE)))
DTB_BASE=$(_size16b $((PFLASH_BASE + _KRN_SIZE + _RDK_SIZE)))

PFLOAD_KERNEL="cp $KERNEL_BASE $KRN_ADDR $_KRN_SIZE;"
[ "$RDK_ADDR" != "-" ] && PFLOAD_RAMDISK="cp $RAMDISK_BASE $RDK_ADDR $_RDK_SIZE;"
[ "$DTB_ADDR" != "-" ] && PFLOAD_DTB="cp $DTB_BASE $DTB_ADDR $_DTB_SIZE;"
PFLOADS="$PFLOAD_KERNEL $PFLOAD_RAMDISK $PFLOAD_DTB"

BOOT_PFLASH="$BOOTARGS $PFLOADS $BOOTM"

## Use tftp by default
BOOT_CMD=$U_BOOT_CMD

# build env image or customize config file?

## build env image
if [ -z "$_CONFIG_FILE" ]; then

    case $BOOT_CMD in
      bootcmd3) boot_cmd=$BOOT_PFLASH
	;;
      bootcmd2) boot_cmd=$BOOT_SDCARD
	;;
      *) boot_cmd=$BOOT_TFTP
	;;
    esac

    dd if=/dev/zero of=$ENV_IMG bs=1M count=1 status=none
    echo -e -n "bootcmdx=${boot_cmd}\0" > $ENV_IMG 
    ##hexdump -C $ENV_IMG

    exit 0
fi

## customize config file

# Others
CONFIG_SYS_CBSIZE=1024
CONFIG_INITRD_TAG=1
CONFIG_OF_LIBFDT=1
# aligh with 1M for env partition, for saveenv command
FLASH_MAX_SECTOR_SIZE=0x00100000
CONFIG_EXTRA_ENV_SETTINGS="\"bootcmd1=$BOOT_TFTP\\\\0bootcmd2=$BOOT_SDCARD\\\\0bootcmd3=$BOOT_PFLASH\\\\0bootcmdx=run $BOOT_CMD\\\\0\""

ENV_OFFSET=$(_size16b_m $((PFLASH_SIZE-1)))
ENV_ADDR=$(_size16b $((PFLASH_BASE + ENV_OFFSET)))
CONFIG_BOOTCOMMAND="\"env import $ENV_ADDR $CONFIG_SYS_CBSIZE; run bootcmdx\""

# More
EXTRA_CONFIGS=`env | grep ^CONFIG | cut -d'=' -f1`

echo $CONFIG_BOOTCOMMAND

# Build the config lines

CONFIGS="CONFIG_EXTRA_ENV_SETTINGS FLASH_MAX_SECTOR_SIZE CONFIG_BOOTCOMMAND CONFIG_SYS_CBSIZE CONFIG_INITRD_TAG CONFIG_OF_LIBFDT $EXTRA_CONFIGS"

# Reset changes
pushd $_CONFIG_DIR
git checkout -- $_CONFIG_FILE
popd

# Update the new one
# Insert the new configs in the end of the external #if .. #endif condition
sed -i -e "/LINUX LAB INSERT START/,/LINUX LAB INSERT END/d" $CONFIG_FILE

line=`grep -n "#endif" $CONFIG_FILE | tail -1 | cut -d':' -f1`

sed -i -e "${line}i/* LINUX LAB INSERT END */" $CONFIG_FILE

for config in $CONFIGS
do
    value=`eval echo \\$${config}`

    grep -q "^#define $config" $CONFIG_FILE
    if [ $? -eq 0 ]; then
        sed -i -e "s%^#define $config[^\\]*\([\\]*\)$%#define $config\t${value}\1%g" $CONFIG_FILE
    else
        sed -i -e "${line}i#define ${config}\t${value}" $CONFIG_FILE
    fi
    grep "^#define $config" $CONFIG_FILE
done

sed -i -e "${line}i/* LINUX LAB INSERT START */" $CONFIG_FILE

sed -i -e "${line}i#endif" $CONFIG_FILE
sed -i -e "${line}i#undef CONFIG_BOOTCOMMAND" $CONFIG_FILE
sed -i -e "${line}i#ifdef CONFIG_BOOTCOMMAND" $CONFIG_FILE
