#
# Core Makefile
#

TOP_DIR = $(CURDIR)

USER ?= $(shell whoami)

BOARD_CONFIG = $(shell cat $(TOP_DIR)/.board_config 2>/dev/null)
PLUGIN_CONFIG = $(shell cat $(TOP_DIR)/.plugin_config 2>/dev/null)
MODULE_CONFIG = $(shell cat $(TOP_DIR)/.module_config 2>/dev/null)

board ?= $(b)
B ?= $(board)
ifeq ($(B),)
  ifeq ($(BOARD_CONFIG),)
    BOARD = versatilepb
  else
    BOARD ?= $(BOARD_CONFIG)
  endif
else
    BOARD := $(B)
endif

plugin ?= $(p)
P ?= $(plugin)
ifeq ($(P),)
  ifneq ($(PLUGIN_CONFIG),)
    PLUGIN ?= $(PLUGIN_CONFIG)
  endif
else
  PLUGIN := $(P)
  _plugin := $(PLUGIN)
endif

TOOL_DIR = $(TOP_DIR)/tools/
BOARDS_DIR = $(TOP_DIR)/boards
BOARD_DIR = $(BOARDS_DIR)/$(BOARD)/
TFTPBOOT = $(TOP_DIR)/tftpboot/

PREBUILT_DIR = $(TOP_DIR)/prebuilt/
PREBUILT_TOOLCHAINS = $(PREBUILT_DIR)/toolchains/
PREBUILT_ROOT = $(PREBUILT_DIR)/root/
PREBUILT_KERNEL = $(PREBUILT_DIR)/kernel/
PREBUILT_BIOS = $(PREBUILT_DIR)/bios/
PREBUILT_UBOOT = $(PREBUILT_DIR)/uboot/

ifneq ($(BOARD),)
  include $(BOARD_DIR)/Makefile
endif

_BIMAGE := $(BIMAGE)
_KIMAGE := $(KIMAGE)
_ROOTFS := $(ROOTFS)

QEMU_GIT ?= https://github.com/qemu/qemu.git
QEMU_SRC ?= $(TOP_DIR)/qemu/

UBOOT_GIT ?= https://github.com/u-boot/u-boot.git
UBOOT_SRC ?= $(TOP_DIR)/u-boot/

KERNEL_GIT ?= https://github.com/tinyclub/linux-stable.git
# git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_SRC ?= $(TOP_DIR)/linux-stable/

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
ROOT_GIT ?= https://github.com/buildroot/buildroot
ROOT_SRC ?= $(TOP_DIR)/buildroot/

QEMU_OUTPUT = $(TOP_DIR)/output/$(XARCH)/qemu/
UBOOT_OUTPUT = $(TOP_DIR)/output/$(XARCH)/uboot-$(UBOOT)-$(BOARD)/
KERNEL_OUTPUT = $(TOP_DIR)/output/$(XARCH)/linux-$(LINUX)-$(BOARD)/
ROOT_OUTPUT = $(TOP_DIR)/output/$(XARCH)/buildroot-$(CPU)/

CCPATH ?= $(ROOT_OUTPUT)/host/usr/bin/
TOOLCHAIN = $(PREBUILT_TOOLCHAINS)/$(XARCH)

HOST_CPU_THREADS = $(shell grep processor /proc/cpuinfo | wc -l)

ifneq ($(BIOS),)
  BIOS_ARG = -bios $(BIOS)
endif

EMULATOR = qemu-system-$(XARCH) $(BIOS_ARG)

# prefer new binaries to the prebuilt ones
# PBK = prebuilt kernel; PBR = prebuilt rootfs; PBD= prebuilt dtb

# TODO: kernel defconfig for $ARCH with $LINUX
LINUX_DTB    = $(KERNEL_OUTPUT)/$(ORIDTB)
LINUX_KIMAGE = $(KERNEL_OUTPUT)/$(ORIIMG)
LINUX_UKIMAGE = $(KERNEL_OUTPUT)/$(UORIIMG)
ifeq ($(LINUX_KIMAGE),$(wildcard $(LINUX_KIMAGE)))
  PBK ?= 0
else
  PBK = 1
endif
ifeq ($(LINUX_DTB),$(wildcard $(LINUX_DTB)))
  PBD ?= 0
else
  PBD = 1
endif

ifneq ($(_BIMAGE),)
  PREBUILT_UBOOTDIR ?= $(shell dirname $(_BIMAGE))
endif
ifneq ($(_KIMAGE),)
  PREBUILT_KERNELDIR ?= $(shell dirname $(_KIMAGE))
endif
ifneq ($(_ROOTFS),)
  PREBUILT_ROOTDIR ?= $(shell dirname $(_ROOTFS))
