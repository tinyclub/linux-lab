# Copyright (C) 2023 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := powerpc
XARCH   := ppc64le
MEM     ?= 256M

# Qemu 7.0 was released with a replacement for SLOF called VOF, enable it
MACH_OPT ?= x-vof=on

LINUX   ?= v6.4

# no buildroot support for arm/virt currently, use nolibc initrd by default
NOLIBC  := $(or $(NOLIBC),1)

SERIAL  ?= hvc0

ROOTDEV_LIST := /dev/ram0
ROOTDEV ?= /dev/ram0

ORIIMG  ?= arch/$(ARCH)/boot/zImage
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/zImage

CCORI   ?= internal
