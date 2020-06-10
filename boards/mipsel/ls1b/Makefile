# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
_BASE    = 1
ARCH     = mips
XARCH    = mipsel
CPU     ?= mips32r2
LINUX   ?= v5.2
BUILDROOT?= 2016.05
MEM     ?= 128M
NETDEV_LIST ?= synopgmac
NETDEV  ?= synopgmac
SERIAL  ?= ttyS0

ORIIMG  ?= vmlinuz
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz

ROOTDEV_LIST ?= /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# From https://gitee.com/loongsonlab/qemu
QEMU_GIT:= https://gitee.com/loongsonlab/qemu
QEMU_SRC:= loongsonlab
QEMU    ?= loongson-v1.0
QTOOL[OS_trusty]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)
QTOOL[OS_focal]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

CCORI   ?= internal
