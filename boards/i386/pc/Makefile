_BASE    = 1
ARCH     = x86
XARCH    = i386
# qemu-system-i386 -M pc -cpu ?
CPU     ?= qemu32
MEM     ?= 128M
QEMU    ?= v0.10.6
SMP     ?= 4
LINUX   ?= v5.1
BUILDROOT?= 2019.02.2

# Check qemu support:
# $ qemu-system-i386 -net nic,model=?
#   qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
#
# Kernel enabled: ne2k_pci, e1000, rtl8139, pcnet
NETDEV  ?= pcnet

# Verified ROOTDEV: /dev/ram0, /dev/nfs, /dev/hda
ROOTDEV ?= /dev/ram0

SERIAL  ?= ttyS0
ORIIMG  ?= arch/$(ARCH)/boot/bzImage
#CCPRE   = i686-pc-linux-gnu-
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/bzImage
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.ext2
# Fixup: MP-BIOS bug: 8254 timer not connected to IO-APIC
# No such issue in newer kernels??
XKCLI   ?= noapic
