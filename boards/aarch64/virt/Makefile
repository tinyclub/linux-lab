_BASE    = 1
ARCH     = arm64
XARCH    = aarch64
CPU     ?= cortex-a57
SMP     ?= 2
MEM     ?= 128M
XOPTS   ?= -cpu $(CPU)
# v2.12.0 has sdl based graphic, boots with G=1, v4.0.0 with vnc output
QEMU    ?= v4.0.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 0
LINUX   ?= v5.1
BUILDROOT?= 2016.05

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
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)
XKCLI   ?= earlycon
# Only for current v5.0.10 support
#KP      ?= 1
#QP      ?= 1
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

CCTYPE ?= internal

ifeq ($(CCTYPE), internal)
  # builtin toolchain
  CCPRE   ?= aarch64-linux-gnu-
endif

ifeq ($(CCTYPE), external)
  # external toolchain, please download it while: make toolchain
  # Available origin: bootlin, arm, linaro
  CCORI ?= bootlin
  include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.head
endif
