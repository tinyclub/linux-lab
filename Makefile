#
# Core Makefile
#

TOP_DIR := $(CURDIR)

# Phony targets
PHONY :=
comma := ,
empty :=
space := $(empty) $(empty)

USER ?= ubuntu

# Check running host
LAB_ENV_ID=/home/$(USER)/Desktop/lab.desktop
ifneq ($(LAB_ENV_ID),$(wildcard $(LAB_ENV_ID)))
  ifneq (../../configs/linux-lab, $(wildcard ../../configs/linux-lab))
    $(error ERR: No Cloud Lab found, please refer to 'Download the lab' part of README.md)
  else
    $(error ERR: Please not try Linux Lab in local host, but use it with Cloud Lab, please refer to 'Run and login the lab' part of README.md)
  endif
endif

# Check running user, must as ubuntu
ifneq ($(shell whoami),$(USER))
  $(error ERR: Must run Linux Lab as general user: '$(USER)', not use it as root, please try 'su ubuntu'.)
endif

# Check permission issue, must available to ubuntu
ifneq ($(shell stat -c '%U' /.git/HEAD),$(USER))
  $(error ERR: Must make sure Cloud Lab and Linux Lab **NOT** belong to user: 'root', please change their owner in host: 'sudo chown $$USER:$$USER -R /path/to/cloud-lab')
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

# Supported apps and their version variable
APP_MAP ?= bsp:BSP kernel:LINUX root:BUILDROOT uboot:UBOOT qemu:QEMU

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
HOME_DIR    := /home/$(USER)/

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
BSP_PATCH  = $(BSP_DIR)/patch

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
#QEMU_GIT ?= https://github.com/qemu/qemu.git
QEMU_GIT ?= https://gitee.com/mirrors/qemu.git
_QEMU_GIT := $(QEMU_GIT)
_QEMU_SRC ?= qemu
QEMU_SRC ?= $(_QEMU_SRC)

#UBOOT_GIT ?= https://github.com/u-boot/u-boot.git
UBOOT_GIT ?= https://gitee.com/mirrors/u-boot.git
_UBOOT_GIT := $(UBOOT_GIT)
_UBOOT_SRC ?= u-boot
UBOOT_SRC ?= $(_UBOOT_SRC)

#KERNEL_GIT ?= https://github.com/tinyclub/linux-stable.git
KERNEL_GIT ?= https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git
_KERNEL_GIT := $(KERNEL_GIT)
# git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
_KERNEL_SRC ?= linux-stable
KERNEL_SRC ?= $(_KERNEL_SRC)

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
#ROOT_GIT ?= https://github.com/buildroot/buildroot
ROOT_GIT ?= https://gitee.com/mirrors/buildroot.git
_ROOT_GIT := $(ROOT_GIT)
_ROOT_SRC ?= buildroot
ROOT_SRC ?= $(_ROOT_SRC)

_LINUX=$(LINUX)
KERNEL_ABS_SRC := $(TOP_DIR)/$(KERNEL_SRC)
ROOT_ABS_SRC   := $(TOP_DIR)/$(ROOT_SRC)
UBOOT_ABS_SRC  := $(TOP_DIR)/$(UBOOT_SRC)
QEMU_ABS_SRC   := $(TOP_DIR)/$(QEMU_SRC)

BOARD_MAKEFILE      := $(BOARD_DIR)/Makefile

# Common functions

_uc = $(shell echo $1 | tr a-z A-Z)
_lc = $(shell echo $1 | tr A-Z a-z)
_stamp = $(3)/.stamp_$(1)-$(2)

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
$(if $(call __v,$1,$2),$(call __v,$1,$2),$(if $3,$3,$($1)))
endef
#$(shell a="$(call __v,$1,$2)"; if [ -n "$$a" ]; then echo "$$a"; else echo $($1); fi)

define __vs
 ifneq ($$(call __v,$(1),$(2)),)
  $(3) $(1) := $$(call __v,$(1),$(2))
 endif
endef

define _vs
 $(1) := $$(call _v,$(1),$(2))
endef

# $(BOARD_DIR)/Makefile.linux_$(LINUX)
define _f
$(3)/$(2).$(1)
endef

define _vf
$(call _f,$(if $(4),$(call _lc,$1)_$($1),$(1)),$(2),$(3))
endef

# include $(3)/$(2).lowcase($(1))_$(1)
define _i
  $(1)_$(2) := $$(call _vf,$(1),$(2),$(3),$(4))
  ifeq ($$($(1)_$(2)),$$(wildcard $$($(1)_$(2))))
    include $$($(1)_$(2))
  endif
endef

# include $(BOARD_DIR)/Makefile.linux_$(LINUX)
define _vi
$(call _i,$(1),$(2),$(3),1)
endef

define _bvi
$(call _vi,$(1),$(2),$(BOARD_DIR))
endef

define _bi
$(call _i,$(1),$(2),$(BOARD_DIR))
endef

define _ti
$(call _i,$(1),$(2),$(TOP_DIR))
endef

define _hi
$(call _i,$(1),$(2),$(HOME_DIR))
endef

# Include board detailed configuration
# Makefile.config/beforeconfig/afterconfig hooks for more

define board_config
$(call _bi,beforeconfig.private,Makefile)
$(call _bi,beforeconfig,Makefile)

$(call _bi,config.private,Makefile)
$(call _bi,config,Makefile)

$(call _bi,GCC,Makefile)
$(call _bi,ROOT,Makefile)
$(call _bi,NET,Makefile)
$(call _bvi,LINUX,Makefile)

$(call _bi,afterconfig,Makefile)
$(call _bi,afterconfig.private,Makefile)
endef

define fixup_arch
ifneq ($$(KERNEL_SRC),)
  ifneq ($$(_KERNEL_SRC),$$(KERNEL_SRC))
    KERNEL_ABS_SRC := $$(KERNEL_SRC)
  endif
endif
IS_ARCH = $$(shell cd $$(KERNEL_ABS_SRC); git show $$(call _v,LINUX,LINUX):arch/$$(ARCH)/boot >/dev/null 2>&1; echo $$$$?)
ifneq ($$(IS_ARCH),0)
  ARCH  := $$(XARCH)
endif
endef

# include Makefile.init if exist
# the .private version is for user local customization, should not be added in mainline repository
$(eval $(call _ti,init,Makefile))
$(eval $(call _ti,init.private,Makefile))
$(eval $(call _ti,config,Makefile))
$(eval $(call _ti,config.private,Makefile))

# Loading board configurations
ifneq ($(BOARD),)
  # include $(BOARD_DIR)/Makefile.init if exist
  $(eval $(call _bi,init.private,Makefile))
  $(eval $(call _bi,init,Makefile))
  include $(BOARD_MAKEFILE)
  # include $(BOARD_DIR)/Makefile.fini if exist
  $(eval $(call _bi,fini,Makefile))
  $(eval $(call _bi,fini.private,Makefile))
  $(eval $(call _bi,labconfig))
endif

$(eval $(call _ti,labconfig))
$(eval $(call _hi,labconfig))

# Customize kernel git repo and local dir
$(eval $(call __vs,KERNEL_SRC,LINUX))
$(eval $(call __vs,KERNEL_GIT,LINUX))

# Prepare build environment

define genbuildenv

GCC_$(1) = $$(call __v,GCC,$(1))
CCORI_$(1) = $$(call __v,CCORI,$(1))

ifeq ($$(findstring $(2),$$(MAKECMDGOALS)),$(2))
  ifneq ($$(CCORI_$(1))$$(GCC_$(1)),)
    ifeq ($$(CCORI_$(1))$$(CCORI),)
      CCORI := internal
    endif
    GCC_$(1)_SWITCH := 1
  endif
endif

endef # genbuildenv

#$(warning $(call genbuildenv,LINUX,kernel))
$(eval $(call genbuildenv,LINUX,kernel))

#$(warning $(call genbuildenv,UBOOT,uboot))
$(eval $(call genbuildenv,UBOOT,uboot))

#$(warning $(call genbuildenv,QEMU,qemu))
$(eval $(call genbuildenv,QEMU,qemu))

#$(warning $(call genbuildenv,BUILDROOT,root))
$(eval $(call genbuildenv,BUILDROOT,root))

ifneq ($(GCC),)
  # Force using internal CCORI if GCC specified
  ifeq ($(CCORI),)
    CCORI := internal
  endif
  GCC_SWITCH := 1
endif

# generate verify function
define genverify
 ifneq ($$($2),)
  ifneq ($$(BSP_$(1)),)
   ifeq ($$(BSP_$(1)), $$(wildcard $$(BSP_$(1))))
    $(2)_LIST ?= $$(shell ls $$(BSP_$(1)))
   endif
  endif
  # If Linux version specific qemu list defined, use it
  $$(eval $$(call __vs,$(2)_LIST,$$(if $(3),$(3),LINUX),override))
  ifneq ($$($(2)_LIST),)
    ifneq ($$(filter $$($2), $$($(2)_LIST)), $$($2))
      $$(if $(4),$$(eval $$(call $(4))))
      $$(error Supported $(2) list: $$($(2)_LIST))
    endif
  endif
 endif
 # Strip prefix of LINUX to get the real version, e.g. XXX-v3.10, XXX may be the customized repo name
 ifneq ($$($(1)_SRC),)
   ifneq ($$(_$(1)_SRC), $$($(1)_SRC))
    _$(2) := $$(subst $$(shell basename $$($(1)_SRC))-,,$$($(2)))
    $(1)_ABS_SRC := $$($(1)_SRC)
   endif
 endif

