# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = mips
XARCH    = mipsel
# Not sure, use the default one
CPU     ?=
LINUX   ?= v5.13

# NOTE: need to update docker image to get 4.3 gcc
GCC[LINUX_v2.6.36] = 4.3
GCC     ?= 9

BUILDROOT?= 2021.08.2
MEM     ?= 128M
NETDEV_LIST := pcnet
NETDEV  ?= pcnet
SERIAL  ?= ttyS0
FSTYPE  ?= ext2
ORIIMG  ?= vmlinuz
ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0

# FIXME: v2.6.36 built with 4.3 in latest ubuntu 20.4 get 'bootmem alloc of 1048576 bytes failed!' error with ram0 boot
ROOTDEV_LIST[LINUX_v2.6.36] = /dev/hda /dev/nfs
ROOTDEV[LINUX_v2.6.36] = /dev/hda

KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# prebuilt toolchain, please download it if not internal via: make toolchain
# Available CCORI: internal, bootlin, mips

CCORI   ?= internal
