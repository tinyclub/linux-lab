# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = mips
XARCH    = mipsel
CPU     ?= LS232_1
BUILDROOT?= 2016.05
MEM     ?= 256M
SERIAL  ?= ttyS0

# Based on v2.6.32, from https://gitee.com/loongsonlab/linux-2.6.32.git
LINUX   ?= v2.6.32-r190726

KERNEL_GIT := https://gitee.com/loongsonlab/linux-2.6.32.git
KERNEL_SRC := loongsonlab-linux-2.6.32

ORIIMG  ?= vmlinux
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux

NETDEV_LIST  ?= synopgmac
NETDEV  ?= synopgmac

ROOTDEV_LIST := /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0

FSTYPE  ?= ext2
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# From https://gitee.com/loongsonlab/qemu
QEMU_GIT:= https://gitee.com/loongsonlab/qemu
QEMU_SRC:= loongsonlab-qemu
QEMU    ?= loongson-v1.0
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

XOPTS   ?=

# loongnix toolchain is downloaded from http://www.loongnix.org/index.php/GCC
# NOTE: internal gcc not work with this board, require loongnix gcc
CCORI   ?= loongnix
