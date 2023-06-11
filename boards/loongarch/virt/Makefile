# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := loongarch
XARCH   := loongarch64
CPU     ?= la464-loongarch-cpu
MEM     ?= 1024M
SERIAL  ?= ttyS0,115200

QEMU    ?= v8.0.2

LINUX   ?= v6.3.6

HOST_GCC := 9

# no buildroot support for loongarch currently, use nolibc initrd by default
NOLIBC  ?= 1

# download from https://github.com/loongson/Firmware/tree/main/LoongArchVirtMachine
BIOS    ?= $(BSP_BIOS)/edk2/edk2-loongarch64-code.fd

ORIIMG  ?= arch/$(ARCH)/boot/vmlinux.efi
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux.efi

QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

CCORI   ?= mirrors.edge.kernel.org
