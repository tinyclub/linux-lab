# Copyright (C) 2023 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := arm
XARCH   := $(ARCH)
MEM     ?= 128M

LINUX   ?= v6.3

# no buildroot support for arm/virt currently, use nolibc initrd by default
NOLIBC  := $(or $(NOLIBC),1)

SERIAL  ?= ttyAMA0

ROOTDEV_LIST := /dev/ram0
ROOTDEV ?= /dev/ram0

ORIIMG  ?= arch/$(ARCH)/boot/zImage
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/zImage

CCORI   ?= internal
