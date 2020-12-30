# Copyright (C) 2020 Wu Zhangjin <falcon@tinylab.org>
# _BASE: 1, virt; 2, real; 3: virt+real
_BASE    = 2
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= cortex-a9
MEM     ?= 512M
QEMU    ?= v4.1.1
## compile qemu-user with QEMU_US=1, by default only compile qemu-system-$(XARCH)
## after enabling QEMU_US=1, qemu-system-$(XARCH) will not be compiled
QEMU_US ?= 0
LINUX   ?= v4.19.35

BUILDROOT?= 2020.02

# Verified netdev options
NETDEV_LIST  ?= smc91c111 lan9118
NETDEV  ?= smc91c111

SERIAL  ?= ttymxc0

ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0 /dev/nfs

ROOTDEV ?= /dev/mmcblk0
FSTYPE  ?= ext4
ORIIMG  ?= arch/$(ARCH)/boot/zImage
DIMAGE  ?= imx6ull-nand-npi.dtb
ORIDTB  ?= arch/$(ARCH)/boot/dts/$(DIMAGE)
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/zImage
DTB     ?= $(BSP_KERNEL)/$(LINUX)/$(DIMAGE)
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
UROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.uboot
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)
QTOOL[OS_trusty]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

#
## prebuilt toolchain, please download it if not internal via: make toolchain
## Available CCORI: internal, bootlin, arm
## Notes: Uboot compiled with Linaro toolchain can not boot, simply hang there.
CCORI   ?= internal
#
