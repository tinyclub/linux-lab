# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := mips
XARCH   := mips64el
CPU     ?= Loongson-3A1000
BUILDROOT?= 2020.08
MEM     ?= 1024M
SERIAL  ?= ttyS0

QEMU    ?= v6.2.0

NETDEV_LIST ?= e1000
NETDEV  ?= e1000

LINUX   ?= v5.18

HOST_GCC := 9

ORIIMG  ?= vmlinuz
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz

ORIDTB  ?= arch/$(ARCH)/boot/dts/loongson/loongson64c_4core_ls7a.dtb

ROOTDEV_LIST ?= /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

XOPTS   ?= -device usb-mouse -device usb-kbd

CCORI   ?= internal