endif

KIMAGE ?= $(LINUX_KIMAGE)
UKIMAGE ?= $(LINUX_UKIMAGE)
DTB     ?= $(LINUX_DTB)
ifeq ($(PBK),0)
  KIMAGE = $(LINUX_KIMAGE)
  UKIMAGE = $(LINUX_UKIMAGE)
endif
ifeq ($(PBD),0)
  DTB = $(LINUX_DTB)
endif

# Uboot image
UBOOT_BIMAGE = $(UBOOT_OUTPUT)/u-boot
ifeq ($(UBOOT_BIMAGE),$(wildcard $(UBOOT_BIMAGE)))
  PBU ?= 0
else
  PBU = 1
endif

ifeq ($(UBOOT_BIMAGE),$(wildcard $(UBOOT_BIMAGE)))
  U ?= 1
else
  ifeq ($(PREBUILT_UBOOTDIR)/u-boot,$(wildcard $(PREBUILT_UBOOTDIR)/u-boot))
    U ?= 1
  else
    U = 0
  endif
endif

BIMAGE ?= $(UBOOT_BIMAGE)
ifeq ($(PBU),0)
  BIMAGE = $(UBOOT_BIMAGE)
endif

ifneq ($(U),0)
  KIMAGE = $(BIMAGE)
endif

# TODO: buildroot defconfig for $ARCH

ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
BUILDROOT_UROOTFS = $(ROOT_OUTPUT)/images/rootfs.cpio.uboot
BUILDROOT_HROOTFS = $(ROOT_OUTPUT)/images/rootfs.$(FSTYPE)
BUILDROOT_ROOTFS = $(ROOT_OUTPUT)/images/rootfs.cpio.gz

