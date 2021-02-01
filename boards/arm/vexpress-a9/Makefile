# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= cortex-a9
MEM     ?= 128M
QEMU    ?= v4.1.1
# compile qemu-user with QEMU_US=1, by default only compile qemu-system-$(XARCH)
# after enabling QEMU_US=1, qemu-system-$(XARCH) will not be compiled
QEMU_US ?= 0
UBOOT   ?= v2020.04
LINUX   ?= v5.1

# Uboot breaks 9pnet sharing, disable uboot if 9pnet share used
UBOOT[SHARE_1] := disabled

# Upgrade to v4.7, supported by old and new docker images
GCC[LINUX_v3.18.39] = 4.7
GCC[LINUX_v3.16.80] = 4.7
GCC[LINUX_v4.0.9] = 4.7
GCC[LINUX_v4.12] = 4.7
GCC[OS_focal] = 9

# Uboot v2020.04 requires gcc >= 6.0, not supported by old docker image
CCORI[UBOOT_v2020.04,OS_trusty] = linaro
CCORI[UBOOT_v2020.04,OS_focal]  = internal

BUILDROOT?= 2016.05
KRN_ADDR?= 0x60003000
KRN_SIZE?= 5
RDK_ADDR?= 0x60900000
RDK_SIZE?= 4
DTB_ADDR?= 0x60500000
DTB_SIZE?= 1
UCONFIG ?= vexpress_common.h
BOOTDEV_LIST := tftp sdcard sd mmc flash pflash
BOOTDEV ?= flash
# 64M pflash0@0x40000000, 64M pflash1@0x44000000
PFLASH_BASE ?= 0x40000000
PFLASH_SIZE ?= 64
PFLASH_BS   ?= 512
# Environment Offset, see CONFIG_ENV_OFFSET in $UCONFIG
ENV_OFFSET  ?= 63
# see CONFIG_ENV_ADDR in defconfig
# ENV_ADDR   ?= 0x47F80000

# 9pnet based network filesystem sharing, vexpress-a9 not support virtio-9p-pci, so, the virtio-9p-pci based -virtfs not work
NET9PDEV ?= virtio-9p-device

NETDEV_LIST := lan9118
NETDEV  ?= lan9118
SERIAL  ?= ttyAMA0

ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0 /dev/nfs

ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/zImage
UORIIMG ?= arch/$(ARCH)/boot/uImage
ORIDTB  ?= arch/$(ARCH)/boot/dts/vexpress-v2p-ca9.dtb
BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/zImage
DTB     ?= $(BSP_KERNEL)/$(LINUX)/vexpress-v2p-ca9.dtb
UKIMAGE ?= $(BSP_KERNEL)/$(LINUX)/uImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
UROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.uboot
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)
#QP      ?= 1
QTOOL[OS_trusty]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

# prebuilt toolchain, please download it if not internal via: make toolchain
# Available CCORI: internal, bootlin, arm
# Notes: Uboot compiled with Linaro toolchain can not boot, simply hang there.
CCORI   ?= internal
