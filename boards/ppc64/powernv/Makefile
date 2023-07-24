# Copyright (C) 2023 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := powerpc
XARCH   := ppc64
MEM     ?= 1024M

LINUX   ?= v6.4

# no buildroot support for arm/virt currently, use nolibc initrd by default
NOLIBC  := $(or $(NOLIBC),1)

# Use the same toolchain as ppc64le
NOLIBC_CFLAGS  := -mbig-endian -mmultiple -Wl,-EB -Wl,-melf64ppc -mno-vsx
NOLIBC_LDFLAGS := -EB -melf64ppc

SERIAL  ?= hvc0

ROOTDEV_LIST := /dev/ram0
ROOTDEV ?= /dev/ram0

# Use vmlinux instead of zImage, there is a bug in QEMU or SLOF
# ref: https://github.com/linuxppc/issues/issues/402
ORIIMG  ?= vmlinux
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux

CCORI   ?= internal
# Use big endian toolchain
# CCORI   ?= mirrors.edge.kernel.org