PREBUILT_ROOTDIR ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/
PREBUILT_KERNELDIR ?= $(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/
PREBUILT_UBOOTDIR ?= $(PREBUILT_UBOOT)/$(XARCH)/$(BOARD)/$(UBOOT)/$(LINUX)

PBR ?= 0
_PBR := $(PBR)

PREBUILT_ROOTFS ?= $(PREBUILT_ROOTDIR)/rootfs.cpio.gz
ROOTDIR ?= $(PREBUILT_ROOTDIR)/rootfs

ifeq ($(_PBR), 0)
  ifeq ($(BUILDROOT_ROOTFS),$(wildcard $(BUILDROOT_ROOTFS)))
    ROOTDIR = $(ROOT_OUTPUT)/target/
    PREBUILT_ROOTFS = $(ROOTFS)
  else
    ifeq ($(PREBUILT_ROOTFS),$(wildcard $(PREBUILT_ROOTFS)))
      PBR = 1
    endif
  endif
endif

ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    ROOTFS ?= $(BUILDROOT_ROOTFS)
  endif
else
  ROOTFS = $(UROOTFS)
endif

HD = 0
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  HD = 1
endif
ifeq ($(findstring /dev/hda,$(ROOTDEV)),/dev/hda)
  HD = 1
endif
ifeq ($(findstring /dev/mmc,$(ROOTDEV)),/dev/mmc)
  HD = 1
endif

ifeq ($(PBR),0)
  ROOTDIR ?= $(ROOT_OUTPUT)/target/
  ifeq ($(U),0)
    ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
      ROOTFS = $(BUILDROOT_ROOTFS)
    endif
  else
    ROOTFS = $(BUILDROOT_UROOTFS)
  endif

  ifeq ($(HD),1)
    HROOTFS = $(BUILDROOT_HROOTFS)
  endif
endif

# TODO: net driver for $BOARD
#NET = " -net nic,model=smc91c111,macaddr=DE:AD:BE:EF:3E:03 -net tap"
NET =  -net nic,model=$(NETDEV) -net tap

MACADDR_TOOL = $(TOP_DIR)/tools/qemu/macaddr.sh
RANDOM_MACADDR = $(shell $(MACADDR_TOOL))
ifeq ($(NETDEV), virtio)
  NET += -device virtio-net-device,netdev=net0,mac=$(RANDOM_MACADDR) -netdev tap,id=net0
endif

ifeq ($(SMP),)
  SMP = 1
endif

# Common
ROUTE = $(shell ifconfig br0 | grep "inet addr" | cut -d':' -f2 | cut -d' ' -f1)

SERIAL ?= ttyS0
CONSOLE?= tty0
RDINIT ?= /linuxrc

CMDLINE = route=$(ROUTE)
ifeq ($(findstring /dev/null,$(ROOTDEV)),/dev/null)
  CMDLINE += rdinit=$(RDINIT)
else
  CMDLINE += root=$(ROOTDEV)
endif
CMDLINE += $(XKCLI)

TMP = $(shell bash -c 'echo $$(($$RANDOM%230+11))')
IP = $(shell echo $(ROUTE)END | sed -e 's/\.\([0-9]*\)END/.$(TMP)/g')

ifeq ($(ROOTDEV),/dev/nfs)
  CMDLINE += nfsroot=$(ROUTE):$(ROOTDIR) ip=$(IP)
endif

# For debug
BOARD_TOOL=${TOOL_DIR}/board/show.sh
export GREP_COLOR=32;40
FILTER   ?= ^[ [\./_a-z0-9-]* \]|^ *[\_a-zA-Z0-9]* *
# all: 0, plugin: 1, noplugin: 2
BTYPE    ?= ^_BASE|^_PLUGIN

board: board-save plugin-save
	@find $(BOARDS_DIR)/$(BOARD) -maxdepth 3 -name "Makefile" -exec egrep -H "$(BTYPE)" {} \; \
		| sort -t':' -k2 | cut -d':' -f1 | xargs -i $(BOARD_TOOL) {} $(_plugin) \
		| egrep -v "/module" \
		| sed -e "s%$(TOP_DIR)/boards/\(.*\)/Makefile%\1%g" \
		| sed -e "s/[[:digit:]]\{2,\}\t/  /g;s/[[:digit:]]\{1,\}\t/ /g" \
		| egrep -v " *_BASE| *_PLUGIN| *#" | egrep --colour=auto "$(FILTER)"

board-clean:
	@rm $(TOP_DIR)/.board_config

board-save:
ifneq ($(BOARD),)
  ifeq ($(board),)
	@echo $(BOARD) > $(TOP_DIR)/.board_config
  endif
endif

plugin-save:
ifneq ($(PLUGIN),)
  ifeq ($(plugin),)
	@echo $(PLUGIN) > $(TOP_DIR)/.plugin_config
  endif
endif

plugin-clean:
	@rm $(TOP_DIR)/.plugin_config

plugin: plugin-save
	@echo $(PLUGIN)

plugin-list:
	@find $(BOARDS_DIR) -maxdepth 3 -name ".plugin" | xargs -i dirname {} | xargs -i basename {} | cat -n

plugin-list-full:
	@find $(BOARDS_DIR) -maxdepth 3 -name ".plugin" | xargs -i dirname {} | cat -n

p: plugin
p-l: plugin-list
p-l-f: plugin-list-full
p-c: plugin-clean

list:
	@make -s board BOARD= FILTER="^ *ARCH |^[ [\./a-z0-9-]* \]|^ *CPU|^ *LINUX|^ *ROOTDEV"

list-base:
	@make -s list BTYPE="^_BASE"

list-plugin:
	@make -s list BTYPE="^_PLUGIN"

list-full:
	@make -s board BOARD=

l: list
l-b: list-base
l-p: list-plugin
l-f: list-full

# Please makesure docker, git are installed
# TODO: Use gitsubmodule instead, ref: http://tinylab.org/nodemcu-kickstart/
uboot-source:
	git submodule update --init --remote u-boot

qemu-source:
	git submodule update --init --remote qemu

kernel-source:
	git submodule update --init --remote linux-stable

root-source:
	git submodule update --init --remote buildroot

prebuilt-images:
	git submodule update --init --remote prebuilt

source: prebuilt-images kernel-source root-source

core-source: source uboot-source

all-source: source uboot-source qemu-source

# Qemu

QCO ?= 1
ifneq ($(QEMU),)
ifneq ($(QCO),0)
  EMULATOR_CHECKOUT = emulator-checkout
endif
endif
emulator-checkout:
	cd $(QEMU_SRC) && git checkout -f $(QEMU) && git clean -fdx && cd $(TOP_DIR)

QEMU_BASE=$(shell bash -c 'V=${QEMU}; echo $${V%.*}')

QPD_BASE=$(TOP_DIR)/patch/qemu/$(QEMU_BASE)/
QPD=$(TOP_DIR)/patch/qemu/$(QEMU)/
QP ?= 1

emulator-patch: $(EMULATOR_CHECKOUT)
ifeq ($(QPD_BASE),$(wildcard $(QPD_BASE)))
	-$(foreach p,$(shell ls $(QPD_BASE)),$(shell echo patch -r- -N -l -d $(QEMU_SRC) -p1 \< $(QPD_BASE)/$p\;))
endif
ifeq ($(QPD),$(wildcard $(QPD)))
	-$(foreach p,$(shell ls $(QPD)),$(shell echo patch -r- -N -l -d $(QEMU_SRC) -p1 \< $(QPD)/$p\;))
endif

ifneq ($(QEMU),)
ifneq ($(QP),0)
  EMULATOR_PATCH = emulator-patch
endif
endif

emulator: $(EMULATOR_PATCH)
	mkdir -p $(QEMU_OUTPUT)
	cd $(QEMU_OUTPUT) && $(QEMU_SRC)/configure --target-list=$(XARCH)-softmmu --disable-kvm && cd $(TOP_DIR)
	make -C $(QEMU_OUTPUT) -j$(HOST_CPU_THREADS)

# Toolchains

toolchain:
	make -C $(TOOLCHAIN)

toolchain-clean:
	make -C $(TOOLCHAIN) clean

# Rootfs

RCO ?= 0
BUILDROOT ?= master
ifeq ($(RCO),1)
  ROOT_CHECKOUT = root-checkout
endif

# Configure Buildroot
root-checkout:
	cd $(ROOT_SRC) && git checkout -f $(BUILDROOT) && git clean -fdx && cd $(TOP_DIR)

ROOT_CONFIG_FILE = buildroot_$(CPU)_defconfig
ROOT_CONFIG_PATH = $(BOARD_DIR)/$(ROOT_CONFIG_FILE)

root-defconfig: $(ROOT_CONFIG_PATH) $(ROOT_CHECKOUT)
	mkdir -p $(ROOT_OUTPUT)
	cp $(ROOT_CONFIG_PATH) $(ROOT_SRC)/configs/
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) $(ROOT_CONFIG_FILE)

