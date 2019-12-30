_BASE    = 1
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= arm926t
MEM     ?= 128M
UBOOT   ?= v2015.07
GCC[UBOOT_v2015.07] = 4.3
BUILDROOT?= 2016.05
# Need comment ORIDTB for 2.6.36 Linux
LINUX   ?= v5.1
GCC[LINUX_v2.6.36] = 4.3
# get flash info: flinfo
PFLASH_BASE ?= 0x34000000
PFLASH_SIZE ?= 64
PFLASH_BS   ?= 256
# get dram range: bdinfo
KRN_ADDR?= 0x007fc0
KRN_SIZE?= 5
RDK_ADDR?= 0x900000
RDK_SIZE?= 4
DTB_ADDR?= 0xc07fc0
DTB_SIZE?= 1
BOOTDEV_LIST := tftp flash pflash
BOOTDEV ?= flash
UCONFIG ?= versatile.h
NETDEV_LIST := smc91c111 rtl8139
NETDEV  ?= smc91c111
SERIAL  ?= ttyAMA0
ROOTDEV_LIST := /dev/sda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/zImage
UORIIMG ?= arch/$(ARCH)/boot/uImage

# Old Linux kernel don't support dts
# FIXME: check which version is the first one support dts
HAS_DTS[LINUX_v2.6.36] = 0

HAS_DTS := $(call _v,HAS_DTS,LINUX,1)

ifeq ($(HAS_DTS), 1)
  ORIDTB  ?= arch/$(ARCH)/boot/dts/versatile-pb.dtb
  BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot
else
  BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/nodtb/u-boot
endif

KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/zImage
DTB     ?= $(BSP_KERNEL)/$(LINUX)/versatile-pb.dtb
UKIMAGE ?= $(BSP_KERNEL)/$(LINUX)/uImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
UROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.uboot
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# prebuilt toolchain, please download it if not internal via: make toolchain
# Available CCORI: internal, bootlin, arm
CCORI   ?= internal
include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile
