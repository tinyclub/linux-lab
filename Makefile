#
# Core Makefile
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

TOP_DIR := $(CURDIR)

# Disable the implict rules for our Makefile
.SUFFIXES:
SUFFIXES :=

# Force set default goal
.DEFAULT_GOAL := board

# Phony targets
PHONY :=
comma := ,
empty :=
space := $(empty) $(empty)

USER := ubuntu
WARN_ON_USER ?= 1

# Check running host
LAB_ENV_ID=/home/$(USER)/Desktop/lab.desktop
ifneq ($(LAB_ENV_ID),$(wildcard $(LAB_ENV_ID)))
  ifneq (../../configs/linux-lab, $(wildcard ../../configs/linux-lab))
    $(error ERR: No Cloud Lab found, please refer to 'Download the lab' part of README.md)
  else
    $(error ERR: Please not try Linux Lab in local host, but use it with Cloud Lab, please refer to 'Run and login the lab' part of README.md)
  endif
endif

# Warning if run as root
ifeq ($(WARN_ON_USER), 1)
# Check running user, must as ubuntu
ifeq ($(TEST_TIMEOUT),)
  ifneq ($(shell whoami),$(USER))
    $(warning WARN: Please not run as 'root', but as general user: '$(USER)', please try 'sudo -su $(USER)'.)
  endif
endif

# Check permission issue, must available to ubuntu
ifneq ($(shell stat -c '%U' /.git/HEAD),$(USER))
  $(warning WARN: Lab should **NOT** belong to 'root', please change their owner in host: 'sudo chown $$USER:$$USER -R /path/to/cloud-lab/{*,.git}')
  $(warning WARN: Cancel this warning via: 'export WARN_ON_USER=0')
endif
endif # Warning on user

# Detect system version of docker image
OS := $(shell lsb_release -c | awk '{printf $$2}')

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
  Q ?= @
  NPD ?= --no-print-directory
  S ?= -s $(NPD)
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
TFTPBOOT    := tftpboot
HOME_DIR    := /home/$(USER)/
GDBINIT_DIR := $(TOP_DIR)/.gdb
TOP_SRC     := $(TOP_DIR)/src
FEATURE_DIR := $(TOP_SRC)/feature/linux

# Search board in basic arch list while board name given without arch specified
ifneq ($(BOARD),)
 BASE_ARCHS := arm aarch64 mipsel mips64el ppc i386 x86_64 riscv32 riscv64 csky
 ifneq ($(BOARD_DIR)/Makefile,$(wildcard $(BOARD_DIR)/Makefile))
  ARCH := $(shell for arch in $(BASE_ARCHS); do if [ -d $(TOP_DIR)/$(BOARDS_DIR)/$$arch/$(BOARD) ]; then echo $$arch; break; fi; done)
  ifneq ($(ARCH),)
    override BOARD     := $(ARCH)/$(BOARD)
    override BOARD_DIR := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD)
    #$(info LOG: Current board is $(BOARD))
  else
    ifeq ($(filter $(BOARD),$(BASE_ARCHS)),$(BOARD))
      $(error ERR: $(BOARD) is ARCH, check available boards with 'make list ARCH=$(BOARD)')
    else
      matched_boards=$(shell find $(TOP_DIR)/$(BOARDS_DIR) -mindepth 2 -maxdepth 2 -type d -name "*$(BOARD)*" | sed -e 's%$(TOP_DIR)/$(BOARDS_DIR)/%%g')
      ifneq ($(matched_boards),)
        $(error ERR: $(BOARD) not exist, do you mean: $(matched_boards), check more with 'make list')
      else
        $(error ERR: $(BOARD) not exist, check available boards with 'make list')
      endif
    endif
  endif
 endif
endif

# Check if it is a plugin
BOARD_PREFIX:= $(subst /,,$(dir $(BOARD)))
PLUGIN_DIR  := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD_PREFIX)
PLUGIN_FLAG := $(PLUGIN_DIR)/.plugin

ifneq ($(PLUGIN_FLAG), $(wildcard $(PLUGIN_FLAG)))
  PLUGIN_DIR :=
else
  _PLUGIN   ?= 1
endif

# add board directories
BOARD_TOOLCHAIN ?= $(BOARD_DIR)/toolchains

# add a standlaone bsp directory
BSP_DIR ?= $(BOARD_DIR)/bsp
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
PREBUILT_BIOS       := $(PREBUILT_DIR)/bios

# Core source: remote and local
#QEMU_GIT ?= https://github.com/qemu/qemu.git
QEMU_GIT  ?= https://gitee.com/mirrors/qemu.git
_QEMU_GIT := $(QEMU_GIT)
_QEMU_SRC ?= $(if $(QEMU_FORK),$(call _lc,$(QEMU_FORK)-qemu),qemu)
QEMU_SRC  ?= $(_QEMU_SRC)

#UBOOT_GIT ?= https://github.com/u-boot/u-boot.git
UBOOT_GIT  ?= https://gitee.com/mirrors/u-boot.git
_UBOOT_GIT := $(UBOOT_GIT)
_UBOOT_SRC ?= $(if $(UBOOT_FORK),$(call _lc,$(UBOOT_FORK)-uboot),u-boot)
UBOOT_SRC  ?= $(_UBOOT_SRC)

#KERNEL_GIT ?= https://github.com/tinyclub/linux-stable.git
#KERNEL_GIT ?= https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git
KERNEL_GIT  ?= https://kernel.source.codeaurora.cn/pub/scm/linux/kernel/git/stable/linux.git
#KERNEL_GIT ?= git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
_KERNEL_GIT := $(KERNEL_GIT)
_KERNEL_SRC ?= $(if $(KERNEL_FORK),$(call _lc,$(KERNEL_FORK)-kernel),linux-stable)
KERNEL_SRC  ?= $(_KERNEL_SRC)

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
#ROOT_GIT ?= https://github.com/buildroot/buildroot
ROOT_GIT  ?= https://gitee.com/mirrors/buildroot.git
_ROOT_GIT := $(ROOT_GIT)
_ROOT_SRC ?= $(if $(ROOT_FORK),$(call _lc,$(ROOT_FORK)-buildroot),buildroot)
ROOT_SRC  ?= $(_ROOT_SRC)

BOARD_MAKEFILE := $(BOARD_DIR)/Makefile

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

define ___v
$($(1)[$(2)_$($(2))$(if $($(3)),$(comma)$(3)_$($(3)))])
endef

define __v
$(if $($(3)),$(if $(call ___v,$1,$2,$3),$(call ___v,$1,$2,$3),$(if $(call ___v,$1,$2),$(call ___v,$1,$2),$(call ___v,$1,$3))),$(call ___v,$1,$2))
endef

define _v
$(if $(call __v,$1,$2),$(call __v,$1,$2),$(if $3,$3,$($1)))
endef
#$(shell a="$(call __v,$1,$2)"; if [ -n "$$a" ]; then echo "$$a"; else echo $($1); fi)

define __vs
 ifneq ($$(call __v,$(1),$(2),$(3)),)
   $(1) := $$(call __v,$(1),$(2),$(3))
 endif
endef

define __vs_override
 ifneq ($$(call __v,$(1),$(2),$(3)),)
   override $(1) := $$(call __v,$(1),$(2),$(3))
 endif
endef

define _vs
 $(1) := $$(call _v,$(1),$(2))
endef

# Convert version string to version number, support 4 levels version string, like: v2.6.30.5
define _v2v
$(shell echo $(1) | tr -d '[a-zA-Z]' | awk -F"." '{ printf("%d\n",$$1*16777216 + $$2*65536 + $$3*256 + $$4);}')
endef

define _vsif
 ifeq ($$(shell expr $(call _v2v,$($(3))) \$(4) $(call _v2v,$(5))),1)
   $(1) := $(2)
 endif
endef

define _any
$(shell if [ $$(expr $(call _v2v,$($(1))) \$(2) $(call _v2v,$(3))) -eq 1 ]; then echo $($(1)); else echo NONE; fi)
endef

define _range
$(shell if [ $$(expr $(call _v2v,$($(1))) \>= $(call _v2v,$(2))) -eq 1 -a $$(expr $(call _v2v,$($(1))) \<= $(call _v2v,$(3))) -eq 1 ]; then echo $($(1)); else echo NONE; fi)
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
define board_config
$(call _bi,GCC,Makefile)
$(call _bi,ROOT,Makefile)
$(call _bi,NET,Makefile)
$(call _bvi,LINUX,Makefile)
endef

# include .labinit if exist
$(eval $(call _ti,labinit))

$(eval $(call _ti,labconfig))
$(eval $(call _hi,labconfig))

# Loading board configurations
ifneq ($(BOARD),)
  # include $(BOARD_DIR)/.labinit
  $(eval $(call _bi,labinit))
  $(eval $(call _bi,labconfig))
endif

QEMU_FORK_ := $(if $(QEMU_FORK),$(call _lc,$(QEMU_FORK))/,)
UBOOT_FORK_ := $(if $(UBOOT_FORK),$(call _lc,$(UBOOT_FORK))/,)
KERNEL_FORK_ := $(if $(KERNEL_FORK),$(call _lc,$(KERNEL_FORK))/,)
ROOT_FORK_ := $(if $(ROOT_FORK),$(call _lc,$(ROOT_FORK))/,)

_QEMU_FORK := $(if $(QEMU_FORK),$(call _lc,/$(QEMU_FORK)),)
_UBOOT_FORK := $(if $(UBOOT_FORK),$(call _lc,/$(UBOOT_FORK)),)
_KERNEL_FORK := $(if $(KERNEL_FORK),$(call _lc,/$(KERNEL_FORK)),)
_ROOT_FORK := $(if $(ROOT_FORK),$(call _lc,/$(ROOT_FORK)),)

BSP_QEMU ?= $(BSP_DIR)/qemu$(_QEMU_FORK)
BSP_UBOOT ?= $(BSP_DIR)/uboot$(_UBOOT_FORK)
BSP_ROOT ?= $(BSP_DIR)/root$(_ROOT_FORK)
BSP_KERNEL ?= $(BSP_DIR)/kernel$(_KERNEL_FORK)

PREBUILT_QEMU       := $(PREBUILT_DIR)/qemu$(_QEMU_FORK)
PREBUILT_UBOOT      := $(PREBUILT_DIR)/uboot$(_UBOOT_FORK)
PREBUILT_ROOT       := $(PREBUILT_DIR)/root$(_ROOT_FORK)
PREBUILT_KERNEL     := $(PREBUILT_DIR)/kernel$(_KERNEL_FORK)

BOARD_QEMU ?= $(BOARD_DIR)/qemu$(_QEMU_FORK)
BOARD_UBOOT ?= $(BOARD_DIR)/uboot$(_UBOOT_FORK)
BOARD_ROOT ?= $(BOARD_DIR)/root$(_ROOT_FORK)
BOARD_KERNEL ?= $(BOARD_DIR)/kernel$(_KERNEL_FORK)

ifneq ($(BOARD),)
  ifeq ($(BOARD_MAKEFILE), $(wildcard $(BOARD_MAKEFILE)))
    include $(BOARD_MAKEFILE)
  endif
  # include $(BOARD_DIR)/.labfini
  $(eval $(call _bi,labfini))
endif

# Customize kernel git repo and local dir
$(eval $(call __vs,KERNEL_SRC,LINUX,KERNEL_FORK))
$(eval $(call __vs,KERNEL_GIT,LINUX,KERNEL_FORK))
$(eval $(call __vs,ROOT_SRC,BUILDROOT,ROOT_FORK))
$(eval $(call __vs,ROOT_GIT,BUILDROOT,ROOT_FORK))
$(eval $(call __vs,UBOOT_SRC,UBOOT,UBOOT_FORK))
$(eval $(call __vs,UBOOT_GIT,UBOOT,UBOOT_FORK))
$(eval $(call __vs,QEMU_SRC,QEMU,QEMU_FORK))
$(eval $(call __vs,QEMU_GIT,QEMU,QEMU_FORK))

# Allow configure default LINUX version for different kernel fork repo
$(eval $(call __vs,LINUX,KERNEL_FORK))

# Allow boards to customize source and repos
KERNEL_ABS_SRC := $(TOP_SRC)/$(KERNEL_SRC)
ROOT_ABS_SRC   := $(TOP_SRC)/$(ROOT_SRC)
UBOOT_ABS_SRC  := $(TOP_SRC)/$(UBOOT_SRC)
QEMU_ABS_SRC   := $(TOP_SRC)/$(QEMU_SRC)

$(eval $(call __vs,DTS,LINUX))
$(eval $(call __vs,DTB,LINUX))

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
  ifeq ($$(filter $$($(call _lc,$1)),1 new build),$$($(call _lc,$1)))
    PB$1 := 0
  endif
  ifeq ($$(filter $$($(call _lc,$1)),0 old pre prebuild prebuilt),$$($(call _lc,$1)))
    PB$1 := 1
  endif
endif

endef

define _lpb
__$(1) := $(subst x,,$(firstword $(foreach i,K U D R Q,$(findstring x$i,x$(call _uc,$(1))))))
ifneq ($$($1),)
  ifeq ($$(filter $$($1),1 new build),$$($1))
    PB$$(__$(1)) := 0
  endif
  ifeq ($$(filter $$($1),0 old pre prebuild prebuilt),$$($1))
    PB$$(__$(1)) := 1
  endif
endif
ifneq ($(BUILD),)
  ifeq ($$(filter $(1),$(BUILD)),$(1))
    PB$$(__$(1)) := 0
  endif
endif

endef # _lpb

define default_detectbuild
ifneq ($$($(2)),)
  override BUILD += $(1)
endif

endef

#$(warning $(foreach x,K R D Q U,$(call _pb,$x)))
$(eval $(foreach x,K R D Q U,$(call _pb,$x)))

#$(warning $(foreach x,kernel root dtb qemu uboot,$(call _lpb,$x)))
$(eval $(foreach x,kernel root dtb qemu uboot,$(call _lpb,$x)))

# Init 9pnet share variables
ifeq ($(origin SHARE_DIR),command line)
  SHARE := 1
else
  SHARE ?= 0
endif
SHARE_DIR ?= hostshare
HOST_SHARE_DIR ?= $(SHARE_DIR)
GUEST_SHARE_DIR ?= /hostshare
SHARE_TAG ?= hostshare

# Supported apps and their version variable
APPS := kernel uboot root qemu
APP_MAP ?= bsp:BSP kernel:LINUX root:BUILDROOT uboot:UBOOT qemu:QEMU