endef

# Verify LINUX argument
#$(warning $(call genverify,KERNEL,LINUX))
$(eval $(call genverify,KERNEL,LINUX))

# Verify ROOT argument
#$(warning $(call genverify,ROOT,BUILDROOT))
$(eval $(call genverify,ROOT,BUILDROOT))

# Verify UBOOT argument
#$(warning $(call genverify,UBOOT,UBOOT))
$(eval $(call genverify,UBOOT,UBOOT))

# Verify QEMU argument
#$(warning $(call genverify,QEMU,QEMU))
$(eval $(call genverify,QEMU,QEMU))

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
$(eval $(call __vs,ROOTFS,LINUX))
$(eval $(call __vs,BUILDROOT,LINUX))
$(eval $(call __vs,UBOOT,LINUX))
$(eval $(call __vs,QEMU,LINUX))

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
BSP_OUTPUT      := $(TOP_OUTPUT_ARCH)/bsp-$(MACH)

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

ifneq ($(LD_LIBRARY_PATH),)
  ifneq ($(LLPATH),)
    L_PATH=LD_LIBRARY_PATH=$(LLPATH):$(LD_LIBRARY_PATH)
  else
    L_PATH=LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)
  endif
else
  ifneq ($(LLPATH),)
    L_PATH=LD_LIBRARY_PATH=$(LLPATH)
  endif
endif

ifneq ($(CCPATH),)
  C_PATH ?= env PATH=$(CCPATH):$(PATH) $(L_PATH)
endif

#$(info Using gcc: $(CCPATH)/$(CCPRE)gcc, $(CCORI))

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
# PBU = 1, prebuilt uboot ; 0, new building qemu if exist
#
# Allow using contrary alias: k/kernel,r/root,d/dtb,q/qemu,u/uboot for PBK,PBR,PBD,PBQ,PBU
#
# Notes: the uppercase of d,q,u has been used for other cases,
# so, use the lowercase here.
#

define _pb
ifneq ($$($(call _lc,$1)),)
  ifeq ($$($(call _lc,$1))),1)
    PB$1 := 0
  else
    PB$1 := 1
  endif
endif

endef

define _lpb
_$(1) := $(subst x,,$(firstword $(foreach i,K U D R Q,$(findstring x$i,x$(call _uc,$(1))))))
ifneq ($$($1),)
  ifeq ($$($1),1)
    PB$$(_$(1)) := 0
  else
    PB$$(_$(1)) := 1
  endif
endif
ifneq ($(BUILD),)
  ifeq ($(filter $(1),$(BUILD)),$(1))
    PB$$(_$(1)) := 0
  endif
endif

endef # _lpb

define default_detectbuild
ifneq ($$($(2)),)
  override BUILD += $(1)
endif

endef

ifeq ($(BUILD),all)
  override BUILD :=
  $(foreach m,$(APP_MAP),$(eval $(call default_detectbuild,$(firstword $(subst :,$(space),$m)),$(lastword $(subst :,$(space),$m)))))
endif

#$(warning $(foreach x,K R D Q U,$(call _pb,$x)))
$(eval $(foreach x,K R D Q U,$(call _pb,$x)))

#$(warning $(foreach x,kernel root dtb qemu uboot,$(call _lpb,$x)))
$(eval $(foreach x,kernel root dtb qemu uboot,$(call _lpb,$x)))

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
$(eval $(call __vs,U,LINUX))
ifneq ($(U),0)
  QEMU_KIMAGE := $(BIMAGE)
else
  QEMU_KIMAGE := $(KIMAGE)
endif

# Root configurations

# TODO: buildroot defconfig for $ARCH

# Verify rootdev argument
#$(warning $(call genverify,ROOTDEV,ROOTDEV,,0))
$(eval $(call genverify,ROOTDEV,ROOTDEV,,0))

ROOTDEV ?= /dev/ram0
$(eval $(call _vs,ROOTDEV,LINUX))
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
ROOTFS_TYPE_TOOL  := tools/root/rootfs_type.sh
ROOTDEV_TYPE_TOOL := tools/root/rootdev_type.sh

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

BSP_SUBMODULE=$(shell grep $(BOARD)/bsp -q $(TOP_DIR)/.gitmodules; echo $$?)
ifeq ($(BSP_SUBMODULE),0)
  ifneq ($(BSP_ROOT),$(wildcard $(BSP_ROOT)))
    BSP_DOWNLOADED := 0
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

ifneq ($(MAKECMDGOALS),)
 ifeq ($(filter $(MAKECMDGOALS),_boot root-dir-rebuild root-rd-rebuild root-hd-rebuild),$(MAKECMDGOALS))
  ifeq ($(findstring $(BSP_DIR),$(ROOTFS)),$(BSP_DIR))
    ifeq ($(BSP_DOWNLOADED),0)
      # Allow download bsp automatically
      INVALID_ROOTFS := 0
      INVALID_ROOTDEV := 0
    endif
  endif
  ifeq ($(INVALID_ROOTFS),1)
    $(error rootfs: $(ROOTFS_TYPE), try run 'make bsp' to get newer rootfs.)
  endif
  ifeq ($(INVALID_ROOTDEV),1)
    $(error rootdev: $(ROOTDEV_TYPE), try run 'make bsp' to get newer rootfs.)
  endif
 endif
endif

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

# Board targets

BOARD_TOOL := ${TOOL_DIR}/board/show.sh

export GREP_COLOR=32;40
FILTER   ?= ^[ [\./_a-z0-9-]* \]|^ *[\_a-zA-Z0-9]* *
# all: 0, plugin: 1, noplugin: 2
BTYPE    ?= ^_BASE|^_PLUGIN

define getboardvars
cat $(BOARD_MAKEFILE) | egrep -v "^ *\#|ifeq|ifneq|else|endif|include |call |eval " | egrep -v "_BASE|_PLUGIN"  | cut -d'?' -f1 | cut -d'=' -f1 | cut -d':' -f1 | tr -d ' '
endef

define showboardvars
echo [ $(BOARD) ]:"\n" $(foreach v,$(or $(VAR),$(or $(1),$(shell $(call getboardvars)))),"    $(v) = $($(v)) \n") | tr -s '/' | egrep --colour=auto "$(FILTER)"
endef

board: board-save plugin-save board-cleanstamp board-show

board-cleanstamp:
ifneq ($(BOARD),$(BOARD_CONFIG))
	$(Q)make -s cleanstamp
endif

board-show:
	$(Q)$(call showboardvars)

board-init: cleanstamp

board-clean:
	$(Q)rm -rf .board_config

board-save:
ifneq ($(BOARD),)
  ifeq ($(board),)
    ifneq ($(BOARD),$(BOARD_CONFIG))
	$(Q)$(shell echo "$(BOARD)" > .board_config)
    endif
  endif
endif

PHONY += board board-init board-clean board-save board-cleanstamp

board-edit:
	$(Q)vim $(BOARD_MAKEFILE)

board-config: board-save cleanstamp
	$(foreach vs, $(MAKEOVERRIDES), tools/board/config.sh $(vs) $(BOARD_MAKEFILE) $(LINUX);)

PHONY += board-config board-edit

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

PHONY += plugin-save plugin-clean plugin plugin-list plugin-list-full

# List targets for boards and plugins

INFO ?= raw

ifneq ($(INFO),raw)

define getboardlist
find $(BOARDS_DIR)/$(2) -maxdepth 3 -name "Makefile" -exec egrep -H "$(or $(1),$(BTYPE))" {} \; | sort -t':' -k2 | cut -d':' -f1 | sed -e "s%boards/\(.*\)/Makefile%\1%g"
endef

list-default:
	$(Q)$(foreach x,$(shell $(call getboardlist)),make -s board-show b=$x VAR="ARCH CPU LINUX ROOTDEV";)

list-board:
	$(Q)$(foreach x,$(shell $(call getboardlist)),make -s board-show b=$x VAR="ARCH";)

list-short:
	$(Q)$(foreach x,$(shell $(call getboardlist)),make -s board-show b=$x VAR="ARCH LINUX";)

list-base:
	$(Q)$(foreach x,$(shell $(call getboardlist,"^_BASE")),make -s board-show b=$x VAR="ARCH";)

list-plugin:
	$(Q)$(foreach x,$(shell $(call getboardlist,"^_PLUGIN")),make -s board-show b=$x VAR="ARCH";)

list-full:
	$(Q)$(foreach x,$(shell $(call getboardlist)),make -s board-show b=$x;)
else

board-info:
	$(Q)find $(BOARDS_DIR)/$(BOARD) -maxdepth 3 -name "Makefile" -exec egrep -H "$(BTYPE)" {} \; \
		| sort -t':' -k2 | cut -d':' -f1 | xargs -i $(BOARD_TOOL) {} $(PLUGIN) \
		| egrep -v "/module" \
		| sed -e "s%boards/\(.*\)/Makefile%\1%g" \
		| sed -e "s/[[:digit:]]\{2,\}\t/  /g;s/[[:digit:]]\{1,\}\t/ /g" \
		| egrep -v " *_BASE| *_PLUGIN| *#" | egrep -v "^[[:space:]]*$$" \
		| egrep -v "^[[:space:]]*include |call |eval " | egrep --colour=auto "$(FILTER)"


