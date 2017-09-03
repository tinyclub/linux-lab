_BASE    = 1
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= arm926t
MEM     ?= 128M
UBOOT   ?= v2015.07
BUILDROOT?= 2016.05
# Need comment ORIDTB for 2.6.36 Linux
LINUX   ?= v4.6.7
# get flash info: flinfo
PFLASH_BASE ?= 0x34000000
PFLASH_SIZE ?= 64
# get dram range: bdinfo
KRN_ADDR?= 0x007fc0
KRN_SIZE?= 5
RDK_ADDR?= 0x607fc0
RDK_SIZE?= 4
DTB_ADDR?= 0xa07fc0
DTB_SIZE?= 1
# tftp, flash/pflash
BOOTDEV ?= tftp
UCONFIG ?= versatile.h
NETDEV  ?= smc91c111
SERIAL  ?= ttyAMA0
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/zImage
UORIIMG ?= arch/$(ARCH)/boot/uImage
ORIDTB  ?= arch/$(ARCH)/boot/dts/versatile-pb.dtb
CCPRE   ?= arm-linux-gnueabi-
BIMAGE  ?= $(PREBUILT_UBOOT)/$(XARCH)/$(BOARD)/$(UBOOT)/$(LINUX)/u-boot
KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/zImage
DTB     ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/versatile-pb.dtb
UKIMAGE ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/uImage
ROOTFS  ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
UROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.uboot
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.$(FSTYPE)
