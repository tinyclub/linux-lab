# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = mips
XARCH    = mipsel
CPU     ?= mips32r2
MEM     ?= 128M

BUILDROOT?= 2016.05

# FIXME: network works with v5.2, but not work with >= v5.4 kernels
LINUX   ?= v5.2

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
QEMU_SRC:= loongsonlab-qemu
QEMU    ?= loongson-v1.0
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

CCORI   ?= internal