list-default:
	$(Q)make $(S) board-info BOARD= FILTER="^ *ARCH |^\[ [\./_a-z0-9-]* \]|^ *CPU|^ *LINUX|^ *ROOTDEV"

list-board:
	$(Q)make $(S) board-info BOARD= FILTER="^\[ [\./_a-z0-9-]* \]|^ *ARCH"

list-short:
	$(Q)make $(S) board-info BOARD= FILTER="^\[ [\./_a-z0-9-]* \]|^ *LINUX|^ *ARCH"

list-base:
	$(Q)make $(S) list BTYPE="^_BASE"

list-plugin:
	$(Q)make $(S) list BTYPE="^_PLUGIN"

list-full:
	$(Q)make $(S) board-info BOARD=
endif

list-%: FORCE
	$(Q)if [ -n "$($(call _uc,$(subst list-,,$@))_LIST)" ]; then \
		echo $($(call _uc,$(subst list-,,$@))_LIST); \
	else					\
		if [ $(shell make --dry-run -s $(subst list-,,$@)-list >/dev/null 2>&1; echo $$?) -eq 0 ]; then \
			make -s $(subst list-,,$@)-list; \
		fi		\
	fi


PHONY += board-info list list-base list-plugin list-full

# Define generic target deps support
define make_qemu
$(C_PATH) make -C $(QEMU_OUTPUT) -j$(JOBS) V=$(V)
endef

define make_kernel
$(C_PATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) LOADADDR=$(KRN_ADDR) CROSS_COMPILE=$(CCPRE) V=$(V) $(KOPTS) -j$(JOBS) $(1)
endef

define make_root
$(C_PATH) make O=$(ROOT_OUTPUT) -C $(ROOT_SRC) V=$(V) -j$(JOBS) $(1)
endef

define make_uboot
$(C_PATH) make O=$(UBOOT_OUTPUT) -C $(UBOOT_SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(JOBS) $(1)
endef

# generate target dependencies
define gendeps
_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_OUTPUT))

$$(call _stamp_$(1),%):
	$$(Q)make $$(subst $$($(call _uc,$(1))_OUTPUT)/.stamp_,,$$@)
	$$(Q)touch $$@

$(1)-source: $$(call _stamp_$(1),outdir)
$(1)-checkout: $$(call _stamp_$(1),source)
$(1)-patch: $$(call _stamp_$(1),checkout)
$(1)-defconfig: $$(call _stamp_$(1),patch)
$(1)-defconfig: $$(call _stamp_$(1),env)
$(1)-modules-install: $$(call _stamp_$(1),modules)
$(1)-modules-install-km: $$(call _stamp_$(1),modules-km)
$(1)-help: $$(call _stamp_$(1),defconfig)

$(1)_defconfig_childs := $(1)-config $(1)-getconfig $(1)-saveconfig $(1)-menuconfig $(1)-oldconfig $(1)-oldnoconfig $(1)-olddefconfig $(1)-feature $(1)-build $(1)-buildroot $(1)-modules $(1)-modules-km
ifeq ($(firstword $(MAKECMDGOALS)),$(1))
  $(1)_defconfig_childs := $(1)
endif
$$($(1)_defconfig_childs): $$(call _stamp_$(1),defconfig)

$(1)-save: $$(call _stamp_$(1),build)

$(1)_APP_TYPE := $(subst x,,$(firstword $(foreach i,K U R Q,$(findstring x$i,x$(call _uc,$(1))))))
ifeq ($$(PB$$($(1)_APP_TYPE)),0)
  ifeq ($$(origin PB$$($(1)_APP_TYPE)),command line)
    boot_deps += $$(call _stamp_$(1),build)
  endif
endif
$(1)_app_type := $(subst x,,$(firstword $(foreach i,k u r q,$(findstring x$i,x$(1)))))
ifeq ($$($$($(1)_app_type)),1)
  ifeq ($$(origin $$($(1)_app_type)),command line)
    boot_deps += $$(call _stamp_$(1),build)
  endif
endif
ifeq ($$($(1)),1)
  ifeq ($$(origin $(1)),command line)
    boot_deps += $$(call _stamp_$(1),build)
  endif
endif
ifeq ($(filter $(1),$(BUILD)),$(1))
  boot_deps += $$(call _stamp_$(1),build)
endif

$$(call _stamp_$(1),bsp): $(1)-outdir
	$(Q)if [ -e $$(BSP_DIR)/.git ]; then \
		touch $$(call _stamp_$(1),bsp); \
	else					\
		if [ $$(shell grep $$(BOARD)/bsp -q $$(TOP_DIR)/.gitmodules; echo $$$$?) -eq 0 ]; then \
			make $$(S) bsp-checkout;		\
			touch $$(call _stamp_$(1),bsp); \
		fi;					\
	fi

$(1)-outdir: $$($(call _uc,$(1))_OUTPUT)

$$($(call _uc,$(1))_OUTPUT):
	$(Q)mkdir -p $$($(call _uc,$(1))_OUTPUT)

$(1)_bsp_childs := $(1)-defconfig $(1)-patch $(1)-save $(1)-saveconfig $(1)-clone boot test boot-test
$$($(1)_bsp_childs): $$(call _stamp_$(1),bsp)

boot: $$(boot_deps)

$(1)-cleanstamp:
	$$(Q)rm -rf $$(addprefix $$($(call _uc,$(1))_OUTPUT)/.stamp_$(1)-,outdir source checkout patch env modules modules-km defconfig olddefconfig menuconfig build bsp)
PHONY += $(1)-cleanstamp

## clean up $(1) source code
$(1)-cleanup:
	$$(Q)if [ -d $$($(call _uc,$(1))_SRC) -a -e $$($(call _uc,$(1))_SRC)/.git ]; then \
		cd $$($(call _uc,$(1))_SRC) && git reset --hard && git clean -fdx $$(GIT_CLEAN_EXTRAFLAGS[$(1)]) && cd $$(TOP_DIR); \
	fi
$(1)-outdir:
	$$(Q)if [ ! -d $$($(call _uc,$(1))_OUTPUT) ]; then mkdir -p $$($(call _uc,$(1))_OUTPUT); fi

$(1)-clean: $(1)-cleanup $(1)-cleanstamp

PHONY += $(1)-cleanup $(1)-outdir

$(1)-build: $(1)
$(1)-release: $(1) $(1)-save $(1)-saveconfig

PHONY += $(1)-build $(1)-release

$(1)-new $(1)-clone: $(1)-cloneconfig

PHONY += $(1)-checkout $(1)-patch $(1) $(1)-help $(1)-clean $(1)-distclean
PHONY += $(1)-defconfig $(1)-olddefconfig $(1)-oldnoconfig $(1)-menuconfig $(1)-new $(1)-clone $(1)-cloneconfig
PHONY += $(1)-save $(1)-saveconfig $(1)-savepatch

endef # gendeps

# generate xxx-source target
define gensource

$(call _uc,$(1))_SRC_DEFAULT := 1

ifneq ($$(notdir $(patsubst %/,%,$$($(call _uc,$(1))_SRC))),$$($(call _uc,$(1))_SRC))
  ifeq ($$(findstring x$$(BSP_DIR),x$$($(call _uc,$(1))_SRC)),x$$(BSP_DIR))
    $(call _uc,$(1))_SROOT := $$(BSP_DIR)
    $(call _uc,$(1))_SPATH := $$(subst $$(BSP_DIR)/,,$$($(call _uc,$(1))_SRC))
    $(call _uc,$(1))_SRC_DEFAULT := 0
  else
    ifneq ($$(PLUGIN_DIR),)
      ifeq ($$(findstring x$$(PLUGIN_DIR),x$$($(call _uc,$(1))_SRC)),x$$(PLUGIN_DIR))
        $(call _uc,$(1))_SROOT := $$(PLUGIN_DIR)
        $(call _uc,$(1))_SPATH := $$(subst $$(PLUGIN_DIR)/,,$$($(call _uc,$(1))_SRC))
        $(call _uc,$(1))_SRC_DEFAULT := 0
      endif
    endif
  endif
endif

ifeq ($$($(call _uc,$(1))_SRC_DEFAULT),1)
  # Put submodule is root of linux-lab if no directory specified or if not the above cases
  $(call _uc,$(1))_SROOT := $$(TOP_DIR)
  $(call _uc,$(1))_SPATH := $$(subst $$(TOP_DIR)/,,$$($(call _uc,$(1))_SRC))
endif

$(call _uc,$(1))_GITADD = git remote -v
ifneq ($$(_$(call _uc,$(1))_SRC), $$($(call _uc,$(1))_SRC))
  ifeq ($$(_$(call _uc,$(1))_GIT), $$($(call _uc,$(1))_GIT))
    $(call _uc,$(1))_GETGITURL := 1
  endif
else
  ifneq ($$(_$(call _uc,$(1))_GIT), $$($(call _uc,$(1))_GIT))
    $(call _uc,$(1))_GITREPO := $(1)-$$(subst /,-,$$(BOARD))-$$(notdir $$(patsubst %/,%,$$($(call _uc,$(1))_SPATH)))
    $(call _uc,$(1))_GITADD  := if [ $$$$(git remote | grep -q $$($(call _uc,$(1))_GITREPO); echo $$$$?) -ne 0 ]; then git remote add $$($(call _uc,$(1))_GITREPO) $$($(call _uc,$(1))_GIT); fi
  endif
