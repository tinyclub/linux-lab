# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := x86
XARCH   := x86_64

# qemu-system-x86_64 -M pc -cpu ?
CPU     ?= qemu64
MEM     ?= 128M
SMP     ?= 4
LINUX   ?= v5.13

# git repos for other kernel fork
KERNEL_GIT[KERNEL_FORK_openeuler] := https://gitee.com/openeuler/kernel.git
LINUX[KERNEL_FORK_openeuler]   ?= 5.10.0-5.10.0

KERNEL_GIT[KERNEL_FORK_wsl2] := https://gitee.com/mirrors/WSL2-Linux-Kernel.git
LINUX[KERNEL_FORK_wsl2]   ?= $(call _latest,wsl2,$(KERNEL_GIT[KERNEL_FORK_wsl2]),linux-msft-wsl-5.10.74.3)

GCC[LINUX_$(call _any,LINUX,<=,v5.1.1023)] := 4.8

# Disable RETPOLINE for Linux <= v4.18, enabled by gcc=9 by default, but conflicts with fcf-protector
# Boot2docker use v4.19, but require retpoline support
CFGS[K_N][GCC_9,LINUX_$(call _any,LINUX,<=,v5.1.1023)] := RETPOLINE

# Force change ARCH for kernel version <= 2.6.23
# $(eval $(call _vsif,ARCH,$(XARCH),LINUX,<=,v2.6.23))
ARCH[LINUX_$(call _any,LINUX,<=,v2.6.23)] := $(XARCH)
$(eval $(call __vs,ARCH,LINUX))

BUILDROOT?= 2019.02.2

# Check qemu support:
# $ qemu-system-i386 -net nic,model=?
#   qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
#
NETDEV_LIST := ne2k_pci e1000 rtl8139 pcnet
NETDEV  ?= ne2k_pci
SERIAL  ?= ttyS0
ORIIMG  ?= arch/$(ARCH)/boot/bzImage

ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
ROOTDEV_LIST[LINUX_v3.2] := /dev/sda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0

KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/bzImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
ROOTFS[LINUX_v2.6.12.6]  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs32.cpio.gz
# Workaround boot issue
XKCLI   := lpj=246205838 raid=noautodetect
