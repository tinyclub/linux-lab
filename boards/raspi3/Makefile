# Raspberry Pi 3
_BASE    = 1
ARCH     = arm64
XARCH    = aarch64
CPU     ?= cortex-a53
SMP     ?= 4
MEM     ?= 512M
XOPTS   ?= -cpu $(CPU)

# Ref: https://github.com/bztsrc/raspi3-tutorial#emulation
UART    ?= 1
ifeq ($(UART), 1)
  # UART1 as earlycon
  XOPTS   += -serial null -serial mon:stdio
  XKCLI   ?= earlycon=uart8250,mmio32,0x3f215040
  SERIAL  ?= ttyS0,115200
else
  # UART0 as earlycon
  XOPTS   += -serial mon:stdio
  XKCLI   ?= earlycon=pl011,0x3f201000
  SERIAL  ?= ttyAMA0,115200
endif

# QEMU    ?= v3.1.0
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

ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
ORIIMG  ?= arch/$(ARCH)/boot/Image
ORIDTB  ?= arch/$(ARCH)/boot/dts/broadcom/bcm2710-rpi-3-b.dtb
CCPRE   ?= aarch64-linux-gnu-
KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/Image
DTB     ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/bcm2710-rpi-3-b.dtb
ROOTFS  ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.$(FSTYPE)
# Only for current v5.0.10 support
KP      ?= 1
QP      ?= 1
QTOOL   ?= $(PREBUILT_QEMU)/$(XARCH)/$(QEMU)/bin/qemu-system-$(XARCH)
CCVER   ?= 8.3-2019.03
CCPATH  ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/gcc-arm-$(CCVER)-x86_64-aarch64-linux-gnu/bin/
