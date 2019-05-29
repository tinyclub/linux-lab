_BASE    = 1
ARCH     = arm64
XARCH    = aarch64
CPU     ?= cortex-a57
SMP     ?= 2
MEM     ?= 128M
XOPTS   ?= -cpu $(CPU)
QEMU    ?= v2.12.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 0
LINUX   ?= v5.1
BUILDROOT?= 2016.05
NETDEV  ?= virtio
SERIAL  ?= ttyAMA0

# virtio sda: https://blahcat.github.io/2018/01/07/building-a-debian-stretch-qemu-image-for-aarch64/
# ROOTDEV ?= /dev/sda
# virtio vda: https://wiki.debian.org/Arm64Qemu
ROOTDEV ?= /dev/vda

FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/Image
CCPRE   ?= aarch64-linux-gnu-
KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/Image
ROOTFS  ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.$(FSTYPE)
XKCLI   ?= earlycon
# Only for current v5.0.10 support
#KP      ?= 1
#QP      ?= 1
QTOOL   ?= $(PREBUILT_QEMU)/$(XARCH)/$(QEMU)/bin/qemu-system-$(XARCH)
CCVER   ?= 8.3-2019.03
CCPATH  ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/gcc-arm-$(CCVER)-x86_64-aarch64-linux-gnu/bin/
