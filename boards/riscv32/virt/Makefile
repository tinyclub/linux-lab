_BASE    = 1
ARCH     = riscv
XARCH    = riscv32
CPU     ?= any
SMP     ?= 4
MEM     ?= 128M
# v2.12.0 has sdl based graphic, boots with G=1, v4.0.0 with vnc output
#QEMU    ?= v2.12.0
QEMU    ?= v4.0.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 0
LINUX   ?= v5.0.13
BUILDROOT?= 2019.05
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

# virtio sda: https://blahcat.github.io/2018/01/07/building-a-debian-stretch-qemu-image-for-aarch64/
# ROOTDEV ?= /dev/sda
# virtio vda: https://wiki.debian.org/Arm64Qemu
ROOTDEV ?= /dev/vda

FSTYPE  ?= ext2

# Proxy kernel image is built in buildroot-output/images/
# Both of bbl and fw_jump.elf work, but fw_jump.elf is smaller a lot, bbl is deprecated...
# bbl is from https://github.com/riscv/riscv-pk
# fw_jump.elf is from https://github.com/riscv/opensbi

#PORIIMG ?= bbl
PORIIMG ?= fw_jump.elf
#PKIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/$(PORIIMG)
PKIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/$(PORIIMG)

KRN_ADDR ?= 0x80400000
ORIIMG  ?= arch/$(ARCH)/boot/Image
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)

#XKCLI   ?= earlycon=sbi
# Only for current v5.0.10 support
#KP      ?= 1
#QP      ?= 1
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

# To use this prebuilt toolchain, please run `make toolchain` before `make kernel`
# Use the prebuilt riscv64 toolchain with multilib support for riscv32, so, no need to prepare two toolchains
CCTYPE ?= external
ifeq ($(CCTYPE), external)
  # external toolchain, please download it while: make toolchain
  # Available CCORI: bootlin, gnu-mcu-eclipse
  CCORI  ?= gnu-mcu-eclipse
  include $(PREBUILT_TOOLCHAINS)/riscv64/Makefile.head
endif

# Force use riscv64 toolchain for us
TOOLCHAIN ?= $(PREBUILT_TOOLCHAINS)/riscv64