endif

ifeq ($$($(call _uc,$(1))_GIT),)
  $(call _uc,$(1))_GETGITURL := 1
endif

ifeq ($$($(call _uc,$(1))_GETGITURL),1)
  __$(call _uc,$(1))_GIT := $$(shell [ -f $$($(call _uc,$(1))_SROOT)/.gitmodules ] && grep -A1 "path = $$($(call _uc,$(1))_SPATH)" -ur $$($(call _uc,$(1))_SROOT)/.gitmodules | tail -1 | cut -d'=' -f2 | tr -d ' ')
  ifneq ($$(__$(call _uc,$(1))_GIT),)
    _$(call _uc,$(1))_GIT := $$(__$(call _uc,$(1))_GIT)
    $(call _uc,$(1))_GIT := $$(__$(call _uc,$(1))_GIT)
  endif
else
  _$(call _uc,$(1))_GIT := $$($(call _uc,$(1))_GIT)
endif

# Build the full src directory
$(call _uc,$(1))_SRC_FULL := $$($(call _uc,$(1))_SROOT)/$$($(call _uc,$(1))_SPATH)

$(1)-source:
	@echo
	@echo "Downloading $(1) source ..."
	@echo
	$$(Q)if [ -e $$($(call _uc,$(1))_SRC_FULL)/.git ]; then \
		cd $$($(call _uc,$(1))_SRC_FULL);	\
		if [ $$(shell cd $$($(call _uc,$(1))_SRC_FULL) && git show --pretty=oneline -q $$(_$(call _uc,$(2))) >/dev/null 2>&1; echo $$$$?) -ne 0 ]; then \
			$$($(call _uc,$(1))_GITADD); \
			git fetch --tags $$(or $$($(call _uc,$(1))_GITREPO),origin); \
		fi;	\
		cd $$(TOP_DIR); \
	else		\
		cd $$($(call _uc,$(1))_SROOT) && \
			mkdir -p $$($(call _uc,$(1))_SPATH) && \
			cd $$($(call _uc,$(1))_SPATH) && \
			git init &&		\
			git remote add origin $$(_$(call _uc,$(1))_GIT) && \
			git fetch --tags origin && \
		cd $$(TOP_DIR); \
	fi

$(1)_source_childs := $(1)-download download-$(1)

$$($(1)_source_childs): $(1)-source

PHONY += $(1)-source download-$(1) $(1)-download

endef # gensource

# Generate basic goals
define gengoals
$(1)-list:
	$$(Q)echo $$($(2)_LIST)

$(1)-help:
	$$(Q)$$(if $$($(1)_make_help),$$(call $(1)_make_help),$$(call make_$(1),help))

$(1)-checkout:
	$$(Q)if [ -d $$($(call _uc,$(1))_SRC) -a -e $$($(call _uc,$(1))_SRC)/.git ]; then \
	cd $$($(call _uc,$(1))_SRC) && git checkout $$(GIT_CHECKOUT_FORCE) $$(_$(2)) && cd $$(TOP_DIR); \
	fi

_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_OUTPUT))
$(1)-patch:
	@if [ ! -f $$($(call _uc,$(1))_SRC)/$(1).patched ]; then \
	  $($(call _uc,$(1))_PATCH_EXTRAACTION) \
	  if [ -f tools/$(1)/patch.sh ]; then tools/$(1)/patch.sh $$(BOARD) $$($2) $$($(call _uc,$(1))_SRC) $$($(call _uc,$(1))_OUTPUT); fi; \
	  touch $$($(call _uc,$(1))_SRC)/$(1).patched; \
	else		\
	  echo "ERR: $(1) patchset has been applied, if want, please do 'make $(1)-cleanup' at first." && exit 1; \
	fi

endef # gengoals

define gencfgs

$$(call _uc,$1)_CONFIG_FILE ?= $(2)_$$($$(call _uc,$(2)))_defconfig
$(3)CFG ?= $$($$(call _uc,$1)_CONFIG_FILE)

ifeq ($$($(3)CFG),$$($$(call _uc,$1)_CONFIG_FILE))
  $(3)CFG_FILE := $$(_BSP_CONFIG)/$$($(3)CFG)
