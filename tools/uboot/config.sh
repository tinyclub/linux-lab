#!/bin/bash
#
# config.sh -- configure uboot for kernel boot on specific boards
#
# Example: ./config.sh 127.168.1.3 127.168.1.1 /dev/ram - 0x7fc0 - - include/configs/versatile.h

IP=$1
ROUTE=$2
ROOTDEV=$3
ROOTDIR=$4

KERNEL_ADDR=$5
RAMDISK_ADDR=$6
DTB_ADDR=$7

CONFIG_FILE=$8

KERNEL_IMG=uImage
RAMDISK_IMG=ramdisk
DTB_IMG=dtb

TFTP_KERNEL="tftpboot $KERNEL_ADDR $KERNEL_IMG;"
[ "$RAMDISK_ADDR" != "-" ] && TFTP_RAMDISK="tftpboot $RAMDISK_ADDR $RAMDISK_IMG;"
[ "$DTB_ADDR" != "-" ] && TFTP_DTB="tftpboot $DTB_ADDR $DTB_IMG;"

# Core configuration

IPADDR="set ipaddr $IP;"
SERVERIP="set serverip $ROUTE;"
if [ ${ROOTDEV} == "/dev/nfs" ]; then
    BOOTARGS="set bootargs 'route=$ROUTE console=tty0 console=ttyAMA0 root=$ROOTDEV nfsroot=$ROUTE:$ROOTDIR ip=$IP';"
else
    BOOTARGS="set bootargs 'route=$ROUTE console=tty0 console=ttyAMA0 root=$ROOTDEV';"
fi
TFTPS="$TFTP_KERNEL $TFTP_RAMDISK $TFTP_DTB"
[ "$DTB_ADDR" == "-" ] && DTB_ADDR=""
BOOTM="bootm $KERNEL_ADDR $RAMDISK_ADDR $DTB_ADDR"

CONFIG_BOOTCOMMAND="\"$IPADDR $SERVERIP $BOOTARGS $TFTPS $BOOTM\""

# Others
CONFIG_SYS_CBSIZE=1024
CONFIG_INITRD_TAG=1
CONFIG_OF_LIBFDT=1

# More
EXTRA_CONFIGS=`env | grep ^CONFIG | cut -d'=' -f1`

echo $CONFIG_BOOTCOMMAND

# Build the config lines

CONFIGS="CONFIG_BOOTCOMMAND CONFIG_SYS_CBSIZE CONFIG_INITRD_TAG CONFIG_OF_LIBFDT $EXTRA_CONFIGS"

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
        sed -i -e "s%^#define $config.*$%#define $config\t${value}%g" $CONFIG_FILE
    else
        sed -i -e "${line}i#define ${config}\t${value}" $CONFIG_FILE
    fi
    grep "^#define $config" $CONFIG_FILE
done

sed -i -e "${line}i/* LINUX LAB INSERT START */" $CONFIG_FILE
