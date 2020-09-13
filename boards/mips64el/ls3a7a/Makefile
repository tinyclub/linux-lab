# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
_BASE    = 1
ARCH     = mips
XARCH    = mips64el
CPU     ?= mips64r2
BUILDROOT?= 2020.08
MEM     ?= 1024M
SERIAL  ?= ttyS0

# e1000 not work for interrupt issue
NETDEV_LIST ?= synopgmac rtl8139
NETDEV  ?= synopgmac

# Based on v3.10, from http://cgit.loongnix.org/cgit
LINUX   ?= loongnix-release-1903
LINUX[LINUX_loongnix-release-1903] := 04b98684

# Mainline v5.7 boots but network not work currently, let's wait for v5.8
# LINUX   ?= v5.7

HOST_GCC := 9

KERNEL_GIT[LINUX_loongnix-release-1903] := http://cgit.loongnix.org/cgit/linux-3.10
KERNEL_SRC[LINUX_loongnix-release-1903] := loongnix-linux-3.10

ORIIMG  ?= vmlinuz
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
DTS[LINUX_loongnix-release-1903] ?= $(KERNEL_SRC)/arch/$(ARCH)/loongson/loongson-3/dts/loongson3_ls7a.dts
DTB[LINUX_loongnix-release-1903] ?= $(BSP_KERNEL)/$(LINUX)/loongson3_ls7a.dtb

ROOTDEV_LIST ?= /dev/sda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# From https://gitee.com/loongsonlab/qemu
QEMU_GIT:= https://gitee.com/loongsonlab/qemu
QEMU_SRC:= loongsonlab-qemu
QEMU[OS_trusty]    ?= loongson-v1.0
QEMU[OS_focal]     ?= loongson-v1.1-rc1
QTOOL   ?= $(BSP_QEMU)/$(call __v,QEMU,OS)/bin/qemu-system-$(XARCH)

XOPTS   ?= -device usb-mouse -device usb-kbd -show-cursor

# FIXME: workaround -initrd (/dev/ram0) loading
XENVS   ?= INITRD_OFFSET=0x04000000

# SMP not supported, without maxcpus=1, kernel boot hang after Booting CPU#1 ...
XKCLI   += maxcpus=1 nomsi nmsix

CCORI   ?= internal