root-menuconfig:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) menuconfig

# Build Buildroot
ROOT_INSTALL_TOOL = $(TOOL_DIR)/rootfs/install.sh
ROOT_REBUILD_TOOL = $(TOOL_DIR)/rootfs/rebuild.sh

# Install kernel modules?
KM ?= 1

ifeq ($(KM), 1)
  KERNEL_MODULES_INSTALL = module-install
endif

root-build:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) -j$(HOST_CPU_THREADS)

# Install system/ to ROOTDIR
root-install:
	ROOTDIR=$(ROOTDIR) $(ROOT_INSTALL_TOOL)

root-rebuild:
ifeq ($(PBR), 1)
	ROOTDIR=$(ROOTDIR) USER=$(USER) $(ROOT_REBUILD_TOOL)
else
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC)
	chown -R $(USER):$(USER) $(ROOT_OUTPUT)/target
  ifeq ($(U),1)
    ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	make $(BUILDROOT_UROOTFS)
    endif
  endif
endif

ROOT ?= rootdir
ifeq ($(_PBR), 0)
  ifneq ($(BUILDROOT_ROOTFS),$(wildcard $(BUILDROOT_ROOTFS)))
    ROOT = root-build
  endif
endif

root: $(ROOT) root-install $(KERNEL_MODULES_INSTALL) root-rebuild

# Kernel modules

TOP_MODULE_DIR = $(TOP_DIR)/modules/
ifneq ($(PLUGIN),)
  PLUGIN_MODULE_DIR = $(TOP_DIR)/boards/$(PLUGIN)/modules/
endif

