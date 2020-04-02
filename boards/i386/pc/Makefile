# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
_BASE    = 1
ARCH     = x86
XARCH    = i386

# qemu-system-i386 -M pc -cpu ?
CPU     ?= qemu32
MEM     ?= 128M

# This is for old linux 0.11 floppy support
QEMU    ?= v0.10.6

ifeq ($(QEMU),v0.10.6)
QEMU_SDL    := 0
QEMU_CURSES := 0
QEMU_VIRTFS := 0
QEMU_VNC    :=
GCC[QEMU_v0.10.6] = 4.4
endif

SMP     ?= 4
LINUX   ?= v5.1
BUILDROOT?= 2019.02.2

# Add board detailed configuration
#$(warning $(call board_config))
$(eval $(call board_config))

# Force change ARCH for kernel version <= 2.6.23
#$(warning $(call fixup_arch))
$(eval $(call fixup_arch))
#$(warning ARCH is $(ARCH))


# Check qemu support:
# $ qemu-system-i386 -net nic,model=?
#   qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
#
NETDEV_LIST ?= ne2k_pci e1000 rtl8139 pcnet
NETDEV  ?= e1000

ROOTDEV_LIST ?= /dev/hda /dev/ram0 /dev/nfs
ROOTDEV_LIST[LINUX_v2.6.34.9] ?= /dev/sda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/hda

SERIAL  ?= ttyS0
ORIIMG  ?= arch/$(ARCH)/boot/bzImage
#CCPRE   = i686-pc-linux-gnu-
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/bzImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.ext2
# Fixup: MP-BIOS bug: 8254 timer not connected to IO-APIC
# No such issue in newer kernels??
XKCLI   ?= noapic
#
# -m32 must be added to CFLAGS and AFLAGS in linux-stable/arch/i386/Makefile for kernel version <= 2.6.23
# see boards/i386/pc/bsp/patch/linux/v2.6.12/0001-v2.6.12-i386-force-using-m32-for-x86_64-host.patch
