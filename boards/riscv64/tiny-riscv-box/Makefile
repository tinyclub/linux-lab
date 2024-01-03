# Copyright (C) 2020 Wu Zhangjin <falcon@tinylab.org>
# _BASE: 1, virt; 2, real; 3: virt+real
_BASE   := 2
ARCH    := riscv
XARCH   := riscv64
CPU     ?= cv1800b
SMP     ?= 1
MEM     ?= 64MB
LINUX   ?= v5.10.4

UBOOT   ?= v2021.10

BUILDROOT?= 2021.05

SERIAL  ?= ttyS0

ROOTDEV_LIST := /dev/mmcblk0
ROOTDEV ?= /dev/mmcblk0
FSTYPE  ?= ext4

ORIIMG  ?= arch/$(ARCH)/boot/Image
UORIIMG ?= $(ORIIMG)
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image
UKIMAGE ?= $(KIMAGE)
KRELEASE?= $(BSP_KERNEL)/$(LINUX)/kernel.release

ORIDTB  ?= arch/$(ARCH)/boot/dts/cvitek/cv1800b_milkv_duo_sd.dtb
DTB     ?= $(BSP_KERNEL)/$(LINUX)/cv1800b_milkv_duo_sd.dtb

CCPATH	?= $(BSP_TOOLCHAIN)/riscv64-linux-musl-x86_64/bin
CCPRE	?= riscv64-unknown-linux-musl-
# Path to toolchain package
CCURL     ?= $(BSP_TOOLCHAIN)/toolchain.tar.xz
# Path to decompressing directory
TOOLCHAIN ?= $(BSP_TOOLCHAIN)

# Prefer serial port login instead of ssh
LOGIN_METHOD ?= serial

# Usb ethernet ip, only for usb rndis mode
BOARD_IP  ?= 192.168.42.1

BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot.bin

BIOS    ?= $(BSP_DIR)/opensbi/bin/fw_dynamic.bin

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
