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

BIMAGE  ?= $(BSP_UBOOT)/$(UBOOT)/u-boot.bin

BIOS    ?= $(BSP_DIR)/opensbi/bin/fw_dynamic.bin

ROOTFS  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs.cpio.gz

# Prefer serial port login instead of ssh
LOGIN_METHOD ?= serial

# Usb ethernet ip, only for usb rndis mode
BOARD_IP  ?= 192.168.42.1

# Upload support, require run /mnt/system/usb-rndis.sh after connect the main board to host
LOCAL_MODULES  ?= $(ROOTDIR)/lib/modules/
REMOTE_MODULES ?= /lib/modules/
# We don't have a rsync in the target system? use scp instead
RSYNC_CMD ?= $(SCP_CMD) -r

# Both kimage and dtb are put in boot.sd
IMAGE_BUILD = $(TOP_BUILD)/$(XARCH)/$(MACH)/image

LOCAL_KIMAGE ?= $(IMAGE_BUILD)/boot.sd
REMOTE_KIMAGE ?= /media/boot/boot.sd
LOCAL_DTB    ?= $(LOCAL_KIMAGE)
REMOTE_DTB   ?= $(REMOTE_KIMAGE)
LOCAL_BIMAGE ?= $(IMAGE_BUILD)/fip.bin
REMOTE_BIMAGE ?= /media/boot/fip.bin

# Prepare local fip.bin and remote fip.bin store directory
$(LOCAL_BIMAGE): fip-bin remote-boot

fip-bin:
	$(Q)echo "LOG: Building $(LOCAL_KIMAGE)"
	$(Q)mkdir -p $(IMAGE_BUILD); cd $(IMAGE_BUILD); $(BSP_DIR)/tools/fip-bin.sh

# Prepare local boot.sd and remote boot.sd store directory
$(LOCAL_KIMAGE): boot-sd remote-boot

boot-sd:
	$(Q)echo "LOG: Building $(LOCAL_KIMAGE)"
	$(Q)mkdir -p $(IMAGE_BUILD); cd $(IMAGE_BUILD); $(BSP_DIR)/tools/boot-sd.sh

remote-boot: FORCE
	$(Q)echo "LOG: Mounting from remote /dev/mmcblk0p1 to /media/boot/"
	$(Q)$(SSH_CMD) -t "mkdir -p /media/boot; grep -q /media/boot /proc/mounts || mount /dev/mmcblk0p1 /media/boot/" || true

PHONY += fip-bin boot-sd remote-boot

# Put all images together to one SD Card image, you must build and save the sub images manually
IMAGE_BIN = $(IMAGE_BUILD)/tiny-riscv-box.img
IMAGE_MODULES ?= hello,8723du

prepare-rootfs: root-dir
	$(Q)make root-dir-install-system
	$(Q)make root-rd

prepare-modules: root-dir
	$(Q)make modules-install
	$(Q)make modules-install m=$(IMAGE_MODULES)
	$(Q)make root-rd

prepare-uboot: uboot-save
prepare-kernel: kernel-save
prepare-dtb: prepare-kernel

prepare-image: $(addprefix prepare-,uboot kernel rootfs modules)

clean-image:
	$(Q)echo "LOG: Removing $(IMAGE_BIN) ..."
	$(Q)rm -rf $(IMAGE_BIN)

post-image: $(IMAGE_BIN)

$(IMAGE_BIN):
	$(Q)echo "LOG: Building $(IMAGE_BIN) ..."
	$(Q)mkdir -p $(IMAGE_BUILD); cd $(IMAGE_BUILD); $(BSP_DIR)/tools/post-image.sh

burn-image: $(IMAGE_BIN)
	$(Q)echo "LOG: Burning $(IMAGE_BIN) ..."
	$(Q)if [ -z "$(SD_SIZE)" -o -z "$(SD_CARD)" ]; then \
	  echo "ERR: Please configure SD_CARD and SD_SIZE in $(BOARD_LABCONFIG) with these commands:"; \
	  echo ""; \
	  echo "     $$ make local-config SD_CARD=/path/to/your-sd-card"; \
	  echo "     $$ lsblk -dbno size /path/to/your-sd-card"; \
	  echo "     $$ make local-config SD_SIZE=the-above-bytes-of-your-sd-card"; \
	  echo ""; \
	  false; \
	fi
	$(Q)SD_IMAGE=$(IMAGE_BIN) SD_SIZE=$(SD_SIZE) SD_CARD=$(SD_CARD) $(BSP_DIR)/tools/burn-image.sh

PHONY += post-image burn-image clean-image $(addprefix prepare-,uboot kernel rootfs modules image)
