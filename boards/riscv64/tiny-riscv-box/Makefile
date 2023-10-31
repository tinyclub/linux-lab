# Copyright (C) 2020 Wu Zhangjin <falcon@tinylab.org>
# _BASE: 1, virt; 2, real; 3: virt+real
_BASE   := 2
ARCH    := riscv
XARCH   := riscv64
CPU     ?= cv1800b
SMP     ?= 1
MEM     ?= 64MB
LINUX   ?= v5.10.4

SERIAL  ?= ttyS0

ROOTDEV_LIST := /dev/mmcblk0
ROOTDEV ?= /dev/mmcblk0
FSTYPE  ?= ext4

ORIIMG  ?= arch/$(ARCH)/boot/Image
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image

CCORI := mirrors.edge.kernel.org