else
  _$(3)CFG_FILE := $$(shell for f in $$($(3)CFG) $(_BSP_CONFIG)/$$($(3)CFG) $$($$(call _uc,$1)_CONFIG_DIR)/$$($(3)CFG) $$($$(call _uc,$1)_SRC)/arch/$$(ARCH)/$$($(3)CFG); do \
		if [ -f $$$$f ]; then echo $$$$f; break; fi; done)
  ifneq ($$(_$(3)CFG_FILE),)
    $(3)CFG_FILE := $$(subst //,/,$$(_$(3)CFG_FILE))
  else
    $$(error $$($(3)CFG): can not be found, please pass a valid $(1) defconfig)
  endif
endif

ifeq ($$(findstring $$($$(call _uc,$1)_CONFIG_DIR),$$($(3)CFG_FILE)),$$($$(call _uc,$1)_CONFIG_DIR))
  $(3)CFG_BUILTIN := 1
endif

_$(3)CFG := $$(notdir $$($(3)CFG_FILE))

$(1)-defconfig:
	$$(Q)mkdir -p $$($$(call _uc,$1)_OUTPUT)
	$$(Q)mkdir -p $$($$(call _uc,$1)_CONFIG_DIR)
	$$(Q)$$(if $$($(3)CFG_BUILTIN),,cp $$($(3)CFG_FILE) $$($$(call _uc,$1)_CONFIG_DIR))
	$$(call make_$(1),$$(_$(3)CFG) $$($$(call _uc,$1)_CONFIG_EXTRAFLAG))

$(1)-olddefconfig:
	$$($$(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,$$(if $$($$(call _uc,$1)_OLDDEFCONFIG),$$($$(call _uc,$1)_OLDDEFCONFIG),olddefconfig) $$($$(call _uc,$1)_CONFIG_EXTRAFLAG))

$(1)-oldconfig:
	$$($$(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,oldconfig $$($$(call _uc,$1)_CONFIG_EXTRAFLAG))

$(1)-menuconfig:
	$$(call make_$1,menuconfig $$($$(call _uc,$1)_CONFIG_EXTRAFLAG))

endef # gencfgs

define genclone
ifneq ($$($$(call _uc,$2)_NEW),)

ifneq ($$($$(call _uc,$2)_NEW),$$($$(call _uc,$2)))

NEW_$(3)CFG_FILE=$$(_BSP_CONFIG)/$(2)_$$($$(call _uc,$2)_NEW)_defconfig
NEW_PREBUILT_$$(call _uc,$1)_DIR=$$(subst $$($$(call _uc,$2)),$$($$(call _uc,$2)_NEW),$$(PREBUILT_$$(call _uc,$1)_DIR))
NEW_$$(call _uc,$1)_PATCH_DIR=$$(BSP_PATCH)/$2/$$($$(call _uc,$2)_NEW)/
NEW_$$(call _uc,$1)_GCC=$$(if $$(call __v,GCC,$$(call _uc,$2)),GCC[$$(call _uc,$2)_$$($$(call _uc,$2)_NEW)] = $$(call __v,GCC,$$(call _uc,$2)))

$(1)-cloneconfig:
	$$(Q)if [ -f "$$($(3)CFG_FILE)" ]; then cp $$($(3)CFG_FILE) $$(NEW_$(3)CFG_FILE); fi
	$$(Q)tools/board/config.sh $$(call _uc,$2)=$$($$(call _uc,$2)_NEW) $$(BOARD_MAKEFILE)
	$$(Q)grep -q "GCC\[$$(call _uc,$2)_$$($$(call _uc,$2)_NEW)" $$(BOARD_MAKEFILE); if [ $$$$? -ne 0 -a -n "$$(NEW_$$(call _uc,$1)_GCC)" ]; then \
		sed -i -e "/GCC\[$$(call _uc,$2)_$$($$(call _uc,$2))/a $$(NEW_$$(call _uc,$1)_GCC)" $$(BOARD_MAKEFILE); fi
	$$(Q)mkdir -p $$(NEW_PREBUILT_$$(call _uc,$1)_DIR)
	$$(Q)mkdir -p $$(NEW_$$(call _uc,$1)_PATCH_DIR)
else
$(1)-cloneconfig:
	$(Q)echo $$($$(call _uc,$2)_NEW) already exists!
endif

else
  ifeq ($$(MAKECMDGOALS),$(1)-clone)
    $$(error Usage: make $(1)-clone $$(call _uc,$2)_NEW=<$2-version>)
  endif
endif

endef #genclone

define genenvdeps

$(1)-env: env
ifeq ($$(GCC_$(2)_SWITCH),1)
	$$(Q)make $$(S) gcc-switch $$(if $$(CCORI_$(2)),CCORI=$$(CCORI_$(2))) $$(if $$(GCC_$(2)),GCC=$$(GCC_$(2)))
endif

PHONY += $(1)-env

endef #genenvdeps


# Source download
#$(warning $(call gensource,uboot,UBOOT))
$(eval $(call gensource,uboot,UBOOT))

#$(warning $(call gensource,qemu,QEMU))
$(eval $(call gensource,qemu,QEMU))

#$(warning $(call gensource,kernel,LINUX))
$(eval $(call gensource,kernel,LINUX))

#$(warning $(call gensource,root,BUILDROOT))
$(eval $(call gensource,root,BUILDROOT))

# Build bsp targets
BSP ?= master
_BSP ?= $(BSP)

ifeq ($(_PLUGIN),1)
  BSP_SRC  := $(subst x$(TOP_DIR)/,,x$(PLUGIN_DIR))
else
  BSP_SRC  := $(subst x$(TOP_DIR)/,,x$(BSP_DIR))
endif

#$(warning $(call gensource,bsp))
$(eval $(call gensource,bsp))
$(eval $(call gendeps,bsp))
$(eval $(call gengoals,bsp,BSP))
$(eval $(call genenvdeps,bsp,BSP))

ifeq ($(findstring bsp,$(firstword bsp,$(MAKECMDGOALS))),bsp)
bsp:
	$(Q)make -s bsp-source
endif

PHONY += bsp

# Qemu targets

_QEMU  ?= $(call _v,QEMU,QEMU)
# Add basic qemu dependencies
#$(warning $(call gendeps,qemu))
$(eval $(call gendeps,qemu))

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
  $(error ERR: No qemu version specified, please configure QEMU= in $(BOARD_MAKEFILE) or pass it manually)
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
qemu_make_help := cd $(QEMU_OUTPUT) && $(QEMU_CONF_CMD) --help && cd $(TOP_DIR)

#$(warning $(call gengoals,qemu,QEMU))
$(eval $(call gengoals,qemu,QEMU))

qemu-defconfig:
	$(Q)mkdir -p $(QEMU_OUTPUT)
	$(Q)cd $(QEMU_OUTPUT) && $(QEMU_CONF_CMD) && cd $(TOP_DIR)

ifeq ($(findstring qemu,$(firstword $(MAKECMDGOALS))),qemu)
qemu:
	$(call make_qemu)
endif

#$(warning $(call genclone,qemu,qemu,Q))
$(eval $(call genclone,qemu,qemu,Q))

# Toolchains targets

toolchain-source: toolchain
download-toolchain: toolchain
gcc: toolchain

SCRIPT_GETCCVER := tools/gcc/version.sh

ifeq ($(CCORI),internal)
  CCVER := `echo gcc-$$($(SCRIPT_GETCCVER) $(CCPRE) $(CCPATH))`
endif

include $(PREBUILT_TOOLCHAINS)/Makefile
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
  include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile
endif

toolchain-install:
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
  ifneq ($(CCVER),)
    ifneq ($(shell which $(CCVER) 2>&1 >/dev/null; echo $$?),0)
	@echo
	@echo "Installing prebuilt toolchain ..."
	@echo
	$(Q)add-apt-repository -y ppa:ubuntu-toolchain-r/test
	$(Q)apt-get -y update
	$(Q)apt-get install -y --force-yes $(CCVER)
	$(Q)apt-get install -y --force-yes libc6-dev libc6-dev-i386 lib32gcc-8-dev gcc-multilib
	$(Q)update-alternatives --install /usr/bin/gcc gcc /usr/bin/$(CCVER) 46
    endif
  endif
else
  ifneq ($(CCPATH), $(wildcard $(CCPATH)))
	@echo
	@echo "Downloading prebuilt toolchain ..."
	@echo
	$(Q)cd $(TOOLCHAIN) && wget -c $(CCURL) && \
		tar $(TAR_OPTS) $(CCTAR) -C $(TOOLCHAIN) && \
		cd $(TOP_DIR)
  endif
endif

toolchain:
	$(Q)make $(S) toolchain-install
	$(Q)make $(S) gcc-info

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
	@echo

gcc-info: toolchain-info
gcc-version: toolchain-info
toolchain-version: toolchain-info

toolchain-clean:
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
  ifeq ($(shell which $(CCVER) 2>&1 >/dev/null; echo $$?),0)
	$(Q)apt-get remove --purge $(CCVER)
  endif
else
  ifeq ($(TOOLCHAIN), $(wildcard $(TOOLCHAIN)))
     ifneq ($(CCBASE),)
	$(Q)rm -rf $(TOOLCHAIN)/$(CCBASE)
     endif
  endif
endif

gcc-clean: toolchain-clean

PHONY += toolchain-source download-toolchain toolchain toolchain-clean toolchain-list gcc-list gcc-clean gcc

ifeq ($(filter $(MAKECMDGOALS),toolchain-switch gcc-switch), $(MAKECMDGOALS))
  _CCORI := $(shell grep --color=always ^CCORI $(BOARD_MAKEFILE) | cut -d '=' -f2 | tr -d ' ')
endif
toolchain-switch:
ifneq ($(filter $(GCC),$(CCORI_LIST)), $(GCC))
	$(Q)update-alternatives --verbose --set $(CCPRE)gcc /usr/bin/$(CCPRE)gcc-$(GCC)
else
  ifneq ($(_CCORI), $(CCORI))
	$(Q)echo OLD: `grep --color=always ^CCORI $(BOARD_MAKEFILE)`
	$(Q)tools/board/config.sh CCORI=$(CCORI) $(BOARD_MAKEFILE)
	$(Q)echo NEW: `grep --color=always ^CCORI $(BOARD_MAKEFILE)`
  else
	@echo "Usage: make toolchain-switch CCORI=<CCORI> GCC=<Internal-GCC-Version>"
	@echo "       e.g. make toolchain-switch CCORI=bootlin"
	@echo "            make toolchain-switch CCORI=internal GCC=4.3"
	@echo "            make toolchain-switch GCC=4.3       # If CCORI is already internal"
	$(Q)make $(S) toolchain-list
  endif
endif

gcc-switch: toolchain-switch gcc-info

PHONY += toolchain-switch gcc-switch toolchain-version gcc-version gcc-info

# Rootfs targets

_BUILDROOT  ?= $(call _v,BUILDROOT,BUILDROOT)

# Add basic root dependencies
#$(warning $(call gendeps,root))
$(eval $(call gendeps,root))

# Configure Buildroot

GIT_CLEAN_EXTRAFLAGS[root] := -e dl/
#$(warning $(call gengoals,root,BUILDROOT))
$(eval $(call gengoals,root,BUILDROOT))

ROOT_CONFIG_DIR := $(ROOT_SRC)/configs

#$(warning $(call gencfgs,root,buildroot,R))
$(eval $(call gencfgs,root,buildroot,R))
#$(warning $(call genclone,root,buildroot,R))
$(eval $(call genclone,root,buildroot,R))

# Build Buildroot
ROOT_INSTALL_TOOL := $(TOOL_DIR)/root/install.sh

# Install kernel modules?
IKM ?= 1

ifeq ($(IKM), 1)
  ifeq ($(KERNEL_OUTPUT)/.modules.order, $(wildcard $(KERNEL_OUTPUT)/.modules.order))
    KERNEL_MODULES_INSTALL := module-install
  endif
endif

root-buildroot:
	$(call make_root,$(RT))

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
  ROOT_GENRD_TOOL := $(TOOL_DIR)/root/dir2rd.sh
else
  ROOT_GENRD_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2rd.sh
endif

root-rd:
	$(Q)if [ ! -f "$(IROOTFS)" ]; then make $(S) root-rd-rebuild; fi

root-rd-rebuild: FORCE
	@echo "LOG: Generating ramdisk image with $(ROOT_GENRD_TOOL) ..."
	ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) USER=$(USER) $(ROOT_GENRD_TOOL)

ROOT_GENDISK_TOOL := $(TOOL_DIR)/root/dir2$(DEV_TYPE).sh

# This is used to repackage the updated root directory, for example, `make r-i` just executed.
root-rebuild:
ifeq ($(prebuilt_root_dir), 1)
	@echo "LOG: Generating $(DEV_TYPE) with $(ROOT_GENDISK_TOOL) ..."
	ROOTDIR=$(ROOTDIR) INITRD=$(IROOTFS) HROOTFS=$(HROOTFS) FSTYPE=$(FSTYPE) USER=$(USER) $(ROOT_GENDISK_TOOL)
	$(Q)if [ $(build_root_uboot) -eq 1 ]; then make $(S) _root-ud-rebuild; fi
else
	$(call make_root)
	$(Q)chown -R $(USER):$(USER) $(BUILDROOT_ROOTDIR)
	$(Q)if [ $(build_root_uboot) -eq 1 ]; then make $(S) $(BUILDROOT_UROOTFS); fi
endif

ROOT ?= rootdir
ifeq ($(_PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    ROOT := root-buildroot
  endif
endif

PHONY += root-rd root-rd-rebuild

# Specify buildroot target

RT ?= $(x)

ifneq ($(RT),)
  ROOT :=
endif

ifeq ($(findstring root,$(firstword $(MAKECMDGOALS))),root)
root:
	$(Q)make $(S) $(ROOT)
ifneq ($(RT),)
	$(Q)$(call make_root,$(RT))
else
	$(Q)make root-install
	$(Q)if [ -n "$(KERNEL_MODULES_INSTALL)" ]; then make $(KERNEL_MODULES_INSTALL); fi
	$(Q)make root-rebuild
endif
endif # root

# root directory
ifneq ($(FS_TYPE),dir)
  ROOT_GENDIR_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2dir.sh
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

ROOT_GENHD_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2hd.sh

root-hd:
	$(Q)if [ ! -f "$(HROOTFS)" ]; then make root-hd-rebuild; fi

root-hd-rebuild: FORCE
	@echo "LOG: Generating harddisk image with $(ROOT_GENHD_TOOL) ..."
	ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) $(ROOT_GENHD_TOOL)

PHONY += root-hd root-hd-rebuild

# Kernel modules

# Add basic kernel & modules deps
#$(warning $(call gendeps,kernel))
$(eval $(call gendeps,kernel))

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

export KM
endif

PHONY += modules-prompt kernel-modules-save

ifeq ($(internal_module),1)
  MODULE_PREPARE := prepare
else
  MODULE_PREPARE := modules_prepare
endif

kernel-modules-km: $(KERNEL_MODULES_DEPS)
	$(Q)if [ "$(shell $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" != "y" ]; then  \
		make -s feature feature=module; \
		make -s kernel-olddefconfig; \
		$(call make_kernel); \
	fi
	$(call make_kernel,$(MODULE_PREPARE))
	$(Q)if [ -f $(KERNEL_SRC)/scripts/Makefile.modbuiltin ]; then \
		$(call make_kernel,$(if $(m),$(m).ko,modules) $(KM)); \
	else	\
		$(call make_kernel,modules $(KM)); \
	fi

kernel-modules:
	make kernel-modules-km KM=

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

PHONY += kernel-modules-km kernel-modules kernel-modules-list kernel-modules-list-full

M_I_ROOT ?= rootdir
ifeq ($(PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    M_I_ROOT := root-buildroot
  endif
endif

# From linux-stable/scripts/depmod.sh, v5.1
SCRIPTS_DEPMOD := $(TOP_DIR)/tools/kernel/depmod.sh

kernel-modules-install-km:
	$(Q)if [ "$(shell $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" = "y" ]; then \
		$(call make_kernel,modules_install $(KM) INSTALL_MOD_PATH=$(ROOTDIR)); \
		if [ ! -f $(KERNEL_SRC)/scripts/depmod.sh ]; then \
		    cd $(KERNEL_OUTPUT) && \
		    INSTALL_MOD_PATH=$(ROOTDIR) $(SCRIPTS_DEPMOD) /sbin/depmod $$(grep UTS_RELEASE -ur include |  cut -d ' ' -f3 | tr -d '"'); \
		    cd $(TOP_DIR); \
		fi;				\
	fi

kernel-modules-install: $(M_I_ROOT)
	$(Q)if [ "$(shell $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" = "y" ]; then \
		$(call make_kernel,modules_install INSTALL_MOD_PATH=$(ROOTDIR));	\
	fi

ifeq ($(internal_module),1)
  M_ABS_PATH := $(KERNEL_OUTPUT)/$(M_PATH)
else
  M_ABS_PATH := $(wildcard $(M_PATH))
endif

KERNEL_MODULE_CLEAN := tools/module/clean.sh
kernel-modules-clean-km:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_OUTPUT) $(M_ABS_PATH)
	$(Q)rm -rf .module_config

kernel-modules-clean:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_OUTPUT)

PHONY += kernel-modules-install-km kernel-modules-install kernel-modules-clean

_module: kernel-modules-km plugin-save
module-list: kernel-modules-list plugin-save
module-list-full: kernel-modules-list-full plugin-save
_module-install: kernel-modules-install-km
_module-clean: kernel-modules-clean-km

modules-list: module-list
modules-list-full: module-list-full

module-test: test
modules-test: module-test

PHONY += _module module-list module-list-full _module-install _module-clean modules-list modules-list-full

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
ifneq ($(firstword $(MAKECMDGOALS)),list)

ifneq ($(module)$(M)$(KM)$(M_PATH),)
modules: module
modules-install: module-install
modules-clean: module-clean
else
modules: kernel-modules FORCE
modules-install: kernel-modules-install
modules-clean: kernel-modules-clean
endif

endif # skip modules target for list command

PHONY += modules modules-install modules-clean module module-install module-clean

# Linux Kernel targets
_LINUX  := $(call _v,LINUX,LINUX)
_KERNEL ?= $(_LINUX)

# Configure Kernel
#$(warning $(call gengoals,kernel,LINUX))
$(eval $(call gengoals,kernel,LINUX))

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

KERNEL_CONFIG_DIR := $(KERNEL_SRC)/arch/$(ARCH)/configs/
KERNEL_CONFIG_EXTRAFLAG := M=
KERNEL_CONFIG_EXTRACMDS := yes N | 

#$(warning $(call gencfgs,kernel,linux,K))
$(eval $(call gencfgs,kernel,linux,K))
#$(warning $(call genclone,kernel,linux,K))
$(eval $(call genclone,kernel,linux,K))

kernel-oldnoconfig: kernel-olddefconfig

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
	  $(KERNEL_FEATURE_TOOL) $(ARCH) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_OUTPUT) "$(FEATURE)"; \
	  if [ $(FPL) -eq 1 ]; then touch $(FEATURE_PATCHED_TAG); fi; \
	else \
	  echo "ERR: feature patchset has been applied, if want, please pass 'FPL=0' or 'make kernel-checkout' at first." && exit 1; \
	fi

feature: kernel-feature
features: feature
kernel-features: feature

kernel-feature-list:
	$(Q)echo [ $(FEATURE_DIR) ]:
	$(Q)find $(FEATURE_DIR) -mindepth 1 | sed -e "s%$(FEATURE_DIR)/%%g" | sort | egrep -v ".gitignore|downloaded" | sed -e "s%\(^[^/]*$$\)%  + \1%g" | sed -e "s%[^/]*/.*/%      * %g" | sed -e "s%[^/]*/%    - %g"

kernel-features-list: kernel-feature-list
features-list: kernel-feature-list
feature-list: kernel-feature-list

ifneq ($(module),)
  ifneq ($(FEATURE),)
    FEATURE := $(FEATURE),module
  else
    FEATURE := module
  endif
endif

PHONY += kernel-feature feature features kernel-features kernel-feature-list kernel-features-list features-list

kernel-init:
	$(Q)make kernel-config
	$(Q)make kernel-olddefconfig
	$(Q)$(call make_kernel,$(IMAGE))

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

PHONY += kernel-init rootdir-init module-init feature-init kernel-feature-test kernel-features-test features-test feature-test

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
	$(Q)$(call make_kernel,$(DTB_TARGET))
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

ifeq ($(filter kernel-getconfig,$(MAKECMDGOALS)),kernel-getconfig)
  o ?= $m
endif

kernel-getconfig: FORCE
	$(Q)$(if $(o), $(foreach _o, $(shell echo $(o) | tr ',' ' '), \
		__o=$(shell echo $(_o) | tr '[a-z]' '[A-Z]') && \
		echo "\nGetting kernel config: $$__o ...\n" && make $(S) _kernel-getconfig o=$$__o;) echo '')

_kernel-getconfig:
	$(Q)printf "option state: $(o)="&& $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_GET_OPT)
	$(Q)egrep -iH "_$(o)( |=|_)" $(DEFAULT_KCONFIG) | sed -e "s%$(TOP_DIR)/%%g"

kernel-config: kernel-setconfig
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

	$(Q)make -s kernel-olddefconfig
	$(Q)$(call make_kernel,prepare M=)
else
	$(Q)make -s kernel-olddefconfig
endif
	$(Q)echo "\nChecking kernel config: $(KCONFIG_OPT) ...\n"
	$(Q)printf "option state: $(KCONFIG_OPT)=" && $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_GET_OPT)
	$(Q)egrep -iH "_$(KCONFIG_OPT)(_|=| )" $(DEFAULT_KCONFIG) | sed -e "s%$(TOP_DIR)/%%g"