module ?= $(m)
ifeq ($(module),all)
  module := $(shell find $(TOP_MODULE_DIR) $(PLUGIN_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | xargs -i basename {} | tr '\n' ',')
endif

ifneq ($(module),)
  M := $(shell find $(TOP_MODULE_DIR) $(PLUGIN_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | grep "/$(module)$$")
else
  ifneq ($(MODULE_CONFIG),)
    M ?= $(MODULE_CONFIG)
  endif
endif

kernel-modules-save:
ifneq ($(M),)
	@echo $(M) > $(TOP_DIR)/.module_config
endif

MODULES_EN=$(shell [ -f $(KERNEL_OUTPUT)/.config ] && grep -q MODULES=y $(KERNEL_OUTPUT)/.config; echo $$?)

kernel-modules: kernel-modules-save
ifeq ($(MODULES_EN), 0)
	make kernel KTARGET=modules M=$M
endif

kernel-modules-list:
	@find $(TOP_MODULE_DIR) $(PLUGIN_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | xargs -i basename {} | cat -n

kernel-modules-list-full:
	@find $(TOP_MODULE_DIR) $(PLUGIN_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | cat -n

M_I_ROOT ?= rootdir
ifeq ($(PBR), 0)
  ifneq ($(BUILDROOT_ROOTFS),$(wildcard $(BUILDROOT_ROOTFS)))
    M_I_ROOT = root-build
  endif
endif

kernel-modules-install: kernel-modules $(M_I_ROOT)
ifeq ($(MODULES_EN), 0)
	make kernel KTARGET=modules_install INSTALL_MOD_PATH=$(ROOTDIR) M=$M
endif

KERNEL_MODULE_CLEAN = $(TOP_DIR)/tools/module/clean.sh
kernel-modules-clean:
	$(KERNEL_MODULE_CLEAN) $(KERNEL_OUTPUT) $M
	rm -rf $(TOP_DIR)/.module_config

module: kernel-modules plugin-save
module-list: kernel-modules-list plugin-save
module-list-full: kernel-modules-list-full plugin-save
module-install: kernel-modules-install
module-clean: kernel-modules-clean

modules: FORCE
	@$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nBuilding module: $(m) ...\n" && make module m=$(m);) echo '')

modules-install: FORCE
	@$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nInstalling module: $(m) ...\n" && make module-install m=$(m);) echo '')

modules-clean: FORCE
	@$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nCleaning module: $(m) ...\n" && make module-clean m=$(m);) echo '')

m: module
m-l: module-list
m-l-f: module-list-full
m-i: module-install
m-c: module-clean

ms: modules
ms-i: modules-install
ms-c: modules-clean

# Configure Kernel
kernel-checkout:
	cd $(KERNEL_SRC) && git checkout -f $(LINUX) && git clean -fdx && cd $(TOP_DIR)

KCO ?= 0
LINUX ?= master
ifeq ($(KCO),1)
  KERNEL_CHECKOUT = kernel-checkout
endif

KERNEL_PATCH_TOOL = $(TOP_DIR)/tools/kernel/patch.sh

KP ?= 0
kernel-patch:
	-$(KERNEL_PATCH_TOOL) $(BOARD) $(LINUX) $(KERNEL_SRC) $(KERNEL_OUTPUT)

ifeq ($(KP),1)
  KERNEL_PATCH = kernel-patch
endif

KERNEL_CONFIG_FILE = linux_$(LINUX)_defconfig
KERNEL_CONFIG_PATH = $(BOARD_DIR)/$(KERNEL_CONFIG_FILE)
KERNEL_CONFIG_PATH_TMP = $(KERNEL_SRC)/arch/$(ARCH)/configs/$(KERNEL_CONFIG_FILE)

kernel-defconfig:  $(KERNEL_CHECKOUT) $(KERNEL_PATCH)
	mkdir -p $(KERNEL_OUTPUT)
	cp $(KERNEL_CONFIG_PATH) $(KERNEL_CONFIG_PATH_TMP)
	make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) $(KERNEL_CONFIG_FILE)

kernel-oldconfig:
	make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) oldnoconfig
	#make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) silentoldconfig

kernel-menuconfig:
	make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) menuconfig

# Build Kernel

KERNEL_FEATURE_TOOL = $(TOP_DIR)/tools/kernel/feature.sh

kernel-feature:
	@$(KERNEL_FEATURE_TOOL) $(BOARD) $(LINUX) $(KERNEL_SRC) $(KERNEL_OUTPUT) "$(FEATURE)"

IMAGE = $(shell basename $(ORIIMG))

ifeq ($(U),1)
  IMAGE=uImage
endif

# 2.6 kernel doesn't support DTB?
ifeq ($(findstring v2.6.,$(LINUX)),v2.6.)
  ORIDTB=
endif

ifneq ($(ORIDTB),)
  DTBS=dtbs
endif

KTARGET ?= $(IMAGE) $(DTBS)

ifeq ($(findstring /dev/null,$(ROOTDEV)),/dev/null)
  K_ROOT_DIR = rootdir
  KOPTS = CONFIG_INITRAMFS_SOURCE=$(ROOTDIR)
endif

KMAKE_CMD  = make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC)
KMAKE_CMD += ARCH=$(ARCH) LOADADDR=$(KRN_ADDR) CROSS_COMPILE=$(CCPRE) V=$(V) $(KOPTS)
KMAKE_CMD += -j$(HOST_CPU_THREADS) $(KTARGET)

kernel: $(K_ROOT_DIR)
	PATH=$(PATH):$(CCPATH) $(KMAKE_CMD)

# Configure Uboot
uboot-checkout:
	cd $(UBOOT_SRC) && git checkout -f $(UBOOT) && git clean -fdx && cd $(TOP_DIR)

BCO ?= 0
UBOOT ?= master
ifeq ($(BCO),1)
  UBOOT_CHECKOUT = uboot-checkout
endif

UPD_BOARD=$(TOP_DIR)/boards/$(BOARD)/patch/uboot/$(UBOOT)/
UPD=$(TOP_DIR)/patch/uboot/$(UBOOT)/

UP ?= 1

ROOTDIR ?= -
KRN_ADDR ?= -
RDK_ADDR ?= -
DTB_ADDR ?= -
UCFG_DIR = $(TOP_DIR)/u-boot/include/configs/

ifneq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  RDK_ADDR = -
endif
ifeq ($(ORIDTB),)
  DTB_ADDR = -
endif

