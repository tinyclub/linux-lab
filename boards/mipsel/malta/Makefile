# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = mips
XARCH    = mipsel
# Not sure, use the default one
CPU     ?=
LINUX   ?= v5.1

# FIXME: need to work with mipsel gcc 9
GCC[LINUX_v2.6.36] = 4.3

BUILDROOT?= 2016.05
MEM     ?= 128M
NETDEV_LIST := pcnet
NETDEV  ?= pcnet
SERIAL  ?= ttyS0
FSTYPE  ?= ext2
ORIIMG  ?= vmlinuz
ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# prebuilt toolchain, please download it if not internal via: make toolchain
# Available CCORI: internal, bootlin, mips

CCORI   ?= internal
