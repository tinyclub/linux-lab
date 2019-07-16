_BASE    = 1
ARCH     = riscv
XARCH    = riscv64
CPU     ?= any
SMP     ?= 4
MEM     ?= 128M
QEMU    ?= v4.0.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 1
LINUX   ?= v5.1
BUILDROOT?= 2019.05
NETDEV_LIST := virtio
NETDEV  ?= virtio
SERIAL  ?= ttyS0

# ref: https://wiki.qemu.org/Documentation/9psetup
# 9pnet based network filesystem sharing, aarch64/virt board support both virtio-9p-pci/-virtfs and virtio-9p-device
# But virtio-9p-device requires less kernel options (no need the PCI related parts in features/linux/9pnet/)
# To eanble this function, please make sure the 9pnet feature is enabled: make feature f=9pnet && make kernel-olddefconfig
#
# TODO: add board specific 9pnet options.
#

NET9PDEV ?= virtio-9p-device

# virtio vda: https://wiki.debian.org/Arm64Qemu
ROOTDEV_LIST := /dev/vda /dev/ram0 /dev/nfs
ROOTDEV ?= /dev/vda

FSTYPE  ?= ext2

# Proxy kernel image is built in buildroot-output/images/
# Both of bbl and fw_jump.elf work, but fw_jump.elf is smaller a lot, bbl is deprecated...
# bbl is from https://github.com/riscv/riscv-pk
# fw_jump.elf is from https://github.com/riscv/opensbi

#PORIIMG ?= bbl
PORIIMG ?= fw_jump.elf
PKIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/$(PORIIMG)

KRN_ADDR ?= 0x80200000
ORIIMG  ?= arch/$(ARCH)/boot/Image
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

#XKCLI   ?= earlycon=sbi
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

# external toolchain, please download it while: make toolchain
# Available CCORI: bootlin, gnu-mcu-eclipse
CCORI   ?= gnu-mcu-eclipse
include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.head
