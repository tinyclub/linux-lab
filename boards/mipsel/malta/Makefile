_BASE    = 1
ARCH     = mips
XARCH    = mipsel
CPU     ?= mips32r2
#LINUX   ?= v4.6.7
LINUX   ?= v5.1
BUILDROOT?= 2016.05
MEM     ?= 128M
NETDEV  ?= pcnet
SERIAL  ?= ttyS0
FSTYPE  ?= ext2
ORIIMG  ?= vmlinuz
ROOTDEV ?= /dev/ram0
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinuz
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

CCTYPE ?= internal

ifeq ($(CCTYPE), internal)
  # builtin toolchain
  CCPRE   ?= mipsel-linux-gnu-
endif

ifeq ($(CCTYPE), external)
  # external toolchain, please download it while: make toolchain
  # Available CCORI: bootlin, mips

  CCORI  ?= bootlin
  include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.lib
endif
