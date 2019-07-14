_BASE    = 1
ARCH     = mips
XARCH    = mipsel
CPU     ?= mips32r2
#LINUX   ?= v4.6.7
LINUX   ?= v5.1
BUILDROOT?= 2016.05
MEM     ?= 128M
NETDEV_LIST := pcnet
NETDEV  ?= pcnet
SERIAL  ?= ttyS0
FSTYPE  ?= ext2
ORIIMG  ?= vmlinuz
ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

# prebuilt toolchain, please download it if not internal via: make toolchain
# Available CCORI: internal, bootlin, mips

CCORI  ?= internal
include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.head
