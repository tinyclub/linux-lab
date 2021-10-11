# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = mips
XARCH    = mips64el
CPU     ?= loongson2k
BUILDROOT?= 2016.05
MEM     ?= 1024M
SERIAL  ?= ttyS0

NETDEV_LIST  ?= synopgmac rtl8139 e1000
NETDEV  ?= synopgmac

# Based on v3.10, from http://cgit.loongnix.org/cgit
LINUX   ?= loongnix-release-1903
LINUX[LINUX_loongnix-release-1903] := 04b98684

KERNEL_GIT := http://cgit.loongnix.org/cgit/linux-3.10
KERNEL_SRC := loongnix-linux-3.10

ORIIMG  ?= vmlinuz
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
DTS     ?= $(KERNEL_SRC)/arch/$(ARCH)/loongson2/dts/2k1000_board.dts
DTB     ?= $(BSP_KERNEL)/$(LINUX)/2k1000_board.dtb

ROOTDEV_LIST := /dev/sda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# From https://gitee.com/loongsonlab/qemu
QEMU_GIT:= https://gitee.com/loongsonlab/qemu
QEMU_SRC:= loongsonlab-qemu
QEMU    ?= loongson-v1.0
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

XOPTS   ?= -device usb-mouse -device usb-kbd -show-cursor

# SMP not supported, without maxcpus=1, kernel boot hang after Booting CPU#1 ...
XKCLI   += maxcpus=1

CCORI   ?= internal
