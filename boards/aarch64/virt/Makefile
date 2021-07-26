# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
_BASE    = 1
ARCH     = arm64
XARCH    = aarch64
CPU     ?= cortex-a57
SMP     ?= 2
MEM     ?= 256M
XOPTS   ?= -cpu $(CPU) -serial mon:stdio -machine virt,gic_version=3 -machine type=virt,virtualization=true -d guest_errors -nodefaults
# v2.12.0 has sdl based graphic, boots with G=1, v4.0.0 with vnc output
QEMU    ?= v4.0.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 0

UBOOT   ?= v2019.10

CCORI[UBOOT_v2019.10,OS_trusty] = linaro
CCORI[UBOOT_v2019.10,OS_focal]  = internal

LINUX   ?= v5.1
BUILDROOT?= 2019.11.1

# git repos for other kernel fork
KERNEL_GIT[KERNEL_FORK_openEuler] := https://gitee.com/openeuler/kernel.git

NETDEV_LIST := virtio

NETDEV  ?= virtio
SERIAL  ?= ttyAMA0

# ref: https://wiki.qemu.org/Documentation/9psetup
# 9pnet based network filesystem sharing, aarch64/virt board support both virtio-9p-pci/-virtfs and virtio-9p-device
# But virtio-9p-device requires less kernel options (no need the PCI related parts in features/linux/9pnet/)
# To eanble this function, please make sure the 9pnet feature is enabled: make feature f=9pnet && make kernel-olddefconfig
#
# Note: 9pnet pci kernel options has broken nfsroot on virt board, please use virtio-9p-device instead of virtio-9p-pci
#       and also, must not enable the pci related options in feature/linux/9pnet/
#
# TODO: add board specific 9pnet options.
#

NET9PDEV ?= virtio-9p-device

# virtio sda: https://blahcat.github.io/2018/01/07/building-a-debian-stretch-qemu-image-for-aarch64/
# ROOTDEV ?= /dev/sda
# virtio vda: https://wiki.debian.org/Arm64Qemu

ROOTDEV_LIST := /dev/sda /dev/vda /dev/ram0 /dev/nfs

ROOTDEV ?= /dev/vda

FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/Image
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image

# Get DRAM start & size via `bdinfo`
KRN_ADDR?= 0x45000000
KRN_SIZE?= 10
RDK_ADDR?= 0x42000000
RDK_SIZE?= 6
DTB_ADDR?= 0x44000000
DTB_SIZE?= 2
UCONFIG ?= qemu-arm.h

BOOTDEV_LIST := tftp flash pflash ram
BOOTDEV ?= flash
# get FLASH info from `flinfo`: 64M pflash0@0x00000000, 64M pflash1@0x04000000
# The first one is used for -bios, the second one for environment, dtb and ramdisk if required
PFLASH_BASE ?= 0x4000000
PFLASH_SIZE ?= 64
PFLASH_BS   ?= 512
# Environment Offset, see CONFIG_ENV_OFFSET in $UCONFIG
ENV_OFFSET  ?= 0
ENV_SIZE    ?= 1
ENVDEV      ?= flash
ifeq ($(ENV_DEV), flash)
  ENV_ADDR  ?= 0x4000000
else
  ENV_ADDR  ?= 0x49000000
endif

# Run uboot as bios, use -bios instead of -kernel
UBOOT_BIOS ?= 1

BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/$(LINUX)/u-boot.bin
DTS     ?= $(BSP_KERNEL)/$(LINUX)/virt-gicv3.dts
# DTB is loaded by QEMU automatically at start of RAM, we load a new one for easier customization
# This is dumped out by qemu, see README.md
DTB     ?= $(BSP_KERNEL)/$(LINUX)/virt-gicv3.dtb
UKIMAGE ?= $(BSP_KERNEL)/$(LINUX)/Image

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)
UROOTFS := $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.uboot
XKCLI   ?= earlycon
# Only for current v5.0.10 support
QTOOL[OS_trusty]   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)
QTOOL[OS_focal]    ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

# prebuilt toolchains, please download it if not internal via: make toolchain
# Available origin: internal, bootlin, arm, linaro
CCORI   ?= internal
