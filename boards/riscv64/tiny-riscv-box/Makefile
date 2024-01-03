# Copyright (C) 2020 Wu Zhangjin <falcon@tinylab.org>
# _BASE: 1, virt; 2, real; 3: virt+real
_BASE   := 2
ARCH    := riscv
XARCH   := riscv64
CPU     ?= cv1800b
SMP     ?= 1
MEM     ?= 64MB
LINUX   ?= v5.10.4

UBOOT   ?= v2021.10

BUILDROOT?= 2021.05

SERIAL  ?= ttyS0

ROOTDEV_LIST := /dev/mmcblk0
ROOTDEV ?= /dev/mmcblk0
FSTYPE  ?= ext4

ORIIMG  ?= arch/$(ARCH)/boot/Image
UORIIMG ?= $(ORIIMG)
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/Image
UKIMAGE ?= $(KIMAGE)
KRELEASE?= $(BSP_KERNEL)/$(LINUX)/kernel.release

ORIDTB  ?= arch/$(ARCH)/boot/dts/cvitek/cv1800b_milkv_duo_sd.dtb
DTB     ?= $(BSP_KERNEL)/$(LINUX)/cv1800b_milkv_duo_sd.dtb

CCPATH	?= $(BSP_TOOLCHAIN)/riscv64-linux-musl-x86_64/bin
CCPRE	?= riscv64-unknown-linux-musl-
# Path to toolchain package
CCURL     ?= $(BSP_TOOLCHAIN)/toolchain.tar.xz
# Path to decompressing directory
TOOLCHAIN ?= $(BSP_TOOLCHAIN)

# Prefer serial port login instead of ssh
LOGIN_METHOD ?= serial

# Usb ethernet ip, only for usb rndis mode
BOARD_IP  ?= 192.168.42.1

# Upload support, require run /mnt/system/usb-rndis.sh after connect the main board to host
REMOTE_MODULES ?= /mnt/system/ko/3rd/
# We don't have a rsync in the target system? use scp instead
RSYNC_CMD ?= $(SCP_CMD) -r

# Both kimage and dtb are put in boot.sd
LOCAL_KIMAGE ?= $(BSP_DIR)/tools/boot.sd
REMOTE_KIMAGE ?= /media/boot/boot.sd
LOCAL_DTB    ?= $(LOCAL_KIMAGE)
REMOTE_DTB   ?= $(REMOTE_KIMAGE)

# Prepare local boot.sd and remote boot.sd store directory
$(LOCAL_KIMAGE): $(KIMAGE) $(DTB) remote_boot_sd
	$(Q)echo "LOG: Building $(REMOTE_KIMAGE)"
	$(Q)cd $(BSP_DIR)/tools/; cp $(LINUX_KIMAGE) ./; lzma -fk Image; cp $(LINUX_DTB) ./; mkimage -f multi.its boot.sd; rm Image Image.lzma

remote_boot_sd: FORCE
	$(Q)echo "LOG: Mounting from remote /dev/mmcblk0p1 to /media/boot/"
	$(Q)$(SSH_CMD) "mkdir -p /media/boot; grep -q /media/boot /proc/mounts || mount /dev/mmcblk0p1 /media/boot/" || true

BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot.bin

BIOS    ?= $(BSP_DIR)/opensbi/bin/fw_dynamic.bin

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz
