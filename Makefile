#
# Core Makefile
#

TOP_DIR := $(CURDIR)

USER ?= $(shell whoami)

# Check running host
LAB_ENV_ID=/home/ubuntu/Desktop/lab.desktop
ifneq ($(LAB_ENV_ID),$(wildcard $(LAB_ENV_ID)))
  $(error ERR: Please not try Linux Lab in local host, but use it with Cloud Lab, please refer to 'Run and login the lab' part of README.md)
endif

# Current variables: board, plugin, module
BOARD_CONFIG  := $(shell cat .board_config 2>/dev/null)
PLUGIN_CONFIG := $(shell cat .plugin_config 2>/dev/null)
MODULE_CONFIG := $(shell cat .module_config 2>/dev/null)
MPATH_CONFIG  := $(shell cat .mpath_config 2>/dev/null)

# Verbose logging control
ifeq ($V, 1)
  Q :=
  S :=
else
  S ?= -s
  Q ?= @
endif

# Board config: B/BOARD persistent, b/board temporarily
board ?= $(b)
B ?= $(board)
ifeq ($(B),)
  ifeq ($(BOARD_CONFIG),)
    BOARD := arm/vexpress-a9
  else
    BOARD ?= $(BOARD_CONFIG)
  endif
else
    BOARD := $(B)
endif

# Plugin config: P/PLUGIN persistent, p/plugin temporarily (FIXME: this feature is really required?)
plugin ?= $(p)
P ?= $(plugin)
ifeq ($(P),)
  ifeq ($(origin P), command line)
    PLUGIN :=
  else
    ifneq ($(PLUGIN_CONFIG),)
      PLUGIN ?= $(PLUGIN_CONFIG)
    endif
  endif
else
  PLUGIN := $(P)
endif

# Core directories
TOOL_DIR    := tools
BOARDS_DIR  := boards
BOARD_DIR   := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD)
FEATURE_DIR := feature/linux
TFTPBOOT    := tftpboot

# Search board in basic arch list while board name given without arch specified
BASE_ARCHS := arm aarch64 mipsel ppc i386 x86_64 loongson csky
ifneq ($(BOARD_DIR),$(wildcard $(BOARD_DIR)))
  ARCH := $(shell for arch in $(BASE_ARCHS); do if [ -d $(TOP_DIR)/$(BOARDS_DIR)/$$arch/$(BOARD) ]; then echo $$arch; break; fi; done)
  ifneq ($(ARCH),)
    override BOARD     := $(ARCH)/$(BOARD)
    override BOARD_DIR := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD)
    ifeq ($(filter _boot, $(MAKECMDGOALS)), _boot)
      $(info LOG: Current board is $(BOARD))
    endif
  else
    $(error ERR: $(BOARD) not exist, check available boards in 'make list')
  endif
endif

# Check if it is a plugin
BOARD_PREFIX:= $(subst /,,$(dir $(BOARD)))
PLUGIN_DIR  := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD_PREFIX)
PLUGIN_FLAG := $(PLUGIN_DIR)/.plugin

ifneq ($(PLUGIN_FLAG), $(wildcard $(PLUGIN_FLAG)))
  PLUGIN_DIR:=
  _PLUGIN   := 0
else
  _PLUGIN   := 1
endif

# add board directories
BOARD_ROOT ?= $(BOARD_DIR)/root
BOARD_KERNEL ?= $(BOARD_DIR)/kernel
BOARD_UBOOT ?= $(BOARD_DIR)/uboot
BOARD_QEMU ?= $(BOARD_DIR)/qemu
BOARD_TOOLCHAIN ?= $(BOARD_DIR)/toolchains

# add a standlaone bsp directory
BSP_DIR ?= $(BOARD_DIR)/bsp
BSP_ROOT ?= $(BSP_DIR)/root
BSP_KERNEL ?= $(BSP_DIR)/kernel
BSP_UBOOT ?= $(BSP_DIR)/uboot
BSP_QEMU ?= $(BSP_DIR)/qemu
BSP_TOOLCHAIN ?= $(BSP_DIR)/toolchains
BSP_CONFIG = $(BSP_DIR)/configs

# Support old directory arch
ifeq ($(BSP_DIR),$(wildcard $(BSP_DIR)))
  _BSP_CONFIG := $(BSP_CONFIG)
else
  _BSP_CONFIG := $(BOARD_DIR)
endif

# Get the machine name for qemu-system-$(XARCH)
MACH ?= $(notdir $(BOARD))

# Prebuilt directories (in standalone prebuilt repo, github.com/tinyclub/prebuilt)
PREBUILT_DIR        := $(TOP_DIR)/prebuilt
PREBUILT_TOOLCHAINS := $(PREBUILT_DIR)/toolchains
PREBUILT_ROOT       := $(PREBUILT_DIR)/root
PREBUILT_KERNEL     := $(PREBUILT_DIR)/kernel
PREBUILT_BIOS       := $(PREBUILT_DIR)/bios
PREBUILT_UBOOT      := $(PREBUILT_DIR)/uboot
PREBUILT_QEMU       := $(PREBUILT_DIR)/qemu

# Core source: remote and local
QEMU_GIT ?= https://github.com/qemu/qemu.git
_QEMU_SRC ?= qemu
QEMU_SRC ?= $(_QEMU_SRC)

UBOOT_GIT ?= https://github.com/u-boot/u-boot.git
_UBOOT_SRC ?= u-boot
UBOOT_SRC ?= $(_UBOOT_SRC)

KERNEL_GIT ?= https://github.com/tinyclub/linux-stable.git
# git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
_KERNEL_SRC = linux-stable
KERNEL_SRC ?= $(_KERNEL_SRC)

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
ROOT_GIT ?= https://github.com/buildroot/buildroot
_ROOT_SRC ?= buildroot
ROOT_SRC ?= $(_ROOT_SRC)

_LINUX=$(LINUX)
KERNEL_ABS_SRC := $(TOP_DIR)/$(KERNEL_SRC)
ROOT_ABS_SRC   := $(TOP_DIR)/$(ROOT_SRC)
UBOOT_ABS_SRC  := $(TOP_DIR)/$(UBOOT_SRC)
QEMU_ABS_SRC   := $(TOP_DIR)/$(QEMU_SRC)

BOARD_MAKEFILE      := $(BOARD_DIR)/Makefile

# Common functions

## Version specific variable
## GCC = GCC[LINUX_v2.6.12]
##
## GCC = 4.4
## LINUX = v2.6.35
## GCC[LINUX_v2.6.35] = 4.3
##
## A=$(call __v,GCC,LINUX), 4.3
## B=$(call _v,GCC,LINUX),  4.4 if LINUX is not v2.6.35

define __v
$($(1)[$(2)_$($(2))])
endef

define _v
$(if $(call __v,$1,$2),$(call __v,$1,$2),$($1))
endef
#$(shell a="$(call __v,$1,$2)"; if [ -n "$$a" ]; then echo "$$a"; else echo $($1); fi)

# Loading board configurations
ifneq ($(BOARD),)
  include $(BOARD_MAKEFILE)
endif

# board specific src submodule parent
ifeq ($(_PLUGIN), 1)
  BSP_SROOT = $(PLUGIN_DIR)
else
  BSP_SROOT = $(BSP_DIR)
endif

# Verify LINUX argument
KERNEL_SPATH := $(subst $(BSP_SROOT)/,,$(KERNEL_SRC))
ifneq ($(LINUX),)
  ifeq ($(BSP_KERNEL), $(wildcard $(BSP_KERNEL)))
    LINUX_LIST ?= $(shell ls $(BSP_KERNEL))
  endif
  ifneq ($(LINUX_LIST),)
    ifneq ($(filter $(LINUX), $(LINUX_LIST)), $(LINUX))
      $(error Supported LINUX list: $(LINUX_LIST))
    endif
  endif
endif

# Strip prefix of LINUX to get the real version, e.g. XXX-v3.10, XXX may be the customized repo name
ifneq ($(_KERNEL_SRC), $(KERNEL_SRC))
  _LINUX := $(subst $(shell basename $(KERNEL_SRC))-,,$(LINUX))
  KERNEL_ABS_SRC := $(KERNEL_SRC)
endif

# Verify ROOT argument
ROOT_SPATH := $(subst $(BSP_SROOT)/,,$(ROOT_SRC))
ifneq ($(ROOT),)
  ifeq ($(BSP_ROOT), $(wildcard $(BSP_ROOT)))
    ROOT_LIST ?= $(shell ls $(BSP_ROOT))
  endif
  ifneq ($(ROOT_LIST),)
    ifneq ($(filter $(ROOT), $(ROOT_LIST)), $(ROOT))
      $(error Supported ROOT list: $(ROOT_LIST))
    endif
  endif
endif

ifneq ($(_ROOT_SRC), $(ROOT_SRC))
  ROOT_ABS_SRC := $(ROOT_SRC)
endif

# Verify UBOOT argument
UBOOT_SPATH := $(subst $(BSP_SROOT)/,,$(UBOOT_SRC))
ifneq ($(UBOOT),)
  ifeq ($(BSP_UBOOT), $(wildcard $(BSP_UBOOT)))
    UBOOT_LIST ?= $(shell ls $(BSP_UBOOT))
  endif
  ifneq ($(UBOOT_LIST),)
    ifneq ($(filter $(UBOOT), $(UBOOT_LIST)), $(UBOOT))
      $(error Supported UBOOT list: $(UBOOT_LIST))
    endif
  endif
endif

ifneq ($(_UBOOT_SRC), $(UBOOT_SRC))
  UBOOT_ABS_SRC := $(UBOOT_SRC)
endif

# Verify QEMU argument
QEMU_SPATH := $(subst $(BSP_SROOT)/,,$(QEMU_SRC))
ifneq ($(QEMU),)
  ifeq ($(BSP_QEMU), $(wildcard $(BSP_QEMU)))
    QEMU_LIST ?= $(shell ls $(BSP_QEMU))
  endif
  # If Linux version specific qemu list defined, use it
   _QEMU_LIST=$(call __v,QEMU_LIST,LINUX)
  ifneq ($(_QEMU_LIST),)
    override QEMU_LIST := $(_QEMU_LIST)
  endif
  ifneq ($(QEMU_LIST),)
    ifneq ($(filter $(QEMU), $(QEMU_LIST)), $(QEMU))
      $(error Supported QEMU list: $(QEMU_LIST))
    endif
  endif
endif

ifneq ($(_QEMU_SRC), $(QEMU_SRC))
  QEMU_ABS_SRC := $(QEMU_SRC)
endif

# Kernel features configuration, e.g. kft, gcs ...
f ?= $(feature)
F ?= $(f)
FEATURES ?= $(F)
FEATURE ?= $(FEATURES)
ifneq ($(FEATURE),)
  FEATURE_ENVS := $(foreach f, $(shell echo $(FEATURE) | tr ',' ' '), \
			$(shell if [ -f $(FEATURE_DIR)/$(f)/$(LINUX)/env.$(XARCH).$(MACH) ]; then \
			echo $(FEATURE_DIR)/$(f)/$(LINUX)/env.$(XARCH).$(MACH); \
			elif [ -f $(FEATURE_DIR)/$(f)/$(LINUX)/env.$(MACH) ]; then \
			echo $(FEATURE_DIR)/$(f)/$(LINUX)/env.$(MACH); fi))

  ifneq ($(FEATURE_ENVS),)
    include $(FEATURE_ENVS)
  endif
endif

# Core images: qemu, bootloader, kernel and rootfs
ROOTFS_LINUX ?= $(call __v,ROOTFS,LINUX)
ifneq ($(ROOTFS_LINUX),)
  ROOTFS := $(ROOTFS_LINUX)
endif

_BIMAGE := $(BIMAGE)
_KIMAGE := $(KIMAGE)
_ROOTFS := $(ROOTFS)
_QTOOL  := $(QTOOL)

# Core output: for building in standalone directories
TOP_OUTPUT      := $(TOP_DIR)/output
TOP_OUTPUT_ARCH := $(TOP_OUTPUT)/$(XARCH)
QEMU_OUTPUT     := $(TOP_OUTPUT_ARCH)/qemu-$(QEMU)-$(MACH)
UBOOT_OUTPUT    := $(TOP_OUTPUT_ARCH)/uboot-$(UBOOT)-$(MACH)
KERNEL_OUTPUT   := $(TOP_OUTPUT_ARCH)/linux-$(LINUX)-$(MACH)
ROOT_OUTPUT     := $(TOP_OUTPUT_ARCH)/buildroot-$(BUILDROOT)-$(MACH)

# Cross Compiler toolchains
ifneq ($(XARCH), i386)
  BUILDROOT_CCPRE  = $(XARCH)-linux-
else
  BUILDROOT_CCPRE  = i686-linux-
endif
BUILDROOT_CCPATH = $(ROOT_OUTPUT)/host/usr/bin

