# Copyright (C) 2023 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := powerpc
XARCH   := ppc
# Not sure, use the default setting
CPU     ?=
LINUX   ?= v6.3.6

# no buildroot support for arm/virt currently, use nolibc initrd by default
NOLIBC  := $(or $(NOLIBC),1)

MEM     ?= 128M
SERIAL  ?= ttyS0

ORIIMG  ?= vmlinux
ROOTDEV_LIST := /dev/ram0
ROOTDEV ?= /dev/ram0

#BIOS    ?= $(BSP_QEMU)/v4.0.0/share/qemu/openbios-ppc
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux

CCORI   ?= internal