APP_TARGETS := source download checkout patch defconfig olddefconfig oldconfig menuconfig build cleanup cleanstamp clean distclean save saveconfig savepatch clone help list debug boot test test-debug run upload env

define gengoalslist
$(foreach m,$(or $(2),$(APP_MAP)),$(if $($(lastword $(subst :,$(space),$m))),$(firstword $(subst :,$(space),$m))-$(1)))
endef

define genaliastarget
$(strip $(foreach m,$(APP_MAP),$(if $(subst $(call _lc,$(lastword $(subst :,$(space),$m))),,$(firstword $(subst :,$(space),$m))),$(call _lc,$(lastword $(subst :,$(space),$m))))))
endef

define genaliassource
$(strip $(subst $(1),,$(foreach m,$(APP_MAP),$(subst $(call _lc,$(lastword $(subst :,$(space),$m))),$(firstword $(subst :,$(space),$m)),$(1)))))
endef

# Support alias, root -> buildroot, kernel -> linux
ifneq ($(BUILD),)
  override BUILD := $(call genaliassource,$(BUILD))
endif

ifeq ($(BUILD),all)
  override BUILD :=
  $(foreach m,$(APP_MAP),$(eval $(call default_detectbuild,$(firstword $(subst :,$(space),$m)),$(lastword $(subst :,$(space),$m)))))
endif