UBOOT_CONFIG_TOOL = $(TOOL_DIR)/uboot/config.sh

uboot-patch:
ifneq ($(UCONFIG),)
	$(UBOOT_CONFIG_TOOL) $(IP) $(ROUTE) $(ROOTDEV) $(ROOTDIR) $(KRN_ADDR) $(RDK_ADDR) $(DTB_ADDR) $(UCFG_DIR)/$(UCONFIG)
endif
ifeq ($(UPD_BOARD),$(wildcard $(UPD_BOARD)))
	cp -r $(UPD_BOARD)/* $(UPD)/
endif
ifeq ($(UPD),$(wildcard $(UPD)))
	-$(foreach p,$(shell ls $(UPD)),$(shell echo patch -r- -N -l -d $(UBOOT_SRC) -p1 \< $(UPD)/$p\;))
endif

ifeq ($(UP),1)
  UBOOT_PATCH = uboot-patch
endif

UBOOT_CONFIG_FILE = uboot_$(UBOOT)_defconfig
UBOOT_CONFIG_PATH = $(BOARD_DIR)/$(UBOOT_CONFIG_FILE)

uboot-defconfig: $(UBOOT_CONFIG_PATH) $(UBOOT_CHECKOUT) $(UBOOT_PATCH)
	mkdir -p $(UBOOT_OUTPUT)
	cp $(UBOOT_CONFIG_PATH) $(UBOOT_SRC)/configs/
	make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) $(UBOOT_CONFIG_FILE)

uboot-menuconfig:
	make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) menuconfig

# Build Uboot
uboot:
	PATH=$(PATH):$(CCPATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(HOST_CPU_THREADS)

# Checkout kernel and Rootfs
checkout: kernel-checkout root-checkout

# Config Kernel and Rootfs
config: root-defconfig kernel-defconfig

# Build Kernel and Rootfs
build: root kernel

# Save the built images
root-save:
	mkdir -p $(PREBUILT_ROOTDIR)/
	-cp $(BUILDROOT_ROOTFS) $(PREBUILT_ROOTDIR)/

kernel-save:
	mkdir -p $(PREBUILT_KERNELDIR)
	-cp $(LINUX_KIMAGE) $(PREBUILT_KERNELDIR)
ifeq ($(LINUX_UKIMAGE),$(wildcard $(LINUX_UKIMAGE)))
	-cp $(LINUX_UKIMAGE) $(PREBUILT_KERNELDIR)
endif
ifeq ($(LINUX_DTB),$(wildcard $(LINUX_DTB)))
	-cp $(LINUX_DTB) $(PREBUILT_KERNELDIR)
endif

uboot-save:
	mkdir -p $(PREBUILT_UBOOTDIR)
	-cp $(UBOOT_BIMAGE) $(PREBUILT_UBOOTDIR)

uboot-saveconfig: uconfig-save

uconfig-save:
	-PATH=$(PATH):$(CCPATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) savedefconfig
	if [ -f $(UBOOT_OUTPUT)/defconfig ]; \
	then cp $(UBOOT_OUTPUT)/defconfig $(BOARD_DIR)/uboot_$(UBOOT)_defconfig; \
	else cp $(UBOOT_OUTPUT)/.config $(BOARD_DIR)/uboot_$(UBOOT)_defconfig; fi

# kernel < 2.6.36 doesn't support: `make savedefconfig`
kernel-saveconfig: kconfig-save

kconfig-save:
	-PATH=$(PATH):$(CCPATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) savedefconfig
	if [ -f $(KERNEL_OUTPUT)/defconfig ]; \
	then cp $(KERNEL_OUTPUT)/defconfig $(BOARD_DIR)/linux_$(LINUX)_defconfig; \
	else cp $(KERNEL_OUTPUT)/.config $(BOARD_DIR)/linux_$(LINUX)_defconfig; fi

root-saveconfig: rconfig-save

rconfig-save:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) -j$(HOST_CPU_THREADS) savedefconfig
	if [ -f $(ROOT_OUTPUT)/defconfig ]; \
	then cp $(ROOT_OUTPUT)/defconfig $(BOARD_DIR)/buildroot_$(CPU)_defconfig; \
	else cp $(ROOT_OUTPUT)/.config $(BOARD_DIR)/buildroot_$(CPU)_defconfig; fi


save: root-save kernel-save rconfig-save kconfig-save

# Graphic output? we prefer Serial port ;-)
G ?= 0
MACH ?= $(shell echo $(BOARD) | tr '/' '\n' | tail -1 | cut -d'_' -f1)

# Sharing with the 9p virtio protocol
SHARE ?= 0
SHARE_DIR ?= $(TOP_DIR)/hostshare/
SHARE_TAG ?= hostshare
ifneq ($(SHARE),0)
  SHARE_OPT ?= -fsdev local,path=$(SHARE_DIR),security_model=passthrough,id=fsdev0 -device virtio-9p-device,fsdev=fsdev0,mount_tag=$(SHARE_TAG)
  CMDLINE += sharetag=$(SHARE_TAG) sharedir=/$(shell basename $(SHARE_DIR))
endif

# Shutdown the board if 'poweroff -h/-n' or crash
ifneq ($(TEST_REBOOT),)
  TEST_FINISH = reboot
endif
ifneq ($(findstring reboot,$(TEST_FINISH)),reboot)
  EXIT_ACTION ?= -no-reboot
endif

EMULATOR_OPTS ?= -M $(MACH) -m $(MEM) $(NET) -smp $(SMP) $(XOPTS) -kernel $(KIMAGE) $(EXIT_ACTION)
EMULATOR_OPTS += $(SHARE_OPT)

# Launch Qemu, prefer our own instead of the prebuilt one
BOOT_CMD = PATH=$(QEMU_OUTPUT)/$(ARCH)-softmmu/:$(PATH) sudo $(EMULATOR) $(EMULATOR_OPTS)
ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    BOOT_CMD += -initrd $(ROOTFS)
  endif
  ifeq ($(DTB),$(wildcard $(DTB)))
    BOOT_CMD += -dtb $(DTB)
  endif
  ifeq ($(G),0)
    BOOT_CMD += -append '$(CMDLINE) console=$(SERIAL)'
  else
    BOOT_CMD += -append '$(CMDLINE) console=$(CONSOLE)'
  endif
endif
ifeq ($(findstring /dev/hda,$(ROOTDEV)),/dev/hda)
  BOOT_CMD += -hda $(HROOTFS)
endif
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  BOOT_CMD += -hda $(HROOTFS)
endif
ifeq ($(findstring /dev/mmc,$(ROOTDEV)),/dev/mmc)
  BOOT_CMD += -sd $(HROOTFS)
endif
ifeq ($(G),0)
  BOOT_CMD += -nographic
else
  ifeq ($(G), 2)
    BOOT_CMD += -curses
  endif
endif

D ?= 0
ifeq ($(D),1)
  DEBUG = 1
endif
ifeq ($(DEBUG),1)
  BOOT_CMD += -s -S
endif

rootdir:
ifneq ($(PREBUILT_ROOTDIR)/rootfs,$(wildcard $(PREBUILT_ROOTDIR)/rootfs))
	- mkdir -p $(ROOTDIR) && cd $(ROOTDIR)/ && gunzip -kf ../rootfs.cpio.gz \
		&& sudo cpio -idmv -R $(USER):$(USER) < ../rootfs.cpio >/dev/null 2>&1 && cd $(TOP_DIR)
	chown $(USER):$(USER) -R $(ROOTDIR)
endif

ifeq ($(ROOTDIR),$(PREBUILT_ROOTDIR)/rootfs)
  BOOT_ROOT_DIR = rootdir
endif

rootdir-clean:
ifeq ($(ROOTDIR),$(PREBUILT_ROOTDIR)/rootfs)
	-rm -rf $(ROOTDIR)
endif

ifeq ($(U),1)
ifeq ($(PBR),0)
  UROOTFS_SRC=$(BUILDROOT_ROOTFS)
else
  UROOTFS_SRC=$(PREBUILT_ROOTFS)
endif

$(ROOTFS):
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	mkimage -A $(ARCH) -O linux -T ramdisk -C none -d $(UROOTFS_SRC) $@
endif

$(UKIMAGE):
ifeq ($(PBK),0)
	make kernel KTARGET=uImage
endif

U_ROOT_IMAGE=-
U_DTB_IMAGE=-
U_KERNEL_IMAGE=$(UKIMAGE)
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  U_ROOT_IMAGE=$(ROOTFS)
endif
ifeq ($(DTB),$(wildcard $(DTB)))
  U_DTB_IMAGE=$(DTB)
endif

UBOOT_IMAGES_TOOL=$(TOOL_DIR)/uboot/images.sh

uboot-imgs: $(ROOTFS) $(UKIMAGE)
	$(UBOOT_IMAGES_TOOL) $(U_ROOT_IMAGE) $(U_DTB_IMAGE) $(U_KERNEL_IMAGE) $(TFTPBOOT)

UBOOT_IMGS = uboot-imgs
endif

ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  ifeq ($(PBR),0)
    ifneq ($(BUILDROOT_ROOTFS),$(wildcard $(BUILDROOT_ROOTFS)))
      ROOT_CPIO = root-rebuild
    endif
  else
    ifneq ($(PREBUILT_ROOTFS),$(wildcard $(PREBUILT_ROOTFS)))
      ROOT_CPIO = root-rebuild
    endif
  endif
endif

ROOT_MKFS_TOOL = $(TOOL_DIR)/rootfs/mkfs.sh

root-fs:
ifneq ($(HROOTFS),$(wildcard $(HROOTFS)))
	$(ROOT_MKFS_TOOL) $(ROOTDIR) $(FSTYPE)
endif

ifeq ($(HD),1)
ifneq ($(PBR),0)
  ROOT_FS = root-fs
endif
endif

ifeq ($(findstring prebuilt,$(ROOTFS)),prebuilt)
  ifneq ($(PREBUILT_ROOT),$(wildcard $(PREBUILT_ROOT)))
    PREBUILT = prebuilt-images
  endif
endif

# Test support
TEST_KCLI =
ifneq ($(FEATURE),)
  TEST_KCLI  = feature=$(shell echo $(FEATURE) | tr ' ' ',')
  ifeq ($(findstring module,$(FEATURE)),module)
    TEST_KCLI += module=$(shell echo $(MODULE) | tr ' ' ',')
  endif
endif
ifneq ($(TEST_REBOOT),)
  TEST_KCLI += reboot=$(TEST_REBOOT)
endif
ifneq ($(TEST_FINISH),)
  TEST_KCLI += test_finish=$(TEST_FINISH)
endif
ifneq ($(TEST_CASE),)
  TEST_KCLI += test_case=$(TEST_CASE)
endif

ifeq ($(TEST),1)
  CMDLINE += $(TEST_KCLI)
endif

# ROOTDEV=/dev/nfs for file sharing between guest and host
# SHARE=1 is another method, but only work on some boards

test:
	@make boot TEST=1 ROOTDEV=/dev/nfs

boot: $(PREBUILT) $(BOOT_ROOT_DIR) $(UBOOT_IMGS) $(ROOT_FS) $(ROOT_CPIO)
	$(BOOT_CMD)


# Debug

VMLINUX ?= $(KERNEL_OUTPUT)/vmlinux
GDB_CMD ?= $(CCPRE)gdb --quiet $(VMLINUX)
XTERM_CMD ?= lxterminal --working-directory=$(TOP_DIR) -t "$(GDB_CMD)" -e "$(GDB_CMD)"

debug:
ifeq ($(VMLINUX),$(wildcard $(VMLINUX)))
	@echo "add-auto-load-safe-path $(TOP_DIR)/.gdbinit" > $(HOME)/.gdbinit
	@$(XTERM_CMD) &
	@make -s boot DEBUG=1
else
	@echo "ERROR: No $(VMLINUX) found, please compile with 'make kernel'"
endif

# Allinone
all: config build boot

# Clean up

emulator-clean:
	-make -C $(QEMU_OUTPUT) clean

root-clean:
	-make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) clean

uboot-clean:
	-make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) clean

kernel-clean:
	-make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) clean

clean: emulator-clean root-clean kernel-clean rootdir-clean uboot-clean

emulator-distclean:
	-make -C $(QEMU_OUTPUT) distclean

root-distclean:
	-make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) distclean

uboot-distclean:
	-make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) distclean

kernel-distclean:
	-make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) distclean

GCC_SWITCH_TOOL = $(TOP_DIR)/tools/gcc/switch.sh
gcc:
ifneq ($(GCC),)
	$(GCC_SWITCH_TOOL) $(ARCH) $(GCC)
endif

distclean: emulator-distclean root-distclean kernel-distclean rootdir-distclean uboot-distclean

# Show the variables 
VARS = $(shell cat $(TOP_DIR)/boards/$(BOARD)/Makefile | grep -v "^ *\#" | cut -d'?' -f1 | cut -d'=' -f1 | tr -d ' ')
VARS += FEATURE TFTPBOOT
VARS += ROOTDIR ROOT_SRC ROOT_OUTPUT ROOT_GIT
VARS += KERNEL_SRC KERNEL_OUTPUT KERNEL_GIT UBOOT_SRC UBOOT_OUTPUT UBOOT_GIT
VARS += ROOT_CONFIG_PATH KERNEL_CONFIG_PATH UBOOT_CONFIG_PATH
VARS += IP ROUTE BOOT_CMD

env:
	@echo [ $(BOARD) ]:
	@echo -n " "
	-@echo $(foreach v,$(VARS),"    $(v) = $($(v))\n") | tr -s '/'

ENV_SAVE_TOOL = $(TOOL_DIR)/save-env.sh

env-save:
	@$(ENV_SAVE_TOOL) $(BOARD_DIR)/Makefile "$(VARS)"

help:
	@cat $(TOP_DIR)/README.md


FORCE:
