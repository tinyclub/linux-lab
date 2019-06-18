_BASE    = 1
ARCH     = powerpc
XARCH    = ppc
CPU     ?= generic
# Note: <2.6.37 kernel don't have __NR_socket implementation
LINUX   ?= v5.1
BUILDROOT?= 2016.05
MEM     ?= 128M
NETDEV  ?= pcnet
SERIAL  ?= ttyS0
ORIIMG  ?= vmlinux
ROOTDEV ?= /dev/ram0
BIOS    ?= $(BSP_QEMU)/v4.0.0/share/qemu/openbios-ppc
CCPRE   ?= powerpc-linux-gnu-
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/vmlinux
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.ext2