first_target := $(firstword $(MAKECMDGOALS))
ifeq ($(findstring -run,$(first_target)),-run)
  # use the rest as arguments for "run"
  reserve_target := $(first_target:-run=)
  APP_ARGS := $(filter-out $(reserve_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
  x := $(APP_ARGS)
endif

# common commands
ifneq ($(filter $(first_target),$(APP_TARGETS)),)
  # use the rest as arguments for "run"
  APP_ARGS := $(filter-out $(first_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
  ifeq ($(first_target),run)
    x := $(filter-out $(first_target),$(wordlist 2,$(words $(APP_ARGS)),$(APP_ARGS)))
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

endef #default_detectapp

ifneq ($(APP_ARGS),)
  APP := $(firstword $(APP_ARGS))
else
  APP :=
  $(foreach m,$(APP_MAP),$(eval $(call cli_detectapp,$(firstword $(subst :,$(space),$m)),$(lastword $(subst :,$(space),$m)))))
endif

ifneq ($(APP),)
  app ?= $(APP)
  override app := $(call genaliassource,$(app))
endif

ifeq ($(app),all)
  override app :=
  $(foreach m,$(APP_MAP),$(eval $(call default_detectapp,$(firstword $(subst :,$(space),$m)),$(lastword $(subst :,$(space),$m)))))
  ifeq ($(first_target), upload)
    override app+= dtb modules
  endif
endif

ifeq ($(app),)
  app := kernel
  ifeq ($(filter $(MAKECMDGOALS),list help),$(MAKECMDGOALS))
    app := default
  endif
endif

endif # common commands

# Prepare build environment

define genbuildenv

GCC_$(2) = $$(call __v,GCC,$(2),$(3))
CCORI_$(2) = $$(call __v,CCORI,$(2),$(3))

ifeq ($$(findstring $(1),$$(MAKECMDGOALS)),$(1))
  ifneq ($$(CCORI_$(2))$$(GCC_$(2)),)
    ifeq ($$(CCORI_$(2))$$(CCORI),)
      CCORI_$(2) := internal
      CCORI := internal
    else
      $$(eval $$(call __vs,CCORI,$(2),$(3)))
    endif
    GCC_$(2)_SWITCH := 1
  endif
endif

ifneq ($$(filter $(ARCH),x86 i386 x86_64),$(ARCH))
 HOST_GCC_$(2) = $$(call __v,HOST_GCC,$(2),$(3))
 HOST_CCORI_$(2) = $$(call __v,HOST_CCORI,$(2),$(3))

 ifeq ($$(findstring $(1),$$(MAKECMDGOALS)),$(1))
  ifneq ($$(HOST_CCORI_$(2))$$(HOST_GCC_$(2)),)
    ifeq ($$(HOST_CCORI_$(2))$$(HOST_CCORI),)
      HOST_CCORI_$(2) := internal
    endif
    HOST_GCC_$(2)_SWITCH := 1
  endif
 endif
endif
endef # genbuildenv

# Customize toolchains for different docker images
$(eval $(call __vs,CCORI,OS))
$(eval $(call __vs,GCC,OS))
$(eval $(call __vs,HOST_GCC,OS))

$(eval $(call genbuildenv,kernel,LINUX,OS))
$(eval $(call genbuildenv,uboot,UBOOT,OS))
$(eval $(call genbuildenv,qemu,QEMU,OS))
$(eval $(call genbuildenv,root,BUILDROOT,OS))

PREBUILT_TOOLCHAIN_MAKEFILE=$(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile

ifeq ($(PREBUILT_TOOLCHAIN_MAKEFILE),$(wildcard $(PREBUILT_TOOLCHAIN_MAKEFILE)))
  include $(PREBUILT_TOOLCHAIN_MAKEFILE)
endif

ifneq ($(GCC),)
  # Force using internal CCORI if GCC specified
  ifeq ($(CCORI),)
    CCORI := internal
  endif
  GCC_SWITCH := 1
endif

ifneq ($$(filter $(ARCH),x86 i386 x86_64),$(ARCH))
 ifneq ($(HOST_GCC),)
  # Force using internal CCORI if GCC specified
  ifeq ($(HOST_CCORI),)
    HOST_CCORI := internal
  endif
  HOST_GCC_SWITCH := 1
 endif
endif

# tuning notify method
notice := error
# stop error for force targets ??
ifeq ($(findstring xforce, x$(MAKECMDGOALS)), xforce)
  notice := warning
endif
# warning instead of error for bsp downloading
ifeq ($(findstring xbsp, x$(MAKECMDGOALS)),xbsp)
  notice := warning
endif
ifeq ($(findstring clone, $(MAKECMDGOALS)),clone)
  notice := ignore
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
  $$(eval $$(call __vs_override,$(2)_LIST,$$(if $(3),$(3),LINUX)))
  ifneq ($$($(2)_LIST),)
    ifneq ($$(filter $$($2), $$($(2)_LIST)), $$($2))
      $$(if $(4),$$(eval $$(call $(4))))
      verify_notice := $$($2) not in supported $(2) list: $$($(2)_LIST),
      ifeq ($$(filter $$(call _lc,$(1)),$(APPS)),$$(call _lc,$(1)))
        verify_notice += clone one please: 'make $$(call _lc,$(1))-clone $(1)_NEW=$$($2)'
      else
        verify_notice += update may help: 'make bsp B=$$(BOARD)'
      endif
      ifneq ($$(notice), ignore)
        ifeq ($$(notice), error)
          $$(error ERR: $$(verify_notice))
        else
          $$(warning WARN: $$(verify_notice))
        endif
      endif
    endif
  endif
 endif
 # Strip prefix of LINUX to get the real version, e.g. XXX-v3.10, XXX may be the customized repo name
 ifneq ($$($(1)_SRC),)
   ifneq ($$(_$(1)_SRC), $$($(1)_SRC))
    _$(2) := $$(subst $$(shell basename $$($(1)_SRC))-,,$$($(2)))
    ifneq ($$(findstring $$(TOP_SRC),$$($(1)_SRC)),$$(TOP_SRC))
      $(1)_ABS_SRC := $$(TOP_SRC)/$$($(1)_SRC)
    else
      $(1)_ABS_SRC := $$($(1)_SRC)
    endif
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
$(eval $(call __vs,QEMU,OS))
$(eval $(call __vs,QTOOL,OS))

_BIMAGE := $(BIMAGE)
_KIMAGE := $(KIMAGE)
_ROOTFS := $(ROOTFS)
_QTOOL  := $(QTOOL)

# Core build: for building in standalone directories
TOP_BUILD      := $(TOP_DIR)/build
TOP_BUILD_ARCH := $(TOP_BUILD)/$(XARCH)
QEMU_BUILD     := $(TOP_BUILD_ARCH)/$(QEMU_FORK_)qemu-$(QEMU)-$(MACH)
UBOOT_BUILD    := $(TOP_BUILD_ARCH)/$(UBOOT_FORK_)uboot-$(UBOOT)-$(MACH)
KERNEL_BUILD   := $(TOP_BUILD_ARCH)/$(KERNEL_FORK_)linux-$(LINUX)-$(MACH)
ROOT_BUILD     := $(TOP_BUILD_ARCH)/$(ROOT_FORK_)buildroot-$(BUILDROOT)-$(MACH)
BSP_BUILD      := $(TOP_BUILD_ARCH)/bsp-$(MACH)

# Cross Compiler toolchains
ifneq ($(XARCH), i386)
  BUILDROOT_CCPRE  = $(XARCH)-linux-
else
  BUILDROOT_CCPRE  = i686-linux-
endif
BUILDROOT_CCPATH = $(ROOT_BUILD)/host/usr/bin

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

C_PATH ?= env PATH=$(if $(CCPATH),$(CCPATH):)$(PATH)$(if $(RUST_PATH),:$(RUST_PATH)) $(L_PATH)

#$(info Using gcc: $(CCPATH)/$(CCPRE)gcc, $(CCORI))

TOOLCHAIN ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)

# Parallel Compiling threads
HOST_CPU_THREADS := $(shell nproc)
JOBS ?= $(HOST_CPU_THREADS)

# Emulator configurations
ifneq ($(BIOS),)
  BIOS_ARG := -bios $(BIOS)
endif

# Another qemu-system-$(ARCH)
QEMU_SYSTEM ?= $(QEMU_BUILD)/$(XARCH)-softmmu/qemu-system-$(XARCH)

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
LINUX_PKIMAGE  := $(ROOT_BUILD)/images/$(PORIIMG)
LINUX_KIMAGE   := $(KERNEL_BUILD)/$(ORIIMG)
LINUX_UKIMAGE  := $(KERNEL_BUILD)/$(or $(UORIIMG),$(notdir $(UKIMAGE)))
LINUX_KRELEASE := $(KERNEL_BUILD)/include/config/kernel.release

ifeq ($(LINUX_KIMAGE),$(wildcard $(LINUX_KIMAGE)))
  PBK ?= 0
else
  PBK := 1
endif

# Customize DTS?
_DTS := $(DTS)

ifeq ($(DTS),)
  ifneq ($(ORIDTS),)
    DTS    := $(KERNEL_ABS_SRC)/$(ORIDTS)
    ORIDTB ?= $(ORIDTS:.dts=.dtb)
  endif
  ifneq ($(ORIDTB),)
    ORIDTS := $(ORIDTB:.dtb=.dts)
    DTS    := $(KERNEL_ABS_SRC)/$(ORIDTS)
  endif
endif

ifneq ($(DTS),)
  DTB_TARGET ?= $(patsubst %.dts,%.dtb,$(shell echo $(DTS) | sed -e "s%.*/dts/%%g"))
  LINUX_DTB  := $(KERNEL_BUILD)/$(ORIDTB)
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

PKIMAGE  ?= $(LINUX_PKIMAGE)
KIMAGE   ?= $(LINUX_KIMAGE)
KRELEASE ?= $(LINUX_KRELEASE)
UKIMAGE  ?= $(LINUX_UKIMAGE)
DTB      ?= $(LINUX_DTB)

ifeq ($(PBK),0)
  KIMAGE   := $(LINUX_KIMAGE)
  KRELEASE := $(LINUX_KRELEASE)
  UKIMAGE  := $(LINUX_UKIMAGE)
endif
ifeq ($(PBD),0)
  DTB := $(LINUX_DTB)
endif

# Prebuilt path (not top dir) setting
ifneq ($(_BIMAGE),)
  PREBUILT_UBOOT_DIR  ?= $(subst //,,$(dir $(_BIMAGE))/)
endif
ifneq ($(_KIMAGE),)
  PREBUILT_KERNEL_DIR ?= $(subst //,,$(dir $(_KIMAGE))/)
endif
ifneq ($(_ROOTFS),)
  PREBUILT_ROOT_DIR   ?= $(subst //,,$(dir $(_ROOTFS))/)
endif
ifneq ($(_QTOOL),)
  PREBUILT_QEMU_DIR   ?= $(patsubst %/bin/,%,$(dir $(_QTOOL)))
endif

# Uboot configurations

ifneq ($(UBOOT),)
  ifeq ($(SHARE),1)
    ifeq ($(call _v,UBOOT,SHARE),disabled)
      # FIXME: Disable uboot by default, vexpress-a9 boot with uboot can not use this feature, so, disable it if SHARE=1 give
      #        versatilepb works with 9pnet + uboot?
      $(info LOG: 9pnet file sharing enabled with SHARE=1, disable uboot for it breaks sharing)
      UBOOT :=
    endif
  endif
endif

ifneq ($(UBOOT),)
UBOOT_BIMAGE    := $(UBOOT_BUILD)/$(notdir $(BIMAGE))
PREBUILT_BIMAGE := $(PREBUILT_UBOOT_DIR)/$(notdir $(BIMAGE))

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

ifeq ($(filter $(MAKECMDGOALS),boot test), $(MAKECMDGOALS))
  ifeq ($(U),1)
    app := uboot
  endif
  ifneq ($(U),0)
    ifeq ($(filter command line,$(foreach i,PBU u uboot,$(origin $i))),command line)
      app := uboot
    endif
  endif
endif

endif # UBOOT != ""

# Use u-boot as 'kernel' if uboot used (while PBU=1/U=1 and u-boot exists)
$(eval $(call __vs,U,LINUX))
ifeq ($(U),1)
  QEMU_KIMAGE := $(BIMAGE)
else
  QEMU_KIMAGE := $(KIMAGE)
endif

# Root configurations

# TODO: buildroot defconfig for $ARCH

# Allow use short ROOTDEV argument
ifneq ($(ROOTDEV),)
  ifneq ($(findstring /dev/,$(ROOTDEV)),/dev/)
    override ROOTDEV := /dev/$(ROOTDEV)
  endif
endif

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
BUILDROOT_ROOTDIR  :=  $(ROOT_BUILD)/target
# As a temp variable
_BUILDROOT_ROOTDIR :=  $(ROOT_BUILD)/images/rootfs

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

ROOTFS_TYPE  := $(shell $(ROOTFS_TYPE_TOOL) $(ROOTFS) $(BSP_ROOT))
ROOTDEV_TYPE := $(shell $(ROOTDEV_TYPE_TOOL) $(ROOTDEV))

#$(error ROOTFS_TYPE: $(ROOTFS_TYPE) ROOTDEV_TYPE:= $(ROOTDEV_TYPE))

# FIXME: workaround if the .cpio.gz or .ext2 are removed and only rootfs/ exists
ifeq ($(findstring not invalid or not exists,$(ROOTFS_TYPE)),not invalid or not exists)
  ROOTFS := $(dir $(ROOTFS))
  ROOTFS_TYPE  := $(shell $(ROOTFS_TYPE_TOOL) $(ROOTFS))
endif

ifeq ($(findstring not invalid or not exists,$(ROOTFS_TYPE)),not invalid or not exists)
  INVALID_ROOTFS := 1
  INVALID_ROOT := 1
endif

ifeq ($(findstring not support yet,$(ROOTDEV_TYPE)),not support yet)
  INVALID_ROOTDEV := 1
  INVALID_ROOT := 1
endif

ifneq ($(MAKECMDGOALS),)
 ifeq ($(filter $(MAKECMDGOALS),_boot root-dir-rebuild root-rd-rebuild root-hd-rebuild),$(MAKECMDGOALS))
  ifeq ($(INVALID_ROOTFS),1)
    $(error rootfs: $(ROOTFS_TYPE), try run 'make bsp' to get newer rootfs.)
  endif
  ifeq ($(INVALID_ROOTDEV),1)
    $(error rootdev: $(ROOTDEV_TYPE), try run 'make bsp' to get newer rootfs.)
  endif
 endif
endif

ifneq ($(INVALID_ROOT),1)
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
endif # INVALID ROOT

# Board targets

BOARD_TOOL := ${TOOL_DIR}/board/show.sh

export GREP_COLOR=32;40
# FILTER for board name
FILTER   ?= .*
# FILTER for board settings
VAR_FILTER   ?= ^[ [\./_a-z0-9-]* \]|^ *[\_a-zA-Z0-9]* *
# all: 0, plugin: 1, noplugin: 2
BTYPE    ?= ^_BASE|^_PLUGIN

define getboardvars
cat $(BOARD_MAKEFILE) | egrep -v "^ *\#|ifeq|ifneq|else|endif|include |call |eval " | egrep -v "_BASE|_PLUGIN"  | cut -d'?' -f1 | cut -d'=' -f1 | cut -d':' -f1 | cut -d'+' -f1 | tr -d ' '
endef

define showboardvars
echo [ $(BOARD) ]:"\n" $(foreach v,$(or $(VAR),$(or $(1),$(shell $(call getboardvars)))),"    $(v) = $($(v)) \n") | tr -s '/' | egrep --colour=auto "$(VAR_FILTER)"
endef

BSP_CHECKOUT ?= bsp-checkout
ifneq ($(BSP_ROOT),$(wildcard $(BSP_ROOT)))
  ifneq ($(app),default)
    BOARD_DOWNLOAD := $(BSP_CHECKOUT)
  endif
endif

board: board-save plugin-save board-cleanstamp board-show $(BOARD_DOWNLOAD)

CLEAN_STAMP := $(call gengoalslist,cleanstamp)
ifneq ($(BOARD),$(BOARD_CONFIG))
  BOARD_CLEAN_STAMP := $(CLEAN_STAMP)
endif

board-cleanstamp: $(BOARD_CLEAN_STAMP)

board-show:
	$(Q)$(call showboardvars)

board-init: $(CLEAN_STAMP)

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

board-config: board-save
	$(Q)$(foreach vs, $(MAKEOVERRIDES), tools/board/config.sh $(vs) $(BOARD_MAKEFILE) $(LINUX);)

BOARD_LABCONFIG := $(BOARD_DIR)/.labconfig

edit: local-edit
config: local-config

local-edit:
	$(Q)touch $(BOARD_LABCONFIG)
	$(Q)vim $(BOARD_LABCONFIG)

local-config: board-save
	$(Q)$(foreach vs, $(MAKEOVERRIDES), tools/board/config.sh $(vs) $(BOARD_LABCONFIG) $(LINUX);)

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
board-info:
	$(Q)find $(BOARDS_DIR)/$(BOARD)/$(or $(_ARCH),) -maxdepth 3 -name "Makefile" -exec egrep -H "$(BTYPE)" {} \; \
		| tr -s '/' | egrep "$(FILTER)" \
		| sort -t':' -k2 | cut -d':' -f1 | xargs -i $(BOARD_TOOL) {} $(PLUGIN) \
		| egrep -v "/module" \
		| sed -e "s%boards/\(.*\)/Makefile%\1%g" \
		| sed -e "s/[[:digit:]]\{2,\}\t/  /g;s/[[:digit:]]\{1,\}\t/ /g" \
		| egrep -v " *_BASE| *_PLUGIN| *#" | egrep -v "^[[:space:]]*$$" \
		| egrep -v "^[[:space:]]*include |call |eval " | egrep --colour=auto "$(VAR_FILTER)"

list-default:
	$(Q)make $(S) board-info BOARD= VAR_FILTER="^ *ARCH |^\[ [\./_a-z0-9-]* \]|^ *CPU|^ *LINUX|^ *ROOTDEV"

list-board:
	$(Q)make $(S) board-info BOARD= VAR_FILTER="^\[ [\./_a-z0-9-]* \]|^ *ARCH"

list-short:
	$(Q)make $(S) board-info BOARD= VAR_FILTER="^\[ [\./_a-z0-9-]* \]|^ *LINUX|^ *ARCH"

list-real:
	$(Q)make $(S) list BTYPE="^_BASE *= 2|^_PLUGIN *= 2"

list-virt:
	$(Q)make $(S) list BTYPE="^_BASE *= 1|^_PLUGIN *= 1"

list-base:
	$(Q)make $(S) list BTYPE="^_BASE"

list-plugin:
	$(Q)make $(S) list BTYPE="^_PLUGIN"

list-full:
	$(Q)make $(S) board-info BOARD=

list-%: FORCE
	$(Q)if [ -n "$($(call _uc,$(subst list-,,$@))_LIST)" ]; then \
		echo " $($(call _uc,$(subst list-,,$@))_LIST) " | sed -e 's%\([ ]\{1,\}\)\($($(call _uc,$(subst list-,,$@)))\)\([ ]\{1,\}\)%\1[\2]\3%g;s%^ %%g;s% $$%%g'; \
	else					\
		if [ $(shell make --dry-run -s $(subst list-,,$@)-list >/dev/null 2>&1; echo $$?) -eq 0 ]; then \
			make -s $(subst list-,,$@)-list; \
		fi		\
	fi

PHONY += board-info list list-base list-plugin list-full

# Define generic target deps support
define make_qemu
$(C_PATH) make -C $(QEMU_BUILD)/$(2) -j$(JOBS) V=$(V) $(1)
endef

define make_kernel
$(C_PATH) make O=$(KERNEL_BUILD) -C $(KERNEL_ABS_SRC) $(if $(LLVM),LLVM=$(LLVM)) ARCH=$(ARCH) LOADADDR=$(KRN_ADDR) CROSS_COMPILE=$(CCPRE) V=$(V) $(KOPTS) -j$(JOBS) $(1)
endef

define make_root
make O=$(ROOT_BUILD) -C $(ROOT_ABS_SRC) V=$(V) -j$(JOBS) $(1)
endef

# FIXME: ugly workaround for uboot, it share code between arm and arm64
define uboot_arch
$(shell if [ $1 = arm64 ]; then echo arm; else echo $1; fi)
endef

define make_uboot
$(C_PATH) make O=$(UBOOT_BUILD) -C $(UBOOT_ABS_SRC) ARCH=$(call uboot_arch,$(ARCH)) CROSS_COMPILE=$(CCPRE) -j$(JOBS) $(1)
endef

# generate target dependencies
define gendeps

ifeq ($$(_stamp_$(1)),)
_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_BUILD))

ifneq ($(firstword $(MAKECMDGOALS)),cleanstamp)
__stamp_$(1)=$$(_stamp_$(1))
endif
endif

$(1)-patch: $(1)-checkout
$(1)-defconfig: $(1)-patch
$(1)-defconfig: $(1)-env
$(1)-modules-install: $(1)-modules
$(1)-modules-install-km: $(1)-modules-km
$(1)-help: $(1)-defconfig

$(1)_defconfig_childs := $(addprefix $(1)-,config getconfig saveconfig menuconfig oldconfig oldnoconfig olddefconfig feature build buildroot modules modules-km run)
ifeq ($(firstword $(MAKECMDGOALS)),$(1))
  $(1)_defconfig_childs := $(1)
endif
$$($(1)_defconfig_childs): $(1)-defconfig

$(1)-save $(1)-saveconfig: $(1)-build

$(1)_APP_TYPE := $(subst x,,$(firstword $(foreach i,K U R Q,$(findstring x$i,x$(call _uc,$(1))))))
ifeq ($$(PB$$($(1)_APP_TYPE)),0)
  ifeq ($$(origin PB$$($(1)_APP_TYPE)),command line)
    boot_deps += $(1)-build
  endif
endif
$(1)_app_type := $(subst x,,$(firstword $(foreach i,k u r q,$(findstring x$i,x$(1)))))
ifeq ($$($$($(1)_app_type)),1)
  ifeq ($$(origin $$($(1)_app_type)),command line)
    boot_deps += $(1)-build
  endif
endif
ifeq ($$($(1)),1)
  ifeq ($$(origin $(1)),command line)
    boot_deps += $(1)-build
  endif
endif
ifeq ($(filter $(1),$(BUILD)),$(1))
  boot_deps += $(1)-build
endif

$(1)_bsp_childs := $(addprefix $(1)-,defconfig patch save saveconfig clone)
$$($(1)_bsp_childs): $(BSP_CHECKOUT)

_boot: $$(boot_deps)

$$(call __stamp_$(1),build): $$(if $$($(call _uc,$(1))_CONFIG_STATUS),,$$($(call _uc,$(1))_BUILD)/$$(or $$($(call _uc,$(1))_CONFIG_STATUS),.config))
	$$(Q)make $$(NPD) _$(1)
	$$(Q)touch $$@

ifeq ($$(findstring $(1),$$(firstword $$(MAKECMDGOALS))),$(1))
$(1): $(if $(x),_$(1),$(1)-build)
endif

# Force app building for current building targets can not auto detect code update
ifeq ($(filter $(first_target),$(1) $(1)-build build), $(first_target))
$(1)-build: _$(1)
else
$(1)-build: $$(call __stamp_$(1),build)
endif

$(1)-run: _$(1)

$(1)-release: $(1) $(1)-save $(1)-saveconfig

$(1)-new $(1)-clone: $(1)-cloneconfig $(1)-clonepatch

PHONY += $(addprefix $(1)-,save saveconfig savepatch build release new clone)

endef # gendeps

# generate xxx-source target
define gensource

ifeq ($$(_stamp_$(1)),)
_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_BUILD))

ifneq ($(firstword $(MAKECMDGOALS)),cleanstamp)
__stamp_$(1)=$$(_stamp_$(1))
endif
endif

$(call _uc,$(1))_SRC_DEFAULT := 1

ifneq ($$(notdir $(patsubst %/,%,$$($(call _uc,$(1))_SRC))),$$($(call _uc,$(1))_SRC))
  ifeq ($$(findstring x$$(BSP_DIR),x$$($(call _uc,$(1))_SRC)),x$$(BSP_DIR))
    $(call _uc,$(1))_SROOT := $$(BSP_DIR)
    $(call _uc,$(1))_SPATH := $$(subst $$(BSP_DIR)/,,$$($(call _uc,$(1))_SRC))
    $(call _uc,$(1))_SRC_DEFAULT := 0
  else
    ifneq ($$(PLUGIN_DIR),)
      ifeq ($$(findstring x$$(PLUGIN_DIR),x$$(TOP_DIR)/$$($(call _uc,$(1))_SRC)),x$$(PLUGIN_DIR))
        $(call _uc,$(1))_SROOT := $$(PLUGIN_DIR)
        $(call _uc,$(1))_SPATH := $$(subst $$(PLUGIN_DIR),,$$(TOP_DIR)/$$($(call _uc,$(1))_SRC))
        $(call _uc,$(1))_SRC_DEFAULT := 0
      endif
    endif
  endif
endif

ifeq ($$($(call _uc,$(1))_SRC_DEFAULT),1)
  # Put submodule is root of linux-lab if no directory specified or if not the above cases
  ifneq ($1, bsp)
    $(call _uc,$(1))_SROOT := $$(TOP_SRC)
    $(call _uc,$(1))_SPATH := $$(subst $$(TOP_SRC)/,,$$($(call _uc,$(1))_SRC))
  else
    $(call _uc,$(1))_SROOT := $$(TOP_DIR)
    $(call _uc,$(1))_SPATH := $$(subst $$(TOP_DIR)/,,$$($(call _uc,$(1))_DIR))
  endif
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

$$(call _stamp_$(1),source): $$(call _stamp_$(1),outdir)
	@echo
	@echo "Downloading $(1) source ..."
	@echo
	$$(Q)if [ -e $$($(call _uc,$(1))_SRC_FULL)/.git ]; then \
		[ -d $$($(call _uc,$(1))_SRC_FULL) ] && cd $$($(call _uc,$(1))_SRC_FULL);	\
		if [ $$(shell [ -d $$($(call _uc,$(1))_SRC_FULL) ] && cd $$($(call _uc,$(1))_SRC_FULL) && git show --pretty=oneline -q $$(or $$(__$(call _uc,$(2))),$$(_$(call _uc,$(2)))) >/dev/null 2>&1; echo $$$$?) -ne 0 ]; then \
			$$($(call _uc,$(1))_GITADD); \
			git fetch --tags $$(or $$($(call _uc,$(1))_GITREPO),origin) && touch $$@; \
		fi;	\
		cd $$(TOP_DIR); \
	else		\
		cd $$($(call _uc,$(1))_SROOT) && \
			mkdir -p $$($(call _uc,$(1))_SPATH) && \
			cd $$($(call _uc,$(1))_SPATH) && \
			git init &&		\
			git remote add origin $$(_$(call _uc,$(1))_GIT) && \
			git fetch --tags origin && touch $$@; \
		cd $$(TOP_DIR); \
	fi

$(1)-source: $$(call __stamp_$(1),source)

$(1)-checkout: $(1)-source

$$(call _stamp_$(1),checkout):
	$$(Q)if [ -d $$($(call _uc,$(1))_SRC_FULL) -a -e $$($(call _uc,$(1))_SRC_FULL)/.git ]; then \
	cd $$($(call _uc,$(1))_SRC_FULL) && git checkout $$(GIT_CHECKOUT_FORCE) $$(_$(2)) && touch $$@ && cd $$(TOP_DIR); \
	fi

$(1)-checkout: $$(call __stamp_$(1),checkout)

$$(call _stamp_$(1),outdir):
	$$(Q)mkdir -p $$($(call _uc,$(1))_BUILD)
	$$(Q)touch $$@

$(1)-outdir: $$(call __stamp_$(1),outdir)

$(1)_source_childs := $(1)-download download-$(1)

$$($(1)_source_childs): $(1)-source

PHONY += $(addprefix $(1)-,source download) download-$(1)

$(1)-%-cleanstamp:
	$$(Q)rm -f $$(call _stamp_$(1),$$(subst $(1)-,,$$(subst -cleanstamp,,$$@)))

$(1)-cleanstamp:
	$$(Q)rm -rf $$(addprefix $$($(call _uc,$(1))_BUILD)/.stamp_$(1)-,outdir source checkout patch env modules modules-km defconfig olddefconfig menuconfig build bsp)

## clean up $(1) source code
$(1)-cleanup: $(1)-cleanstamp
	$$(Q)if [ -d $$($(call _uc,$(1))_SRC_FULL) -a -e $$($(call _uc,$(1))_SRC_FULL)/.git ]; then \
		cd $$($(call _uc,$(1))_SRC_FULL) && git reset --hard && git clean -fdx $$(GIT_CLEAN_EXTRAFLAGS[$(1)]) && cd $$(TOP_DIR); \
	fi

$(1)-clean: $(1)-rawclean $(1)-cleanup

$(1)-rawclean: $$($(call _uc,$(1))_CLEAN_DEPS)
ifeq ($$($(call _uc,$(1))_BUILD)/Makefile, $$(wildcard $$($(call _uc,$(1))_BUILD)/Makefile))
	-$$(Q)$$(call make_$(1),clean)
endif

$(1)-distclean:
ifeq ($$($(call _uc,$(1))_BUILD)/Makefile, $$(wildcard $$($(call _uc,$(1))_BUILD)/Makefile))
	-$$(Q)$$(call make_$(1),distclean)
	$$(Q)rm -rf $$($(call _uc,$(1))_BUILD)
endif

PHONY += $(addprefix $(1)-,cleanstamp cleanup outdir clean distclean)

endef # gensource

# Generate basic goals
define gengoals

#_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_BUILD))

$(1)-list:
	$$(Q)echo " $$($(2)_LIST) " | sed -e 's%\($$($(2))\)\([ ]\{1,\}\)%[\1]\2%g;s%^ %%g;s% $$$$%%g'

$(1)-help:
	$$(Q)$$(if $$($(1)_make_help),$$(call $(1)_make_help),$$(call make_$(1),help))

$$(call _stamp_$(1),patch):
	@if [ ! -f $$($(call _uc,$(1))_SRC_FULL)/.$(1).patched ]; then \
	  $($(call _uc,$(1))_PATCH_EXTRAACTION) \
	  if [ -f tools/$(1)/patch.sh ]; then \
		tools/$(1)/patch.sh $$(BOARD) $$($2) $$($(call _uc,$(1))_SRC_FULL) $$($(call _uc,$(1))_BUILD) && \
		touch $$($(call _uc,$(1))_SRC_FULL)/.$(1).patched && \
		touch $$@; \
	  fi; \
	else		\
	  echo "ERR: $(1) patchset has been applied, if want, please backup important changes and do 'make $(1)-cleanup' at first." && exit 1; \
	fi

$(1)-patch: $$(call __stamp_$(1),patch)

$(1)-savepatch:
	$(Q)cd $$($(call _uc,$(1))_SRC_FULL) && git format-patch $$(_$2) && cd $$(TOP_DIR)
	$(Q)mkdir -p $$(BSP_PATCH)/$(call _lc,$(2))/$$($2)/
	$(Q)cp $$($(call _uc,$(1))_SRC_FULL)/*.patch $$(BSP_PATCH)/$(call _lc,$(2))/$$($2)/

debug-$(1): $(1)-debug

ifeq ($(_VIRT),1)
$(1)-debug: _boot
else
$(1)-debug: _debug
endif

$(1)-boot: _boot

$(1)-test: _test

$(1)-test-debug:
	$$(Q)make _test DEBUG=$(1)

PHONY += $(addprefix $(1)-,list help checkout patch debug boot test)

endef # gengoals

define gencfgs

ifeq ($$(_stamp_$(1)),)
_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_BUILD))

ifneq ($(firstword $(MAKECMDGOALS)),cleanstamp)
__stamp_$(1)=$$(_stamp_$(1))
endif
endif

$(call _uc,$1)_CONFIG_FILE ?= $$($(call _uc,$(1))_FORK_)$(2)_$$($(call _uc,$(2)))_defconfig
$(3)CFG ?= $$($(call _uc,$1)_CONFIG_FILE)

ifeq ($$($(3)CFG),$$($(call _uc,$1)_CONFIG_FILE))
  $(3)CFG_FILE := $$(_BSP_CONFIG)/$$($(3)CFG)
else
  _$(3)CFG_FILE := $$(shell for f in $$($(3)CFG) $(_BSP_CONFIG)/$$($(3)CFG) $$($(call _uc,$1)_CONFIG_DIR)/$$($(3)CFG) $$($(call _uc,$1)_SRC_FULL)/arch/$$(ARCH)/$$($(3)CFG); do \
		if [ -f $$$$f ]; then echo $$$$f; break; fi; done)
  ifneq ($$(_$(3)CFG_FILE),)
    $(3)CFG_FILE := $$(subst //,/,$$(_$(3)CFG_FILE))
  else
    $$(error $$($(3)CFG): can not be found, please pass a valid $(1) defconfig)
  endif
endif

ifeq ($$(findstring $$($(call _uc,$1)_CONFIG_DIR),$$($(3)CFG_FILE)),$$($(call _uc,$1)_CONFIG_DIR))
  $(3)CFG_BUILTIN := 1
endif

_$(3)CFG := $$(notdir $$($(3)CFG_FILE))

$$(call _stamp_$(1),defconfig): $$(if $$($(3)CFG_BUILTIN),,$$($(3)CFG_FILE))
	$$(Q)mkdir -p $$($(call _uc,$1)_BUILD)
	$$(Q)$$(if $$($(call _uc,$1)_CONFIG_DIR),mkdir -p $$($(call _uc,$1)_CONFIG_DIR))
	$$(Q)$$(if $$($(3)CFG_BUILTIN),,cp $$($(3)CFG_FILE) $$($(call _uc,$1)_CONFIG_DIR))
	$$(Q)$$(if $$(CFGS[$(3)_N]),$$(foreach n,$$(CFGS[$(3)_N]),$$(SCRIPTS_$(3)CONFIG) --file $$($(call _uc,$1)_CONFIG_DIR)/$$(_$(3)CFG) -d $$n;))
	$$(Q)$$(if $$(CFGS[$(3)_Y]),$$(foreach n,$$(CFGS[$(3)_N]),$$(SCRIPTS_$(3)CONFIG) --file $$($(call _uc,$1)_CONFIG_DIR)/$$(_$(3)CFG) -e $$n;))
	$$(Q)$$(if $$($(1)_make_defconfig),$$(call $(1)_make_defconfig),$$(call make_$(1),$$(_$(3)CFG) $$($(call _uc,$1)_CONFIG_EXTRAFLAG)))
	$$(Q)touch $$@

$(1)-defconfig: $$(call __stamp_$(1),defconfig)

$(1)-olddefconfig:
	$$($(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,$$(if $$($(call _uc,$1)_OLDDEFCONFIG),$$($(call _uc,$1)_OLDDEFCONFIG),olddefconfig) $$($(call _uc,$1)_CONFIG_EXTRAFLAG))

$(1)-oldconfig:
	$$($(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,oldconfig $$($(call _uc,$1)_CONFIG_EXTRAFLAG))

$(1)-menuconfig:
	$$(call make_$1,menuconfig $$($(call _uc,$1)_CONFIG_EXTRAFLAG))

PHONY += $(addprefix $(1)-,defconfig olddefconfig oldconfig menuconfig)

endef # gencfgs

define genclone
ifneq ($$($(call _uc,$2)_NEW),)

NEW_$(3)CFG_FILE=$$(_BSP_CONFIG)/$$($(call _uc,$(1))_FORK_)$(2)_$$($(call _uc,$2)_NEW)_defconfig
NEW_PREBUILT_$(call _uc,$1)_DIR=$$(subst $$($(call _uc,$2)),$$($(call _uc,$2)_NEW),$$(PREBUILT_$(call _uc,$1)_DIR))

ifneq ($$(NEW_PREBUILT_$(call _uc,$1)_DIR),$$(wildcard $$(NEW_PREBUILT_$(call _uc,$1)_DIR)))

OLD_$(call _uc,$1)_PATCH_DIR=$$(BSP_PATCH)/$$($(call _uc,$(1))_FORK_)$2/$$($(call _uc,$2))
NEW_$(call _uc,$1)_PATCH_DIR=$$(BSP_PATCH)/$$($(call _uc,$(1))_FORK_)$2/$$($(call _uc,$2)_NEW)
NEW_$(call _uc,$1)_GCC=$$(if $$(call __v,GCC,$(call _uc,$2)),GCC[$(call _uc,$2)_$$($(call _uc,$2)_NEW)] = $$(call __v,GCC,$(call _uc,$2)))

$(1)-cloneconfig:
	$$(Q)if [ -f "$$($(3)CFG_FILE)" ]; then cp $$($(3)CFG_FILE) $$(NEW_$(3)CFG_FILE); fi
	$$(Q)tools/board/config.sh $(call _uc,$2)=$$($(call _uc,$2)_NEW) $$(BOARD_LABCONFIG)
	$$(Q)grep -q "GCC\[$(call _uc,$2)_$$($(call _uc,$2)_NEW)" $$(BOARD_LABCONFIG); if [ $$$$? -ne 0 -a -n "$$(NEW_$(call _uc,$1)_GCC)" ]; then \
		sed -i -e "/GCC\[$(call _uc,$2)_$$($(call _uc,$2))/a $$(NEW_$(call _uc,$1)_GCC)" $$(BOARD_LABCONFIG); fi
	$$(Q)mkdir -p $$(NEW_PREBUILT_$(call _uc,$1)_DIR)

$(1)-clonepatch:
	$$(Q)mkdir -p $$(NEW_$(call _uc,$1)_PATCH_DIR)
ifneq ($(PATCH_CLONE),0)
	$$(Q)if [ -d $$(OLD_$(call _uc,$1)_PATCH_DIR) ]; then cp -rf $$(OLD_$(call _uc,$1)_PATCH_DIR)/*.patch $$(NEW_$(call _uc,$1)_PATCH_DIR); fi
endif

else
$(1)-cloneconfig:
	$$(Q)echo $$($(call _uc,$2)_NEW) already exists!
	$$(Q)tools/board/config.sh $(call _uc,$2)=$$($(call _uc,$2)_NEW) $$(BOARD_LABCONFIG)
	$$(Q)grep -q "GCC\[$(call _uc,$2)_$$($(call _uc,$2)_NEW)" $$(BOARD_LABCONFIG); if [ $$$$? -ne 0 -a -n "$$(NEW_$(call _uc,$1)_GCC)" ]; then \
		sed -i -e "/GCC\[$(call _uc,$2)_$$($(call _uc,$2))/a $$(NEW_$(call _uc,$1)_GCC)" $$(BOARD_LABCONFIG); fi

$(1)-clonepatch:
endif

else
$(1)-cloneconfig $(1)-clonepatch:

  ifeq ($$(MAKECMDGOALS),$(1)-clone)
    $$(error Usage: make $(1)-clone [$(call _uc,$2)=<old-$2-version>] $(call _uc,$2)_NEW=<new-$2-version>)
  endif
endif


PHONY += $(addprefix $(1)-,cloneconfig clonepatch)

endef #genclone

define genenvdeps

ifeq ($$(_stamp_$(1)),)
_stamp_$(1)=$$(call _stamp,$(1),$$(1),$$($(call _uc,$(1))_BUILD))

ifneq ($(firstword $(MAKECMDGOALS)),cleanstamp)
__stamp_$(1)=$$(_stamp_$(1))
endif
endif

$$(call _stamp_$(1),env):
	$$(Q)make $$(S) _env
ifeq ($$(GCC_$(2)_SWITCH),1)
	$$(Q)make $$(S) gcc-switch $$(if $$(CCORI_$(2)),CCORI=$$(CCORI_$(2))) $$(if $$(GCC_$(2)),GCC=$$(GCC_$(2)))
endif
ifeq ($$(HOST_GCC_$(2)_SWITCH),1)
	$$(Q)make $$(S) gcc-switch $$(if $$(HOST_CCORI_$(2)),CCORI=$$(HOST_CCORI_$(2))) $$(if $$(HOST_GCC_$(2)),GCC=$$(HOST_GCC_$(2))) b=i386/pc ROOTDEV=/dev/ram0
endif
	$$(Q)touch $$@

$(1)-env: $$(call __stamp_$(1),env)

PHONY += $(1)-env

endef #genenvdeps

# Build bsp targets
# Always checkout the latest commit for bsp
BSP ?= FETCH_HEAD
_BSP ?= $(BSP)

# NOTE: No tag or version defined for bsp repo currently, -source target need fetch latest all the time
__BSP := notexist

ifneq ($(_PLUGIN),)
  BSP_SRC  := $(subst x$(TOP_DIR)/,,x$(PLUGIN_DIR))
else
  BSP_SRC  := $(subst x$(TOP_DIR)/,,x$(BSP_DIR))
endif

# Check and configure board type
# If board support virt and real, allow configure it via VIRT
_VIRT ?= 1
 VIRT ?= 0

# 2 means only support virt
ifeq ($(_BASE)$(_PLUGIN),2)
  _VIRT := 0
endif
# 3 means virt and real, use as virt by default
ifeq ($(_BASE)$(_PLUGIN),3)
  _VIRT := $(VIRT)
endif

ifeq ($(firstword $(MAKECMDGOALS)),bsp)
bsp: bsp-cleanstamp bsp-checkout
PHONY += bsp
endif

#$(warning $(call gensource,bsp,BSP))
$(eval $(call gensource,bsp,BSP))
$(eval $(call genenvdeps,bsp,BSP))

# Qemu targets

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
  QEMU_BUILD := $(TOP_BUILD)/qemu-$(QEMU)-all
  QEMU_ARCH = $(ARCH_LIST)
else
  QEMU_ARCH = $(XARCH)
endif

# Allow use QEMU_USER_STATIC instead of QEMU_US
QEMU_USER_STATIC ?= $(QEMU_US)

ifeq ($(QEMU_USER_STATIC), 1)
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

    ifneq ($(QEMU_VNC),)
      ifeq ($(QEMU_VNC),1)
        QEMU_CONF += --enable-vnc
      else
        QEMU_CONF += --disable-vnc
      endif
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

QEMU_CONFIG_STATUS := config.log
QEMU_PREFIX ?= $(PREBUILT_QEMU_DIR)
QEMU_CONF_CMD := $(QEMU_ABS_SRC)/configure $(QEMU_CONF) --disable-werror --prefix=$(QEMU_PREFIX)
qemu_make_help := cd $(QEMU_BUILD) && $(QEMU_CONF_CMD) --help && cd $(TOP_DIR)
qemu_make_defconfig := $(Q)cd $(QEMU_BUILD) && $(QEMU_CONF_CMD) && cd $(TOP_DIR)

_QEMU  ?= $(call _v,QEMU,QEMU)

#$(warning $(call gensource,qemu,QEMU))
$(eval $(call gensource,qemu,QEMU))
# Add basic qemu dependencies
#$(warning $(call gendeps,qemu))
$(eval $(call gendeps,qemu))
#$(warning $(call gengoals,qemu,QEMU))
$(eval $(call gengoals,qemu,QEMU))
$(eval $(call gencfgs,qemu,QEMU,Q))
#$(warning $(call genenvdeps,qemu,QEMU)
$(eval $(call genenvdeps,qemu,QEMU))
#$(warning $(call genclone,qemu,qemu,Q))
$(eval $(call genclone,qemu,qemu,Q))

QT ?= $(x)

QEMU_UPDATE_GITMODULES=tools/qemu/update-submodules.sh

_qemu_update_submodules:
	$(QEMU_UPDATE_GITMODULES) $(QEMU_ABS_SRC)/.gitmodules

_qemu: _qemu_update_submodules
	$(call make_qemu,$(QT))

# Toolchains targets

toolchain-source: toolchain
download-toolchain: toolchain
gcc: toolchain

include $(PREBUILT_TOOLCHAINS)/Makefile
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
  include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile
endif

SCRIPT_GETCCVER := tools/gcc/version.sh

ifeq ($(filter $(CCORI),internal buildroot),$(CCORI))
  _CCVER := gcc-$(shell $(SCRIPT_GETCCVER) $(CCPRE) $(CCPATH))

  ifneq ($(CCVER),)
    ifeq ($(CCVER),$(_CCVER))
      CCVER_EXIST := 0
    endif
    ifeq ($(CCVER),$(subst gcc-,,$(_CCVER)))
      CCVER_EXIST := 0
    endif
    ifneq ($(CCVER_EXIST),0)
      CCVER_EXIST := $(shell which gcc-$(subst gcc-,,$(CCVER)) 2>&1 >/dev/null; echo $$?)
      ifeq ($(CCVER_EXIST),0)
        ifeq ($(origin CCVER),command line)
          $(warning gcc: $(CCVER) already installed.)
        endif
      endif
    endif
  else
    CCVER := $(_CCVER)
    CCVER_EXIST := 0
  endif
  ifeq ($(CCVER_EXIST),0)
    override CCVER := $(_CCVER)
  endif
endif

toolchain-install:
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
  ifneq ($(CCVER_EXIST),0)
	@echo
	@echo "Installing prebuilt toolchain ..."
	@echo
	$(Q)sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
	$(Q)sudo apt-get -y update
	$(Q)sudo apt-get install -y --force-yes $(CCVER)
	$(Q)sudo apt-get install -y --force-yes libc6-dev libc6-dev-i386 lib32gcc-8-dev gcc-multilib
	$(Q)sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/$(CCVER) 46
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

toolchain: toolchain-install gcc-info

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
	-@echo More...: `/usr/bin/update-alternatives --list $(CCPRE)gcc`
endif
	@echo

gcc-info: toolchain-info
gcc-version: toolchain-info
toolchain-version: toolchain-info

toolchain-clean:
ifeq ($(filter $(XARCH),i386 x86_64),$(XARCH))
  ifeq ($(shell which $(CCVER) 2>&1 >/dev/null; echo $$?),0)
	$(Q)sudo apt-get remove --purge $(CCVER)
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

ifneq ($(_CCORI),$(CCORI))
  ifneq ($(filter $(CCORI),buildroot),$(CCORI))
    UPDATE_CCORI := 1
  endif
endif

ifeq ($(CCORI), internal)
  ifneq ($(CCVER), $(GCC))
    UPDATE_GCC := 1
  endif
endif

toolchain-switch:
ifeq ($(UPDATE_GCC),1)
	-$(Q)update-alternatives --verbose --set $(CCPRE)gcc /usr/bin/$(CCPRE)gcc-$(GCC)
endif
ifeq ($(UPDATE_CCORI),1)
	@#echo OLD: `grep --color=always ^CCORI $(BOARD_MAKEFILE)`
	@tools/board/config.sh CCORI=$(CCORI) $(BOARD_LABCONFIG)
	@#echo NEW: `grep --color=always ^CCORI $(BOARD_MAKEFILE)`
endif
	$(Q)make -s gcc-info

gcc-switch: toolchain-switch

PHONY += toolchain-switch gcc-switch toolchain-version gcc-version gcc-info

# Rootfs targets

_BUILDROOT  ?= $(call _v,BUILDROOT,BUILDROOT)

#$(warning $(call gensource,root,BUILDROOT))
$(eval $(call gensource,root,BUILDROOT))
# Add basic root dependencies
#$(warning $(call gendeps,root))
$(eval $(call gendeps,root))

# Configure Buildroot
GIT_CLEAN_EXTRAFLAGS[root] := -e dl/
#$(warning $(call gengoals,root,BUILDROOT))
$(eval $(call gengoals,root,BUILDROOT))

ROOT_CONFIG_DIR := $(ROOT_ABS_SRC)/configs

#$(warning $(call gencfgs,root,buildroot,R))
$(eval $(call gencfgs,root,buildroot,R))
#$(warning $(call genclone,root,buildroot,R))
$(eval $(call genclone,root,buildroot,R))
#$(warning $(call genenvdeps,root,BUILDROOT)
$(eval $(call genenvdeps,root,BUILDROOT))

# Build Buildroot
ROOT_INSTALL_TOOL := $(TOOL_DIR)/root/install.sh

# Install kernel modules?
IKM ?= 1

ifeq ($(IKM), 1)
  ifeq ($(KERNEL_BUILD)/.modules.order, $(wildcard $(KERNEL_BUILD)/.modules.order))
    KERNEL_MODULES_INSTALL := module-install
  endif
endif

root-buildroot:
	$(call make_root,$(RT))

# Install system/ to ROOTDIR
root-install: $(ROOTDIR)
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
ifneq ($(FS_TYPE),rd)
  ROOT_GENRD_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2rd.sh
  IROOTFS_DEPS    := $(HROOTFS)
else
  ifeq ($(ROOTDIR), $(wildcard $(ROOTDIR)))
    ROOT_GENRD_TOOL := $(TOOL_DIR)/root/dir2rd.sh
    IROOTFS_DEPS    := FORCE
  endif
endif

# Always update rootfs by default, if there is no really file update, disable it with ROOT_UPDATE=0
ROOT_UPDATE ?= 1

$(IROOTFS): $(IROOTFS_DEPS)
ifeq ($(ROOT_UPDATE),1)
	@echo "LOG: Generating ramdisk image with $(ROOT_GENRD_TOOL) ..."
	$(Q)rm -rf $(IROOTFS).tmp
	$(Q)ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS).tmp USER=$(USER) $(ROOT_GENRD_TOOL)
	$(Q)mv $(IROOTFS).tmp $(IROOTFS)
endif

root-rd: $(IROOTFS)

root-rd-rebuild: $(IROOTFS) FORCE

root-rd-clean:
	-$(Q)rm -f $(IROOTFS)

PHONY += root-rd root-rd-rebuild root-rd-clean

ROOT_GENDISK_TOOL := $(TOOL_DIR)/root/dir2$(DEV_TYPE).sh

ifeq ($(prebuilt_root_dir), 1)
  ROOT_REBUILD_DEPS := $(ROOTDIR) FORCE
endif

ifeq ($(DEV_TYPE),rd)
  XROOTFS := $(IROOTFS)
else
  XROOTFS := $(HROOTFS)
endif

# This is used to repackage the updated root directory, for example, `make r-i` just executed.
root-rebuild: $(ROOT_REBUILD_DEPS)
ifeq ($(ROOT_UPDATE),1)
ifeq ($(prebuilt_root_dir), 1)
	@echo "LOG: Generating $(DEV_TYPE) with $(ROOT_GENDISK_TOOL) ..."
	$(Q)rm -rf $(XROOTFS).tmp
	$(Q)ROOTDIR=$(ROOTDIR) INITRD=$(IROOTFS).tmp HROOTFS=$(HROOTFS).tmp FSTYPE=$(FSTYPE) USER=$(USER) $(ROOT_GENDISK_TOOL)
	$(Q)if [ -f $(XROOTFS).tmp ]; then mv $(XROOTFS).tmp $(XROOTFS); fi
	$(Q)if [ $(build_root_uboot) -eq 1 ]; then make $(S) root-ud-rebuild; fi
else
	$(call make_root)
	$(Q)chown -R $(USER):$(USER) $(BUILDROOT_ROOTDIR)
	$(Q)if [ $(build_root_uboot) -eq 1 ]; then make $(S) $(BUILDROOT_UROOTFS); fi
endif
endif

ROOT ?= $(ROOTDIR)
ifeq ($(_PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    ROOT := root-buildroot
  endif
endif

# Specify buildroot target

RT ?= $(x)

ifneq ($(RT),)
  ROOT :=
endif

_root: $(ROOT)
ifneq ($(RT),)
	$(Q)$(call make_root,$(RT))
else
	$(Q)make $(NPD) root-install
	$(Q)if [ -n "$(KERNEL_MODULES_INSTALL)" ]; then make $(NPD) $(KERNEL_MODULES_INSTALL); fi
	$(Q)make $(NPD) root-rebuild
endif

# root directory
ifneq ($(FS_TYPE),dir)
  ROOT_GENDIR_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2dir.sh
  ifeq ($(FS_TYPE),rd)
    # Fix up circular deps, if rootdir is there, remove dep from irootfs
    ifneq ($(ROOTDIR), $(wildcard $(ROOTDIR)))
      ROOTDIR_DEPS := $(IROOTFS)
    endif
  endif
  ifeq ($(FS_TYPE),hd)
    ROOTDIR_DEPS := $(HROOTFS)
  endif
endif

root-dir rootdir: $(ROOTDIR)
root-dir-rebuild rootdir-rebuild: $(ROOTDIR) FORCE

PHONY += root-dir rootdir root-dir-rebuild rootdir-rebuild

$(ROOTDIR): $(ROOTDIR_DEPS)
ifneq ($(ROOTDIR), $(BUILDROOT_ROOTDIR))
	@echo "LOG: Generating rootfs directory with $(ROOT_GENDIR_TOOL) ..."
	$(Q)rm -rf $(ROOTDIR).tmp
	$(Q)rm -rf $(ROOTDIR)
	$(Q)ROOTDIR=$(ROOTDIR).tmp USER=$(USER) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) $(ROOT_GENDIR_TOOL)
	$(Q)mv $(ROOTDIR).tmp $(ROOTDIR)
endif

root-dir-install rootdir-install: root-install

PHONY += root-dir-install rootdir-install

root-dir-clean rootdir-clean:
	-$(Q)if [ "$(ROOTDIR)" = "$(PREBUILT_ROOTDIR)" ]; then rm -rf $(ROOTDIR); fi

root-dir-distclean rootdir-distclean: rootdir-clean

PHONY += root-dir-distclean rootdir-distclean root-dir-clean rootdir-clean

fullclean: $(call gengoalslist,distclean)
	$(Q)git clean -fdx

ifeq ($(FS_TYPE),dir)
  HROOTFS_DEPS := $(ROOTDIR) FORCE
endif
ifeq ($(FS_TYPE),rd)
  HROOTFS_DEPS := $(IROOTFS)
endif

ROOT_GENHD_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2hd.sh

$(HROOTFS): $(HROOTFS_DEPS)
ifeq ($(ROOT_UPDATE),1)
	@echo "LOG: Generating harddisk image with $(ROOT_GENHD_TOOL) ..."
	$(Q)rm -rf $(HROOTFS).tmp
	$(Q)ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS).tmp INITRD=$(IROOTFS) $(ROOT_GENHD_TOOL)
	$(Q)mv $(HROOTFS).tmp $(HROOTFS)
endif

root-hd: $(HROOTFS)

root-hd-rebuild: $(HROOTFS) FORCE

root-hd-clean:
	-$(Q)rm -f $(HROOTFS)

PHONY += root-hd root-hd-rebuild root-hd-clean

# Kernel modules

# Linux Kernel targets
_LINUX  := $(call _v,LINUX,LINUX)
_KERNEL ?= $(_LINUX)

# kernel remove oldnoconfig after 4.19 and use olddefconfig instead,
# see commit: 312ee68752faaa553499775d2c191ff7a883826f kconfig: announce removal of oldnoconfig if used
#        and: 04c459d204484fa4747d29c24f00df11fe6334d4 kconfig: remove oldnoconfig target
ifeq ($(filter kernel-olddefconfig,$(MAKECMDGOALS)),kernel-olddefconfig)
KERNEL_OLDDEFCONFIG := $(shell tools/kernel/olddefconfig.sh $(KERNEL_ABS_SRC)/scripts/kconfig/Makefile)
endif
KERNEL_CONFIG_DIR := $(KERNEL_ABS_SRC)/arch/$(ARCH)/configs/
KERNEL_CONFIG_EXTRAFLAG := M=
KERNEL_CONFIG_EXTRACMDS := yes N | $(empty)
KERNEL_CLEAN_DEPS := kernel-modules-clean

kernel-oldnoconfig: kernel-olddefconfig

#$(warning $(call gensource,kernel,LINUX))
$(eval $(call gensource,kernel,LINUX))
# Add basic kernel & modules deps
#$(warning $(call gendeps,kernel))
$(eval $(call gendeps,kernel))
#$(warning $(call gengoals,kernel,LINUX))
$(eval $(call gengoals,kernel,LINUX))
# Configure Kernel
#$(warning $(call gencfgs,kernel,linux,K))
$(eval $(call gencfgs,kernel,linux,K))
#$(warning $(call genclone,kernel,linux,K))
$(eval $(call genclone,kernel,linux,K))
#$(warning $(call genenvdeps,kernel,LINUX))
$(eval $(call genenvdeps,kernel,LINUX))
# Get configs must be enabled/disabled for target toolchain and kernel versions
$(eval $(call __vs,CFGS[K_N],GCC,LINUX))
$(eval $(call __vs,CFGS[K_Y],GCC,LINUX))

TOP_MODULE_DIR := $(TOP_SRC)/modules
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
KERNEL_SEARCH_PATH := $(addprefix $(KERNEL_MODULE_DIR)/,drivers kernel fs block crypto mm net security sound samples)

modules ?= $(m)
module  ?= $(modules)
ifeq ($(module),all)
  module := $(shell find $(EXT_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | xargs -i basename {} | tr '\n' ',')
endif

internal_module := 0
ifneq ($(M),)
  ifneq ($(M),)
    override M := $(subst //,/,$(patsubst %/,%,$(M)))
  endif
  ifeq ($(M),$(wildcard $(M)))
    ifeq ($(findstring $(KERNEL_MODULE_DIR),$(M)),$(KERNEL_MODULE_DIR))
      # Convert to relative path: must related to top dir of linux kernel, otherwise, will be compiled in source directory
      M_PATH = $(subst $(KERNEL_MODULE_DIR)/,,$(M))
      internal_module := 1
    else
      ifeq ($(findstring $(TOP_DIR),$(M)),$(TOP_DIR))
        M_PATH ?= $(M)
      else
        M_PATH ?= $(TOP_DIR)/$(M)
      endif
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
    MODULE := $(shell printf $(module) | tr ',' '\n' | tr '\n' ',' | sed -e 's%,$$%%g')
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
      $(error 'ERR: No such module found: $(module), list all by: `make modules-list`')
    else
      $(info LOG: m=$(module) ; M=$(M_PATH))
    endif
  endif # module not empty
endif   # ext_one_module = 1

ifneq ($(M_PATH),)
  M_PATH := $(subst //,/,$(patsubst %/,%,$(M_PATH)))
endif

SCRIPTS_KCONFIG := tools/kernel/config
DEFAULT_KCONFIG := $(KERNEL_BUILD)/.config

ifneq ($(M_PATH),)
modules-prompt:
	@echo
	@echo "  Current using module is $(M_PATH)."
	@echo "  to compile modules under $(KERNEL_ABS_SRC), use 'make kernel-modules'."
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
		make -s $(NPD) feature feature=module; \
		make -s $(NPD) kernel-olddefconfig; \
		$(call make_kernel); \
	fi
	# M variable can not be set for modules_prepare target
	$(call make_kernel,$(MODULE_PREPARE) M=)
	$(Q)if [ -f $(KERNEL_ABS_SRC)/scripts/Makefile.modbuiltin ]; then \
		$(call make_kernel,$(if $(m),$(m).ko,modules) $(KM)); \
	else	\
		$(call make_kernel,modules $(KM)); \
	fi

kernel-modules:
	$(Q)make $(NPD) kernel-modules-km KM=

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
	$(Q)find $(EXT_MODULE_DIR) -name "Makefile" | $(PF) | xargs -i egrep -iH "^obj-m[[:space:]]*[+:]*=[[:space:]]*.*($(IMF)).*\.o" {} | sed -e "s%$(PWD)\(.*\)/Makefile:obj-m[[:space:]]*[+:]*=[[:space:]]*\(.*\).o%m=\2 ; M=\$$PWD/\1%g" | cat -n
ifeq ($(internal_search),1)
	$(Q)find $(KERNEL_SEARCH_PATH) -name "Makefile" | $(PF) | xargs -i egrep -iH "^obj-.*_($(IMF))(\)|_).*[[:space:]]*[+:]*=[[:space:]]*($(IMF)).*\.o" {} | sed -e "s%$(KERNEL_MODULE_DIR)/\(.*\)/Makefile:obj-\$$(CONFIG_\(.*\))[[:space:]]*[+:]*=[[:space:]]*\(.*\)\.o%c=\2 ; m=\3 ; M=\1%g" | cat -n
endif

PHONY += kernel-modules-km kernel-modules kernel-modules-list kernel-modules-list-full

M_I_ROOT ?= $(ROOTDIR)
ifeq ($(PBR), 0)
  ifneq ($(BUILDROOT_IROOTFS),$(wildcard $(BUILDROOT_IROOTFS)))
    M_I_ROOT := root-buildroot
  endif
endif

# From linux-stable/scripts/depmod.sh, v5.1
SCRIPTS_DEPMOD := $(TOP_DIR)/tools/kernel/depmod.sh

kernel-modules-install-km: $(M_I_ROOT)
	$(Q)if [ "$(shell $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" = "y" ]; then \
		$(call make_kernel,modules_install $(KM) INSTALL_MOD_PATH=$(ROOTDIR)); \
		if [ ! -f $(KERNEL_ABS_SRC)/scripts/depmod.sh ]; then \
		    cd $(KERNEL_BUILD) && \
		    INSTALL_MOD_PATH=$(ROOTDIR) $(SCRIPTS_DEPMOD) /sbin/depmod $$(grep UTS_RELEASE -ur include |  cut -d ' ' -f3 | tr -d '"'); \
		    cd $(TOP_DIR); \
		fi;				\
	fi

kernel-modules-install: $(M_I_ROOT)
	$(Q)if [ "$(shell $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" = "y" ]; then \
		$(call make_kernel,modules_install INSTALL_MOD_PATH=$(ROOTDIR));	\
	fi

ifeq ($(internal_module),1)
  M_ABS_PATH := $(KERNEL_BUILD)/$(M_PATH)
else
  M_ABS_PATH := $(wildcard $(M_PATH))
endif

KERNEL_MODULE_CLEAN := tools/module/clean.sh
kernel-modules-clean-km:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_BUILD) $(M_ABS_PATH)
	$(Q)rm -rf .module_config

kernel-modules-clean:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_BUILD)

PHONY += kernel-modules-install-km kernel-modules-install kernel-modules-clean

_module: kernel-modules-km plugin-save
module-list: kernel-modules-list plugin-save
module-list-full: kernel-modules-list-full plugin-save
_module-install: kernel-modules-install-km
_module-clean: kernel-modules-clean-km

modules-list: module-list
modules-list-full: module-list-full

module-test: kernel-test
modules-test: module-test

PHONY += _module module-list module-list-full _module-install _module-clean modules-list modules-list-full

kernel-module: module
module: FORCE
	$(Q)$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nBuilding module: $(m) ...\n" && make $(NPD) _module m=$(m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(shell echo $(M) | tr ',' ' '), \
		echo "\nBuilding module: $(_M) ...\n" && make $(NPD) _module M=$(_M);) echo '')

kernel-module-install: module-install
module-install: FORCE
	$(Q)$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nInstalling module: $(m) ...\n" && make $(NPD) _module-install m=$(m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(shell echo $(M) | tr ',' ' '), \
		echo "\nInstalling module: $(_M) ...\n" && make $(NPD) _module-install M=$(_M);) echo '')

kernel-module-clean: module-clean
module-clean: FORCE
	$(Q)$(if $(module), $(foreach m, $(shell echo $(module) | tr ',' ' '), \
		echo "\nCleaning module: $(m) ...\n" && make $(NPD) _module-clean m=$(m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(shell echo $(M) | tr ',' ' '), \
		echo "\nCleaning module: $(_M) ...\n" && make $(NPD) _module-clean M=$(_M);) echo '')

PHONY += kernel-module kernel-module-install kernel-module-clean

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

# Build Kernel

KERNEL_FEATURE_DOWNLOAD_TOOL := tools/kernel/feature-download.sh
KERNEL_FEATURE_TOOL := tools/kernel/feature.sh

FPL ?= 1
ifeq ($(filter $(FEATURE),debug module boot nfsroot initrd), $(FEATURE))
  FPL := 0
endif
ifeq ($(FEATURE),boot,module)
  FPL := 0
endif

FEATURE_PATCHED_TAG := $(KERNEL_ABS_SRC)/.feature.patched

kernel-defconfig: kernel-feature-download
kernel-feature-download:
ifneq ($(FEATURE),)
	  @$(KERNEL_FEATURE_DOWNLOAD_TOOL) $(ARCH) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_BUILD) "$(FEATURE)"
endif

FCS ?= 0
ifeq ($(origin F), command line)
  FCS := 1
endif
ifeq ($(origin FEATURE), command line)
  FCS := 1
endif
ifeq ($(origin FEATURES), command line)
  FCS := 1
endif

kernel-feature:
	@if [ $(FPL) -eq 0 -o ! -f $(FEATURE_PATCHED_TAG) ]; then \
	  $(KERNEL_FEATURE_TOOL) $(ARCH) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_BUILD) "$(FEATURE)"; \
	  [ $(FCS) -eq 1 ] && tools/board/config.sh feature=$(FEATURE) $(BOARD_LABCONFIG) $(LINUX); \
	  $(call make_kernel,olddefconfig); \
	  if [ $(FPL) -eq 1 -a -n "$(FEATURE)" ]; then touch $(FEATURE_PATCHED_TAG); fi; \
	  if [ -z "$(FEATURE)" ]; then rm -rf $(FEATURE_PATCHED_TAG); fi; \
	else \
	  echo "ERR: feature patchset has been applied, if want, please backup important changes and pass 'FPL=0' or 'make kernel-cleanup' at first." && exit 1; \
	fi

ifneq ($(firstword $(MAKECMDGOALS)),list)
feature: kernel-feature
features: feature
endif

kernel-features: kernel-feature

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

kernel-feature-test: kernel-test
kernel-features-test: kernel-feature-test
features-test: kernel-feature-test
feature-test: kernel-feature-test

PHONY += kernel-feature-test kernel-features-test features-test feature-test

IMAGE := $(notdir $(ORIIMG))

# aarch64 not add uboot header for kernel image
ifeq ($(U),1)
  ifeq ($(ARCH),arm64)
    IMAGE := Image
  else
    IMAGE := uImage
  endif
endif

# Default kernel target is kernel image
KT ?= $(IMAGE)
ifneq ($(x),)
  KT := $(x)
endif

# Allow to accept external kernel compile options, such as XXX_CONFIG=y
KOPTS ?=

ifeq ($(findstring /dev/null,$(ROOTDEV)),/dev/null)
  ROOT_RD := $(IROOTFS)
  # directory is ok, but is not compressed cpio
  KOPTS   += CONFIG_INITRAMFS_SOURCE=$(IROOTFS)
else
  KOPTS   += CONFIG_INITRAMFS_SOURCE=
endif

DTC := tools/kernel/dtc

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
	$(Q)$(DTC) -I dts -O dtb -o $(DTB) $(DTS)
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
	$(Q)$(call make_kernel,$(MODULE_PREPARE) M=)
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

_kernel: $(KERNEL_DEPS)
	$(call make_kernel,$(KT))

KERNEL_CALLTRACE_TOOL := tools/kernel/calltrace-helper.sh

ifeq ($(findstring calltrace,$(MAKECMDGOALS)),calltrace)
  ifneq ($(lastcall),)
    LASTCALL ?= $(lastcall)
  endif
  ifeq ($(LASTCALL),)
    $(error make kernel-calltrace lastcall=func+offset/length)
  endif
endif

calltrace: kernel-calltrace
kernel-calltrace: kernel-build
	$(Q)$(KERNEL_CALLTRACE_TOOL) $(VMLINUX) $(LASTCALL) $(KERNEL_ABS_SRC) "$(C_PATH)" "$(CCPRE)"

PHONY += kernel-calltrace calltrace

# Uboot specific part
ifneq ($(UBOOT),)

# Uboot targets
_UBOOT  ?= $(call _v,UBOOT,UBOOT)

PFLASH_BASE ?= 0
PFLASH_SIZE ?= 0
BOOTDEV ?= none
KRN_ADDR ?= -
KRN_SIZE ?= 0
RDK_ADDR ?= -
RDK_SIZE ?= 0
DTB_ADDR ?= -
DTB_SIZE ?= 0
UCFG_DIR := $(UBOOT_ABS_SRC)/include/configs

#$(warning $(call genverify,BOOTDEV,BOOTDEV,UBOOT))
$(eval $(call genverify,BOOTDEV,BOOTDEV,UBOOT))

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
ifeq ($(BOOTDEV),ram)
  U_BOOT_CMD := bootcmd4
  RAM_BOOT ?= 1
endif

ifneq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  RDK_ADDR := -
endif
ifeq ($(DTS),)
  DTB_ADDR := -
endif

export U_BOOT_CMD IP ROUTE ROOTDEV BOOTDEV ROOTDIR PFLASH_BASE KRN_ADDR KRN_SIZE RDK_ADDR RDK_SIZE DTB_ADDR DTB_SIZE

UBOOT_CONFIG_TOOL := $(TOOL_DIR)/uboot/config.sh
UBOOT_PATCH_EXTRAACTION := if [ -n "$$(UCONFIG)" ]; then $$(UBOOT_CONFIG_TOOL) $$(UCFG_DIR) $$(UCONFIG); fi;
UBOOT_CONFIG_DIR := $(UBOOT_ABS_SRC)/configs
UBOOT_CLEAN_DEPS := $(UBOOT_IMGS_DISTCLEAN)

#$(warning $(call gensource,uboot,UBOOT))
$(eval $(call gensource,uboot,UBOOT))
# Add basic uboot dependencies
#$(warning $(call gendeps,uboot))
$(eval $(call gendeps,uboot))
# Verify BOOTDEV argument
#$(warning $(call gengoals,uboot,UBOOT))
$(eval $(call gengoals,uboot,UBOOT))
#$(warning $(call gencfgs,uboot,uboot,U))
$(eval $(call gencfgs,uboot,uboot,U))
#$(warning $(call genclone,uboot,uboot,U))
$(eval $(call genclone,uboot,uboot,U))
#$(warning $(call genenvdeps,uboot,UBOOT))
$(eval $(call genenvdeps,uboot,UBOOT))

# Specify uboot targets
UT ?= $(x)

# Build Uboot
_uboot:
	$(call make_uboot,$(UT))

UBOOT_MKIMAGE := tools/uboot/mkimage

# root uboot image
$(UROOTFS): $(IROOTFS)
ifeq ($(ROOT_UPDATE),1)
	@echo "LOG: Generating rootfs image for uboot ..."
	$(Q)$(UBOOT_MKIMAGE) -A $(ARCH) -O linux -T ramdisk -C none -d $(IROOTFS) $(UROOTFS)
endif

root-ud: $(UROOTFS)

root-ud-rebuild: $(UROOTFS) FORCE

root-ud-clean:
	-$(Q)rm -f $(UROOTFS)

PHONY += root-ud root-ud-rebuild root-ud-clean

# aarch64 not add uboot header for kernel image
$(UKIMAGE): $(KIMAGE)
ifeq ($(PBK), 0)
ifeq ($(notdir $(UKIMAGE)), uImage)
	$(Q)$(UBOOT_MKIMAGE) -A $(ARCH) -O linux -T kernel -C none -a $(KRN_ADDR) -e $(KRN_ADDR) \
		-n 'Linux-$(LINUX)' -d $(KIMAGE) $(UKIMAGE)
else
	$(Q)cp $(KIMAGE) $(UKIMAGE)
endif
endif

ifneq ($(INVALID_ROOTFS),1)
U_ROOT_IMAGE = $(UROOTFS)
endif

U_KERNEL_IMAGE = $(UKIMAGE)

ifeq ($(DTB),$(wildcard $(DTB)))
  U_DTB_IMAGE=$(DTB)
endif

BOOTX := $(if $(UBOOT_BIOS),booti,bootm)

export CMDLINE PFLASH_IMG PFLASH_SIZE PFLASH_BS ENV_ADDR ENV_OFFSET ENV_SIZE BOOTX BOOTDEV_LIST SD_IMG U_ROOT_IMAGE RDK_SIZE U_DTB_IMAGE DTB_SIZE U_KERNEL_IMAGE KRN_SIZE TFTPBOOT BIMAGE ROUTE BOOTDEV

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
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  UBOOT_DEPS += $(UROOTFS)
endif
UBOOT_DEPS += $(UKIMAGE)

ifeq ($(SD_BOOT),1)
  UBOOT_PACKAGES_INSTALL := packages-install
endif

_uboot-images: $(UBOOT_PACKAGES_INSTALL) $(UBOOT_DEPS)
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
ifneq ($(BOOTDEV),none)
	$(Q)$(UBOOT_ENV_TOOL)
endif

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
	-$(Q)$(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(PORIIMG)) 2>/dev/null || true
endif

kernel-save:
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	-cp $(LINUX_KIMAGE) $(PREBUILT_KERNEL_DIR)
	-cp $(LINUX_KRELEASE) $(PREBUILT_KERNEL_DIR)
	-$(Q)$(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(ORIIMG)) 2>/dev/null || true
	-if [ -n "$(UORIIMG)" -a -f "$(LINUX_UKIMAGE)" ]; then cp $(LINUX_UKIMAGE) $(PREBUILT_KERNEL_DIR); fi
	-if [ -n "$(DTS)" -a -f "$(LINUX_DTB)" ]; then cp $(LINUX_DTB) $(PREBUILT_KERNEL_DIR); fi

# Required packages for auto login (ssh, serial)
packages-install:
	$(Q)/usr/bin/which $(PACKAGES_NEED[bin]) >/dev/null 2>&1 || \
	(echo "LOG: Install missing tools: $(PACKAGES_NEED[deb])" && \
	sudo apt-get update -y && sudo apt-get install -y $(PACKAGES_NEED[deb]))

# Targets for real boards
ifeq ($(_VIRT),0)

# Remote automatical login related parts
LOGIN_METHOD ?= ssh

ifneq ($(LOGIN_METHOD),ssh)
  $(error Only support ssh upload method currently)
endif

# The ip address of target board, must make sure python3-serial is installed
ifeq ($(shell [ -c $(BOARD_SERIAL) ] && sudo sh -c 'echo > $(BOARD_SERIAL)' 2>/dev/null; echo $$?),0)
  GETIP_TOOL    ?= $(TOP_DIR)/tools/helper/getip.py
  GETIP_TIMEOUT ?= 2
  BOARD_IP ?= $$(sudo timeout $(GETIP_TIMEOUT) python3 $(GETIP_TOOL) $(BOARD_SERIAL) $(BOARD_BAUDRATE))
else
  SSH_TARGETS    ?= login boot boot-config reboot -upload
  TARGET_MATCHED := $(strip $(foreach s,$(SSH_TARGETS),$(findstring $s,$(MAKECMDGOALS))))
  ifneq ($(TARGET_MATCHED),)
    ifeq ($(BOARD_IP),)
      $(error This is a real hardware board, please buy one from $(BOARD_SHOP) and configure BOARD_SERIAL or BOARD_IP in $(BOARD_MAKEFILE) before uploading)
    endif
  endif
endif

ifeq ($(BOARD_PASS),)
  $(error BOARD_PASS must be configured in $(BOARD_MAKEFILE) before uploading)
endif

SSH_PASS  = sshpass -p $(BOARD_PASS)
SSH_CMD   = $(SSH_PASS) ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t $(BOARD_USER)@$(BOARD_IP)
SCP_CMD   = $(SSH_PASS) scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

SSH_RSH   = --rsh='sshpass -e ssh -l $(BOARD_USER) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no '
RSYNC_CMD = SSHPASS=$(BOARD_PASS) rsync -av $(SSH_RSH)

# KERNEL_RELEASE version info required by -upload and boot-config targets
ifneq ($(MAKECMDGOALS),)
 ifeq ($(filter $(firstword $(MAKECMDGOALS)),$(addsuffix -upload,kernel dtb module modules) boot-config boot upload),$(firstword $(MAKECMDGOALS)))
  KERNEL_RELEASE ?= $(shell cat $(KRELEASE))
  ifeq ($(KERNEL_RELEASE),)
    $(error Linux must be compiled before uploading)
  endif
 endif
endif

# Check ip variable
getip:
	$(Q)if [ -z "$(BOARD_IP)" ]; then echo "$(GETIP_TOOL) timeout, $(BOARD_SERIAL) may be connected by another client." && exit 1; fi

# Upload images to remote board

ifeq ($(findstring upload,$(MAKECMDGOALS)),upload)
LOCAL_MODULES  ?= $(PREBUILT_ROOTDIR)/lib/modules/$(KERNEL_RELEASE)
REMOTE_KIMAGE  ?= /boot/vmlinuz-$(KERNEL_RELEASE)
REMOTE_MODULES ?= /lib/modules/$(KERNEL_RELEASE)
REMOTE_DTB     ?= /boot/dtbs/$(KERNEL_RELEASE)/$(DIMAGE)

ifneq ($(DTS),)
dtb-upload: packages-install getip $(call __stamp_kernel,build)
	$(Q)echo "LOG: Upload dtb image from $(DTB) to $(BOARD_IP):$(REMOTE_DTB)"
	$(Q)$(SSH_CMD) 'rm -f $(REMOTE_DTB); mkdir -p $(dir $(REMOTE_DTB))'
	$(Q)$(SCP_CMD) $(DTB) $(BOARD_USER)@$(BOARD_IP):$(REMOTE_DTB)
endif

kernel-upload: packages-install getip $(call __stamp_kernel,build)
	$(Q)echo "LOG: Upload kernel image from $(KIMAGE) to $(BOARD_IP):$(REMOTE_KIMAGE)"
	$(Q)$(SSH_CMD) 'rm -f $(REMOTE_IMAGE); mkdir -p $(dir $(REMOTE_KIMAGE))'
	$(Q)$(SCP_CMD) $(KIMAGE) $(BOARD_USER)@$(BOARD_IP):$(REMOTE_KIMAGE)

$(LOCAL_MODULES)$(m):
	$(Q)make modules-install m=$(m)
	$(Q)touch $(LOCAL_MODULES)$(m)

module-upload: modules-upload

modules-upload: packages-install getip $(LOCAL_MODULES)$(m)
	$(Q)echo "LOG: Upload modules from $(LOCAL_MODULES) to $(BOARD_IP):$(REMOTE_MODULES)"
	$(Q)rm -f $(LOCAL_MODULES)/source $(LOCAL_MODULES)/build
	$(Q)$(SSH_CMD) 'mkdir -p $(REMOTE_MODULES)'
	$(Q)$(RSYNC_CMD) $(LOCAL_MODULES)/* $(BOARD_IP):$(REMOTE_MODULES)/

# Add dummmy entries for upload target
ifeq ($(first_target), upload)
$(addsuffix -upload, root uboot qemu):
endif

PHONY += $(addsuffix -upload,kernel dtb module modules root uboot qemu) upload

endif # -upload

BOOT_CONFIG ?= uEnv
ifneq ($(BOOT_CONFIG),uEnv)
  $(error Only support uEnv configure method currently)
endif

boot-config: packages-install getip
	$(Q)echo "LOG: Configure new kernel and dtbs images"
	$(Q)$(SSH_CMD) 'sed -i -e "s/uname_r=.*/uname_r=$(KERNEL_RELEASE)/g" /boot/uEnv.txt'
	$(Q)$(SSH_CMD) 'sed -i -e "s/dtb=.*/dtb=$(DIMAGE)/g" /boot/uEnv.txt'

reboot: packages-install getip
	$(Q)echo "LOG: Rebooting via ssh"
	$(Q)$(SSH_CMD) 'sudo reboot' || true

PHONY += boot-config reboot

endif # for real boards

uboot-save:
	$(Q)mkdir -p $(PREBUILT_UBOOT_DIR)
	-cp $(UBOOT_BIMAGE) $(PREBUILT_UBOOT_DIR)


qemu-save:
	$(Q)mkdir -p $(PREBUILT_QEMU_DIR)
	-$(Q)$(call make_qemu,install)
	-$(Q)$(foreach _QEMU_TARGET,$(subst $(comma),$(space),$(QEMU_TARGET)),$(call make_qemu,install,$(_QEMU_TARGET));echo '';)

uboot-saveconfig:
	-$(call make_uboot,savedefconfig)
	$(Q)if [ -f $(UBOOT_BUILD)/defconfig ]; \
	then cp $(UBOOT_BUILD)/defconfig $(_BSP_CONFIG)/$(UBOOT_CONFIG_FILE); \
	else cp $(UBOOT_BUILD)/.config $(_BSP_CONFIG)/$(UBOOT_CONFIG_FILE); fi

# kernel < 2.6.36 doesn't support: `make savedefconfig`
kernel-saveconfig:
	-$(call make_kernel,savedefconfig M=)
	$(Q)if [ -f $(KERNEL_BUILD)/defconfig ]; \
	then cp $(KERNEL_BUILD)/defconfig $(_BSP_CONFIG)/$(KERNEL_CONFIG_FILE); \
	else cp $(KERNEL_BUILD)/.config $(_BSP_CONFIG)/$(KERNEL_CONFIG_FILE); fi

root-saveconfig:
	$(call make_root,savedefconfig)
	$(Q)if [ $(shell grep -q BR2_DEFCONFIG $(ROOT_BUILD)/.config; echo $$?) -eq 0 ]; \
	then cp $(shell grep BR2_DEFCONFIG $(ROOT_BUILD)/.config | cut -d '=' -f2) $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	elif [ -f $(ROOT_BUILD)/defconfig ]; \
	then cp $(ROOT_BUILD)/defconfig $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	else cp $(ROOT_BUILD)/.config $(_BSP_CONFIG)/$(ROOT_CONFIG_FILE); fi

# For virtual boards
ifeq ($(_VIRT),1)

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
ROUTE := $(shell ifconfig br0 | grep 'inet ' | tr -d -c '^[0-9. ]' | awk '{print $$1}')
TMP   := $(shell bash -c 'echo $$(($$RANDOM%230+11))')
IP    := $(basename $(ROUTE)).$(TMP)

CMDLINE += route=$(ROUTE)

# Default iface
IFACE   ?= eth0
CMDLINE += iface=$(IFACE)

# New version of rpc.nfsd in nfs-kernel-server not support old nfs version 2, force using newer nfsver 3
ifneq ($(OS), trusty)
  NFSROOT_EXTRA ?= ,nolock,v3
endif

ifeq ($(ROOTDEV),/dev/nfs)
  ifneq ($(shell lsmod | grep -q ^nfsd; echo $$?),0)
    $(error ERR: 'nfsd' module not inserted, please follow the steps to start nfs service: 1. insert nfsd module in host: 'modprobe nfsd', 2. restart nfs service in docker: '/configs/tools/restart-net-servers.sh')
  endif
  # ref: linux-stable/Documentation/filesystems/nfs/nfsroot.txt
  # Must specify iface while multiple exist, which happens on ls2k board and triggers not supported dhcp
  IP_FULL  ?= $(IP):$(ROUTE):$(ROUTE):255.255.255.0:linux-lab:$(IFACE):off
  IP_SHORT ?= $(IP)::$(ROUTE):::$(IFACE):off
  CMDLINE += nfsroot=$(ROUTE):$(ROOTDIR)$(NFSROOT_EXTRA) rw ip=$(IP_SHORT)
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
ifneq ($(shell env | grep -q ^DISPLAY; echo $$?), 0)
  XTERM := null

  ifeq ($(G), 1)
    override G := 2
  endif
endif

# Sharing with the 9p virtio protocol
# ref: https://wiki.qemu.org/Documentation/9psetup
ifneq ($(SHARE),0)
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
ifeq ($(findstring force-,$(MAKECMDGOALS)),force-)
  ifeq ($(findstring -checkout,$(MAKECMDGOALS)),-checkout)
    FORCE_CHECKOUT ?= 1
  endif
endif
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
  ifeq ($(U),1)
    KERNEL_OPT ?= $(if $(UBOOT_BIOS),-bios,-kernel) $(QEMU_KIMAGE)
  else
    KERNEL_OPT ?= -kernel $(QEMU_KIMAGE)
  endif
endif

EMULATOR_OPTS ?= -M $(MACH) $(if $(CPU),-cpu $(CPU)) -m $(call _v,MEM,LINUX) $(NET) -smp $(call _v,SMP,LINUX) $(KERNEL_OPT) $(EXIT_ACTION)
EMULATOR_OPTS += $(SHARE_OPT)

D ?= 0
DEBUG ?= $(D)

# Launch Qemu, prefer our own instead of the prebuilt one
BOOT_CMD := sudo $(EMULATOR) $(EMULATOR_OPTS)

ifeq ($(U),1)
  ifeq ($(SD_BOOT),1)
    BOOT_CMD += -drive if=sd,file=$(SD_IMG),format=raw,id=sd0
  endif
  ifeq ($(RAM_BOOT),1)
    BOOT_CMD += -device loader,file=$(UKIMAGE),addr=$(KRN_ADDR)
    BOOT_CMD += -device loader,file=$(DTB),addr=$(DTB_ADDR)
    ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
      BOOT_CMD += -device loader,file=$(UROOTFS),addr=$(RDK_ADDR)
    endif
  endif
  ifeq ($(UBOOT_BIOS),1)
    ifneq ($(ENV_DEV), flash)
      BOOT_CMD += -device loader,file=$(ENV_IMG),addr=$(ENV_ADDR)
    endif
  endif

  ifneq ($(PFLASH_SIZE),0)
    # Load pflash for booting with uboot every time
    # pflash is at least used as the env storage
    # unit=1 means the second pflash, the first one is unit=0
    BOOT_CMD += -drive if=pflash,file=$(PFLASH_IMG),format=raw$(if $(UBOOT_BIOS),$(comma)unit=1)
  endif
else # U != 1
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
endif # U != 1

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
BOOT_CMD += $(XOPTS) $(XQOPT)

# Get DEBUG option if -debug found in goals
ifeq (debug,$(firstword $(MAKECMDGOALS)))
  DEBUG = $(app)
else
  ifeq ($(findstring debug,$(firstword $(MAKECMDGOALS))),debug)
    DEBUG = $(subst -,,$(subst debug,,$(firstword $(MAKECMDGOALS))))
  endif
endif

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

SYSTEM_TOOL_DIR := $(TOP_SRC)/system/tools

boot-init: FORCE
	$(Q)echo "Running $@"
	$(Q)$(if $(FEATURE),$(foreach f, $(shell echo $(FEATURE) | tr ',' ' '), \
		[ -x $(SYSTEM_TOOL_DIR)/$f/test_host_before.sh ] && \
		$(SYSTEM_TOOL_DIR)/$f/test_host_before.sh $(ROOTDIR);) echo '')

boot-finish: FORCE
	$(Q)echo "Running $@"
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

ifneq ($(U),1)
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

  # Ref: /labs/linux-lab/logging/arm64-virt-linux-v5.1/20190520-145101/boot.log
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
  TEST_AFTER  ?= ; echo $$? > $(TEST_RET); sudo kill -9 $$(cat $(TEST_LOG_PID)); [ $(TIMEOUT_CONTINUE) -eq 1 ] && echo 0 > $(TEST_RET); \
	ret=$$(cat $(TEST_RET)) && [ $$ret -ne 0 ] && echo "ERR: Boot timeout in $(TEST_TIMEOUT)." && echo "ERR: Log saved in $(TEST_LOG)." && exit $$ret; \
	if [ $(TIMEOUT_CONTINUE) -eq 1 ]; then echo "LOG: Test continue after timeout kill in $(TEST_TIMEOUT)."; else echo "LOG: Boot run successfully."; fi; \
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
	$(Q)echo "Running $@"
ifeq ($(BOOT_TEST), default)
	$(Q)$(TEST_BEFORE) make $(NPD) _boot $(makeclivar) U=$(TEST_UBOOT) XOPTS="$(TEST_XOPTS)" TEST=default ROOTDEV=$(TEST_RD) FEATURE=boot$(if $(FEATURE),$(shell echo ,$(FEATURE))) $(TEST_AFTER)
else
	$(Q)$(foreach r,$(shell seq 0 $(TEST_REBOOT)), \
		echo "\nRebooting test: $r\n" && \
		$(TEST_BEFORE) make $(NPD) _boot $(makeclivar) U=$(TEST_UBOOT) XOPTS="$(TEST_XOPTS)" TEST=default ROOTDEV=$(TEST_RD) FEATURE=boot$(if $(FEATURE),$(shell echo ,$(FEATURE))) $(TEST_AFTER);)
endif

raw-test: $(TEST_PREPARE) boot-init boot-test boot-finish FORCE

PHONY += raw-test boot-test

# Allow to disable feature-init

TEST_INIT ?= 1
TI ?= $(TEST_INIT)
FEATURE_INIT ?= $(TI)
FI ?= $(FEATURE_INIT)

kernel-init: kernel-config kernel-olddefconfig
	$(Q)$(call make_kernel,$(IMAGE))

rootdir-init: rootdir-clean rootdir root-install

module-init: modules modules-install

ifeq ($(findstring module,$(FEATURE)),module)
  MODULE_INIT := module-init
endif

ifneq ($(TEST_RD),/dev/nfs)
  ROOT_REBUILD := root-rebuild
endif

feature-init: $(if $(FEATURE),feature kernel-init rootdir-init $(MODULE_INIT) $(ROOT_REBUILD)) FORCE

PHONY += kernel-init rootdir-init module-init feature-init

ifeq ($(FI),1)
  override TEST_PREPARE += $(if $(FEATURE),feature-init)
endif

_test: $(TEST_PREPARE) boot-init boot-test boot-finish FORCE

PHONY += _test

# Boot dependencies

# Debug support
VMLINUX      ?= $(KERNEL_BUILD)/vmlinux

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

ifeq ($(GDBINIT_DIR)/kernel.user, $(wildcard $(GDBINIT_DIR)/kernel.user))
  GDB_INIT_KERNEL ?= kernel.user
else
  GDB_INIT_KERNEL ?= kernel.default
endif

ifeq ($(GDBINIT_DIR)/uboot.user, $(wildcard $(GDBINIT_DIR)/uboot.user))
  GDB_INIT_UBOOT  ?= uboot.user
else
  GDB_INIT_UBOOT  ?= uboot.default
endif

ifeq ($(DEBUG),uboot)
  GDB_CMD      ?= $(GDB) $(subst .bin,,$(BIMAGE))
  GDB_INIT     ?= $(GDBINIT_DIR)/$(GDB_INIT_UBOOT)
  DEBUG_DEPS   := force-uboot-build
else
  GDB_CMD      ?= $(GDB) $(VMLINUX)
  GDB_INIT     ?= $(GDBINIT_DIR)/$(GDB_INIT_KERNEL)
  DEBUG_DEPS   := force-kernel-build
endif

HOME_GDB_INIT ?= $(HOME)/.gdbinit
# Force run as ubuntu to avoid permission issue of .gdbinit and ~/.gdbinit
GDB_USER     ?= $(USER)

# Xterm: terminator
ifeq ($(XTERM), null)
  XTERM_STATUS := 1
else
  XTERM ?= $(shell tools/xterm.sh terminator)
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
  DEBUG_CMD  := $(Q)sleep 0.1 && echo "\nLOG: debug server started, please connect it with these commands:\n\n" \
                                      "    (host) $$ cd /path/to/cloud-lab\n" \
                                      "    (host) $$ tools/docker/bash linux-lab\n" \
                                      "    ubuntu@linux-lab:/labs/linux-lab$$ make $(MAKECMDGOALS)\n" \
                                      "\n\n" \
                                      "NOTE: To exit debug server, please press 'CTRL+a x'\n\n"
  #DEBUG_CMD  := $(Q)echo "\nLOG: Please run this in another terminal:\n\n    " $(GDB_CMD) "\n"
endif

# FIXME: gdb not continue the commands in .gdbinit while runing with 'CASE=debug tools/testing/run.sh'
#        just ignore the do_fork breakpoint to workaround it.
_debug:
	$(Q)ln -sf $(notdir $(GDBINIT_DIR))/$(notdir $(GDB_INIT)) .gdbinit
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

ifeq ($(shell pgrep flock >/dev/null; echo $$?), 1)
  DEBUG_CLIENT := $(DEBUG_DEPS) $(DEBUG_INIT) _debug
endif

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
ifeq ($(DEV_TYPE),dir)
_BOOT_DEPS += root-install
endif

ifneq ($(DEBUG),0)
  # Debug listen on a unqiue port, should run exclusively
  DEBUG_LOCK := $(GDBINIT_DIR)/.lock
  KEEP_UNIQUE := flock -n -x $(DEBUG_LOCK)
  RUN_BOOT_CMD := $(KEEP_UNIQUE) $(BOOT_CMD) || $(GDB_CMD)
else
  RUN_BOOT_CMD := $(BOOT_CMD)
endif

# just map reboot to boot for virtual board
reboot login: _boot

PHONY += reboot login

else

# For real boards

# FIXME: The real boot should be able to control the power button
#        Here it is only connect or login.

ifeq ($(shell [ -c $(BOARD_SERIAL) ] && sudo sh -c 'echo > $(BOARD_SERIAL)' 2>/dev/null; echo $$?),0)
  RUN_BOOT_CMD ?= $(Q)echo "LOG: Login via serial port" && sudo minicom -D $(BOARD_SERIAL) -b $(BOARD_BAUDRATE)
else
  RUN_BOOT_CMD ?= $(Q)echo "LOG: Login via ssh protocol" && $(SSH_CMD) -t '/bin/bash'
endif

ifeq ($(findstring boot,$(MAKECMDGOALS)),boot)
  _BOOT_DEPS := boot-config reboot
endif

_test _debug:
	$(Q)echo "LOG: This feature is not implemented for real boards."

login: packages-install _boot

PHONY += login

endif

_boot: $(_BOOT_DEPS)
	$(RUN_BOOT_CMD)

PHONY += boot-test _boot

# Show the variables
ifeq ($(filter env-dump,$(MAKECMDGOALS)),env-dump)
VARS := $(shell cat $(BOARD_MAKEFILE) | egrep -v "^ *\#|ifeq|ifneq|else|endif|include"| cut -d'?' -f1 | cut -d'=' -f1 | cut -d':' -f1 | cut -d'+' -f1 | tr -d ' ')
VARS += PBK PBR PBD PBQ PBU
VARS += BOARD FEATURE TFTPBOOT
VARS += ROOTDIR ROOT_SRC ROOT_BUILD ROOT_GIT
VARS += KERNEL_SRC KERNEL_BUILD KERNEL_GIT UBOOT_SRC UBOOT_BUILD UBOOT_GIT
VARS += ROOT_CONFIG_PATH KERNEL_CONFIG_PATH UBOOT_CONFIG_PATH
VARS += IP ROUTE BOOT_CMD
VARS += LINUX_DTB QEMU_PATH QEMU_SYSTEM
VARS += TEST_TIMEOUT TEST_RD
endif

_env: env-prepare
env-prepare: toolchain-install
ifeq ($(GCC_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(CCORI),CCORI=$(CCORI)) $(if $(GCC),GCC=$(GCC))
endif
ifeq ($(HOST_GCC_SWITCH),1)
	$(Q)make $(S) gcc-switch $(if $(HOST_CCORI),CCORI=$(HOST_CCORI)) $(if $(HOST_GCC),GCC=$(HOST_GCC)) b=i386/pc ROOTDEV=/dev/ram0
endif

env-list: env-dump
env-dump:
	@echo \#[ $(BOARD) ]:
	@echo -n " "
	-@echo $(foreach v,$(or $(VAR),$(VARS)),"    $(v)=\"$($(v))\"\n") | tr -s '/'

env-save: board-config

default-help:
	$(Q)cat README.md

PHONY += env env-list env-prepare env-dump env-save lab-help

# memory building support
BUILD_CACHE_TOOL   := tools/build/cache
BUILD_FREE_TOOL    := tools/build/free
BUILD_UNCACHE_TOOL := tools/build/uncache
BUILD_BACKUP_TOOL  := tools/build/backup

cache-build:
	@if [ $(shell grep -q /labs/linux-lab/build /proc/mounts >/dev/null 2>&1; echo $$?) -eq 0 ]; then \
		echo "Building cache free status:"; \
		sudo $(BUILD_FREE_TOOL) || true; \
	else \
		echo "Cache building ..."; echo; \
		sudo $(BUILD_CACHE_TOOL) || true; \
	fi

uncache-build:
	$(Q)echo "Uncache building ..."
	$(Q)echo
	$(Q)sudo $(BUILD_UNCACHE_TOOL) || true

backup-build:
	$(Q)echo "Backing up Cache ..."
	$(Q)echo
	$(Q)sudo $(BUILD_BACKUP_TOOL) || true

PHONY += cache-build uncache-build backup-build

# include .labfini if exist
$(eval $(call _ti,.labfini))

ifneq ($(APP_ARGS),)
# ...and turn them into do-nothing targets
$(eval $(APP_ARGS):FORCE;@:)
endif

ifneq ($(filter $(first_target),$(APP_TARGETS)),)
PREFIX_TARGETS := list
SILENT_TARGETS := list
define silent_flag
$(shell if [ "$(filter $(patsubst %-,,$(1)),$(SILENT_TARGETS))" = "$(1)" ]; then echo $$?; fi)
endef

define real_target
$(shell if [ "$(filter $(1),$(PREFIX_TARGETS))" = "$(1)" ]; then echo $(1)-$(2); else echo $(2)-$(1); fi)
endef

ifneq ($(BOARD_DOWNLOAD),)
$(APP_TARGETS): $(BOARD_DOWNLOAD)
	$(Q)make $(S) $(foreach a,$(app),$(call real_target,$(first_target),$(a)) )
else
$(APP_TARGETS): $(foreach a,$(app),$(call real_target,$(first_target),$(a)) )
endif

PHONY += $(APP_TARGETS)
endif

PHONY += $(APPS) $(patsubst %,_%,$(APPS))

# add alias for linux and buildroot targets
$(foreach t,$(call genaliastarget),$(eval $t:_$(call genaliassource,$t)))
PHONY += $(call genaliastarget)

$(addsuffix -%,$(call genaliastarget)): FORCE
	$(Q)make $(NPD) $(call genaliassource,$@)


# Allow cleanstamp and run a target
force-%:
	$(Q)make $(NPD) $(subst force-,,$@)-cleanstamp
	$(Q)make $(NPD) $(subst force-,,$@)

PHONY += FORCE

FORCE:

.PHONY: $(PHONY)