PHONY += kernel-getconfig kernel-config kernel-setconfig _kernel-getconfig _kernel-setconfig

module-config: module-setconfig
modules-config: module-setconfig

module-getconfig: kernel-getconfig
module-setconfig: kernel-setconfig

PHONY += module-getconfig module-setconfig modules-config module-config

ifeq ($(findstring kernel,$(firstword $(MAKECMDGOALS))),kernel)
kernel:
	$(Q)make $(S) $(KERNEL_DEPS)
	$(call make_kernel,$(KT))
endif

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
	@if [ -z "$(VMLINUX)" -o ! -f $(VMLINUX) ]; then \
	  echo "ERR: No VMLINUX: $(VMLINUX) found, please compile with 'make kernel'" && exit 1; \
	fi

PHONY += vmlinux

calltrace: kernel-calltrace
kernel-calltrace: vmlinux
	$(Q)$(KERNEL_CALLTRACE_TOOL) $(VMLINUX) $(LASTCALL) $(KERNEL_ABS_SRC) "$(C_PATH)" "$(CCPRE)"

PHONY += kernel-calltrace calltrace

# Uboot targets
_UBOOT  ?= $(call _v,UBOOT,UBOOT)
# Add basic uboot dependencies
ifneq ($(UBOOT),)
  #$(warning $(call gendeps,uboot))
  $(eval $(call gendeps,uboot))
endif

# Verify BOOTDEV argument
#$(warning $(call genverify,BOOTDEV,BOOTDEV,UBOOT))
$(eval $(call genverify,BOOTDEV,BOOTDEV,UBOOT))

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
UBOOT_PATCH_EXTRAACTION := if [ -n "$$(UCONFIG)" ]; then $$(UBOOT_CONFIG_TOOL) $$(UCFG_DIR) $$(UCONFIG); fi;

