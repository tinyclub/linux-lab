# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := riscv
XARCH   := riscv64
# Use the default setting
CPU     ?=
SMP     ?= 4
MEM     ?= 256M
QEMU    ?= v6.0.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 0
LINUX   ?= v6.2

# git repos for the other kernel forks
KERNEL_GIT[KERNEL_FORK_openeuler] := https://gitee.com/openeuler/kernel.git
LINUX[KERNEL_FORK_openeuler]   ?= 5.10.0-132.0.0

BUILDROOT?= 2019.05
NETDEV_LIST := virtio
NETDEV  ?= virtio
SERIAL  ?= ttyS0

# use bochs as VGA graphic device
FBDEV   ?= stdvga

UBOOT   ?= v2022.04

KRN_ADDR?= 0x84000000
RDK_ADDR?= 0x87500000

# QEMU load env.img to ram and then U-boot import it from ram
ENV_DEV_LIST := ram
ENV_DEV      ?= ram
ENV_OFFSET   ?= 0
ENV_ADDR     ?= 0x87300000

UCONFIG ?= qemu-riscv.h
BOOTDEV_LIST := ram
BOOTDEV ?= ram

# ref: https://wiki.qemu.org/Documentation/9psetup
# 9pnet based network filesystem sharing, aarch64/virt board support both virtio-9p-pci/-virtfs and virtio-9p-device
# But virtio-9p-device requires less kernel options (no need the PCI related parts in features/linux/9pnet/)
# To eanble this function, please make sure the 9pnet feature is enabled: make feature f=9pnet && make kernel-olddefconfig
#
# TODO: add board specific 9pnet options.
#

NET9PDEV ?= virtio-9p-device

# virtio vda: https://wiki.debian.org/Arm64Qemu
ROOTDEV_LIST := /dev/vda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/vda

FSTYPE  ?= ext2

# fw_jump.elf is from https://github.com/riscv/opensbi
BIOS    ?= $(BSP_BIOS)/opensbi/generic/fw_jump.elf

ifeq ($(vmlinuz),1)
ORIIMG  ?= arch/$(ARCH)/boot/compressed/vmlinuz
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
else
ORIIMG  ?= arch/$(ARCH)/boot/Image
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image
endif

#DTS     ?= $(BSP_KERNEL)/$(LINUX)/qemu-$(XARCH)-$(MACH).dts
UORIIMG ?= $(ORIIMG)
BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot
UKIMAGE ?= $(KIMAGE)
#DTB     ?= $(BSP_KERNEL)/$(LINUX)/qemu-$(XARCH)-$(MACH).dtb

ifneq ($(wildcard $(DTB)),)
  DTB_ADDR := 0x87000000
else
  DTB_ADDR := $$fdtcontroladdr
endif

ifeq ($(NOMMU),1)
  override SMP := 1
  override BIOS := none
  override U := 0
endif

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

#XKCLI   ?= earlycon=sbi
QTOOL[OS_trusty]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)
QTOOL[OS_focal]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

# external toolchain, please download it while: make toolchain
# Available CCORI: bootlin, gnu-mcu-eclipse
CCORI[OS_trusty]   ?= gnu-mcu-eclipse
CCORI[OS_focal]    ?= mirrors.edge.kernel.org
