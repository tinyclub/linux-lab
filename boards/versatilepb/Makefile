_BASE    = 1
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= arm926t
MEM     ?= 128M
UBOOT   ?= v2015.07
BUILDROOT?= 2016.05
# Need comment ORIDTB for 2.6.36 Linux
LINUX   ?= v5.0.13
# get flash info: flinfo
PFLASH_BASE ?= 0x34000000
PFLASH_SIZE ?= 64
PFLASH_BS   ?= 256
# get dram range: bdinfo
KRN_ADDR?= 0x007fc0
KRN_SIZE?= 5
RDK_ADDR?= 0x607fc0
RDK_SIZE?= 4
DTB_ADDR?= 0xa07fc0
DTB_SIZE?= 1
# tftp, flash/pflash
BOOTDEV ?= flash
UCONFIG ?= versatile.h
NETDEV  ?= smc91c111
SERIAL  ?= ttyAMA0
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/zImage
UORIIMG ?= arch/$(ARCH)/boot/uImage
CCPRE   ?= arm-linux-gnueabi-

# Old Linux kernel don't support dts
# FIXME: check which version is the first one support dts
ifneq ($(LINUX), v2.6.36)
  HAS_DTS ?= 1
endif

ifeq ($(HAS_DTS), 1)
  ORIDTB  ?= arch/$(ARCH)/boot/dts/versatile-pb.dtb
  BIMAGE  ?= $(PREBUILT_UBOOT)/$(XARCH)/$(BOARD)/$(UBOOT)/u-boot
else
  BIMAGE  ?= $(PREBUILT_UBOOT)/$(XARCH)/$(BOARD)/$(UBOOT)/$(LINUX)/u-boot
endif

KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/zImage
DTB     ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/versatile-pb.dtb
UKIMAGE ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/uImage
ROOTFS  ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
UROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.uboot
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.$(FSTYPE)