#$(warning $(call gengoals,uboot,UBOOT))
$(eval $(call gengoals,uboot,UBOOT))

UBOOT_CONFIG_DIR := $(UBOOT_SRC)/configs

ifneq ($(U),)
#$(warning $(call gencfgs,uboot,uboot,U))
$(eval $(call gencfgs,uboot,uboot,U))
#$(warning $(call genclone,uboot,uboot,U))
$(eval $(call genclone,uboot,uboot,U))
endif

# Specify uboot targets
UT ?= $(x)

# Build Uboot
ifeq ($(findstring uboot,$(firstword $(MAKECMDGOALS))),uboot)
uboot:
	$(call make_uboot,$(UT))
endif

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
	$(Q)mkimage -A $(ARCH) -O linux -T kernel -C none -a $(KRN_ADDR) -e $(KRN_ADDR) \
		-n 'Linux-$(LINUX)' -d $(KIMAGE) $(UKIMAGE)
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

STRIP_CMD := $(C_PATH) $(CCPRE)strip -s

# Save the built images
root-save:
	$(Q)mkdir -p $(PREBUILT_ROOT_DIR)
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	-cp $(BUILDROOT_IROOTFS) $(PREBUILT_ROOT_DIR)
ifneq ($(PORIIMG),)
	-cp $(LINUX_PKIMAGE) $(PREBUILT_KERNEL_DIR)
	-$(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(PORIIMG))
endif

kernel-save:
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	-cp $(LINUX_KIMAGE) $(PREBUILT_KERNEL_DIR)
	-$(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(ORIIMG))
	-if [ -n "$(UORIIMG)" -a -f "$(LINUX_UKIMAGE)" ]; then cp $(LINUX_UKIMAGE) $(PREBUILT_KERNEL_DIR); fi
	-if [ -n "$(DTS)" -a -f "$(LINUX_DTB)" ]; then cp $(LINUX_DTB) $(PREBUILT_KERNEL_DIR); fi

uboot-save:
	$(Q)mkdir -p $(PREBUILT_UBOOT_DIR)
	-cp $(UBOOT_BIMAGE) $(PREBUILT_UBOOT_DIR)


qemu-save:
	$(Q)mkdir -p $(PREBUILT_QEMU_DIR)
	$(Q)$(foreach _QEMU_TARGET,$(subst $(comma),$(space),$(QEMU_TARGET)),make -C $(QEMU_OUTPUT)/$(_QEMU_TARGET) install V=$(V);echo '';)
	$(Q)make -C $(QEMU_OUTPUT) install V=$(V)

uboot-saveconfig:
	-$(call make_uboot,savedefconfig)
	$(Q)if [ -f $(UBOOT_OUTPUT)/defconfig ]; \
	then cp $(UBOOT_OUTPUT)/defconfig $(_BSP_CONFIG)/$(UBOOT_CONFIG_FILE); \
	else cp $(UBOOT_OUTPUT)/.config $(_BSP_CONFIG)/$(UBOOT_CONFIG_FILE); fi

# kernel < 2.6.36 doesn't support: `make savedefconfig`
kernel-saveconfig:
	-$(call make_kernel,savedefconfig M=)
	$(Q)if [ -f $(KERNEL_OUTPUT)/defconfig ]; \
	then cp $(KERNEL_OUTPUT)/defconfig $(_BSP_CONFIG)/$(KERNEL_CONFIG_FILE); \
	else cp $(KERNEL_OUTPUT)/.config $(_BSP_CONFIG)/$(KERNEL_CONFIG_FILE); fi

