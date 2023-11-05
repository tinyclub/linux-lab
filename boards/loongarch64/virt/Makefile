# Copyright (C) 2023 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := loongarch
XARCH   := loongarch64
CPU     ?= la464-loongarch-cpu
MEM     ?= 1024M
SERIAL  ?= ttyS0,115200

QEMU    ?= v8.0.2

NETDEV_LIST ?= e1000 e1000e ne2k_pci rtl8139
NETDEV  ?= e1000

LINUX   ?= v6.5.4

HOST_GCC := 9

# no buildroot support for loongarch currently, use nolibc initrd by default
NOLIBC  := $(or $(NOLIBC),0)

ROOTDEV_LIST := /dev/ram0 /dev/nfs
ROOTDEV      ?= /dev/ram0

BUILDROOT    ?= 2023.08.2
ROOTFS       ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
FSTYPE       ?= ext2
HROOTFS      ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# download from https://github.com/loongson/Firmware/tree/main/LoongArchVirtMachine
BIOS    ?= $(BSP_BIOS)/edk2/edk2-loongarch64-code.fd

ORIIMG  ?= arch/$(ARCH)/boot/vmlinux.efi
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux.efi

QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

CCORI   ?= mirrors.edge.kernel.org
