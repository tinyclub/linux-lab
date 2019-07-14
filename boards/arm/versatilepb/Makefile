_BASE    = 1
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= arm926t
MEM     ?= 128M
UBOOT   ?= v2015.07
BUILDROOT?= 2016.05
# Need comment ORIDTB for 2.6.36 Linux
LINUX   ?= v5.1
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
ifneq ($(LINUX), v2.6.36)
  HAS_DTS ?= 1
endif

ifeq ($(HAS_DTS), 1)
  ORIDTB  ?= arch/$(ARCH)/boot/dts/versatile-pb.dtb
  BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot
else
  BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/$(LINUX)/u-boot
endif

KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/zImage
DTB     ?= $(BSP_KERNEL)/$(LINUX)/versatile-pb.dtb
UKIMAGE ?= $(BSP_KERNEL)/$(LINUX)/uImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
UROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.uboot
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

CCTYPE ?= internal

ifeq ($(CCTYPE), internal)
  # To use this prebuilt toolchain, please run `make toolchain` before `make kernel`
  CCPRE   ?= arm-linux-gnueabi-
endif

ifeq ($(CCTYPE), external)
  # external toolchain, please download it while: make toolchain
  # Available CCORI: bootlin, arm
  # Notes: Uboot compiled with Linaro toolchain can not boot, simply hang there.
  CCORI  ?= bootlin

  include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.head
endif