kernel-savepatch:
	$(Q)cd $(KERNEL_SRC) && git format-patch $(_LINUX) && cd $(TOP_DIR)
	$(Q)mkdir -p $(BSP_PATCH)/linux/$(LINUX)/
	$(Q)cp $(KERNEL_SRC)/*.patch $(BSP_PATCH)/linux/$(LINUX)/

root-saveconfig:
	$(call make_root,savedefconfig)
	$(Q)if [ $(shell grep -q BR2_DEFCONFIG $(ROOT_OUTPUT)/.config; echo $$?) -eq 0 ]; \
	then cp $(shell grep BR2_DEFCONFIG $(ROOT_OUTPUT)/.config | cut -d '=' -f2) $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	elif [ -f $(ROOT_OUTPUT)/defconfig ]; \
	then cp $(ROOT_OUTPUT)/defconfig $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	else cp $(ROOT_OUTPUT)/.config $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); fi

# Qemu options and kernel command lines

# Network configurations

# Verify NETDEV argument
define netdev_help
 ifeq ($$(MACH), malta)
  EMULATOR += -kernel $(_KIMAGE)
 endif
 ifneq ($$(filter $(BOARD),riscv32/virt riscv64/virt loongson/ls1b loongson/ls2k), $(BOARD))
  $$(info $$(shell $(EMULATOR) -M $$(MACH) -net nic,model=?))
 endif
endef

$(eval $(call genverify,NETDEV,NETDEV,,netdev_help))

# TODO: net driver for $BOARD
#NET = " -net nic,model=smc91c111,macaddr=DE:AD:BE:EF:3E:03 -net tap"
NET ?=  -net nic,model=$(call _v,NETDEV,LINUX) -net tap

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
  IP_FULL  ?= $(IP):$(ROUTE):$(ROUTE):255.255.255.0:linux-lab:$(IFACE):off
  IP_SHORT ?= $(IP):::::$(IFACE):off
  CMDLINE += nfsroot=$(ROUTE):$(ROOTDIR) rw ip=$(IP_SHORT)
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
CMDLINE += $(call _v,XKCLI,LINUX)

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
ifneq ($(TEST_PREPARE),)
  override TEST_PREPARE := $(subst $(comma),$(space),$(TEST_PREPARE))
  ifneq ($(TEST),)
    override TEST_PREPARE := $(TEST_PREPARE) $(subst $(comma),$(space),$(TEST))
  endif
else
  TEST_PREPARE := $(subst $(comma),$(space),$(TEST))
endif

ifeq ($(UBOOT),)
  override TEST_PREPARE := $(patsubst uboot%,,$(TEST_PREPARE))
endif
ifeq ($(QEMU),)
  override TEST_PREPARE := $(patsubst qemu%,,$(TEST_PREPARE))
endif

# Force running git submodule commands
# FIXME: To test automatically, must checkout with -f, otherwise, will stop with failures.
ifeq ($(FORCE_CHECKOUT),1)
  GIT_CHECKOUT_FORCE ?= -f
endif

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
  KERNEL_OPT ?= -kernel $(PKIMAGE) -device loader,file=$(QEMU_KIMAGE),addr=$(KRN_ADDR)
else
  KERNEL_OPT ?= -kernel $(QEMU_KIMAGE)
endif

EMULATOR_OPTS ?= -M $(MACH) -m $(call _v,MEM,LINUX) $(NET) -smp $(call _v,SMP,LINUX) $(KERNEL_OPT) $(EXIT_ACTION)
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

# Add extra qemu options
BOOT_CMD += $(XOPTS)

D ?= 0
DEBUG := $(D)

# Must disable the kaslr feature while debugging, otherwise, breakpoint will not stop and just continue
# ref: https://unix.stackexchange.com/questions/396013/hardware-breakpoint-in-gdb-qemu-missing-start-kernel
#      https://www.spinics.net/lists/newbies/msg59708.html
ifneq ($(DEBUG),0)
    BOOT_CMD += -s
    # workaround error of x86_64: "Remote 'g' packet reply is too long:", just skip the "-S" option
    ifneq ($(XARCH),x86_64)
      BOOT_CMD += -S
    endif
    CMDLINE  += nokaslr
endif

# Debug not work with -enable-kvm
# KVM speedup for x86 architecture, assume our host is x86 currently
ifeq ($(DEBUG),0)
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

  # Allow test continue if the board always hang after poweroff, please pass TIMEOUT_CONTINUE=1
  TIMEOUT_CONTINUE ?= 0

  TEST_BEFORE ?= mkdir -p $(TEST_LOGGING) && sync && mkfifo $(TEST_LOG_PIPE).in && mkfifo $(TEST_LOG_PIPE).out && touch $(TEST_LOG_PID) && make env-dump > $(TEST_ENV) \
	&& $(TEST_LOG_READER) $(TEST_LOG_PIPE) $(TEST_LOG) $(TEST_LOG_PID) 2>&1 \
	&& sleep 1 && sudo timeout $(TEST_TIMEOUT)
  TEST_AFTER  ?= ; echo \$$\$$? > $(TEST_RET); sudo kill -9 \$$\$$(cat $(TEST_LOG_PID)); [ $(TIMEOUT_CONTINUE) -eq 1 ] && echo 0 > $(TEST_RET); \
	ret=\$$\$$(cat $(TEST_RET)) && [ \$$\$$ret -ne 0 ] && echo \"ERR: Boot timeout in $(TEST_TIMEOUT).\" && echo \"ERR: Log saved in $(TEST_LOG).\" && exit \$$\$$ret; \
	if [ $(TIMEOUT_CONTINUE) -eq 1 ]; then echo \"LOG: Test continue after timeout kill in $(TEST_TIMEOUT).\"; else echo \"LOG: Boot run successfully.\"; fi; \
	if [ $(TIMEOUT_CONTINUE) -eq 1 ]; then sleep 2; rm -rf $(TEST_LOG_PIPE).in $(TEST_LOG_PIPE).out; fi
  # If not support netowrk, should use the other root device
endif

TEST_XOPTS ?= $(XOPTS)
TEST_RD ?= $(if $(TEST_ROOTDEV),$(TEST_ROOTDEV),/dev/nfs)
# Override TEST_RD if ROOTDEV specified
ifeq ($(origin ROOTDEV), command line)
  TEST_RD := $(ROOTDEV)
endif

export BOARD TEST_TIMEOUT TEST_LOGGING TEST_LOG TEST_LOG_PIPE TEST_LOG_PID TEST_XOPTS TEST_RET TEST_RD TEST_LOG_READER V

boot-test:
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

raw-test:
	make test FI=0

test: $(TEST_PREPARE) FORCE
	if [ $(FI) -eq 1 -a -n "$(FEATURE)" ]; then make feature-init TEST=default; fi
	make boot-init
	make boot-test
	make boot-finish

PHONY += _boot-test boot-test test raw-test

# Boot dependencies

# Debug support
VMLINUX      ?= $(KERNEL_OUTPUT)/vmlinux

ifneq ($(DEBUG),0)

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

ifeq ($(DEBUG),uboot)
  GDB_CMD      ?= $(GDB) $(BIMAGE)
  GDB_INIT     ?= $(TOP_DIR)/.uboot_gdbinit
else
  GDB_CMD      ?= $(GDB) $(VMLINUX)
  GDB_INIT     ?= $(TOP_DIR)/.kernel_gdbinit
endif

HOME_GDB_INIT ?= $(HOME)/.gdbinit
# Force run as ubuntu to avoid permission issue of .gdbinit and ~/.gdbinit
GDB_USER     ?= $(USER)

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
	$(Q)ln -sf $(GDB_INIT) .gdbinit
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

endif # DEBUG != 0

_BOOT_DEPS ?=
ifneq ($(BOOT_PREPARE),)
  override BOOT_PREPARE := $(subst $(comma),$(space),$(BOOT_PREPARE))
  _BOOT_DEPS += $(BOOT_PREPARE)
endif
_BOOT_DEPS += board-save
_BOOT_DEPS += root-$(DEV_TYPE)
_BOOT_DEPS += $(UBOOT_IMGS)
_BOOT_DEPS += $(DEBUG_CLIENT)
_BOOT_DEPS += $(BOOT_DTB)

_boot: $(_BOOT_DEPS)
	$(BOOT_CMD)

BOOT_DEPS ?=

boot: $(BOOT_DEPS)
	$(Q)make _boot

PHONY += boot-test test _boot boot

debug:
	$(Q)make $(S) boot D=$(or $(DEBUG),1)

PHONY += debug

# Clean up

qemu-clean:
ifeq ($(QEMU_OUTPUT)/Makefile, $(wildcard $(QEMU_OUTPUT)/Makefile))
	-$(Q)$(call make_qemu,clean)
endif

root-clean:
ifeq ($(ROOT_OUTPUT)/Makefile, $(wildcard $(ROOT_OUTPUT)/Makefile))
	-$(Q)$(call make_root,clean)
endif

uboot-clean: $(UBOOT_IMGS_DISTCLEAN)
ifeq ($(UBOOT_OUTPUT)/Makefile, $(wildcard $(UBOOT_OUTPUT)/Makefile))
	-$(Q)$(call make_uboot,clean)
endif

kernel-clean: kernel-modules-clean
ifeq ($(KERNEL_OUTPUT)/Makefile, $(wildcard $(KERNEL_OUTPUT)/Makefile))
	-$(Q)$(call make_kernel,clean)
endif

PHONY += rootdir-clean

qemu-distclean:
ifeq ($(QEMU_OUTPUT)/Makefile, $(wildcard $(QEMU_OUTPUT)/Makefile))
	-$(Q)$(call make_qemu,distclean)
	$(Q)rm -rf $(QEMU_OUTPUT)
endif

root-distclean:
ifeq ($(ROOT_OUTPUT)/Makefile, $(wildcard $(ROOT_OUTPUT)/Makefile))
	-$(Q)$(call make_root,distclean)
	$(Q)rm -rf $(ROOT_OUTPUT)
endif

uboot-distclean:
ifeq ($(UBOOT_OUTPUT)/Makefile, $(wildcard $(UBOOT_OUTPUT)/Makefile))
	-$(Q)$(call make_uboot,distclean)
	$(Q)rm -rf $(UBOOT_OUTPUT)
endif

kernel-distclean:
ifeq ($(KERNEL_OUTPUT)/Makefile, $(wildcard $(KERNEL_OUTPUT)/Makefile))
	-$(Q)$(call make_kernel,distclean)
	$(Q)rm -rf $(KERNEL_OUTPUT)
endif

rootdir-distclean: rootdir-clean

PHONY += rootdir-distclean

fullclean: distclean
	$(Q)git clean -fdx

# Show the variables
ifeq ($(filter env-dump,$(MAKECMDGOALS)),env-dump)
VARS := $(shell cat $(BOARD_MAKEFILE) | egrep -v "^ *\#|ifeq|ifneq|else|endif|include"| cut -d'?' -f1 | cut -d'=' -f1 | cut -d':' -f1 | tr -d ' ')
VARS += PBK PBR PBD PBQ PBU
VARS += BOARD FEATURE TFTPBOOT
VARS += ROOTDIR ROOT_SRC ROOT_OUTPUT ROOT_GIT
VARS += KERNEL_SRC KERNEL_OUTPUT KERNEL_GIT UBOOT_SRC UBOOT_OUTPUT UBOOT_GIT
VARS += ROOT_CONFIG_PATH KERNEL_CONFIG_PATH UBOOT_CONFIG_PATH
VARS += IP ROUTE BOOT_CMD
VARS += LINUX_DTB QEMU_PATH QEMU_SYSTEM
VARS += TEST_TIMEOUT TEST_RD
endif

#$(warning $(call genenvdeps,kernel,LINUX))
$(eval $(call genenvdeps,kernel,LINUX))

#$(warning $(call genenvdeps,uboot,UBOOT))
$(eval $(call genenvdeps,uboot,UBOOT))

#$(warning $(call genenvdeps,uboot,UBOOT)
$(eval $(call genenvdeps,qemu,QEMU))

#$(warning $(call genenvdeps,root,BUILDROOT)
$(eval $(call genenvdeps,root,BUILDROOT))

env: env-prepare
env-prepare: toolchain
ifeq ($(GCC_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CCORI),CCORI=$(CCORI)) $(if $(GCC),GCC=$(GCC))
endif

env-list: env-dump
env-dump:
	@echo \#[ $(BOARD) ]:
	@echo -n " "
	-@echo $(foreach v,$(or $(VAR),$(VARS)),"    $(v)=\"$($(v))\"\n") | tr -s '/'

env-save: board-config

lab-help:
	$(Q)cat README.md

PHONY += env env-list env-prepare env-dump env-save lab-help

# include Makefile.fini if exist
$(eval $(call _ti,fini,Makefile))
$(eval $(call _ti,fini.private,Makefile))

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

APP_TARGETS := source download checkout patch defconfig olddefconfig oldconfig menuconfig build cleanup cleanstamp clean distclean save saveconfig savepatch clone help list
ifeq ($(filter $(first_target),$(APP_TARGETS)),$(first_target))
  # use the rest as arguments for "run"
  RUN_ARGS := $(filter-out $(first_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):FORCE;@:)
endif

define cli_detectapp
ifeq ($$(origin $(2)),command line)
  APP += $(1)
endif

endef

define default_detectapp
ifneq ($$($(2)),)
  override app += $(1)
endif

endef

ifneq ($(RUN_ARGS),)
  APP := $(RUN_ARGS)
else
  APP :=
  $(foreach m,$(APP_MAP),$(eval $(call cli_detectapp,$(firstword $(subst :,$(space),$m)),$(lastword $(subst :,$(space),$m)))))
endif

ifneq ($(APP),)
  app ?= $(APP)
  override app := $(subst buildroot,root,$(subst linux,kernel,$(app)))
endif

ifeq ($(app),all)
  override app :=
  $(foreach m,$(APP_MAP),$(eval $(call default_detectapp,$(firstword $(subst :,$(space),$m)),$(lastword $(subst :,$(space),$m)))))
endif

ifeq ($(app),)
  app := kernel
  ifeq ($(MAKECMDGOALS),list)
    app := default
  endif
endif

PREFIX_TARGETS := list
SILENT_TARGETS := list
define silent_flag
$(shell if [ "$(filter $(1),$(SILENT_TARGETS))" = "$(1)" ]; then echo $(S); fi)
endef

define real_target
$(shell if [ "$(filter $(1),$(PREFIX_TARGETS))" = "$(1)" ]; then echo $(1)-$(2); else echo $(2)-$(1); fi)
endef

$(APP_TARGETS):
	$(Q)$(foreach a,$(app),make $(call silent_flag,$(@)) $(MFLAGS) $(call real_target,$(@),$(a));))

BASIC_TARGETS := kernel uboot root qemu
EXEC_TARGETS  := $(foreach t,$(BASIC_TARGETS),$(t:=-run))

$(EXEC_TARGETS):
	make $(@:-run=) x=$(RUN_ARGS)

PHONY += $(APP_TARGETS) $(EXEC_TARGETS) $(_EXEC_TARGETS)

PHONY += FORCE

FORCE:

.PHONY: $(PHONY)
