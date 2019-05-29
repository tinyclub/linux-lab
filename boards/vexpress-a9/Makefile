_BASE    = 1
ARCH     = arm
XARCH    = $(ARCH)
CPU     ?= cortex-a9
MEM     ?= 128M
QEMU    ?= v2.12.0
# compile qemu-user with QEMU_US=1, by default only compile qemu-system-$(XARCH)
# after enabling QEMU_US=1, qemu-system-$(XARCH) will not be compiled
QEMU_US ?= 0
UBOOT   ?= v2015.07
LINUX   ?= v5.1
ifeq ($(LINUX),v3.18.39)
  U := 0
endif
BUILDROOT?= 2016.05
KRN_ADDR?= 0x60003000
KRN_SIZE?= 5
RDK_ADDR?= 0x60900000
RDK_SIZE?= 4
DTB_ADDR?= 0x60500000
DTB_SIZE?= 1
UCONFIG ?= vexpress_common.h
# tftp, sdcard/sd/mmc, flash/pflash
BOOTDEV ?= flash
# 64M pflash0@0x40000000, 64M pflash1@0x44000000
PFLASH_BASE ?= 0x40000000
PFLASH_SIZE ?= 64
PFLASH_BS   ?= 512
NETDEV  ?= lan9118
SERIAL  ?= ttyAMA0
#ROOTDEV ?= /dev/mmcblk0
ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/zImage
UORIIMG ?= arch/$(ARCH)/boot/uImage
ORIDTB  ?= arch/$(ARCH)/boot/dts/vexpress-v2p-ca9.dtb
CCPRE   ?= arm-linux-gnueabi-
BIMAGE  ?= $(PREBUILT_UBOOT)/$(XARCH)/$(BOARD)/$(UBOOT)/u-boot
KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/zImage
DTB     ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/vexpress-v2p-ca9.dtb
UKIMAGE ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/uImage
ROOTFS  ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
UROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.uboot
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.$(FSTYPE)
QP      ?= 1
QTOOL   ?= $(PREBUILT_QEMU)/$(XARCH)/$(QEMU)/bin/qemu-system-$(XARCH)