# Add internal toolchain to list (the one installed in docker image)
ifneq ($(CCPRE),)
  ifeq ($(shell /usr/bin/which $(CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
    CCORI_INTERNAL := 1
  endif
  # Add builtin toolchain to list (the one builtin the bsp or plugin)
  ifeq ($(CCORI),)
    ifneq ($(CCPATH),)
      ifeq ($(shell env PATH=$(CCPATH) /usr/bin/which $(CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
        CCORI_LIST += builtin
      endif
    endif
  endif
else
  ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
    ifeq ($(shell /usr/bin/which gcc >/dev/null 2>&1; echo $$?),0)
      CCORI_INTERNAL := 1
    endif
  endif
endif

ifeq ($(CCORI_INTERNAL), 1)
  ifneq ($(filter internal, $(CCORI_LIST)), internal)
    CCORI_LIST += internal
  endif
endif

# Add buidroot toolchain to list
ifeq ($(shell env PATH=$(BUILDROOT_CCPATH) /usr/bin/which $(BUILDROOT_CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
  ifneq ($(filter buildroot, $(CCORI_LIST)), buildroot)
    CCORI_LIST += buildroot
  endif
  ifeq ($(CCORI), buildroot)
    CCPATH := $(BUILDROOT_CCPATH)
    CCPRE  := $(BUILDROOT_CCPRE)
  endif
endif

CCORI ?= null

# If no CCORI specified, check internal, buildroot, external one by one
ifeq ($(CCORI), null)

  # Check if there is a local toolchain
  ifneq ($(CCPRE),)
    ifeq ($(shell /usr/bin/which $(CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
      CCORI := internal
    endif
  else
    ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
      ifeq ($(shell /usr/bin/which gcc >/dev/null 2>&1; echo $$?),0)
        CCORI := internal
      endif
    endif
  endif

  # Check if buildroot version exists
  ifeq ($(CCPATH),)
    ifeq ($(shell env PATH=$(BUILDROOT_CCPATH) /usr/bin/which $(BUILDROOT_CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
      CCORI  := buildroot
      CCPATH := $(BUILDROOT_CCPATH)
      CCPRE  := $(BUILDROOT_CCPRE)
    endif
  else
    ifeq ($(shell env PATH=$(CCPATH) /usr/bin/which $(CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
      CCORI := builtin
    endif
  endif

else # CCORI != null

  # Check if internal toolchain is there
  ifeq ($(CCORI), internal)
    ifneq ($(shell /usr/bin/which $(CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
      $(error ERR: No internal toolchain found, please find one via: make toolchain-list)
    endif
  endif

  # Check if external toolchain downloaded
  ifneq ($(filter $(CCORI), buildroot), $(CCORI))
    ifneq ($(CCPRE),)
      ifneq ($(CCPATH),)
        ifneq ($(shell env PATH=$(CCPATH) /usr/bin/which $(CCPRE)gcc >/dev/null 2>&1; echo $$?),0)
          # If CCORI specified and it is not there, just download one
          ifeq ($(TOOLCHAIN), $(wildcard $(TOOLCHAIN)))
            CC_TOOLCHAIN := toolchain-source
          else
            $(error ERR: No internal and external toolchain found, please refer to prebuilt/toolchains/ and prepare one)
          endif
        endif
      endif
    endif
  endif

endif # CCORI = null

# If none exists
ifeq ($(CCORI), null)
  $(info ERR: No toolchain found, please refer to prebuilt/toolchains/ and prepare one)
endif

CCORI_LIST ?= $(CCORI)

ifneq ($(filter $(CCORI), $(CCORI_LIST)), $(CCORI))
  $(error Supported gcc original list: $(CCORI_LIST))
endif

ifneq ($(CCPATH),)
  C_PATH ?= env PATH=$(CCPATH):$(PATH) LD_LIBRARY_PATH=$(LLPATH):$(LD_LIBRARY_PATH)
endif

#$(info Using gcc: $(CCPATH)/$(CCPRE)gcc)

TOOLCHAIN ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)

# Parallel Compiling threads
HOST_CPU_THREADS := $(shell grep -c processor /proc/cpuinfo)
JOBS ?= $(HOST_CPU_THREADS)

#
# Prefer new binaries to the prebuilt ones control
#
# PBK = 1, prebuilt kernel; 0, new building kernel if exist
# PBR = 1, prebuilt rootfs; 0, new building rootfs if exist
# PBD = 1, prebuilt dtb   ; 0, new building dtb if exist
# PBQ = 1, prebuilt qemu  ; 0, new building qemu if exist

# Emulator configurations
ifneq ($(BIOS),)
  BIOS_ARG := -bios $(BIOS)
endif

# Another qemu-system-$(ARCH)
QEMU_SYSTEM ?= $(QEMU_OUTPUT)/$(XARCH)-softmmu/qemu-system-$(XARCH)

ifeq ($(QEMU_SYSTEM),$(wildcard $(QEMU_SYSTEM)))
  PBQ ?= 0
else
  PBQ := 1
endif

ifeq ($(PBQ), 1)
  ifneq ($(QTOOL),)
    ifeq ($(QTOOL),$(wildcard $(QTOOL)))
      QEMU_SYSTEM := $(QTOOL)
    endif
  endif

  QTOOL_LINUX ?= $(call __v,QTOOL,LINUX)
  ifneq ($(QTOOL_LINUX),)
    ifeq ($(QTOOL_LINUX),$(wildcard $(QTOOL_LINUX)))
      QEMU_SYSTEM := $(QTOOL_LINUX)
    endif
  endif
endif

ifneq ($(QEMU),)
  ifeq ($(QEMU_SYSTEM),$(wildcard $(QEMU_SYSTEM)))
    QEMU_PATH := env PATH=$(dir $(QEMU_SYSTEM)):$(PATH)
  endif
endif

EMULATOR := $(QEMU_PATH) $(XENVS) qemu-system-$(XARCH) $(BIOS_ARG)

# Linux configurations
LINUX_PKIMAGE := $(ROOT_OUTPUT)/images/$(PORIIMG)
LINUX_KIMAGE  := $(KERNEL_OUTPUT)/$(ORIIMG)
LINUX_UKIMAGE := $(KERNEL_OUTPUT)/$(UORIIMG)

ifeq ($(LINUX_KIMAGE),$(wildcard $(LINUX_KIMAGE)))
  PBK ?= 0
else
  PBK := 1
endif

# Customize DTS?
_DTS := $(DTS)

ifeq ($(DTS),)
  ifneq ($(ORIDTS),)
    DTS    := $(KERNEL_SRC)/$(ORIDTS)
    ORIDTB ?= $(ORIDTS:.dts=.dtb)
  endif
  ifneq ($(ORIDTB),)
    ORIDTS := $(ORIDTB:.dtb=.dts)
    DTS    := $(KERNEL_SRC)/$(ORIDTS)
  endif
endif

ifneq ($(DTS),)
  DTB_TARGET ?= $(patsubst %.dts,%.dtb,$(shell echo $(DTS) | sed -e "s%.*/dts/%%g"))
  LINUX_DTB  := $(KERNEL_OUTPUT)/$(ORIDTB)
  ifeq ($(LINUX_DTB),$(wildcard $(LINUX_DTB)))
    ifneq ($(ORIDTB),)
      PBD ?= 0
    else
      PBD := 1
    endif
  else
    PBD := 1
  endif
endif

PKIMAGE ?= $(LINUX_PKIMAGE)
KIMAGE  ?= $(LINUX_KIMAGE)
UKIMAGE ?= $(LINUX_UKIMAGE)
DTB     ?= $(LINUX_DTB)

ifeq ($(PBK),0)
  KIMAGE  := $(LINUX_KIMAGE)
  UKIMAGE := $(LINUX_UKIMAGE)
endif
ifeq ($(PBD),0)
  DTB := $(LINUX_DTB)
endif

# Prebuilt path (not top dir) setting
ifneq ($(_BIMAGE),)
  PREBUILT_UBOOT_DIR  ?= $(dir $(_BIMAGE))
endif
ifneq ($(_KIMAGE),)
  PREBUILT_KERNEL_DIR ?= $(dir $(_KIMAGE))
endif
ifneq ($(_ROOTFS),)
  PREBUILT_ROOT_DIR   ?= $(dir $(_ROOTFS))
endif
ifneq ($(_QTOOL),)
  PREBUILT_QEMU_DIR   ?= $(patsubst %/bin/,%,$(dir $(_QTOOL)))
endif

# Uboot configurations
UBOOT_BIMAGE    := $(UBOOT_OUTPUT)/u-boot
PREBUILT_BIMAGE := $(PREBUILT_UBOOT_DIR)/u-boot

ifeq ($(UBOOT_BIMAGE),$(wildcard $(UBOOT_BIMAGE)))
  PBU ?= 0
else
  PBU := 1
endif

ifeq ($(UBOOT_BIMAGE),$(wildcard $(UBOOT_BIMAGE)))
  U ?= 1
else
  ifeq ($(PREBUILT_BIMAGE),$(wildcard $(PREBUILT_BIMAGE)))
    U ?= 1
  else
    U := 0
  endif
endif

BIMAGE ?= $(UBOOT_BIMAGE)
ifeq ($(PBU),0)
  BIMAGE := $(UBOOT_BIMAGE)
endif

# Use u-boot as 'kernel' if uboot used (while PBU=1/U=1 and u-boot exists)
ifneq ($(U),0)
  KIMAGE := $(BIMAGE)
endif

# Root configurations

# TODO: buildroot defconfig for $ARCH

# Verify rootdev argument
ifneq ($(ROOTDEV),)
  # If Linux version specific rootdev list defined, use it
   _ROOTDEV_LIST=$(call __v,ROOTDEV_LIST,LINUX)
  ifneq ($(_ROOTDEV_LIST),)
    override ROOTDEV_LIST := $(_ROOTDEV_LIST)
  endif
  ifneq ($(ROOTDEV_LIST),)
    ifneq ($(filter $(ROOTDEV), $(ROOTDEV_LIST)), $(ROOTDEV))
      $(error Kernel Supported ROOTDEV list: $(ROOTDEV_LIST))
    endif
  endif
endif

ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2

ROOTFS_UBOOT_SUFFIX    := .cpio.uboot
ROOTFS_HARDDISK_SUFFIX := .$(FSTYPE)
ROOTFS_INITRD_SUFFIX   := .cpio.gz

# Real one
BUILDROOT_ROOTDIR  :=  $(ROOT_OUTPUT)/target
# As a temp variable
_BUILDROOT_ROOTDIR :=  $(ROOT_OUTPUT)/images/rootfs

BUILDROOT_UROOTFS := $(_BUILDROOT_ROOTDIR)$(ROOTFS_UBOOT_SUFFIX)
BUILDROOT_HROOTFS := $(_BUILDROOT_ROOTDIR)$(ROOTFS_HARDDISK_SUFFIX)
BUILDROOT_IROOTFS := $(_BUILDROOT_ROOTDIR)$(ROOTFS_INITRD_SUFFIX)

PREBUILT_ROOT_DIR   ?= $(BSP_ROOT)/$(BUILDROOT)
PREBUILT_KERNEL_DIR ?= $(BSP_KERNEL)/$(LINUX)
PREBUILT_UBOOT_DIR  ?= $(BSP_UBOOT)/$(UBOOT)/$(LINUX)
PREBUILT_QEMU_DIR   ?= $(BSP_QEMU)/$(QEMU)

PREBUILT_ROOTDIR ?= $(PREBUILT_ROOT_DIR)/rootfs

PREBUILT_UROOTFS ?= $(PREBUILT_ROOTDIR)$(ROOTFS_UBOOT_SUFFIX)
PREBUILT_HROOTFS ?= $(PREBUILT_ROOTDIR)$(ROOTFS_HARDDISK_SUFFIX)
PREBUILT_IROOTFS ?= $(PREBUILT_ROOTDIR)$(ROOTFS_INITRD_SUFFIX)

# Check default rootfs type: dir, hardisk (.img, .ext*, .vfat, .f2fs, .cramfs...), initrd (.cpio.gz, .cpio), uboot (.uboot)
ROOTFS_TYPE_TOOL  := tools/rootfs/rootfs_type.sh
ROOTDEV_TYPE_TOOL := tools/rootfs/rootdev_type.sh

PBR ?= 0
_PBR := $(PBR)

ifeq ($(_PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    ifeq ($(PREBUILT_IROOTFS),$(wildcard $(PREBUILT_IROOTFS)))
      PBR := 1
    endif
  endif
endif

# Proxy kernel is built in buildroot
ifeq ($(PBR),0)
  PKIMAGE   := $(LINUX_PKIMAGE)
endif

# Prefer ROOTFS: command line > environment override > buildroot > prebuilt
ifeq ($(PBR),0)
  ifeq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    ROOTFS  := $(BUILDROOT_IROOTFS)
    IROOTFS := $(BUILDROOT_IROOTFS)
    UROOTFS := $(BUILDROOT_UROOTFS)
    HROOTFS := $(BUILDROOT_HROOTFS)
    ROOTDIR := $(BUILDROOT_ROOTDIR)
  endif
endif

ROOTFS_TYPE  := $(shell $(ROOTFS_TYPE_TOOL) $(ROOTFS))
ROOTDEV_TYPE := $(shell $(ROOTDEV_TYPE_TOOL) $(ROOTDEV))

# FIXME: workaround if the .cpio.gz or .ext2 are removed and only rootfs/ exists
ifeq ($(findstring not invalid or not exists,$(ROOTFS_TYPE)),not invalid or not exists)
  ROOTFS := $(dir $(ROOTFS))
  ROOTFS_TYPE  := $(shell $(ROOTFS_TYPE_TOOL) $(ROOTFS))
endif

ifeq ($(findstring not invalid or not exists,$(ROOTFS_TYPE)),not invalid or not exists)
  INVALID_ROOTFS := 1
endif

ifeq ($(findstring not support yet,$(ROOTDEV_TYPE)),not support yet)
  INVALID_ROOTDEV := 1
endif

comma := ,
empty :=
space := $(empty) $(empty)

_ROOTFS_TYPE=$(subst $(comma),$(space),$(ROOTFS_TYPE))

FS_TYPE   := $(firstword $(_ROOTFS_TYPE))
FS_PATH   := $(word 2,$(_ROOTFS_TYPE))
FS_SUFFIX := $(word 3,$(_ROOTFS_TYPE))

# Buildroot use its own ROOTDIR in /target, not in images/rootfs
ifneq ($(ROOTFS), $(BUILDROOT_IROOTFS))
  ifeq ($(FS_TYPE),dir)
    ROOTDIR := $(FS_PATH)
  else
    ROOTDIR := $(FS_PATH:$(FS_SUFFIX)=)
  endif

  ifeq ($(FS_TYPE),rd)
    IROOTFS := $(ROOTFS)
  else
    IROOTFS := $(ROOTDIR)$(ROOTFS_INITRD_SUFFIX)
  endif
  ifeq ($(FS_TYPE),hd)
    HROOTFS := $(ROOTFS)
  else
    HROOTFS := $(ROOTDIR)$(ROOTFS_HARDDISK_SUFFIX)
  endif
  UROOTFS := $(ROOTDIR)$(ROOTFS_UBOOT_SUFFIX)
endif

_ROOTDEV_TYPE := $(subst $(comma),$(space),$(ROOTDEV_TYPE))
DEV_TYPE      := $(firstword $(_ROOTDEV_TYPE))

# Phony targets
PHONY :=

# Board targets

BOARD_TOOL := ${TOOL_DIR}/board/show.sh

export GREP_COLOR=32;40
FILTER   ?= ^[ [\./_a-z0-9-]* \]|^ *[\_a-zA-Z0-9]* *
# all: 0, plugin: 1, noplugin: 2
BTYPE    ?= ^_BASE|^_PLUGIN

# board bsp
#
# only trigger bsp downloading while the bsp submodule path is there and nothing download
#
# to force download it, just issue 'make bsp'
#

BSP_SUBMODULE=$(shell grep $(BOARD)/bsp -q $(TOP_DIR)/.gitmodules; echo $$?)
ifeq ($(BSP_SUBMODULE),0)
  ifneq ($(BSP_ROOT),$(wildcard $(BSP_ROOT)))
    BOARD_BSP := bsp
  endif
endif

board: board-save plugin-save
	$(Q)find $(BOARDS_DIR)/$(BOARD) -maxdepth 3 -name "Makefile" -exec egrep -H "$(BTYPE)" {} \; \
		| sort -t':' -k2 | cut -d':' -f1 | xargs -i $(BOARD_TOOL) {} $(PLUGIN) \
		| egrep -v "/module" \
		| sed -e "s%boards/\(.*\)/Makefile%\1%g" \
		| sed -e "s/[[:digit:]]\{2,\}\t/  /g;s/[[:digit:]]\{1,\}\t/ /g" \
		| egrep -v " *_BASE| *_PLUGIN| *#" | egrep -v "^[[:space:]]*$$" | egrep --colour=auto "$(FILTER)"

board-clean:
	$(Q)rm -rf .board_config

board-save:
ifneq ($(BOARD),)
  ifeq ($(board),)
	$(Q)$(shell echo "$(BOARD)" > .board_config)
  endif
endif

b-s: board-save
b-c: board-clean

PHONY += board board-clean board-save b-s b-c

board-config:
	$(foreach vs, $(MAKEOVERRIDES), tools/board/config.sh $(vs) $(BOARD_MAKEFILE);)

PHONY += board-config

# Plugin targets

ifeq ($(filter command line, $(origin P) $(origin PLUGIN)), command line)
  ifeq ($(PLUGIN),)
    PLUGIN_CLEAN = plugin-clean
  endif
endif

plugin-save: $(PLUGIN_CLEAN)
ifneq ($(PLUGIN),)
  ifeq ($(plugin),)
	$(Q)$(shell echo "$(PLUGIN)" > .plugin_config)
  endif
endif

plugin-clean:
	$(Q)rm -rf .plugin_config

plugin: plugin-save
	$(Q)echo $(PLUGIN)

plugin-list:
	$(Q)find $(BOARDS_DIR) -maxdepth 3 -name ".plugin" | xargs -i dirname {} | xargs -i basename {} | cat -n

plugin-list-full:
	$(Q)find $(BOARDS_DIR) -maxdepth 3 -name ".plugin" | xargs -i dirname {} | cat -n

p: plugin
p-s: plugin-save
p-l: plugin-list
p-l-f: plugin-list-full
p-c: plugin-clean

PHONY += plugin-save plugin-clean plugin plugin-list plugin-list-full p p-s p-l p-l-f p-c

# List targets for boards and plugins

list:
	$(Q)make $(S) board BOARD= FILTER="^ *ARCH |^\[ [\./_a-z0-9-]* \]|^ *CPU|^ *LINUX|^ *ROOTDEV"

list-board:
	$(Q)make $(S) board BOARD= FILTER="^\[ [\./_a-z0-9-]* \]|^ *ARCH"

list-short:
	$(Q)make $(S) board BOARD= FILTER="^\[ [\./_a-z0-9-]* \]|^ *LINUX|^ *ARCH"

list-base:
	$(Q)make $(S) list BTYPE="^_BASE"

list-plugin:
	$(Q)make $(S) list BTYPE="^_PLUGIN"

list-full:
	$(Q)make $(S) board BOARD=

l: list
l-b: list-base
l-p: list-plugin
l-f: list-full
b-l: l
b-l-f: l-f

PHONY += list list-base list-plugin list-full l l-b l-p l-f b-l b-l-f

# Source download

uboot-source:
	@echo
	@echo "Downloading u-boot source ..."
	@echo
ifneq ($(_UBOOT_SRC), $(UBOOT_SRC))
	cd $(BSP_SROOT) && $(UPDATE_GITMODULE) $(UBOOT_SPATH) && cd $(TOP_DIR)
else
	$(UPDATE_GITMODULE) $(UBOOT_SRC)
endif

download-uboot: uboot-source
uboot-download: uboot-source
d-u: uboot-source

PHONY += uboot-source download-uboot uboot-download d-u

qemu-source:
	@echo
	@echo "Downloading qemu source ..."
	@echo
ifneq ($(_QEMU_SRC), $(QEMU_SRC))
	cd $(BSP_SROOT) && $(UPDATE_GITMODULE) $(QEMU_SPATH) && cd $(TOP_DIR)
else
	$(UPDATE_GITMODULE) $(QEMU_SRC)
endif

qemu-download: qemu-source
download-qemu: qemu-source
d-q: qemu-source
q-d: qemu-source

emulator-download: qemu-source
e-d: qemu-source

emulator-prepare: emulator-checkout emulator-patch emulator-defconfig
emulator-auto: emulator-prepare emulator
emulator-full: emulator-download emulator-prepare emulator

qemu-prepare: qemu-env emulator-prepare
qemu-auto: emulator-auto
qemu-full: emulator-full
qemu-all: qemu-full qemu-save

PHONY += qemu-download download-qemu d-q q-d emulator-download e-d emulator-prepare emulator-auto emulator-full qemu-prepare qemu-auto qemu-full qemu-all

kernel-source:
	@echo
	@echo "Downloading kernel source ..."
	@echo
ifneq ($(_KERNEL_SRC), $(KERNEL_SRC))
	cd $(BSP_SROOT) && $(UPDATE_GITMODULE) $(KERNEL_SPATH) && cd $(TOP_DIR)
else
	$(UPDATE_GITMODULE) $(KERNEL_SRC)
endif

kernel-download: kernel-source
download-kernel: kernel-source
d-k: kernel-source

PHONY += kernel-source kernel-download download-kernel d-k

root-source:
	@echo
	@echo "Downloading buildroot source ..."
	@echo
ifneq ($(_ROOT_SRC), $(ROOT_SRC))
	cd $(BSP_SROOT) && $(UPDATE_GITMODULE) $(ROOT_SPATH)) && cd $(TOP_DIR)
else
	$(UPDATE_GITMODULE) $(ROOT_SRC)
endif

root-download: root-source
download-root: root-source
d-r: root-source

PHONY += root-source root-download download-root d-r

bsp-source:
	@echo
	@echo "Downloading board bsp ..."
	@echo
	$(UPDATE_GITMODULE) $(BSP_DIR)

bsp-download: bsp-source
download-bsp: bsp-source
bsp: bsp-source
d-b: bsp-source

PHONY += bsp-source bsp-download download-bsp d-b bsp

source: bsp-source kernel-source root-source

download: source
d: source

core-source: source uboot-source

core-download: core-source
download-core: core-source
d-c: core-source

all-source: source uboot-source qemu-source

download-all: all-source
all-download: all-source
d-a: all-source

PHONY += source download core-source download-core d-c all-source all-download download-all d-a

# Qemu targets

QCO ?= 0
ifneq ($(QEMU),)
ifneq ($(QCO),0)
  QEMU_CHECKOUT := qemu-checkout
endif

COMMIT_QEMU  ?= $(call __v,COMMIT,QEMU)
ifneq ($(COMMIT_QEMU),)
  _QEMU := $(COMMIT_QEMU)
else
  _QEMU := $(QEMU)
endif


endif
qemu-checkout:
	cd $(QEMU_SRC) && git checkout -f $(_QEMU) && git clean -fdx && cd $(TOP_DIR)

emulator-checkout: qemu-checkout

e-o: emulator-checkout
q-o: e-o

QP ?= 0

QEMU_PATCH_TOOL  := tools/qemu/patch.sh
QEMU_PATCHED_TAG := $(QEMU_SRC)/.patched

qemu-patch: $(QEMU_CHECKOUT)
	@if [ ! -f $(QEMU_PATCHED_TAG) ]; then \
	  $(QEMU_PATCH_TOOL) $(BOARD) $(QEMU) $(QEMU_SRC) $(QEMU_OUTPUT); \
	  touch $(QEMU_PATCHED_TAG);  \
	else \
	  echo "ERR: qemu patchset has been applied, if want, please do 'make qemu-checkout' at first." && exit 1; \
	fi

emulator-patch: qemu-patch

e-p: qemu-patch
q-p: e-p

PHONY += emulator-patch qemu-patch q-p e-p

ifneq ($(QEMU),)
ifneq ($(QP),0)
  QEMU_PATCH := qemu-patch
endif
endif

# Notes:
#
# 1. --enable-curses is required for G=2, boot with LCD/keyboard from ssh login
#    deps: sudo apt-get install libncursesw5-dev
# 2. --enable-sdl is required for G=1, but from v4.0.0, it requires libsdl2-dev,
# 3. --disable-vnc disable vnc graphic support, this is not that friendly because
#    it requires to install a vnc viewer, such as vinagre.
#    TODO: start vnc viewer automatically while qemu boots and listen on vnc port.
# 4. --disable-kvm is used to let qemu boot in docker environment which not have kvm.
# 5. --enable-virtfs adds 9pnet sharing support, depends on libattr1-dev libcap-dev
#


ifeq ($(findstring qemu,$(MAKECMDGOALS)),qemu)
 ifeq ($(QEMU),)
  $(error ERR: No qemu version specified, please configure QEMU= in boards/$(BOARD)/Makefile or pass it manually)
 endif

 ifneq ($(QCFG),)
   QEMU_CONF := $(QCFG)
 else
   # Use v2.12.0 by default
   QEMU_CONF ?= --disable-kvm
 endif
endif

#
# qemu-user-static, only compile it for it works the same as qemu-user
#
# Ref:
# http://logan.tw/posts/2018/02/18/build-qemu-user-static-from-source-code/
# Disable system for it cann't by compiled with --static currently
#
# it is saved as $(XARCH)-linux-user/qemu-$(XARCH), need to append a suffix
# -static and put in /usr/bin of chroot's target directory
#

# Current supported architectures
ARCH_LIST ?= arm aarch64 i386 x86_64 mipsel mips64el ppc ppc64 riscv32 riscv64
ifeq ($(QEMU_ALL),1)
  PREBUILT_QEMU_DIR := $(PREBUILT_QEMU)/$(QEMU)
  QEMU_OUTPUT := $(TOP_OUTPUT)/qemu-$(QEMU)-all
  QEMU_ARCH = $(ARCH_LIST)
else
  QEMU_ARCH = $(XARCH)
endif

ifeq ($(QEMU_US), 1)
  QEMU_TARGET ?= $(subst $(space),$(comma),$(addsuffix -linux-user,$(QEMU_ARCH)))
  QEMU_CONF   += --enable-linux-user --static
  QEMU_CONF   += --target-list=$(QEMU_TARGET)
  QEMU_CONF   += --disable-system
else
  ifeq ($(QCFG),)
    # Qemu > 4.0 requires libsdl2, which is not installable in current lab
    # (too old ubuntu), use vnc instead
    #QEMU_MAJOR_VER := $(subst v,,$(firstword $(subst .,$(space),$(QEMU))))
    #QEMU_SDL ?= $(shell [ $(QEMU_MAJOR_VER) -ge 4 ];echo $$?)
    #QEMU_VNC ?= $(shell [ $(QEMU_MAJOR_VER) -lt 4 ];echo $$?)
    QEMU_SDL    ?= 1
    QEMU_CURSES ?= 1
    ifneq ($(QEMU_SDL),0)
      QEMU_CONF += --enable-sdl
    endif

    ifeq ($(QEMU_VNC),1)
      QEMU_CONF += --enable-vnc
    else
      QEMU_CONF += --disable-vnc
    endif

    ifneq ($(QEMU_VIRTFS),0)
      QEMU_CONF += --enable-virtfs
    endif

    ifeq ($(QEMU_CURSES),1)
      QEMU_CONF += --enable-curses
    endif
  endif

  QEMU_TARGET ?= $(subst $(space),$(comma),$(addsuffix -softmmu,$(QEMU_ARCH)))
  QEMU_CONF   += --target-list=$(QEMU_TARGET)
endif

QEMU_PREFIX ?= $(PREBUILT_QEMU_DIR)

QEMU_CONF_CMD := $(QEMU_ABS_SRC)/configure $(QEMU_CONF) --prefix=$(QEMU_PREFIX)

qemu-defconfig: qemu-env $(QEMU_PATCH)
	$(Q)mkdir -p $(QEMU_OUTPUT)
	$(Q)cd $(QEMU_OUTPUT) && $(QEMU_CONF_CMD) && cd $(TOP_DIR)

emulator-defconfig: qemu-defconfig

q-c: qemu-defconfig
e-c: emulator-defconfig

PHONY += qemu-defconfig emulator-defconfig q-c e-c

qemu: qemu-env
	$(C_PATH) make -C $(QEMU_OUTPUT) -j$(JOBS) V=$(V)

qemu-build: qemu
emulator: qemu
emulator-build: emulator

q: qemu
e: q
e-b: q
q-b: q

PHONY += qemu qemu-build emulator emulator-build q e e-b q-b


# Toolchains targets

toolchain-source: toolchain
download-toolchain: toolchain
d-t: toolchain
gcc: toolchain

include $(PREBUILT_TOOLCHAINS)/Makefile

toolchain:
	@echo
	@echo "Downloading prebuilt toolchain ..."
	@echo
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
	$(Q)make $(S) -C $(TOOLCHAIN) $(if $(CCVER),CCVER=$(CCVER))
else
  ifneq ($(CCPATH), $(wildcard $(CCPATH)))
	$(Q)wget -c $(CCURL)
	$(Q)tar $(TAR_OPTS) $(CCTAR) -C $(TOOLCHAIN)
  else
	$(Q)make $(S) gcc-info
  endif
endif

toolchain-list:
	@echo
	@echo "Listing prebuilt toolchain ..."
	@echo
	$(Q)$(foreach ccori, $(CCORI_LIST), make $(S) gcc-info CCORI=$(ccori);)

gcc-list: toolchain-list

toolchain-info:
	@echo
	@echo [ $(CCORI) $(CCVER) ]:
	@echo
	@echo Remote.: $(CCURL)
	@echo Local..: $(CCPATH)
	@echo Tool...: $(CCPRE)gcc
ifneq ($(CCPATH), $(wildcard $(CCPATH)))
	@echo Version: Not downloaded, please download it: make toolchain CCORI=$(CCORI)
else
	@echo Version: `/usr/bin/env PATH=$(CCPATH):$(PATH) $(CCPRE)gcc --version | head -1`
endif
ifeq ($(CCORI), internal)
	@echo More...: `/usr/bin/update-alternatives --list $(CCPRE)gcc`
endif

gcc-info: toolchain-info
gcc-version: toolchain-info
toolchain-version: toolchain-info

toolchain-clean:
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
	$(Q)make $(S) clean -C $(TOOLCHAIN) $(if $(CCVER),CCVER=$(CCVER))
else
  ifeq ($(TOOLCHAIN), $(wildcard $(TOOLCHAIN)))
     ifneq ($(CCBASE),)
	$(Q)rm -rf $(TOOLCHAIN)/$(CCBASE)
     endif
  endif
endif

gcc-clean: toolchain-clean

PHONY += toolchain-source download-toolchain toolchain toolchain-clean d-t toolchain-list gcc-list gcc-clean gcc

ifeq ($(filter $(MAKECMDGOALS),toolchain-switch gcc-switch), $(MAKECMDGOALS))
  _CCORI := $(shell grep --color=always ^CCORI $(BOARD_DIR)/Makefile | cut -d '=' -f2 | tr -d ' ')
endif
toolchain-switch:
ifneq ($(filter $(GCC),$(CCORI_LIST)), $(GCC))
	$(Q)update-alternatives --verbose --set $(CCPRE)gcc /usr/bin/$(CCPRE)gcc-$(GCC)
else
  ifneq ($(_CCORI), $(CCORI))
	$(Q)echo OLD: `grep --color=always ^CCORI $(BOARD_DIR)/Makefile`
	$(Q)sed -i -e "s%^\(CCORI.*?=\).*%\1 $(CCORI)%g" $(BOARD_DIR)/Makefile
	$(Q)echo NEW: `grep --color=always ^CCORI $(BOARD_DIR)/Makefile`
  else
	@echo "Usage: make toolchain-switch CCORI=<CCORI> GCC=<Internal-GCC-Version>"
	@echo "       e.g. make toolchain-switch CCORI=bootlin"
	@echo "            make toolchain-switch CCORI=internal GCC=4.9.3"
	@echo "            make toolchain-switch CC=4.9.3       # If CCORI is already internal"
	$(Q)make $(S) toolchain-list
  endif
endif

gcc-switch: toolchain-switch

PHONY += toolchain-switch gcc-switch toolchain-version gcc-version

# Rootfs targets

RCO ?= 0
#BUILDROOT ?= master
ifeq ($(RCO),1)
  ROOT_CHECKOUT := root-checkout
endif

COMMIT_BUILDROOT  ?= $(call __v,COMMIT,BUILDROOT)
ifneq ($(COMMIT_BUILDROOT),)
  _BUILDROOT := $(COMMIT_BUILDROOT)
else
  _BUILDROOT := $(BUILDROOT)
endif

# Configure Buildroot
root-checkout:
	cd $(ROOT_SRC) && git checkout -f $(_BUILDROOT) && git clean -fdx -e dl/ && cd $(TOP_DIR)

ROOT_CONFIG_FILE ?= buildroot_$(BUILDROOT)_defconfig

RCFG ?= $(ROOT_CONFIG_FILE)
ROOT_CONFIG_DIR := $(ROOT_SRC)/configs

ifeq ($(RCFG),$(ROOT_CONFIG_FILE))
  RCFG_FILE := $(_BSP_CONFIG)/$(RCFG)
else
  ifeq ($(RCFG), $(wildcard $(RCFG)))
    RCFG_FILE := $(RCFG)
  else
    TMP := $(_BSP_CONFIG)/$(RCFG)
    ifeq ($(TMP), $(wildcard $(TMP)))
      RCFG_FILE := $(RCFG)
    else
      TMP := $(ROOT_CONFIG_DIR)/$(RCFG)
      ifeq ($(TMP), $(wildcard $(TMP)))
        RCFG_FILE := $(TMP)
      else
        $(error $(RCFG): can not be found, please pass a valid root defconfig)
      endif
    endif
  endif
endif

ifeq ($(findstring $(ROOT_CONFIG_DIR),$(RCFG_FILE)),$(ROOT_CONFIG_DIR))
  RCFG_BUILTIN := 1
endif

_RCFG := $(notdir $(RCFG_FILE))

RP ?= 0
ROOT_PATCH_TOOL := tools/rootfs/patch.sh
ROOT_PATCHED_TAG := $(ROOT_SRC)/.patched

root-patch: $(BOARD_BSP)
	@if [ ! -f $(ROOT_PATCHED_TAG) ]; then \
	  $(ROOT_PATCH_TOOL) $(BOARD) $(BUILDROOT) $(ROOT_SRC) $(ROOT_OUTPUT); \
	  touch $(ROOT_PATCHED_TAG); \
	else \
	  echo "ERR: root patchset has been applied already, if want, please do 'make root-checkout' at first."; \
	fi

ifeq ($(RP),1)
  ROOT_PATCH := root-patch
endif

root-defconfig: root-env $(ROOT_CHECKOUT) $(BOARD_BSP) $(ROOT_PATCH)
	$(Q)mkdir -p $(ROOT_OUTPUT)
	$(Q)$(if $(RCFG_BUILTIN),,cp $(RCFG_FILE) $(ROOT_CONFIG_DIR))
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) $(_RCFG)

ifneq ($(BUILDROOT_NEW),)
ifneq ($(BUILDROOT_NEW),$(BUILDROOT))
NEW_RCFG_FILE=$(_BSP_CONFIG)/buildroot_$(BUILDROOT_NEW)_defconfig
NEW_PREBUILT_ROOT_DIR=$(subst $(BUILDROOT),$(BUILDROOT_NEW),$(PREBUILT_ROOT_DIR))

root-cloneconfig: $(BOARD_BSP)
	$(Q)cp $(RCFG_FILE) $(NEW_RCFG_FILE)
	$(Q)sed -i -e "s%^\(BUILDROOT.*?= \).*%\1$(BUILDROOT_NEW)%g" $(BOARD_DIR)/Makefile
	$(Q)mkdir -p $(NEW_PREBUILT_ROOT_DIR)
endif
root-new: root-clone
root-clone: root-cloneconfig

PHONY += root-new root-clone root-cloneconfig
endif

root-olddefconfig:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) olddefconfig

root-oldconfig:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) oldconfig

root-menuconfig:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) menuconfig

r-d: root-source
r-o: root-checkout
r-c: root-defconfig
r-m: root-menuconfig


PHONY += root-checkout root-patch root-defconfig root-menuconfig r-d r-o r-c r-m

# Build Buildroot
ROOT_INSTALL_TOOL := $(TOOL_DIR)/rootfs/install.sh

# Install kernel modules?
IKM ?= 1

ifeq ($(IKM), 1)
  ifeq ($(KERNEL_OUTPUT)/.modules.order, $(wildcard $(KERNEL_OUTPUT)/.modules.order))
    KERNEL_MODULES_INSTALL := module-install
  endif
endif

root-buildroot:
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) -j$(JOBS) $(RT)

# Install system/ to ROOTDIR
root-install: root-dir
	ROOTDIR=$(ROOTDIR) $(ROOT_INSTALL_TOOL)

PHONY += root-buildroot root-install

prebuilt_root_dir ?= $(PBR)
ifeq ($(FS_TYPE),dir)
  prebuilt_root_dir := 1
endif

build_root_uboot ?= 0
ifeq ($(U),1)
  ifeq ($(DEV_TYPE),rd)
    build_root_uboot := 1
  endif
endif

# root ramdisk image
ifeq ($(FS_TYPE),rd)
  ROOT_GENRD_TOOL := $(TOOL_DIR)/rootfs/dir2rd.sh
else
  ROOT_GENRD_TOOL := $(TOOL_DIR)/rootfs/$(FS_TYPE)2rd.sh
endif

root-rd:
	$(Q)if [ ! -f "$(IROOTFS)" ]; then make $(S) root-rd-rebuild; fi

root-rd-rebuild: FORCE
	@echo "LOG: Generating ramdisk image with $(ROOT_GENRD_TOOL) ..."
	ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) USER=$(USER) $(ROOT_GENRD_TOOL)

ROOT_GENDISK_TOOL := $(TOOL_DIR)/rootfs/dir2$(DEV_TYPE).sh

# This is used to repackage the updated root directory, for example, `make r-i` just executed.
root-rebuild:
ifeq ($(prebuilt_root_dir), 1)
	@echo "LOG: Generating $(DEV_TYPE) with $(ROOT_GENDISK_TOOL) ..."
	ROOTDIR=$(ROOTDIR) INITRD=$(IROOTFS) HROOTFS=$(HROOTFS) FSTYPE=$(FSTYPE) USER=$(USER) $(ROOT_GENDISK_TOOL)
	$(Q)if [ $(build_root_uboot) -eq 1 ]; then make $(S) _root-ud-rebuild; fi
else
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC)
	$(Q)chown -R $(USER):$(USER) $(BUILDROOT_ROOTDIR)
	$(Q)if [ $(build_root_uboot) -eq 1 ]; then make $(S) $(BUILDROOT_UROOTFS); fi
endif

r-p: root-patch
r-B: root-buildroot
r-i: root-install
r-r: root-rebuild

ROOT ?= rootdir
ifeq ($(_PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    ROOT := root-buildroot
  endif
endif

PHONY += root-rd root-rd-rebuild r-p r-B r-i r-r

# Specify buildroot target

RT ?= $(x)

ifneq ($(RT),)
  ROOT :=
endif

root: root-env $(ROOT)
ifneq ($(RT),)
	$(Q)make root-buildroot RT=$(RT)
else
	$(Q)make root-install
	$(Q)if [ -n "$(KERNEL_MODULES_INSTALL)" ]; then make $(KERNEL_MODULES_INSTALL); fi
	$(Q)make root-rebuild
endif

root-help:
	$(Q)make root RT=help

root-build: root

root-prepare: root-checkout root-patch root-defconfig
root-auto: root-prepare root
root-full: root-download root-prepare root
root-all: root-full root-save root-saveconfig

r: root
r-b: root
r-P: root-prepare
r-a: root-auto
r-f: root-full

PHONY += root root-help root-build root-prepare root-auto root-full r r-b r-P r-a r-f root-all

# root directory
ifneq ($(FS_TYPE),dir)
  ROOT_GENDIR_TOOL := $(TOOL_DIR)/rootfs/$(FS_TYPE)2dir.sh
endif

root-dir:
	$(Q)if [ ! -d "${ROOTDIR}" ]; then make root-dir-rebuild; fi

root-dir-rebuild: rootdir

rootdir:
ifneq ($(ROOTDIR), $(BUILDROOT_ROOTDIR))
	@echo "LOG: Generating rootfs directory with $(ROOT_GENDIR_TOOL) ..."
	ROOTDIR=$(ROOTDIR) USER=$(USER) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) $(ROOT_GENDIR_TOOL)
endif

rootdir-install: root-install

rootdir-clean:
	-$(Q)if [ "$(ROOTDIR)" = "$(PREBUILT_ROOTDIR)" ]; then rm -rf $(ROOTDIR); fi


PHONY += root-dir root-dir-rebuild rootdir rootdir-install rootdir-clean

ROOT_GENHD_TOOL := $(TOOL_DIR)/rootfs/$(FS_TYPE)2hd.sh

root-hd:
	$(Q)if [ ! -f "$(HROOTFS)" ]; then make root-hd-rebuild; fi

root-hd-rebuild: FORCE
	@echo "LOG: Generating harddisk image with $(ROOT_GENHD_TOOL) ..."
	ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) $(ROOT_GENHD_TOOL)

PHONY += root-hd root-hd-rebuild

# Kernel modules
TOP_MODULE_DIR := $(TOP_DIR)/modules
ifneq ($(PLUGIN),)
  TMP := $(TOP_DIR)/boards/$(PLUGIN)/modules
  ifeq ($(TMP),$(wildcard $(TMP)))
    PLUGIN_MODULE_DIR := $(TMP)
  endif
else
  PLUGIN_MODULE_DIR := $(shell find $(TOP_DIR)/boards -maxdepth 5 -type d -name "modules")
endif

EXT_MODULE_DIR := $(TOP_MODULE_DIR) $(PLUGIN_MODULE_DIR)
KERNEL_MODULE_DIR := $(KERNEL_ABS_SRC)
KERNEL_SEARCH_PATH := $(addprefix $(KERNEL_MODULE_DIR)/,drivers kernel fs block crypto mm net security sound)

modules ?= $(m)
module  ?= $(modules)
ifeq ($(module),all)
  module := $(shell find $(EXT_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | xargs -i basename {} | tr '\n' ',')
endif

internal_module := 0
ifneq ($(M),)
  ifneq ($(M),)
    override M := $(patsubst %/,%,$(M))
  endif
  ifeq ($(M),$(wildcard $(M)))
    ifeq ($(findstring $(KERNEL_MODULE_DIR),$(M)),$(KERNEL_MODULE_DIR))
      # Convert to relative path: must related to top dir of linux kernel, otherwise, will be compiled in source directory
      M_PATH = $(subst $(KERNEL_MODULE_DIR)/,,$(M))
      internal_module := 1
    else
      M_PATH ?= $(M)
    endif
  else
    ifeq ($(KERNEL_MODULE_DIR)/$(M),$(wildcard $(KERNEL_MODULE_DIR)/$(M)))
      M_PATH ?= $(M)
      internal_module := 1
    else
      MODULES ?= $(M)
    endif
  endif
endif

MODULE ?= $(MODULES)
ifeq ($(MODULE),)
  ifneq ($(module),)
    MODULE := $(shell printf $(module) | tr ',' '\n' | cut -d'_' -f1 | tr '\n' ',' | sed -e 's%,$$%%g')
  endif
endif

# Ignore multiple modules check here
ifneq ($(module),)
  MC ?= $(words $(subst $(comma),$(space),$(module)))
endif

# Only check module exists for 'module' target
one_module := 0
ifeq ($(MC),1)
  ifeq ($(findstring _module,$(MAKECMDGOALS)),_module)
    one_module := 1
  endif
endif

ifeq ($(one_module),1)
  ifeq ($(module),)
    # Prefer user input instead of preconfigured
    ifneq ($(M_PATH),$(wildcard $(M_PATH)))
      ifneq ($(MODULE_CONFIG),)
        module = $(MODULE_CONFIG)
      endif
      ifneq ($(MPATH_CONFIG),)
        M_PATH ?= $(MPATH_CONFIG)
      endif
    endif
  else
    M_PATH := $(shell find $(EXT_MODULE_DIR) -name "Makefile" | xargs -i egrep -iH "^obj-m[[:space:]]*[+:]*=[[:space:]]*($(module))\.o" {} | sed -e "s%\(.*\)/Makefile.*%\1%g" | head -1)
    ifeq ($(M_PATH),)
      M_PATH := $(shell find $(KERNEL_SEARCH_PATH) -name "Makefile" | xargs -i egrep -iH "^obj-.*[[:space:]]*[+:]*=[[:space:]]*($(module))\.o" {} | sed -e "s%\(.*\)/Makefile.*%\1%g" | head -1)
      ifneq ($(M_PATH),)
        M_PATH := $(subst $(KERNEL_MODULE_DIR)/,,$(M_PATH))
        internal_module :=1
      endif
    endif

    ifeq ($(M_PATH),)
      $(error 'ERR: No such module found: $(module), list all by: `make m-l`')
    else
      $(info LOG: m=$(module) ; M=$(M_PATH))
    endif
  endif # module not empty
endif   # ext_one_module = 1

ifneq ($(M_PATH),)
  M_PATH := $(patsubst %/,%,$(M_PATH))
endif

SCRIPTS_KCONFIG := tools/kernel/config
DEFAULT_KCONFIG := $(KERNEL_OUTPUT)/.config

ifeq ($(findstring module,$(MAKECMDGOALS)),module)
  MODULES_STATE   := $(shell $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)
  ifeq ($(MODULES_STATE),y)
    MODULES_EN := 1
  else
    MODULES_EN := 0
  endif
  $(info $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)
endif

ifneq ($(M_PATH),)
modules-prompt:
	@echo
	@echo "  Current using module is $(M_PATH)."
	@echo "  to compile modules under $(KERNEL_SRC), use 'make kernel-modules' or 'make m KM='."
	@echo

kernel-modules-save:
	$(Q)$(shell echo "$(M_PATH)" > .mpath_config)
	$(Q)$(shell echo "$(module)" > .module_config)


KM ?= M=$(M_PATH)
KERNEL_MODULES_DEPS := modules-prompt kernel-modules-save
endif

PHONY += modules-prompt kernel-modules-save

ifeq ($(internal_module),1)
  MODULE_PREPARE := prepare
else
  MODULE_PREPARE := modules_prepare
endif

_kernel-modules: $(KERNEL_MODULES_DEPS)
	if [ $(MODULES_EN) -eq 1 ]; then make kernel KT=$(MODULE_PREPARE); make kernel KT=$(if $(m),$(m).ko,modules) $(KM); fi

kernel-modules:
	make _kernel-modules KM=

ifneq ($(module),)
  IMF ?= $(subst $(comma),|,$(module))
  MF ?= egrep "$(IMF)"
  internal_search := 1
else
  IMF :=.*
  MF := cat
endif

# If m or M argument specified, search modules in kernel source directory
ifneq ($(M),)
  PF ?= egrep "$(subst $(comma),|,$(M))"
  internal_search := 1
else
  PF := cat
endif

kernel-modules-list: kernel-modules-list-full

kernel-modules-list-full:
	$(Q)find $(EXT_MODULE_DIR) -name "Makefile" | $(PF) | xargs -i egrep -iH "^obj-m[[:space:]]*[+:]*=[[:space:]]*.*($(IMF)).*\.o" {} | sed -e "s%$(PWD)/\(.*\)/Makefile:obj-m[[:space:]]*[+:]*=[[:space:]]*\(.*\).o%m=\2 ; M=\$$PWD/\1%g" | cat -n
ifeq ($(internal_search),1)
	$(Q)find $(KERNEL_SEARCH_PATH) -name "Makefile" | $(PF) | xargs -i egrep -iH "^obj-.*_($(IMF))(\)|_).*[[:space:]]*[+:]*=[[:space:]]*($(IMF)).*\.o" {} | sed -e "s%$(KERNEL_MODULE_DIR)/\(.*\)/Makefile:obj-\$$(CONFIG_\(.*\))[[:space:]]*[+:]*=[[:space:]]*\(.*\)\.o%c=\2 ; m=\3 ; M=\1%g" | cat -n
endif

PHONY += _kernel-modules kernel-modules kernel-modules-list kernel-modules-list-full

M_I_ROOT ?= rootdir
ifeq ($(PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    M_I_ROOT := root-buildroot
  endif
endif

_kernel-modules-install:
	if [ $(MODULES_EN) -eq 1 ]; then make kernel KT=modules_install INSTALL_MOD_PATH=$(ROOTDIR) $(KM); fi

kernel-modules-install: $(M_I_ROOT)
	make _kernel-modules-install KM=

ifeq ($(internal_module),1)
  M_ABS_PATH := $(KERNEL_OUTPUT)/$(M_PATH)
else
  M_ABS_PATH := $(wildcard $(M_PATH))
endif

KERNEL_MODULE_CLEAN := tools/module/clean.sh
_kernel-modules-clean:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_OUTPUT) $(M_ABS_PATH)
	$(Q)rm -rf .module_config

kernel-modules-clean:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_OUTPUT)

PHONY += _kernel-modules-install kernel-modules-install kernel-modules-clean

_module: _kernel-modules plugin-save
module-list: kernel-modules-list plugin-save
module-list-full: kernel-modules-list-full plugin-save
_module-install: _kernel-modules-install
_module-clean: _kernel-modules-clean

modules-list: module-list
modules-list-full: module-list-full
ms-l: module-list
ms-l-f: modules-list-full

module-test: test
modules-test: module-test

PHONY += _module module-list module-list-full _module-install _module-clean modules-list modules-list-full ms-l ms-l-f

module: FORCE
	$(Q)$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nBuilding module: $(m) ...\n" && make _module m=$(m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(shell echo $(M) | tr ',' ' '), \
		echo "\nBuilding module: $(_M) ...\n" && make _module M=$(_M);) echo '')

module-install: FORCE
	$(Q)$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nInstalling module: $(m) ...\n" && make _module-install m=$(m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(shell echo $(M) | tr ',' ' '), \
		echo "\nInstalling module: $(_M) ...\n" && make _module-install M=$(_M);) echo '')

module-clean: FORCE
	$(Q)$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nCleaning module: $(m) ...\n" && make _module-clean m=$(m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(shell echo $(M) | tr ',' ' '), \
		echo "\nCleaning module: $(_M) ...\n" && make _module-clean M=$(_M);) echo '')

# If no M, m/module/modules, M_PATH specified, compile internel modules by default
ifneq ($(module)$(M)$(KM)$(M_PATH),)
modules: module
modules-install: module-install
modules-clean: module-clean
else
modules: kernel-modules FORCE
modules-install: kernel-modules-install
modules-clean: kernel-modules-clean
endif

PHONY += modules modules-install modules-clean module module-install module-clean

m: module
m-l: module-list
m-l-f: module-list-full
m-i: module-install
m-c: module-clean
m-t: module-test

ms: modules
ms-t: modules-test
ms-i: modules-install
ms-c: modules-clean

PHONY += m m-l m-l-f m-i m-c m-t ms ms-t ms-i ms-c

# Linux Kernel targets
COMMIT_LINUX  ?= $(call __v,COMMIT,LINUX)
ifneq ($(COMMIT_LINUX),)
  _LINUX := $(COMMIT_LINUX)
endif

# Configure Kernel
kernel-checkout:
	cd $(KERNEL_SRC) && git checkout -f $(_LINUX) && git clean -fdx && cd $(TOP_DIR)

KCO ?= 0
#LINUX ?= master
ifeq ($(KCO),1)
  KERNEL_CHECKOUT := kernel-checkout
endif

KERNEL_PATCH_TOOL := tools/kernel/patch.sh
LINUX_PATCHED_TAG := $(KERNEL_SRC)/.patched

KP ?= 0
kernel-patch: $(BOARD_BSP)
	@if [ ! -f $(LINUX_PATCHED_TAG) ]; then \
	  $(KERNEL_PATCH_TOOL) $(BOARD) $(LINUX) $(KERNEL_SRC) $(KERNEL_OUTPUT); \
	  touch $(LINUX_PATCHED_TAG); \
	else \
	  echo "ERR: kernel patchset has been applied, if want, please do 'make kernel-checkout' at first." && exit 1; \
	fi


ifeq ($(KP),1)
  KERNEL_PATCH := kernel-patch
endif

KERNEL_CONFIG_FILE ?= linux_$(LINUX)_defconfig

KCFG ?= $(KERNEL_CONFIG_FILE)
KERNEL_CONFIG_DIR := $(KERNEL_SRC)/arch/$(ARCH)/configs/

ifeq ($(KCFG),$(KERNEL_CONFIG_FILE))
  KCFG_FILE := $(_BSP_CONFIG)/$(KCFG)
else
  ifeq ($(KCFG), $(wildcard $(KCFG)))
    KCFG_FILE := $(KCFG)
  else
    TMP := $(_BSP_CONFIG)/$(KCFG)
    ifeq ($(TMP), $(wildcard $(TMP)))
      KCFG_FILE := $(TMP)
    else
      TMP := $(KERNEL_CONFIG_DIR)/$(KCFG)
      ifeq ($(TMP), $(wildcard $(TMP)))
        KCFG_FILE := $(TMP)
      else
        TMP := $(KERNEL_SRC)/arch/$(ARCH)/$(KCFG)
        ifeq ($(TMP), $(wildcard $(TMP)))
          KCFG_FILE := $(TMP)
        else
          $(error $(KCFG): can not be found, please pass a valid kernel defconfig)
        endif
      endif
    endif
  endif
endif

ifeq ($(findstring $(KERNEL_CONFIG_DIR),$(KCFG_FILE)),$(KERNEL_CONFIG_DIR))
  KCFG_BUILTIN := 1
endif

_KCFG := $(notdir $(KCFG_FILE))

kernel-defconfig: kernel-env $(KERNEL_CHECKOUT) $(BOARD_BSP) $(KERNEL_PATCH)
	$(Q)mkdir -p $(KERNEL_OUTPUT)
	$(Q)mkdir -p $(KERNEL_CONFIG_DIR)
	$(Q)$(if $(KCFG_BUILTIN),,cp $(KCFG_FILE) $(KERNEL_CONFIG_DIR))
	$(C_PATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) $(_KCFG)

ifneq ($(LINUX_NEW),)
ifneq ($(LINUX_NEW),$(LINUX))
NEW_KCFG_FILE=$(_BSP_CONFIG)/linux_$(LINUX_NEW)_defconfig
NEW_PREBUILT_KERNEL_DIR=$(subst $(LINUX),$(LINUX_NEW),$(PREBUILT_KERNEL_DIR))

kernel-cloneconfig: $(BOARD_BSP)
	$(Q)cp $(KCFG_FILE) $(NEW_KCFG_FILE)
	$(Q)sed -i -e "s%^\(LINUX.*?= \).*%\1$(LINUX_NEW)%g" $(BOARD_DIR)/Makefile
	$(Q)mkdir -p $(NEW_PREBUILT_KERNEL_DIR)
else
kernel-cloneconfig:
	$(Q)echo $(LINUX_NEW) already exists!
endif
kernel-new: kernel-clone
kernel-clone: kernel-cloneconfig
endif

PHONY += kernel-new kernel-clone kernel-cloneconfig

#
# kernel remove oldnoconfig after 4.19 and use olddefconfig instead,
# see commit: 312ee68752faaa553499775d2c191ff7a883826f kconfig: announce removal of oldnoconfig if used
#        and: 04c459d204484fa4747d29c24f00df11fe6334d4 kconfig: remove oldnoconfig target
#

ifeq ($(findstring kernel,$(MAKECMDGOALS)),kernel)
  KCONFIG_MAKEFILE := $(KERNEL_SRC)/scripts/kconfig/Makefile
  KERNEL_OLDDEFCONFIG := olddefconfig
  ifeq ($(KCONFIG_MAKEFILE), $(wildcard $(KCONFIG_MAKEFILE)))
    ifneq ($(shell grep olddefconfig -q $(KCONFIG_MAKEFILE); echo $$?),0)
      ifneq ($(shell grep oldnoconfig -q $(KCONFIG_MAKEFILE); echo $$?),0)
        KERNEL_OLDDEFCONFIG := oldconfig
      else
        KERNEL_OLDDEFCONFIG := oldnoconfig
      endif
    endif
  endif
endif

kernel-oldnoconfig: kernel-olddefconfig
kernel-olddefconfig:
	$(C_PATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) $(KERNEL_OLDDEFCONFIG)

kernel-oldconfig:
	$(C_PATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) oldconfig

kernel-menuconfig:
	$(C_PATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) menuconfig


PHONY += kernel-checkout kernel-patch kernel-defconfig kernel-oldnoconfig kernel-olddefconfig kernel-oldconfig kernel-menuconfig

# Build Kernel

KERNEL_FEATURE_TOOL := tools/kernel/feature.sh

FPL ?= 1
ifeq ($(filter $(FEATURE),debug module boot nfsroot initrd), $(FEATURE))
  FPL := 0
endif
ifeq ($(FEATURE),boot,module)
  FPL := 0
endif

FEATURE_PATCHED_TAG := $(KERNEL_SRC)/.feature.patched

kernel-feature:
	@if [ $(FPL) -eq 0 -o ! -f $(FEATURE_PATCHED_TAG) ]; then \
	  $(KERNEL_FEATURE_TOOL) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_OUTPUT) "$(FEATURE)"; \
	  if [ $(FPL) -eq 1 ]; then touch $(FEATURE_PATCHED_TAG); fi; \
	else \
	  echo "ERR: feature patchset has been applied, if want, please pass 'FPL=0' or 'make kernel-checkout' at first." && exit 1; \
	fi

feature: kernel-feature
features: feature
kernel-features: feature
k-f: feature
f: feature

kernel-feature-list:
	$(Q)echo [ $(FEATURE_DIR) ]:
	$(Q)find $(FEATURE_DIR) -mindepth 1 | sed -e "s%$(FEATURE_DIR)/%%g" | sort | sed -e "s%\(^[^/]*$$\)%  + \1%g" | sed -e "s%[^/]*/.*/%      * %g" | sed -e "s%[^/]*/%    - %g"

kernel-features-list: kernel-feature-list
features-list: kernel-feature-list
feature-list: kernel-feature-list
k-f-l: feature-list
f-l: k-f-l

ifneq ($(module),)
  ifneq ($(FEATURE),)
    FEATURE += module
  else
    FEATURE := module
  endif
endif

PHONY += kernel-feature feature features kernel-features k-f f kernel-feature-list kernel-features-list features-list k-f-l f-l

kernel-init:
	$(Q)make kernel-config
	$(Q)make kernel-$(KERNEL_OLDDEFCONFIG)
	$(Q)make kernel KT=$(IMAGE)

rootdir-init:
	$(Q)make rootdir-clean
	$(Q)make rootdir
	$(Q)make root-install

module-init:
	$(Q)make modules
	$(Q)make modules-install

feature-init: FORCE
ifneq ($(FEATURE),)
	make feature FEATURE="$(FEATURE)"
	make kernel-init
	make rootdir-init
ifeq ($(findstring module,$(FEATURE)),module)
	make module-init
endif
	if [ "$(TEST_RD)" != "/dev/nfs" ]; then make root-rebuild; fi
endif

kernel-feature-test: test
kernel-features-test: kernel-feature-test
features-test: kernel-feature-test
feature-test: kernel-feature-test
k-f-t: feature-test
f-t: k-f-t

PHONY += kernel-init rootdir-init module-init feature-init kernel-feature-test kernel-features-test features-test feature-test k-f-t f-t

IMAGE := $(notdir $(ORIIMG))

ifeq ($(U),1)
  IMAGE := uImage
endif

# Default kernel target is kernel image
KT ?= $(IMAGE)
ifneq ($(x),)
  KT := $(x)
endif

# Allow to accept external kernel compile options, such as XXX_CONFIG=y
KOPTS ?=

ifeq ($(findstring /dev/null,$(ROOTDEV)),/dev/null)
  ROOT_RD := root-rd
  # directory is ok, but is not compressed cpio
  KOPTS   += CONFIG_INITRAMFS_SOURCE=$(IROOTFS)
else
  KOPTS   += CONFIG_INITRAMFS_SOURCE=
endif

KMAKE_CMD := make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC)
KMAKE_CMD += ARCH=$(ARCH) LOADADDR=$(KRN_ADDR) CROSS_COMPILE=$(CCPRE) V=$(V) $(KOPTS)
KMAKE_CMD += -j$(JOBS)
KMAKE_CMD += $(KT) $(KM)

# Update bootargs in dts if exists, some boards not support -append
ifneq ($(DTS),)
  ifeq ($(DTS),$(wildcard $(DTS)))

# FIXME: must introduce gcc -E to translate #define, #include commands for customized dts at first
dtb: $(DTS)
	@echo "Building dtb ..."
	@echo "  DTS: $(DTS)"
	@echo "  DTB: $(DTB)"
	$(Q)sed -i -e "s%.*bootargs.*=.*;%\t\tbootargs = \"$(CMDLINE)\";%g" $(DTS)
ifeq ($(_DTS),)
	$(Q)make kernel KT=$(DTB_TARGET)
else
	$(Q)sed -i -e "s%^#include%/include/%g" $(DTS)
	$(Q)mkdir -p $(dir $(DTB))
	$(Q)dtc -I dts -O dtb -o $(DTB) $(DTS)
endif

# Pass kernel command line in dts, require to build dts for every boot
KCLI_DTS ?= 0
ifeq ($(KCLI_DTS),1)
  BOOT_DTB := dtb
endif
KERNEL_DTB := dtb

PHONY += dtb

  endif
endif

# Ignore DTB and RD dependency if KT is not kernel image
ifeq ($(KT),$(IMAGE))
  KERNEL_DEPS := $(CC_TOOLCHAIN) $(KERNEL_DTB) $(ROOT_RD)
endif

ifeq ($(filter _kernel-setconfig,$(MAKECMDGOALS)),_kernel-setconfig)
  ksetconfig := 1
endif

# Caching commandline variables
makeclivar := $(-*-command-variables-*-)

ifeq ($(ksetconfig),1)

# y=MODULE, n=MODULE, m=MODULE, c=MODULE, s=STR, v=VALUE
ifneq ($(m),)
  KCONFIG_SET_OPT := -m $(m)
  KCONFIG_GET_OPT := -s $(m)
  KCONFIG_OPR := m
  KCONFIG_OPT := $(m)
endif

# c/o added for module option, when it is not the same as module name
ifneq ($(c),)
  KCONFIG_SET_OPT := -m $(c)
  KCONFIG_GET_OPT := -s $(c)
  KCONFIG_OPR := m
  KCONFIG_OPT := $(c)
endif

ifneq ($(o),)
  KCONFIG_SET_OPT := -m $(o)
  KCONFIG_GET_OPT := -s $(o)
  KCONFIG_OPR := m
  KCONFIG_OPT := $(o)
endif

ifneq ($(s),)
  tmp := $(subst =,$(space),$(s))
  KCONFIG_SET_OPT := --set-str $(tmp)
  KCONFIG_OPT := $(firstword $(tmp))
  KCONFIG_GET_OPT := -s $(KCONFIG_OPT)
  KCONFIG_OPR := s
endif

ifneq ($(v),)
  tmp := $(subst =,$(space),$(v))
  KCONFIG_SET_OPT := --set-val $(tmp)
  KCONFIG_OPT := $(firstword $(tmp))
  KCONFIG_GET_OPT := -s $(KCONFIG_OPT)
  KCONFIG_OPR := v
endif

ifneq ($(y),)
  KCONFIG_SET_OPT := -e $(y)
  KCONFIG_GET_OPT := -s $(y)
  KCONFIG_OPR := y
  KCONFIG_OPT := $(y)
endif

ifneq ($(n),)
  KCONFIG_SET_OPT := -d $(n)
  KCONFIG_GET_OPT := -s $(n)
  KCONFIG_OPR := n
  KCONFIG_OPT := $(n)
endif

endif #ksetconfig

ifeq ($(filter _kernel-getconfig,$(MAKECMDGOALS)),_kernel-getconfig)
  ifneq ($(o),)
    KCONFIG_GET_OPT := -s $(o)
  endif
endif

ifeq ($(filter k-gc,$(MAKECMDGOALS)),k-gc)
  o ?= $m
endif

ifeq ($(filter kernel-getconfig,$(MAKECMDGOALS)),kernel-getconfig)
  o ?= $m
endif

kernel-getcfg: kernel-getconfig
kernel-getconfig: FORCE
	$(Q)$(if $(o), $(foreach _o, $(shell echo $(o) | tr ',' ' '), \
		__o=$(shell echo $(_o) | tr '[a-z]' '[A-Z]') && \
		echo "\nGetting kernel config: $$__o ...\n" && make $(S) _kernel-getconfig o=$$__o;) echo '')

_kernel-getconfig:
	$(Q)printf "option state: $(o)="&& $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_GET_OPT)
	$(Q)egrep -iH "_$(o)( |=|_)" $(DEFAULT_KCONFIG) | sed -e "s%$(TOP_DIR)/%%g"

kernel-config: kernel-setconfig
kernel-setcfg: kernel-setconfig
kernel-setconfig: FORCE
	$(Q)$(if $(makeclivar), $(foreach o, $(foreach setting,$(foreach p,y n m c o s v,$(filter $(p)=%,$(makeclivar))), \
		$(shell p=$(shell echo $(setting) | cut -d'=' -f1) && \
		echo $(setting) | cut -d'=' -f2- | tr ',' '\n' | xargs -i echo $$p={} | tr '\n' ' ')), \
		echo "\nSetting kernel config: $o ...\n" && make $(S) _kernel-setconfig y= n= m= s= v= c= o= $o;), echo '')

_kernel-setconfig:
	$(Q)$(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_SET_OPT)
	$(Q)echo "Enabling new kernel config: $(KCONFIG_OPT) ..."
ifeq ($(KCONFIG_OPR),m)
	$(Q)$(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -e MODULES
	$(Q)$(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -e MODULES_UNLOAD
	$(Q)make kernel KT=$(KERNEL_OLDDEFCONFIG)
	$(Q)make kernel KT=prepare
else
	$(Q)make kernel KT=$(KERNEL_OLDDEFCONFIG)
endif
	$(Q)echo "\nChecking kernel config: $(KCONFIG_OPT) ...\n"
	$(Q)printf "option state: $(KCONFIG_OPT)=" && $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_GET_OPT)
	$(Q)egrep -iH "_$(KCONFIG_OPT)(_|=| )" $(DEFAULT_KCONFIG) | sed -e "s%$(TOP_DIR)/%%g"

k-sc: kernel-setconfig
k-gc: kernel-getconfig

PHONY += kernel-getcfg kernel-getconfig kernel-config kernel-setcfg kernel-setconfig _kernel-getconfig _kernel-setconfig k-sc k-gc

module-config: module-setconfig
modules-config: module-setconfig

module-getconfig: kernel-getconfig
module-setconfig: kernel-setconfig
m-gc: module-getconfig
m-sc: module-setconfig

PHONY += module-getconfig module-setconfig m-gc m-sc modules-config module-config

kernel-help:
	$(Q)make kernel KT=help

kernel: kernel-env $(KERNEL_DEPS)
	$(C_PATH) $(KMAKE_CMD)

kernel-build: kernel

KERNEL_CALLTRACE_TOOL := tools/kernel/calltrace-helper.sh

ifeq ($(findstring calltrace,$(MAKECMDGOALS)),calltrace)
  ifneq ($(lastcall),)
    LASTCALL ?= $(lastcall)
  endif
  ifeq ($(LASTCALL),)
    $(error make kernel-calltrace lastcall=func+offset/length)
  endif
endif

vmlinux:
	@if [ ! -f $(VMLINUX) ]; then \
	  echo "ERR: No $(VMLINUX) found, please compile with 'make kernel'" && exit 1; \
	fi

PHONY += vmlinux

calltrace: kernel-calltrace
kernel-calltrace: vmlinux
	$(Q)$(KERNEL_CALLTRACE_TOOL) $(VMLINUX) $(LASTCALL) $(KERNEL_ABS_SRC) "$(C_PATH)" "$(CCPRE)"

PHONY += kernel-calltrace calltrace

k-h: kernel-help
k-d: kernel-source
k-o: kernel-checkout
k-p: kernel-patch
k-c: kernel-defconfig
k-o-c: kernel-oldconfig
k-m: kernel-menuconfig
k-b: kernel
k: kernel

kernel-prepare: kernel-env kernel-checkout kernel-patch kernel-defconfig
kernel-auto: kernel-prepare kernel
kernel-full: kernel-download kernel-prepare kernel
kernel-all: kernel-full kernel-save kernel-saveconfig

# Simplify testing
prepare: kernel-prepare
auto: kernel-auto
full: kernel-full

PHONY += kernel-help kernel kernel-build k-h k-d k-o k-p k-c k-o-c k-m k-b k kernel-prepare kernel-auto kernel-full prepare auto full kernel-all

# Uboot targets
COMMIT_UBOOT  ?= $(call __v,COMMIT,UBOOT)
ifneq ($(COMMIT_UBOOT),)
  _UBOOT := $(COMMIT_UBOOT)
else
  _UBOOT := $(UBOOT)
endif

# Configure Uboot
uboot-checkout:
	cd $(UBOOT_SRC) && git checkout -f $(_UBOOT) && git clean -fdx && cd $(TOP_DIR)


PHONY += uboot-checkout

BCO ?= 0
#UBOOT ?= master
ifeq ($(BCO),1)
  UBOOT_CHECKOUT := uboot-checkout
endif

UP ?= 0

# Verify BOOTDEV argument
ifneq ($(BOOTDEV),)
  # If Uboot version specific bootdev list defined, use it
   _BOOTDEV_LIST=$(call __v,BOOTDEV_LIST,UBOOT)
  ifneq ($(_BOOTDEV_LIST),)
    override BOOTDEV_LIST := $(_BOOTDEV_LIST)
  endif
  ifneq ($(BOOTDEV_LIST),)
    ifneq ($(filter $(BOOTDEV), $(BOOTDEV_LIST)), $(BOOTDEV))
      $(error Uboot Supported BOOTDEV list: $(BOOTDEV_LIST))
    endif
  endif
endif

PFLASH_BASE ?= 0
PFLASH_SIZE ?= 0
BOOTDEV ?= flash
KRN_ADDR ?= -
KRN_SIZE ?= 0
RDK_ADDR ?= -
RDK_SIZE ?= 0
DTB_ADDR ?= -
DTB_SIZE ?= 0
UCFG_DIR := u-boot/include/configs

ifeq ($(findstring sd,$(BOOTDEV)),sd)
  SD_BOOT ?= 1
endif
ifeq ($(findstring mmc,$(BOOTDEV)),mmc)
  SD_BOOT ?= 1
endif

# By default, boot from tftp
U_BOOT_CMD ?= bootcmd1
ifeq ($(SD_BOOT),1)
  U_BOOT_CMD := bootcmd2
endif
ifeq ($(findstring flash,$(BOOTDEV)),flash)
  U_BOOT_CMD := bootcmd3
endif

ifneq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  RDK_ADDR := -
endif
ifeq ($(DTS),)
  DTB_ADDR := -
endif

ifneq ($(U),)
  export U_BOOT_CMD IP ROUTE ROOTDEV BOOTDEV ROOTDIR PFLASH_BASE KRN_ADDR KRN_SIZE RDK_ADDR RDK_SIZE DTB_ADDR DTB_SIZE
endif

UBOOT_CONFIG_TOOL := $(TOOL_DIR)/uboot/config.sh
UBOOT_PATCH_TOOL  := tools/uboot/patch.sh
UBOOT_PATCHED_TAG := $(UBOOT_SRC)/.patched

_uboot-patch:
	@if [ ! -f $(UBOOT_PATCHED_TAG) ]; then \
	  if [ -n "$(UCONFIG)" ]; then $(UBOOT_CONFIG_TOOL) $(UCFG_DIR) $(UCONFIG); fi; \
	  $(UBOOT_PATCH_TOOL) $(BOARD) $(UBOOT) $(UBOOT_SRC) $(UBOOT_OUTPUT); \
	  touch $(UBOOT_PATCHED_TAG); \
	else \
	  echo "ERR: patchset has been applied, if want, please do 'make uboot-checkout' at first." && exit 1; \
	fi

uboot-patch: $(BOARD_BSP)
	@make $(S) _uboot-patch

ifeq ($(UP),1)
  UBOOT_PATCH := uboot-patch
endif

UBOOT_CONFIG_FILE ?= uboot_$(UBOOT)_defconfig

UCFG ?= $(UBOOT_CONFIG_FILE)
UBOOT_CONFIG_DIR := $(UBOOT_SRC)/configs

ifeq ($(UCFG),$(UBOOT_CONFIG_FILE))
  UCFG_FILE := $(_BSP_CONFIG)/$(UCFG)
else
  ifeq ($(UCFG), $(wildcard $(UCFG)))
    UCFG_FILE := $(UCFG)
  else
    TMP := $(_BSP_CONFIG)/$(UCFG)
    ifeq ($(TMP), $(wildcard $(TMP)))
      UCFG_FILE := $(UCFG)
    else
      TMP := $(UBOOT_CONFIG_DIR)/$(UCFG)
      ifeq ($(TMP), $(wildcard $(TMP)))
        UCFG_FILE := $(TMP)
      else
        $(error $(UCFG): can not be found, please pass a valid uboot defconfig)
      endif
    endif
  endif
endif

ifeq ($(findstring $(UBOOT_CONFIG_DIR),$(UCFG_FILE)),$(UBOOT_CONFIG_DIR))
  UCFG_BUILTIN := 1
endif

_UCFG := $(notdir $(UCFG_FILE))

uboot-defconfig: uboot-env $(UBOOT_CHECKOUT) $(BOARD_BSP) $(UBOOT_PATCH)
	$(Q)mkdir -p $(UBOOT_OUTPUT)
	$(Q)$(if $(UCFG_BUILTIN),,cp $(UCFG_FILE) $(UBOOT_CONFIG_DIR))
	make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) $(_UCFG)

ifneq ($(UBOOT_NEW),)
ifneq ($(UBOOT_NEW),$(UBOOT))
NEW_UCFG_FILE=$(_BSP_CONFIG)/uboot_$(UBOOT_NEW)_defconfig
NEW_PREBUILT_UBOOT_DIR=$(subst $(UBOOT),$(UBOOT_NEW),$(PREBUILT_UBOOT_DIR))

uboot-cloneconfig: $(BOARD_BSP)
	$(Q)cp $(UCFG_FILE) $(NEW_UCFG_FILE)
	$(Q)sed -i -e "s%^\(UBOOT.*?=.*\)$(UBOOT)%\1$(UBOOT_NEW)%g" $(BOARD_DIR)/Makefile
	$(Q)mkdir -p $(NEW_PREBUILT_UBOOT_DIR)
endif
uboot-new: uboot-clone
uboot-clone: uboot-cloneconfig

PHONY += uboot-new uboot-clone uboot-cloneconfig
endif


uboot-olddefconfig:
	$(C_PATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) oldefconfig

uboot-oldconfig:
	$(C_PATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) oldconfig

uboot-menuconfig:
	$(C_PATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) menuconfig

# Specify uboot targets
UT ?= $(x)

# Build Uboot
uboot: uboot-env
	$(C_PATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(JOBS) $(UT)

uboot-help:
	$(Q)make uboot UT=help

uboot-build: uboot

uboot-prepare: uboot-env uboot-checkout uboot-patch uboot-defconfig
uboot-auto: uboot-prepare uboot
uboot-full: uboot-download uboot-prepare uboot
uboot-all: uboot-full uboot-save uboot-saveconfig

u-d: uboot-source
u-o: uboot-checkout
u-p: uboot-patch
u-c: uboot-defconfig
u-m: uboot-menuconfig
u-b: uboot
u: uboot

PHONY += uboot-patch uboot-help uboot-build uboot-prepare uboot-auto uboot-full u-d u-o u-p u-c -u-m u-b u uboot-all

# uboot specific part
ifeq ($(U),1)

# root uboot image
root-ud:
	$(Q)if [ ! -f "$(UROOTFS)" ]; then make root-ud-rebuild; fi

_root-ud-rebuild: FORCE
	@echo "LOG: Generating rootfs image for uboot ..."
	$(Q)mkimage -A $(ARCH) -O linux -T ramdisk -C none -d $(IROOTFS) $(UROOTFS)

root-ud-rebuild: root-rd _root-ud-rebuild

kernel-uimage:
ifeq ($(PBK), 0)
	make kernel KT=uImage
endif

ifneq ($(INVALID_ROOTFS),1)
$(UROOTFS): root-ud
U_ROOT_IMAGE = $(UROOTFS)
endif

$(UKIMAGE): kernel-uimage

U_KERNEL_IMAGE = $(UKIMAGE)

ifeq ($(DTB),$(wildcard $(DTB)))
  U_DTB_IMAGE=$(DTB)
endif

PHONY += $(U_KERNEL_IMAGE) $(U_ROOT_IMAGE)

export CMDLINE PFLASH_IMG PFLASH_SIZE PFLASH_BS SD_IMG U_ROOT_IMAGE RDK_SIZE U_DTB_IMAGE DTB_SIZE U_KERNEL_IMAGE KRN_SIZE TFTPBOOT BIMAGE ROUTE BOOTDEV

UBOOT_TFTP_TOOL   := $(TOOL_DIR)/uboot/tftp.sh
UBOOT_SD_TOOL     := $(TOOL_DIR)/uboot/sd.sh
UBOOT_PFLASH_TOOL := $(TOOL_DIR)/uboot/pflash.sh
UBOOT_ENV_TOOL    := $(TOOL_DIR)/uboot/env.sh

TFTP_IMGS := $(addprefix $(TFTPBOOT)/,ramdisk dtb uImage)

# require by env saving, whenever boot from pflash
PFLASH_IMG := $(TFTPBOOT)/pflash.img

SD_IMG     := $(TFTPBOOT)/sd.img
ENV_IMG    := $(TFTPBOOT)/env.img

export ENV_IMG

UBOOT_DEPS := $(U_DTB_IMAGE)
ifneq ($(UROOTFS),$(wildcard $(UROOTFS)))
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    UBOOT_DEPS += root-ud
  endif
endif
ifneq ($(UKIMAGE),$(wildcard $(UKIMAGE)))
  UBOOT_DEPS += kernel-uimage
endif

_uboot-images: $(UBOOT_DEPS)
ifeq ($(BOOTDEV),tftp)
	$(Q)$(UBOOT_TFTP_TOOL)
endif
ifeq ($(findstring flash,$(BOOTDEV)),flash)
	$(Q)$(UBOOT_PFLASH_TOOL)
endif
ifeq ($(SD_BOOT),1)
	$(Q)$(UBOOT_SD_TOOL)
endif

uboot-images: _uboot-images
	$(Q)$(UBOOT_CONFIG_TOOL)
	$(Q)$(UBOOT_ENV_TOOL)

uboot-images-clean:
	$(Q)rm -rf $(TFTP_IMGS) $(PFLASH_IMG) $(SD_IMG) $(ENV_IMG)

uboot-images-distclean: uboot-images-clean
	$(Q)rm -rf $(UROOTFS)
ifeq ($(PBK), 0)
	$(Q)rm -rf $(UKIMAGE)
endif

UBOOT_IMGS := uboot-images
UBOOT_IMGS_DISTCLEAN := uboot-images-distclean

PHONY += _uboot-images uboot-images uboot-images-clean uboot-images-distclean

endif # Uboot specific part


# Checkout kernel and Rootfs
checkout: kernel-checkout root-checkout

# Config Kernel and Rootfs
config: root-defconfig kernel-defconfig

# Build Kernel and Rootfs
build: root kernel


o: checkout
c: config
B: build

PHONY += checkout config build o c B

STRIP_CMD := $(C_PATH) $(CCPRE)strip -s

# Save the built images
root-save: $(BOARD_BSP)
	$(Q)mkdir -p $(PREBUILT_ROOT_DIR)
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	-cp $(BUILDROOT_IROOTFS) $(PREBUILT_ROOT_DIR)
ifneq ($(PORIIMG),)
	-cp $(LINUX_PKIMAGE) $(PREBUILT_KERNEL_DIR)
	-$(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(PORIIMG))
endif

kernel-save: $(BOARD_BSP)
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	-cp $(LINUX_KIMAGE) $(PREBUILT_KERNEL_DIR)
	-$(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(ORIIMG))
	-if [ -n "$(UORIIMG)" -a -f "$(LINUX_UKIMAGE)" ]; then cp $(LINUX_UKIMAGE) $(PREBUILT_KERNEL_DIR); fi
	-if [ -n "$(DTS)" -a -f "$(LINUX_DTB)" ]; then cp $(LINUX_DTB) $(PREBUILT_KERNEL_DIR); fi

uboot-save: $(BOARD_BSP)
	$(Q)mkdir -p $(PREBUILT_UBOOT_DIR)
	-cp $(UBOOT_BIMAGE) $(PREBUILT_UBOOT_DIR)


qemu-save: $(BOARD_BSP)
	$(Q)mkdir -p $(PREBUILT_QEMU_DIR)
	$(Q)$(foreach _QEMU_TARGET,$(subst $(comma),$(space),$(QEMU_TARGET)),make -C $(QEMU_OUTPUT)/$(_QEMU_TARGET) install V=$(V);echo '';)
	$(Q)make -C $(QEMU_OUTPUT) install V=$(V)

emulator-save: qemu-save

r-s: root-save
k-s: kernel-save
u-s: uboot-save
q-s: qemu-save
e-s: q-s

PHONY += root-save kernel-save uboot-save emulator-save qemu-save r-s k-s u-s e-s

uboot-saveconfig: uconfig-save

uconfig-save: $(BOARD_BSP)
	-$(C_PATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) savedefconfig
	$(Q)if [ -f $(UBOOT_OUTPUT)/defconfig ]; \
	then cp $(UBOOT_OUTPUT)/defconfig $(_BSP_CONFIG)/$(UBOOT_CONFIG_FILE); \
	else cp $(UBOOT_OUTPUT)/.config $(_BSP_CONFIG)/$(UBOOT_CONFIG_FILE); fi

# kernel < 2.6.36 doesn't support: `make savedefconfig`
kernel-saveconfig: kconfig-save

kconfig-save: $(BOARD_BSP)
	-$(C_PATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) CROSS_COMPILE=$(CCPRE) ARCH=$(ARCH) savedefconfig
	$(Q)if [ -f $(KERNEL_OUTPUT)/defconfig ]; \
	then cp $(KERNEL_OUTPUT)/defconfig $(_BSP_CONFIG)/$(KERNEL_CONFIG_FILE); \
	else cp $(KERNEL_OUTPUT)/.config $(_BSP_CONFIG)/$(KERNEL_CONFIG_FILE); fi

root-saveconfig: rconfig-save

rconfig-save: $(BOARD_BSP)
	make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) -j$(JOBS) savedefconfig
	$(Q)if [ $(shell grep -q BR2_DEFCONFIG $(ROOT_OUTPUT)/.config; echo $$?) -eq 0 ]; \
	then cp $(shell grep BR2_DEFCONFIG $(ROOT_OUTPUT)/.config | cut -d '=' -f2) $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	elif [ -f $(ROOT_OUTPUT)/defconfig ]; \
	then cp $(ROOT_OUTPUT)/defconfig $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	else cp $(ROOT_OUTPUT)/.config $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); fi

r-c-s: rconfig-save
u-c-s: uconfig-save
k-c-s: kconfig-save

save: root-save kernel-save rconfig-save kconfig-save

s: save

PHONY += uboot-saveconfig uconfig-save kernel-saveconfig kconfig-save root-saveconfig rconfig-save r-c-s u-c-s k-c-s save s

# Qemu options and kernel command lines

# Network configurations

# Verify NETDEV argument
ifneq ($(NETDEV),)
  # If Linux version specific netdev list defined, use it
   _NETDEV_LIST=$(call __v,NETDEV_LIST,LINUX)
  ifneq ($(_NETDEV_LIST),)
    override NETDEV_LIST := $(_NETDEV_LIST)
  endif
  ifneq ($(NETDEV_LIST),)
    ifneq ($(filter $(NETDEV), $(NETDEV_LIST)), $(NETDEV))
      ifeq ($(MACH), malta)
        EMULATOR += -kernel $(_KIMAGE)
      endif
      ifneq ($(filter $(BOARD),riscv32/virt riscv64/virt loongson/ls1b loongson/ls2k), $(BOARD))
        $(info $(shell $(EMULATOR) -M $(MACH) -net nic,model=?))
      endif
      $(error Kernel Supported NETDEV list: $(NETDEV_LIST))
    endif
  endif
endif

# TODO: net driver for $BOARD
#NET = " -net nic,model=smc91c111,macaddr=DE:AD:BE:EF:3E:03 -net tap"
NET ?=  -net nic,model=$(NETDEV) -net tap

ifeq ($(NETDEV), virtio)
  MACADDR_TOOL   := tools/qemu/macaddr.sh
  RANDOM_MACADDR := $(shell $(MACADDR_TOOL))
  NET += -device virtio-net-device,netdev=net0,mac=$(RANDOM_MACADDR) -netdev tap,id=net0
endif

# Kernel command line configuration
CMDLINE :=

# Init route and ip for guest
ROUTE := $(shell ip address show br0 | grep "inet " | sed -e "s%.*inet \([0-9\.]*\)/[0-9]* .*%\1%g")
TMP   := $(shell bash -c 'echo $$(($$RANDOM%230+11))')
IP    := $(basename $(ROUTE)).$(TMP)

CMDLINE += route=$(ROUTE)

# Default iface
IFACE   ?= eth0
CMDLINE += iface=$(IFACE)

ifeq ($(ROOTDEV),/dev/nfs)
  ifneq ($(shell lsmod | grep -q ^nfsd; echo $$?),0)
    $(error ERR: 'nfsd' module not inserted, please follow the steps to start nfs service: 1. insert nfsd module in host: 'modprobe nfsd', 2. restart nfs service in docker: '/configs/tools/restart-net-servers.sh')
  endif
  # ref: linux-stable/Documentation/filesystems/nfs/nfsroot.txt
  # Must specify iface while multiple exist, which happens on ls2k board and triggers not supported dhcp
  CMDLINE += nfsroot=$(ROUTE):$(ROOTDIR) rw ip=$(IP):$(ROUTE):$(ROUTE):255.255.255.0:linux-lab:$(IFACE):off
endif

ifeq ($(DEV_TYPE),hd)
  CMDLINE += rw fsck.repair=yes rootwait
endif

# Ramdisk init configuration
RDINIT ?= /init

ifeq ($(findstring /dev/null,$(ROOTDEV)),/dev/null)
  CMDLINE += rdinit=$(RDINIT)
else
  CMDLINE += root=$(ROOTDEV)
endif

# Extra kernel command line
CMDLINE += $(XKCLI)

# Graphic output? we prefer Serial port ;-)
G ?= 0

# Force using curses based graphic mode for bash/ssh login
ifneq ($(shell env | grep -q ^XDG; echo $$?), 0)
  XTERM := null

  ifeq ($(G), 1)
    override G := 2
  endif
endif

# Sharing with the 9p virtio protocol
# ref: https://wiki.qemu.org/Documentation/9psetup
SHARE ?= 0
SHARE_DIR ?= hostshare
HOST_SHARE_DIR ?= $(SHARE_DIR)
GUEST_SHARE_DIR ?= /hostshare
SHARE_TAG ?= hostshare
ifneq ($(SHARE),0)
  # FIXME: Disable uboot by default, vexpress-a9 boot with uboot can not use this feature, so, disable it if SHARE=1 give
  #        versatilepb works with 9pnet + uboot?
  ifeq ($(U),1)
    $(info LOG: file sharing enabled with SHARE=1, disable uboot for it breaks sharing)
    U := 0
    export U
  endif

  # Note: `-virtfs` uses `-device virtio-9p-pci`, requires more kernel options: PCI, VIRTIO_PCI, PCI_HOST_GENERIC
  # aarch64/virt supports `virtio-9p-device` and `virtio-9p-pci`
  # arm/vexpress-a9 only supports `virtio-9p-device`
  # x86_64/pc only supports `virtio-9p-pci`

  ifeq ($(NET9PDEV),)
     SHARE_OPT ?= -virtfs local,path=$(SHARE_DIR),security_model=passthrough,id=fsdev0,mount_tag=$(SHARE_TAG)
     # The above equals, NET9PDEV := virtio-9p-pci for below line
     # SHARE_OPT ?= -fsdev local,path=$(HOST_SHARE_DIR),security_model=passthrough,id=fsdev0 -device $(NET9PDEV),fsdev=fsdev0,mount_tag=$(SHARE_TAG)
  else
     SHARE_OPT ?= -fsdev local,path=$(HOST_SHARE_DIR),security_model=passthrough,id=fsdev0 -device $(NET9PDEV),fsdev=fsdev0,mount_tag=$(SHARE_TAG)
  endif

  CMDLINE += sharetag=$(SHARE_TAG) sharedir=$(GUEST_SHARE_DIR)
endif

# Console configurations
SERIAL  ?= ttyS0
CONSOLE ?= tty0

ifeq ($(G),0)
  CMDLINE += console=$(SERIAL)
else
  CMDLINE += console=$(CONSOLE)
endif

# Testing support
TEST ?= $(PREPARE)
TEST_PREPARE ?= $(subst $(comma),$(space),$(TEST))

ifeq ($(UBOOT),)
  override TEST_PREPARE := $(patsubst uboot%,,$(TEST_PREPARE))
endif
ifeq ($(QEMU),)
  override TEST_PREPARE := $(patsubst qemu%,,$(TEST_PREPARE))
endif

# Force running git submodule commands
GIT_FORCE := $(if $(TEST),--force,)
UPDATE_GITMODULE := git submodule update $(GIT_FORCE) --init --remote

# Some boards not support 'reboot' test, please use 'power' instead.
#
# reboot means run reboot command in Qemu guest
# power means run poweroff command in Qemu guest and poweron it via host
#
REBOOT_TYPE ?= power
TEST_REBOOT ?= 0

# Shutdown the board if 'poweroff -h/-n' or crash
ifeq ($(REBOOT_TYPE), reboot)
  ifneq ($(TEST_REBOOT),0)
    TEST_FINISH := reboot
  endif
else
  TEST_FINISH := poweroff
endif

ifneq ($(findstring reboot,$(TEST_FINISH)),reboot)
  EXIT_ACTION ?= -no-reboot
endif

# SMP configuration
SMP ?= 1

# If proxy kernel exists, hack the default -kernel option
ifneq ($(PORIIMG),)
  KERNEL_OPT ?= -kernel $(PKIMAGE) -device loader,file=$(KIMAGE),addr=$(KRN_ADDR)
else
  KERNEL_OPT ?= -kernel $(KIMAGE)
endif

EMULATOR_OPTS ?= -M $(MACH) -m $(MEM) $(NET) -smp $(SMP) $(KERNEL_OPT) $(EXIT_ACTION)
EMULATOR_OPTS += $(SHARE_OPT)

# Launch Qemu, prefer our own instead of the prebuilt one
BOOT_CMD := sudo $(EMULATOR) $(EMULATOR_OPTS)
ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    INITRD ?= 1
  endif

  ifneq ($(INITRD),)
    ifeq ($(INITRD),$(wildcard $(INITRD)))
      BOOT_CMD += -initrd $(INITRD)
    else
      BOOT_CMD += -initrd $(IROOTFS)
    endif
  endif

  ifneq ($(DTB),)
    ifeq ($(DTB),$(wildcard $(DTB)))
      BOOT_CMD += -dtb $(DTB)
    endif
  endif
else
  ifeq ($(SD_BOOT),1)
    BOOT_CMD += -drive if=sd,file=$(SD_IMG),format=raw,id=sd0
  endif

  # Load pflash for booting with uboot every time
  # pflash is at least used as the env storage
  BOOT_CMD += -drive if=pflash,file=$(PFLASH_IMG),format=raw
endif

ifeq ($(findstring /dev/hda,$(ROOTDEV)),/dev/hda)
  BOOT_CMD += -hda $(HROOTFS)
endif

ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  # Ref: https://blahcat.github.io/2018/01/07/building-a-debian-stretch-qemu-image-for-aarch64/
  ifeq ($(MACH), virt)
    BOOT_CMD += -drive if=none,file=$(HROOTFS),format=raw,id=virtio-sda -global virtio-blk-device.scsi=off -device virtio-scsi-device,id=scsi -device scsi-hd,drive=virtio-sda
  else
    BOOT_CMD += -hda $(HROOTFS)
  endif
endif

# FIXME: Currently, BOOTDEV and ROOTDEV can not be sed to sd/mmc at the same time
# but it should work when the rootfs is put in a specified partition of the same sdcard.
ifeq ($(findstring /dev/mmc,$(ROOTDEV)),/dev/mmc)
  BOOT_CMD += -drive if=sd,file=$(HROOTFS),format=raw,id=mmc0
endif

ifeq ($(findstring /dev/vda,$(ROOTDEV)),/dev/vda)
  # Ref: https://wiki.debian.org/Arm64Qemu
  BOOT_CMD += -drive if=none,file=$(HROOTFS),format=raw,id=virtio-vda -device virtio-blk-device,drive=virtio-vda
endif

ifeq ($(G),0)
  BOOT_CMD += -nographic
else
  ifeq ($(G), 2)
    BOOT_CMD += -curses
  endif
endif

# Add extra emulator options
BOOT_CMD += $(XOPTS)

D ?= 0
ifeq ($(D),1)
  DEBUG := 1
endif

# Must disable the kaslr feature while debugging, otherwise, breakpoint will not stop and just continue
# ref: https://unix.stackexchange.com/questions/396013/hardware-breakpoint-in-gdb-qemu-missing-start-kernel
#      https://www.spinics.net/lists/newbies/msg59708.html
ifeq ($(DEBUG),1)
    BOOT_CMD += -s
    # workaround error of x86_64: "Remote 'g' packet reply is too long:", just skip the "-S" option
    ifneq ($(XARCH),x86_64)
      BOOT_CMD += -S
    endif
    CMDLINE  += nokaslr
endif

# Debug not work with -enable-kvm
# KVM speedup for x86 architecture, assume our host is x86 currently
ifneq ($(DEBUG),1)
  KVM_DEV ?= /dev/kvm
  ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
    ifeq ($(KVM_DEV),$(wildcard $(KVM_DEV)))
      BOOT_CMD += -enable-kvm
    endif
  endif
endif

# Silence qemu warnings and errors
#ifneq ($(V), 1)
#  QUIET_OPT ?= 2>/dev/null
#endif
#BOOT_CMD += $(QUIET_OPT)

# ROOTDEV=/dev/nfs for file sharing between guest and host
# SHARE=1 is another method, but only work on some boards

SYSTEM_TOOL_DIR := system/tools

boot-init: FORCE
	$(Q)$(if $(FEATURE),$(foreach f, $(shell echo $(FEATURE) | tr ',' ' '), \
		[ -x $(SYSTEM_TOOL_DIR)/$f/test_host_before.sh ] && \
		$(SYSTEM_TOOL_DIR)/$f/test_host_before.sh $(ROOTDIR);) echo '')

boot-finish: FORCE
	$(Q)$(if $(FEATURE),$(foreach f, $(shell echo $(FEATURE) | tr ',' ' '), \
		[ -x $(SYSTEM_TOOL_DIR)/$f/test_host_after.sh ] && \
		$(SYSTEM_TOOL_DIR)/$f/test_host_after.sh $(ROOTDIR);) echo '')

PHONY += boot-init boot-finish

# Test support
ifneq ($(TEST),)
 ifeq ($(filter _boot, $(MAKECMDGOALS)), _boot)
  TEST_KCLI :=
  ifneq ($(FEATURE),)
    TEST_KCLI += feature=$(subst $(space),$(comma),$(strip $(FEATURE)))
    ifeq ($(findstring module,$(FEATURE)),module)
      TEST_KCLI += module=$(subst $(space),$(comma),$(strip $(MODULE)))
    endif
  endif
  ifeq ($(REBOOT_TYPE), reboot)
    ifneq ($(TEST_REBOOT),0)
      TEST_KCLI += reboot=$(TEST_REBOOT)
    endif
  endif
  ifneq ($(TEST_BEGIN),)
    TEST_KCLI += test_begin="$(TEST_BEGIN)"
  endif
  ifneq ($(TEST_END),)
    TEST_KCLI += test_end="$(TEST_END)"
  endif
  ifneq ($(TEST_FINISH),)
    TEST_KCLI += test_finish="$(TEST_FINISH)"
  endif

  TEST_CASE ?= $(TEST_CASES)
  ifneq ($(TEST_CASE),)
    TEST_KCLI += test_case="$(TEST_CASE)"
  endif

  MODULE_ARGS := $(foreach m_args,$(addsuffix _args,$(subst $(comma),$(space),$(MODULE))), \
	$(shell eval 'echo $(m_args)=\"'\$$$(m_args)'\"'))

  TEST_KCLI += $(MODULE_ARGS)

  CMDLINE += $(TEST_KCLI)
 endif
endif

# Strip begin,end and duplicated spaces
CMDLINE  := $(subst $space$space,$space,$(strip $(CMDLINE)))

ifeq ($(U),0)
  BOOT_CMD += -append '$(CMDLINE)'
endif

BOOT_TEST := default
ifneq ($(TEST_REBOOT), 0)
  ifeq ($(findstring power,$(REBOOT_TYPE)),power)
    BOOT_TEST := loop
  endif
endif

# By default, seconds
TIMEOUT ?= 0
TEST_TIMEOUT ?= $(TIMEOUT)
TEST_UBOOT ?= $(U)

ifneq ($(TEST_TIMEOUT),0)
  TEST_LOGGING    ?= $(TOP_DIR)/logging/$(XARCH)-$(MACH)-linux-$(LINUX)/$(shell date +"%Y%m%d-%H%M%S")
  TEST_ENV        ?= $(TEST_LOGGING)/boot.env
  TEST_LOG        ?= $(TEST_LOGGING)/boot.log

  # ref: https://fadeevab.com/how-to-setup-qemu-output-to-console-and-automate-using-shell-script/#3inputoutputthroughanamedpipefile
  # Must create pipe.in and pipe.out, if only one pipe, the guess output will work as guest input
  # and breaks uboot autoboot progress

  TEST_LOG_PIPE   ?= $(TEST_LOGGING)/boot.log.pipe
  TEST_LOG_PID    ?= $(TEST_LOGGING)/boot.log.pid
  TEST_LOG_READER ?= tools/qemu/reader.sh
  TEST_RET        ?= $(TEST_LOGGING)/boot.ret

  # Ref: /labs/linux-lab/logging/arm64-virt-linux-v5.1/20190520-145101/boot.lo
ifeq ($(findstring serial,$(XOPTS)),serial)
    XOPTS     := $(shell echo "$(XOPTS) " | sed -e "s%-serial [^ ]* %-serial mon:pipe:$(TEST_LOG_PIPE) %g")
else
    XOPTS     += -serial mon:pipe:$(TEST_LOG_PIPE)
endif

  TEST_BEFORE ?= mkdir -p $(TEST_LOGGING) && sync && mkfifo $(TEST_LOG_PIPE).in && mkfifo $(TEST_LOG_PIPE).out && touch $(TEST_LOG_PID) && make env-dump > $(TEST_ENV) \
	&& $(TEST_LOG_READER) $(TEST_LOG_PIPE) $(TEST_LOG) $(TEST_LOG_PID) 2>&1 \
	&& sleep 1 && sudo timeout $(TEST_TIMEOUT)
  TEST_AFTER  ?= ; echo \$$\$$? > $(TEST_RET); sudo kill -9 \$$\$$(cat $(TEST_LOG_PID)); \
	ret=\$$\$$(cat $(TEST_RET)) && [ \$$\$$ret -ne 0 ] && echo \"ERR: Boot timeout in $(TEST_TIMEOUT).\" && echo \"ERR: Log saved in $(TEST_LOG).\" && exit \$$\$$ret; \
	echo \"LOG: Boot run successfully.\"
  # If not support netowrk, should use the other root device
endif

TEST_XOPTS ?= $(XOPTS)
TEST_RD ?= /dev/nfs

export BOARD TEST_TIMEOUT TEST_LOGGING TEST_LOG TEST_LOG_PIPE TEST_LOG_PID TEST_XOPTS TEST_RET TEST_RD TEST_LOG_READER V

boot-test: $(BOARD_BSP)
	make _boot-test T_BEFORE="$(TEST_BEFORE)" T_AFTRE="$(TEST_AFTER)" MAKECLIVAR='$(makeclivar)'

_boot-test:
ifeq ($(BOOT_TEST), default)
	$(T_BEFORE) make boot $(MAKECLIVAR) U=$(TEST_UBOOT) XOPTS="$(TEST_XOPTS)" TEST=default ROOTDEV=$(TEST_RD) FEATURE=boot$(if $(FEATURE),$(shell echo ,$(FEATURE))) $(T_AFTRE)
else
	$(Q)$(foreach r,$(shell seq 0 $(TEST_REBOOT)), \
		echo "\nRebooting test: $r\n" && \
		$(T_BEFORE) make boot $(MAKECLIVAR) U=$(TEST_UBOOT) XOPTS="$(TEST_XOPTS)" TEST=default ROOTDEV=$(TEST_RD) FEATURE=boot$(if $(FEATURE),$(shell echo ,$(FEATURE))) $(T_AFTRE);)
endif

# Allow to disable feature-init
FEATURE_INIT ?= 1
FI ?= $(FEATURE_INIT)

r-t: raw-test
raw-test:
	make test FI=0

test: $(BOARD_BSP) $(TEST_PREPARE) FORCE
	if [ $(FI) -eq 1 -a -n "$(FEATURE)" ]; then make feature-init; fi
	make boot-init
	make boot-test
	make boot-finish

PHONY += _boot-test boot-test test r-t raw-test

# Boot dependencies

# Debug support
ifeq ($(DEBUG),1)

GDB         ?= $(C_PATH) $(CCPRE)gdb
ifeq ($(shell which gdb-multiarch >/dev/null 2>&1; echo $$?), 0)
  GDB_MARCH ?= 1
endif
ifeq ($(shell $(GDB) --version >/dev/null 2>&1; echo $$?), 0)
  GDB_ARCH  ?= 1
endif
ifneq ($(GDB_ARCH), 1)
  ifeq ($(GDB_MARCH), 1)
     GDB := gdb-multiarch
  else
     $(error ERR: Both of $(CCPATH)/$(CCPRE)gdb and gdb-multiarch not exist or not valid)
  endif
endif

VMLINUX      ?= $(KERNEL_OUTPUT)/vmlinux

GDB_CMD      ?= $(GDB) $(VMLINUX)
GDB_INIT     ?= $(TOP_DIR)/.gdbinit
HOME_GDB_INIT ?= $(HOME)/.gdbinit
# Force run as ubuntu to avoid permission issue of .gdbinit and ~/.gdbinit
GDB_USER     ?= ubuntu

# Xterm: lxterminal, terminator
ifeq ($(XTERM), null)
  XTERM_STATUS := 1
else
  XTERM ?= $(shell tools/xterm.sh lxterminal)
  # Testing should use non-interactive mode, otherwise, enable interactive.
  ifneq ($(TEST),)
    XTERM_CMD    ?= sudo -u $(GDB_USER) /bin/bash -c "$(GDB_CMD)"
  else
    XTERM_CMD    ?= $(XTERM) --working-directory=$(CURDIR) -T "$(GDB_CMD)" -e "$(GDB_CMD)"
  endif
  XTERM_STATUS := $(shell $(XTERM) --help >/dev/null 2>&1; echo $$?)
endif

ifeq ($(XTERM_STATUS), 0)
  DEBUG_CMD  := $(XTERM_CMD)
else
  DEBUG_CMD  := $(Q)echo "\nLOG: Please run this in another terminal:\n\n    " $(GDB_CMD) "\n"
endif

# FIXME: gdb not continue the commands in .gdbinit while runing with 'CASE=debug tools/testing/run.sh'
#        just ignore the do_fork breakpoint to workaround it.
_debug:
	$(Q)sudo -u $(GDB_USER) echo "add-auto-load-safe-path .gdbinit" > $(HOME_GDB_INIT)
	$(Q)$(DEBUG_CMD) &

_debug_init_1:
	$(Q)sudo -u $(GDB_USER) sed -i -e "/do_fork/s/^#*//g" $(GDB_INIT)

_debug_init_2:
	$(Q)sed -i -e "/do_fork/s/^#*/#/g" $(GDB_INIT)

ifneq ($(TEST_TIMEOUT),0)
  DEBUG_INIT := _debug_init_2
else
  DEBUG_INIT := _debug_init_1
endif
DEBUG_CLIENT := vmlinux $(DEBUG_INIT) _debug

PHONY += _debug _debug_init_1 _debug_init_2

endif # DEBUG = 1

_BOOT_DEPS ?=
_BOOT_DEPS += root-$(DEV_TYPE)
_BOOT_DEPS += $(UBOOT_IMGS)
_BOOT_DEPS += $(DEBUG_CLIENT)
_BOOT_DEPS += $(BOOT_DTB)

_boot: $(_BOOT_DEPS)
	$(BOOT_CMD)

BOOT_DEPS ?=
BOOT_DEPS += $(BOARD_BSP)

ifeq ($(filter _boot,$(MAKECMDGOALS)),_boot)
  ifeq ($(INVALID_ROOTFS),1)
    $(error rootfs: $(ROOTFS) is invalid or not exists)
  endif
  ifeq ($(INVALID_ROOTDEV),1)
    $(error rootdev: $(ROOTDEV) is invalid or not exists)
  endif
endif

boot: $(BOOT_DEPS)
	$(Q)make _boot

t: test
b: boot

PHONY += boot-test test _boot boot t b

debug:
	$(Q)make $(S) boot D=1

PHONY += debug

# Allinone
all: config build boot


PHONY += all

# Clean up

qemu-clean:
ifeq ($(QEMU_OUTPUT)/Makefile, $(wildcard $(QEMU_OUTPUT)/Makefile))
	-$(Q)make $(S) -C $(QEMU_OUTPUT) clean
endif

emulator-clean: qemu-clean

root-clean:
ifeq ($(ROOT_OUTPUT)/Makefile, $(wildcard $(ROOT_OUTPUT)/Makefile))
	-$(Q)make $(S) O=$(ROOT_OUTPUT) -C $(ROOT_SRC) clean
endif

uboot-clean: $(UBOOT_IMGS_DISTCLEAN)
ifeq ($(UBOOT_OUTPUT)/Makefile, $(wildcard $(UBOOT_OUTPUT)/Makefile))
	-$(Q)make $(S) O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) clean
endif

kernel-clean: kernel-modules-clean
ifeq ($(KERNEL_OUTPUT)/Makefile, $(wildcard $(KERNEL_OUTPUT)/Makefile))
	-$(Q)make $(S) O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) clean
endif

clean: emulator-clean qemu-clean root-clean kernel-clean rootdir-clean uboot-clean

PHONY += emulator-clean root-clean kernel-clean rootdir-clean uboot-clean clean

emulator-distclean:
ifeq ($(QEMU_OUTPUT)/Makefile, $(wildcard $(QEMU_OUTPUT)/Makefile))
	-$(Q)make $(S) -C $(QEMU_OUTPUT) distclean
	$(Q)rm -rf $(QEMU_OUTPUT)
endif

root-distclean:
ifeq ($(ROOT_OUTPUT)/Makefile, $(wildcard $(ROOT_OUTPUT)/Makefile))
	-$(Q)make $(S) O=$(ROOT_OUTPUT) -C $(ROOT_SRC) distclean
	$(Q)rm -rf $(ROOT_OUTPUT)
endif

uboot-distclean:
ifeq ($(UBOOT_OUTPUT)/Makefile, $(wildcard $(UBOOT_OUTPUT)/Makefile))
	-$(Q)make $(S) O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) distclean
	$(Q)rm -rf $(UBOOT_OUTPUT)
endif

kernel-distclean:
ifeq ($(KERNEL_OUTPUT)/Makefile, $(wildcard $(KERNEL_OUTPUT)/Makefile))
	-$(Q)make $(S) O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) distclean
	$(Q)rm -rf $(KERNEL_OUTPUT)
endif

rootdir-distclean: rootdir-clean

PHONY += emulator-distclean root-distclean uboot-distclean kernel-distclean rootdir-distclean

c-e: emulator-clean
c-r: root-clean
c-u: uboot-clean
c-k: kernel-clean
c: clean

dc-e: emulator-distclean
dc-r: root-distclean
dc-u: uboot-distclean
dc-k: kernel-distclean
dc: distclean

distclean: emulator-distclean root-distclean kernel-distclean rootdir-distclean uboot-distclean \
	toolchain-clean plugin-clean board-clean

fullclean: distclean
	$(Q)git clean -fdx

PHONY += c-e c-r c-u c-k c dc-e dc-r dc-u dc-k dc distclean

# Show the variables
ifeq ($(filter env-dump,$(MAKECMDGOALS)),env-dump)
VARS := $(shell cat boards/$(BOARD)/Makefile | egrep -v "^ *\#|ifeq|ifneq|else|endif"| cut -d'?' -f1 | cut -d'=' -f1 | tr -d ' ')
VARS += BOARD FEATURE TFTPBOOT
VARS += ROOTDIR ROOT_SRC ROOT_OUTPUT ROOT_GIT
VARS += KERNEL_SRC KERNEL_OUTPUT KERNEL_GIT UBOOT_SRC UBOOT_OUTPUT UBOOT_GIT
VARS += ROOT_CONFIG_PATH KERNEL_CONFIG_PATH UBOOT_CONFIG_PATH
VARS += IP ROUTE BOOT_CMD
VARS += LINUX_DTB QEMU_PATH QEMU_SYSTEM
VARS += TEST_TIMEOUT TEST_RD
endif

# Prepare build environment
GCC_LINUX  ?= $(call __v,GCC,LINUX)
CORI_LINUX ?= $(call __v,CORI,LINUX)

GCC_UBOOT  ?= $(call __v,GCC,UBOOT)
CORI_UBOOT ?= $(call __v,CORI,UBOOT)

GCC_QEMU  ?= $(call __v,GCC,QEMU)
CORI_QEMU ?= $(call __v,CORI,QEMU)

GCC_ROOT  ?= $(call __v,GCC,BUILDROOT)
CORI_ROOT ?= $(call __v,CORI,BUILDROOT)

ifneq ($(GCC),)
  # Force using internal CORI if GCC specified
  CORI := internal
  GCC_SWITCH := 1
endif
ifneq ($(CORI_LINUX)$(GCC_LINUX),)
  GCC_LINUX_SWITCH := 1
endif
ifneq ($(CORI_ROOT)$(GCC_ROOT),)
  GCC_ROOT_SWITCH := 1
endif
ifneq ($(CORI_UBOOT)$(GCC_UBOOT),)
  GCC_UBOOT_SWITCH := 1
endif
ifneq ($(CORI_QEMU)$(GCC_QEMU),)
  GCC_QEMU_SWITCH := 1
endif

kernel-env: kernel-env-prepare
kernel-env-prepare: env-prepare
ifeq ($(GCC_LINUX_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CORI_LINUX),CORI=$(CORI_LINUX)) $(if $(GCC_LINUX),GCC=$(GCC_LINUX))
endif

uboot-env: uboot-env-prepare
uboot-env-prepare: env-prepare
ifeq ($(GCC_UBOOT_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CORI_UBOOT),CORI=$(CORI_UBOOT)) $(if $(GCC_UBOOT),GCC=$(GCC_UBOOT))
endif

qemu-env: qemu-env-prepare
qemu-env-prepare: env-prepare
ifeq ($(GCC_QEMU_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CORI_QEMU),CORI=$(CORI_QEMU)) $(if $(GCC_QEMU),GCC=$(GCC_QEMU))
endif

root-env: root-env-prepare
root-env-prepare: env-prepare
ifeq ($(GCC_ROOT_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CORI_ROOT),CORI=$(CORI_ROOT)) $(if $(GCC_ROOT),GCC=$(GCC_ROOT))
endif

env: env-prepare
env-prepare: toolchain
ifeq ($(GCC_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CORI),CORI=$(CORI)) $(if $(GCC),GCC=$(GCC))
endif

env-dump:
	@echo \#[ $(BOARD) ]:
	@echo -n " "
	-@echo $(foreach v,$(VARS),"    $(v)=\"$($(v))\"\n") | tr -s '/'

ENV_SAVE_TOOL := $(TOOL_DIR)/save-env.sh

env-save: board-config

help:
	$(Q)cat README.md

h: help

PHONY += env env-prepare kernel-env kernel-env-prepare uboot-env uboot-env-prepare qemu-env qemu-env-prepare env-dump env-save help h

#
# override all of the above targets if the first target is XXX-run, treat left parts as its arguments, simplify input
# but warnings exists about 'overriding recipe for target 'xxx' when arguments are existing targets.
#
# ref: https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run#
#

# If the first argument is "xxx-run"...
first_target := $(firstword $(MAKECMDGOALS))
reserve_target := $(first_target:-run=)
_reserve_target := $(first_target:-x=)

ifeq ($(findstring -run,$(first_target)),-run)
  # use the rest as arguments for "run"
  RUN_ARGS := $(filter-out $(reserve_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):FORCE;@:)
endif

ifeq ($(findstring -x,$(first_target)),-x)
  # use the rest as arguments for "run"
  RUN_ARGS := $(filter-out $(reserve_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):FORCE;@:)
endif

BASIC_TARGETS := kernel uboot root
_BASIC_TARGETS := k u r
EXEC_TARGETS  := $(foreach t,$(BASIC_TARGETS),$(t:=-run))
_EXEC_TARGETS  := $(foreach t,$(_BASIC_TARGETS),$(t:=-x))

$(EXEC_TARGETS):
	make $(@:-run=) x=$(RUN_ARGS)

$(_EXEC_TARGETS):
	make $(@:-x=) x=$(RUN_ARGS)

PHONY += $(EXEC_TARGET)) $(_EXEC_TARGETS)

PHONY += FORCE

FORCE:

.PHONY: $(PHONY)
