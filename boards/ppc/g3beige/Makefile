# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = powerpc
XARCH    = ppc
# Not sure, use the default setting
CPU     ?=
# Note: <2.6.37 kernel don't have __NR_socket implementation
LINUX   ?= v5.1
BUILDROOT?= 2016.05
MEM     ?= 128M
NETDEV_LIST := pcnet ne2k_pci rtl8139
NETDEV  ?= pcnet
SERIAL  ?= ttyS0
ORIIMG  ?= vmlinux
ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
BIOS    ?= $(BSP_QEMU)/v4.0.0/share/qemu/openbios-ppc
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.ext2

# prebuilt toolchain, please download it if not internal via: make toolchain
# Available CCORI: internal, bootlin
CCORI   ?= internal
