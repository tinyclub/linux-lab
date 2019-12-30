_BASE    = 1
ARCH     = x86
XARCH    = x86_64

# qemu-system-x86_64 -M pc -cpu ?
CPU     ?= qemu64
MEM     ?= 128M
SMP     ?= 4
LINUX   ?= v5.1
GCC[LINUX_v3.2] = 4.8
GCC[LINUX_v2.6.12.6] = 4.8

# Force change ARCH for kernel version <= 2.6.23
IS_X86 = $(shell cd $(KERNEL_ABS_SRC); git show $(call _v,LINUX,LINUX):arch/$(ARCH)/boot >/dev/null 2>&1; echo $$?)
ifneq ($(IS_X86),0)
  ARCH  := $(XARCH)
endif

BUILDROOT?= 2019.02.2

# Check qemu support:
# $ qemu-system-i386 -net nic,model=?
#   qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
#
NETDEV_LIST := ne2k_pci e1000 rtl8139 pcnet
NETDEV  ?= ne2k_pci
SERIAL  ?= ttyS0
ORIIMG  ?= arch/$(ARCH)/boot/bzImage

ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
ROOTDEV_LIST[LINUX_v3.2] := /dev/sda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/ram0

KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/bzImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
ROOTFS[LINUX_v2.6.12.6]  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs32.cpio.gz
