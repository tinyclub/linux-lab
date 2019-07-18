# Raspberry Pi 3
_BASE    = 1
ARCH     = arm64
XARCH    = aarch64
CPU     ?= cortex-a53
SMP     ?= 4
MEM     ?= 1024M
XOPTS   ?= -cpu $(CPU)

# Ref: https://github.com/bztsrc/raspi3-tutorial#emulation
UART    ?= 0
#XOPTS   += -serial vc -serial vc
ifeq ($(UART), 1)
  # UART1 as earlycon
  XOPTS   += -serial null -serial mon:stdio
  XKCLI   ?= earlycon=uart8250,mmio32,0x3f215040
  SERIAL  ?= ttyS1,115200
else
  # UART0 as earlycon
  XOPTS   += -serial mon:stdio
  XKCLI   ?= earlycon=pl011,0x3f201000
  SERIAL  ?= ttyAMA0,115200
endif

QEMU    ?= v2.12.0
# Enable QEMU_US=1 for qemu-user-static
QEMU_US ?= 0

LINUX   ?= v5.1

BUILDROOT?= 2019.02.2

# NOTE: No network support currently
# raspi3's network is based on usb, but not usb support in current qemu.
#NET     ?= -net nic -net user -net tap,ifname=vnet0,script=no,downscript=no
#NETDEV  ?= smc91c111
NET     ?=

# No network exists in raspi3 currently, use mmc as the testing rootfs disk
TEST_RD ?= /dev/mmcblk0

# Verified root devices
ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0
ROOTDEV_LIST[LINUX_v5.1] := /dev/mmcblk0 /dev/ram0

ROOTDEV ?= /dev/mmcblk0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/Image
# bcm2837-rpi-3-b.dtb all works, bcm2710-rpi-3-b.dtb has less warnings about therem zone access
ORIDTB  ?= arch/$(ARCH)/boot/dts/broadcom/bcm2710-rpi-3-b.dtb
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image
DTB     ?= $(BSP_KERNEL)/$(LINUX)/bcm2710-rpi-3-b.dtb
ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
HROOTFS ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.$(FSTYPE)
# Only for current v5.0.10 support
#KP      ?= 1
#QP      ?= 1
QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

# prebuilt toolchains, please download it while: make toolchain
# Available origin: internal, bootlin, arm, linaro
CCORI   ?= internal
include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile
