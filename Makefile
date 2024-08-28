#
# Core Makefile
#
# Copyright (C) 2016-2024 Wu Zhangjin <falcon@ruma.tech>
#

TOP_DIR := $(CURDIR)

# Disable the implict rules for our Makefile
# ref: https://stackoverflow.com/questions/4122831/disable-make-builtin-rules-and-variables-from-inside-the-make-file
.SUFFIXES:
SUFFIXES :=
%: %,v
%: RCS/%,v
%: RCS/%
%: s.%
%: SCCS/s.%

# Force set default goal
.DEFAULT_GOAL := board

# Phony targets
PHONY :=
comma := ,
empty :=
space := $(empty) $(empty)

USER  := $(or $(UNIX_USER),ubuntu)
UID   := $(or $(UNIX_UID),1000)
WARN_ON_USER ?= 1

# Check running host
LAB_ENV_ID := /home/$(USER)/Desktop/lab.desktop
ifeq ($(wildcard $(LAB_ENV_ID)),)
  ifeq ($(wildcard ../../configs/linux-lab),)
    $(error ERR: No Cloud Lab found, please refer to 'Download the lab' part of README.md)
  else
    $(error ERR: Please not try Linux Lab in local host, but use it with Cloud Lab, please refer to 'Run and login the lab' part of README.md)
  endif
endif

# Warning if run as root
ifeq ($(WARN_ON_USER), 1)
  # Check running user, must as $(USER)
  ifeq ($(TEST_TIMEOUT),)
    ifneq ($(shell whoami),$(USER))
      $(warning WARN: Please not run as 'root', but as general user: '$(USER)', please try 'sudo -su $(USER)'.)
    endif
  endif

  # Check permission issue, must available to ubuntu
  FILE_USER_UID=$(shell stat -c '%U %u' /.git/description)
  ifeq ($(firstword $(FILE_USER_UID)),$(USER))
    WARN_ON_USER := 0
  else
    ifeq ($(word 2,$(FILE_USER_UID)),$(UID))
      WARN_ON_USER := 0
    endif
  endif

  ifneq ($(WARN_ON_USER),0)
    $(warning WARN: Lab should **NOT** belong to 'root', please change their owner in host: 'sudo chown $$USER:$$USER -R /path/to/cloud-lab/{*,.git}')
    $(warning WARN: Cancel this warning via: 'export WARN_ON_USER=0')
  endif
endif # Warning on user

# Detect system version of docker image
OS := $(shell sed -ne "/CODENAME/s/[^=]*=//gp" /etc/lsb-release)

# Current variables: board, plugin, module
define _uc_init
uc_$1 := $(shell echo $1 | tr a-z A-Z)
endef

define _uc
$(or $(uc_$1),$(eval $(call _uc_init,$1))$(uc_$1))
endef

define _lc_init
lc_$1 := $(shell echo $1 | tr A-Z a-z)
endef

define _lc
$(or $(lc_$1),$(eval $(call _lc_init,$1))$(lc_$1))
endef

define load_config
  ifneq ($(wildcard .$1_config),)
    $(call _uc,$1)_CONFIG := $(shell cat .$1_config 2>/dev/null)
  endif
endef

#$(warning $(call load_config,board))
$(foreach c,board plugin module mpath, $(eval $(call load_config,$c)))

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
BOARD_DEFAULT ?= arm/vexpress-a9
board ?= $(b)
B ?= $(board)
ifeq ($(B),)
  ifeq ($(BOARD_CONFIG),)
    BOARD := $(BOARD_DEFAULT)
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
HOME_DIR    := /home/$(USER)
GDBINIT_DIR := $(TOP_DIR)/.gdb
TOP_SRC     := $(TOP_DIR)/src
TOP_BUILD   := $(TOP_DIR)/build
TOP_LICENSE := $(TOP_DIR)/licenses
FEATURE_DIR := $(TOP_SRC)/feature/linux

# Search board in basic arch list while board name given without arch specified
ifneq ($(BOARD),)
 BASE_ARCHS := arm aarch64 mipsel mips64el ppc i386 x86_64 riscv32 riscv64 csky s390x s390 loongarch64 loongarch alpha parisc sparc
 ifeq ($(wildcard $(BOARD_DIR)/Makefile),)
  ARCH := $(strip $(firstword $(foreach arch,$(BASE_ARCHS),$(if $(wildcard $(TOP_DIR)/$(BOARDS_DIR)/$(arch)/$(BOARD)),$(arch) ))))
  ifneq ($(ARCH),)
    override BOARD     := $(ARCH)/$(BOARD)
    override BOARD_DIR := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD)
    #$(info LOG: Current board is $(BOARD))
  else
    _ARCH              := $(firstword $(subst /,$(space),$(BOARD)))
    ifneq ($(filter $(_ARCH),$(BASE_ARCHS)),)
      $(error ERR: do you mean the $(_ARCH) boards, please list with 'make list ARCH=$(_ARCH)')
    else
      MACH             := $(notdir $(BOARD))
      matched_boards   := $(strip $(foreach arch,$(BASE_ARCHS),$(if $(wildcard $(TOP_DIR)/$(BOARDS_DIR)/$(arch)/$(MACH)),$(arch)/$(MACH) )))
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
BOARD_PREFIX := $(subst /,,$(dir $(BOARD)))
PLUGIN_DIR   := $(TOP_DIR)/$(BOARDS_DIR)/$(BOARD_PREFIX)
PLUGIN_FLAG  := $(PLUGIN_DIR)/.plugin

ifeq ($(wildcard $(PLUGIN_FLAG)),)
  PLUGIN_DIR :=
else
  _PLUGIN    ?= 1
endif

# add board directories
BOARD_TOOLCHAIN ?= $(BOARD_DIR)/toolchains

# add a standlaone bsp directory
BSP_DIR         ?= $(BOARD_DIR)/bsp
BSP_TOOLCHAIN   ?= $(BSP_DIR)/toolchains
BSP_CONFIG      := $(BSP_DIR)/configs
BSP_PATCH       := $(BSP_DIR)/patch

# Get the machine name for qemu-system-$(XARCH)
MACH          ?= $(notdir $(BOARD))

# Prebuilt directories (in standalone prebuilt repo, github.com/tinyclub/prebuilt)
PREBUILT_DIR        := $(TOP_DIR)/prebuilt
PREBUILT_TOOLCHAINS := $(PREBUILT_DIR)/toolchains
PREBUILT_BIOS       := $(PREBUILT_DIR)/bios

# Core source: remote and local
#QEMU_GIT   ?= https://github.com/qemu/qemu.git
#QEMU_GIT   ?= https://gitee.com/mirrors/qemu.git
QEMU_GIT    ?= https://gitlab.com/qemu-project/qemu.git
_QEMU_GIT   := $(QEMU_GIT)
_QEMU_SRC   ?= $(if $(QEMU_FORK),$(call _lc,$(QEMU_FORK)-qemu),qemu)
QEMU_SRC    ?= $(_QEMU_SRC)

#UBOOT_GIT  ?= https://github.com/u-boot/u-boot.git
#UBOOT_GIT  ?= https://gitee.com/mirrors/u-boot.git
UBOOT_GIT   ?= https://gitlab.com/qemu-project/u-boot.git
_UBOOT_GIT  := $(UBOOT_GIT)
_UBOOT_SRC  ?= $(if $(UBOOT_FORK),$(call _lc,$(UBOOT_FORK)-uboot),u-boot)
UBOOT_SRC   ?= $(_UBOOT_SRC)

#KERNEL_GIT ?= https://github.com/tinyclub/linux-stable.git
# KERNEL_GIT ?= https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git
KERNEL_GIT ?= https://gitlab.com/linux-kernel/stable.git
#KERNEL_GIT ?= git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
_KERNEL_GIT := $(KERNEL_GIT)
_KERNEL_SRC ?= $(if $(KERNEL_FORK),$(call _lc,$(KERNEL_FORK)-kernel),linux-stable)
KERNEL_SRC  ?= $(_KERNEL_SRC)

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
#ROOT_GIT   ?= https://github.com/buildroot/buildroot
ROOT_GIT    ?= https://gitee.com/mirrors/buildroot.git
_ROOT_GIT   := $(ROOT_GIT)
_ROOT_SRC   ?= $(if $(ROOT_FORK),$(call _lc,$(ROOT_FORK)-buildroot),buildroot)
ROOT_SRC    ?= $(_ROOT_SRC)

BOARD_MAKEFILE := $(BOARD_DIR)/Makefile

# Common functions

define _stamp
$($(call _uc,$1)_BUILD)/.stamp_$1-$2
endef

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
$($1[$2_$($2)$(if $($3),$(comma)$3_$($3))])
endef

define __v
$(if $($3),$(or $(call ___v,$1,$2,$3),$(or $(call ___v,$1,$2),$(call ___v,$1,$3))),$(call ___v,$1,$2))
endef

define _v
$(or $(call __v,$1,$2),$(or $3,$($1)))
endef

define __vsp
 ifneq ($(call __v,$1,$2,$3),)
   $2_$1 := $(call __v,$1,$2,$3)
 endif
endef

define __vsp_override
 ifneq ($(call __v,$1,$2,$3),)
   override $2_$1 := $(call __v,$1,$2,$3)
 endif
endef

define __vs
 ifneq ($(call __v,$1,$2,$3),)
   $1 := $(call __v,$1,$2,$3)
 endif
endef

define __vs_override
 ifneq ($(call __v,$1,$2,$3),)
   override $1 := $(call __v,$1,$2,$3)
 endif
endef

define _vs
$1 := $(call _v,$1,$2)
endef

# Convert version string to version number, support 4 levels version string, like: v2.6.30.5, v4.4.297, we support: v1024.1023.1023.1023
define _v2v_init
vn_$(subst .,,$1) := $(shell echo $1 | tr -d -c '[0-9.]' | awk -F"." '{ printf("%d\n",$$1*1073741824 + $$2*1048576 + $$3*1024 + $$4);}')
endef

define _v2v
$(or $(vn_$(subst .,,$1)),$(eval $(call _v2v_init,$1))$(vn_$(subst .,,$1)))
endef

define _vsif
 ifeq ($(shell expr $(call _v2v,$($3)) \$4 $(call _v2v,$(5))),1)
   $1 := $2
 endif
endef

define _any
$(shell echo $($1) | grep -E -q "^v|^[0-9]" && [ $$(expr $(call _v2v,$($1)) \$2 $(call _v2v,$3)) -eq 1 ] && echo $($1))
endef

define _range
$(shell echo $($1) | grep -E -q "^v|^[0-9]" && [ $$(expr $(call _v2v,$($1)) \>= $(call _v2v,$2)) -eq 1 -a $$(expr $(call _v2v,$($1)) \<= $(call _v2v,$3)) -eq 1 ] && echo $($1))
endef

define _latest_init
latest_$1 := $(shell tmp=$$(mktemp) && wget -v $2 -O $$tmp && echo $$(grep -A1 "scrolling.*data-tab='tags'" $$tmp | tail -1 | sed -e "s/<[^>]*>//g") && rm $$tmp || echo $3)
endef

# name: $1, url: $2, default: $3
define _latest
$(if $(LATEST_TAG),$(or $(latest_$1),$(eval $(call _latest_init,$1,$2,$3))$(latest_$1)),$3)
endef

# $(BOARD_DIR)/Makefile.linux_$(LINUX)
define _f
$3/$2.$1
endef

define _vf
$(call _f,$(if $4,$(call _lc,$1)_$($1),$(call _lc,$1)),$2,$3)
endef

# include $3/$2.lowcase($1)_$1
define _i
  $1_$2 := $$(call _vf,$1,$2,$3,$4)
  ifneq ($$(wildcard $$($1_$2)),)
    include $$($1_$2)
  endif
endef

# include $(BOARD_DIR)/Makefile.linux_$(LINUX)
define _vi
$(call _i,$1,$2,$3,1)
endef

define _bvi
$(call _vi,$1,$2,$(BOARD_DIR))
endef

define _bi
$(call _i,$1,$2,$(BOARD_DIR))
endef

define _ti
$(call _i,$1,$2,$(TOP_DIR))
endef

define _hi
$(call _i,$1,$2,$(HOME_DIR))
endef

# Include board detailed configuration
define board_config
$(call _bi,GCC,Makefile)
$(call _bi,ROOT,Makefile)
$(call _bi,NET,Makefile)
$(call _bvi,LINUX,Makefile)
endef

# include $(TOP_DIR)/.labinit if exist
$(eval $(call _ti,labinit))

$(eval $(call _ti,labconfig))
$(eval $(call _hi,labconfig))

# Loading board configurations
ifneq ($(BOARD),)
  # include $(BOARD_DIR)/.labinit
  $(eval $(call _bi,labinit))
  $(eval $(call _bi,labconfig))
endif

QEMU_FORK_   := $(if $(QEMU_FORK),$(call _lc,$(QEMU_FORK))/,)
UBOOT_FORK_  := $(if $(UBOOT_FORK),$(call _lc,$(UBOOT_FORK))/,)
KERNEL_FORK_ := $(if $(KERNEL_FORK),$(call _lc,$(KERNEL_FORK))/,)
ROOT_FORK_   := $(if $(ROOT_FORK),$(call _lc,$(ROOT_FORK))/,)

_QEMU_FORK   := $(if $(QEMU_FORK),$(call _lc,/$(QEMU_FORK)),)
_UBOOT_FORK  := $(if $(UBOOT_FORK),$(call _lc,/$(UBOOT_FORK)),)
_KERNEL_FORK := $(if $(KERNEL_FORK),$(call _lc,/$(KERNEL_FORK)),)
_ROOT_FORK   := $(if $(ROOT_FORK),$(call _lc,/$(ROOT_FORK)),)

BSP_QEMU     ?= $(BSP_DIR)/qemu$(_QEMU_FORK)
BSP_UBOOT    ?= $(BSP_DIR)/uboot$(_UBOOT_FORK)
BSP_ROOT     ?= $(BSP_DIR)/root$(_ROOT_FORK)
BSP_KERNEL   ?= $(BSP_DIR)/kernel$(_KERNEL_FORK)
BSP_BIOS     ?= $(BSP_DIR)/bios

PREBUILT_QEMU   := $(PREBUILT_DIR)/qemu$(_QEMU_FORK)
PREBUILT_UBOOT  := $(PREBUILT_DIR)/uboot$(_UBOOT_FORK)
PREBUILT_ROOT   := $(PREBUILT_DIR)/root$(_ROOT_FORK)
PREBUILT_KERNEL := $(PREBUILT_DIR)/kernel$(_KERNEL_FORK)

BOARD_QEMU   ?= $(BOARD_DIR)/qemu$(_QEMU_FORK)
BOARD_UBOOT  ?= $(BOARD_DIR)/uboot$(_UBOOT_FORK)
BOARD_ROOT   ?= $(BOARD_DIR)/root$(_ROOT_FORK)
BOARD_KERNEL ?= $(BOARD_DIR)/kernel$(_KERNEL_FORK)

# CPU MMU
nommu ?= 0
NOMMU ?= $(nommu)

# Allow run Kernel as BIOS
LINUX_BIOS ?= 0
KERNEL_BIOS ?= $(LINUX_BIOS)

# Nolibc support
nolibc ?= $(noroot)
NOLIBC ?= $(nolibc)

ifneq ($(BOARD),)
  ifneq ($(wildcard $(BOARD_MAKEFILE)),)
    include $(BOARD_MAKEFILE)
  endif
  $(eval $(call _bi,labcustom))
  # include $(BOARD_DIR)/.labfini
  $(eval $(call _bi,labfini))
endif

# include $(TOP_DIR)/.labbegin if exist
$(eval $(call _ti,labbegin))
$(eval $(call _ti,labcustom))

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

ifeq ($(HOST_OS),Windows)
  CACHE_BUILD  ?= 1
endif

ifeq ($(ONESHOT),1)
  CACHE_BUILD  := 1
  CACHE_SRC    := 1
  FAST_FETCH   := 1
endif

ifeq ($(CACHE_BUILD),1)
  CACHE_BUILD_TARGET := cache-build
endif

ifeq ($(CACHE_BUILD)$(CACHE_SRC)$(FAST_FETCH),111)
  ifneq ($(LOCAL_FETCH),0)
    _TOP_SRC := $(TOP_SRC)
  endif
  TOP_SRC    := $(TOP_BUILD)/src
endif

# Don't touch the kernel code, let kernel developer do himself
ifeq ($(DEVMODE),1)
  SKIP_VERIFY ?= 1
  SKIP_CHECKOUT ?= 1
  SKIP_NOTICE ?= 1
endif
ifneq ($(vip),0)
  SKIP_NOTICE ?= 1
endif

# Allow boards to customize source and repos
BSP_ABS_SRC    := $(BSP_DIR)
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
  ifneq ($$(filter $$($(call _lc,$1)),1 new build),)
    PB$1 := 0
  endif
  ifneq ($$(filter $$($(call _lc,$1)),0 old pre prebuild prebuilt),)
    PB$1 := 1
  endif
endif

endef

define _lpb
__$1 := $(subst x,,$(firstword $(foreach i,K U D R Q,$(findstring x$i,x$(call _uc,$1)))))
ifneq ($$($1),)
  ifneq ($$(filter $$($1),1 new build),)
    PB$$(__$1) := 0
  endif
  ifneq ($$(filter $$($1),0 old pre prebuild prebuilt),)
    PB$$(__$1) := 1
  endif
endif
ifneq ($(BUILD),)
  ifneq ($$(filter $1,$(BUILD)),)
    PB$$(__$1) := 0
  endif
endif

endef # _lpb

define default_detectbuild
ifneq ($$($2),)
  override BUILD += $1
endif

endef

#$(warning $(foreach i,K R D Q U,$(call _pb,$i)))
$(eval $(foreach i,K R D Q U,$(call _pb,$i)))

#$(warning $(foreach i,kernel root dtb qemu uboot,$(call _lpb,$i)))
$(eval $(foreach i,kernel root dtb qemu uboot,$(call _lpb,$i)))

# Init 9pnet share variables
ifeq ($(origin SHARE_DIR),command line)
  SHARE := 1
else
  SHARE ?= 0
endif
SHARE_DIR       ?= hostshare
HOST_SHARE_DIR  ?= $(SHARE_DIR)
GUEST_SHARE_DIR ?= /hostshare
SHARE_TAG       ?= hostshare

# Supported apps and their version variable
APPS    := kernel uboot root qemu
APP_MAP ?= bsp:BSP kernel:LINUX uboot:UBOOT root:BUILDROOT qemu:QEMU

APP_TARGETS := source download checkout patch defconfig olddefconfig oldconfig menuconfig build cleanup cleansrc cleanall cleanstamp clean distclean saveall save saveconfig savepatch clone help list debug boot test test-debug upload env config

define gengoalslist
$(foreach i,$(or $2,$(APP_MAP)),$(if $($(lastword $(subst :,$(space),$i))),$(firstword $(subst :,$(space),$i))-$1))
endef

define genaliastarget
$(strip $(foreach i,$(APP_MAP),$(if $(subst $(call _lc,$(lastword $(subst :,$(space),$i))),,$(firstword $(subst :,$(space),$i))),$(call _lc,$(lastword $(subst :,$(space),$i))))))
endef

define genaliassource
$(or $(strip $(subst $1,,$(foreach i,$(APP_MAP),$(subst $(call _lc,$(lastword $(subst :,$(space),$i))),$(firstword $(subst :,$(space),$i)),$1)))),$1)
endef

# Support alias, root -> buildroot, kernel -> linux
ifneq ($(BUILD),)
  override BUILD := $(call genaliassource,$(subst $(comma),$(space),$(BUILD)))
endif

ifeq ($(BUILD),all)
  override BUILD :=
  $(foreach i,$(APP_MAP),$(eval $(call default_detectbuild,$(firstword $(subst :,$(space),$i)),$(lastword $(subst :,$(space),$i)))))
endif

first_target := $(firstword $(MAKECMDGOALS))
ifneq ($(findstring -defconfigx,$(first_target)x),)
 # use the rest as arguments for "defconfig"
 reserve_target := $(first_target:-defconfig=)
 APP_ARGS       := $(filter-out $(reserve_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
 ifneq ($(APP_ARGS),)
   CFG_PREFIX   := $(subst x,,$(firstword $(foreach i,K U R Q,$(findstring x$i,x$(call _uc,$(first_target))))))
   $(CFG_PREFIX)CFG := $(APP_ARGS)
 endif
endif

# add the same implementation of _stamp as __stamp for all !cleanstamp targets, used to let 'make cleanstamp kernel-build' work without rebuild
ifneq ($(first_target),cleanstamp)
define __stamp
$(call _stamp,$1,$2)
endef
endif

# common commands
ifneq ($(filter $(first_target),$(APPS)),)
 # The second targets passed after APPS, use them as the argument of the APPS.
 APP_ARGS := $(filter-out $(first_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
 x := $(subst src/$(_$(call _uc,$(first_target))_SRC)/,,$(APP_ARGS))
endif

ifneq ($(filter $(first_target),$(APP_TARGETS)),)
APP_ARGS := $(filter-out $(first_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))

define cli_detectapp
ifeq ($$(origin $2),command line)
  APP += $1
endif

endef

define default_detectapp
ifneq ($$($2),)
  override app += $1
endif

endef #default_detectapp

ifneq ($(APP_ARGS),)
  APP := $(firstword $(APP_ARGS))
else
  APP :=
  $(foreach i,$(APP_MAP),$(eval $(call cli_detectapp,$(firstword $(subst :,$(space),$i)),$(lastword $(subst :,$(space),$i)))))
endif

ifneq ($(APP),)
  app ?= $(APP)
  override app := $(call genaliassource,$(subst $(comma),$(space),$(app)))
endif

ifeq ($(app),all)
  override app :=
  $(foreach i,$(APP_MAP),$(eval $(call default_detectapp,$(firstword $(subst :,$(space),$i)),$(lastword $(subst :,$(space),$i)))))
  ifeq ($(first_target), upload)
    override app+= dtb modules
  endif
endif

ifeq ($(app),)
  ifneq ($(filter $(MAKECMDGOALS),list help config),)
    app := default
  else
    app := kernel
  endif
endif

endif # common commands

# Prepare build environment

SCRIPT_GETCCVER := tools/gcc/version.sh

define genbuildenv

GCC_$2   := $$(or $$(call __v,GCC,$2,$3),$(GCC))
CCORI_$2 := $$(or $$(call __v,CCORI,$2,$3),$(CCORI))

  ifneq ($$(CCORI_$2)$$(GCC_$2),)
    ifeq ($$(CCORI_$2)$$(CCORI),)
      CCORI_$2 := internal
      CCORI    := internal
    else
      $$(eval $$(call __vs,CCORI,$2,$3))
    endif
    ifneq ($$(GCC_$2),$$(shell $(SCRIPT_GETCCVER) $(CCPATH) $(CCPRE)))
      GCC_$2_SWITCH := 1
    endif
endif

ifeq ($$(filter $(XARCH),i386 x86_64),)
 HOST_GCC_$2   := $$(or $$(call __v,HOST_GCC,$2,$3),$(HOST_GCC))
 HOST_CCORI_$2 := $$(or $$(call __v,HOST_CCORI,$2,$3),$(HOST_CCORI))

  ifneq ($$(HOST_CCORI_$2)$$(HOST_GCC_$2),)
    ifeq ($$(HOST_CCORI_$2)$$(HOST_CCORI),)
      HOST_CCORI_$2 := internal
    endif

    # Use the default gcc directly for i386
    ifneq ($$(HOST_GCC_$2),$$(shell $(SCRIPT_GETCCVER)))
      HOST_GCC_$2_SWITCH := 1
    endif
  endif
endif
endef # genbuildenv

# Customize toolchains for different docker images
$(eval $(call __vs,CCORI,OS))
$(eval $(call __vs,GCC,OS))
$(eval $(call __vs,HOST_GCC,OS))

PREBUILT_TOOLCHAIN_MAKEFILE := $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile

# Local toolchain package means builtin toolchain too
ifneq ($(wildcard $(CCURL)),)
  CCORI := builtin
  CCORI_LIST += builtin
endif

ifneq ($(wildcard $(PREBUILT_TOOLCHAIN_MAKEFILE)),)
  include $(PREBUILT_TOOLCHAIN_MAKEFILE)
endif

ifneq ($(GCC),)
  # Force using internal CCORI if GCC specified and there is really an internal gcc
  ifeq ($(CCORI),)
    ifneq ($(shell which $(CCPRE)gcc),)
      CCORI := internal
    endif
  endif
endif

ifeq ($(filter $(XARCH),i386 x86_64),)
 ifneq ($(HOST_GCC),)
  # Force using internal CCORI if GCC specified
  ifeq ($(HOST_CCORI),)
    HOST_CCORI := internal
  endif
 endif
endif

# tuning notify method
notice := error
# stop error for force targets ??
ifneq ($(findstring xforce, x$(MAKECMDGOALS)),)
  notice := warning
endif
# warning instead of error for bsp downloading
ifneq ($(findstring xbsp, x$(MAKECMDGOALS)),)
  notice := warning
endif
# warning instead of error for BOARD switch
ifeq ($(MAKECMDGOALS),)
  notice := warning
endif
# warning instead of error for clone targets
ifneq ($(findstring clone, $(MAKECMDGOALS)),)
  notice := ignore
endif
ifneq ($(SKIP_NOTICE),)
  notice := ignore
endif

# generate verify function
define genverify
 ifneq ($$($2),)
  ifneq ($$(BSP_$1),)
   ifneq ($$(wildcard $$(BSP_$1)),)
    ifeq ($1,KERNEL)
      $2_LIST ?= $$(filter-out $$(shell cd $$(BSP_$1) && ls -d -p */* | sed -ne "/\/.*\//{s%/.*%%g;p}"),$$(shell cd $$(BSP_$1) && ls -d * 2>/dev/null | sort -V))
    else
      $2_LIST ?= $$(shell ls $$(BSP_$1) | sort -V)
    endif
   endif
  endif
  # If Linux version specific qemu list defined, use it
  $$(eval $$(call __vs_override,$2_LIST,$$(or $3,LINUX)))
  ifneq ($$($2_LIST),)
    ifeq ($$(filter $$($2), $$($2_LIST)),)
      $$(if $4,$$(eval $$(call $4)))
      verify_notice := $$(BOARD): $$($2) not in supported $2 list: $$($2_LIST),$(if $(KERNEL_FORK), KERNEL_FORK is set as $(KERNEL_FORK)$(comma))
      verify_notice += update may help: 'make bsp B=$$(BOARD)'
      ifneq ($$(filter $$(call _lc,$1),$(APPS)),)
        verify_notice += or clone one please: 'make $$(call _lc,$1)-clone $2_NEW=$$($2)'
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
 ifneq ($$($1_SRC),)
   ifneq ($$(_$1_SRC), $$($1_SRC))
    _$2 := $$(subst $$(shell basename $$($1_SRC))-,,$$($2))
    ifeq ($$(findstring $$(TOP_SRC),$$($1_SRC)),)
      $1_ABS_SRC := $$(TOP_SRC)/$$($1_SRC)
    else
      $1_ABS_SRC := $$($1_SRC)
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
f        ?= $(feature)
F        ?= $(f)
FEATURES ?= $(F)
FEATURE  ?= $(FEATURES)
ifneq ($(FEATURE),)
  FEATURE_ENVS := $(foreach i, $(subst $(comma),$(space),$(FEATURE)), \
    $(shell f_env=$(FEATURE_DIR)/$(i)/$(LINUX); \
    if [ -f $$f_env/env.$(XARCH).$(MACH) ]; then \
      echo $$f_env/env.$(XARCH).$(MACH); \
    elif [ -f $$f_env/env.$(MACH) ]; then \
      echo $$f_env/env.$(MACH); \
    fi))

  ifneq ($(wildcard $(FEATURE_ENVS)),)
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
$(eval $(call __vs,BIOS,LINUX))

_BIMAGE := $(BIMAGE)
_KIMAGE := $(KIMAGE)
_ROOTFS := $(ROOTFS)
_QTOOL  := $(QTOOL)

# Core build: for building in standalone directories
TOP_BUILD_MACH := $(TOP_BUILD)/$(XARCH)/$(MACH)
QEMU_BUILD     := $(TOP_BUILD_MACH)/$(QEMU_FORK_)qemu/$(QEMU)
UBOOT_BUILD    := $(TOP_BUILD_MACH)/$(UBOOT_FORK_)uboot/$(UBOOT)
KERNEL_BUILD   := $(TOP_BUILD_MACH)/$(KERNEL_FORK_)linux/$(LINUX)
ROOT_BUILD     := $(TOP_BUILD_MACH)/$(ROOT_FORK_)buildroot/$(BUILDROOT)
BSP_BUILD      := $(TOP_BUILD_MACH)/bsp

# Cross Compiler toolchains
ifneq ($(XARCH), i386)
  BUILDROOT_CCPRE  := $(XARCH)-linux-
else
  BUILDROOT_CCPRE  := i686-linux-
endif
BUILDROOT_CCPATH   := $(ROOT_BUILD)/host/usr/bin

# Add internal toolchain to list (the one installed in docker image)
ifneq ($(CCPRE),)
  ifneq ($(shell which $(CCPRE)gcc),)
    CCORI_INTERNAL := 1
  endif
  # Add builtin toolchain to list (the one builtin the bsp or plugin)
  ifeq ($(CCORI),)
    ifneq ($(CCPATH),)
      ifneq ($(wildcard $(CCPATH)/$(CCPRE)gcc),)
        CCORI_LIST += builtin
      endif
    endif
  endif
else
  ifneq ($(filter $(XARCH),i386 x86_64),)
    ifneq ($(shell which gcc),)
      CCORI_INTERNAL := 1
    endif
  endif
endif

ifeq ($(CCORI_INTERNAL), 1)
  ifeq ($(filter internal, $(CCORI_LIST)),)
    CCORI_LIST += internal
  endif
endif

# Add buidroot toolchain to list
ifneq ($(wildcard $(BUILDROOT_CCPATH)/$(BUILDROOT_CCPRE)gcc),)
  ifeq ($(filter buildroot, $(CCORI_LIST)),)
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
    ifneq ($(shell which $(CCPRE)gcc),)
      CCORI := internal
    endif
  else
    ifneq ($(filter $(XARCH),i386 x86_64),)
      ifneq ($(shell which gcc,)
        CCORI := internal
      endif
    endif
  endif

  # Check if buildroot version exists
  ifeq ($(CCPATH),)
    ifneq ($(wildcard $(BUILDROOT_CCPATH)/$(BUILDROOT_CCPRE)gcc),)
      CCORI  := buildroot
      CCPATH := $(BUILDROOT_CCPATH)
      CCPRE  := $(BUILDROOT_CCPRE)
    endif
  else
    ifneq ($(wildcard $(CCPATH)/$(CCPRE)gcc),)
      CCORI := builtin
    endif
  endif

else # CCORI != null

  # Check if internal toolchain is there
  ifeq ($(CCORI), internal)
    ifeq ($(shell which $(CCPRE)gcc),)
      $(error ERR: No internal toolchain found, please find one via: make toolchain-list)
    endif
  endif

  # Check if external toolchain downloaded
  ifeq ($(filter $(CCORI),buildroot internal),)
    ifneq ($(CCPRE),)
      ifneq ($(CCPATH),)
        ifeq ($(wildcard $(CCPATH)/$(CCPRE)gcc),)
          # If CCORI specified and it is not there, just download one
          ifeq ($(wildcard $(TOOLCHAIN)),)
            ifneq ($(notice),ignore)
              ifeq ($(notice),error)
                $(error ERR: No internal and external toolchain found, please refer to prebuilt/toolchains/ and prepare one)
              else
                $(warning WARN: No internal and external toolchain found, please refer to prebuilt/toolchains/ and prepare one)
              endif
            endif
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

ifneq ($(CCORI),)
 ifeq ($(filter $(CCORI), $(CCORI_LIST)),)
  $(error Supported gcc original list: $(CCORI_LIST))
 endif
endif

#$(warning $(call genbuildenv,kernel,LINUX,OS))
$(eval $(call genbuildenv,kernel,LINUX,OS))
$(eval $(call genbuildenv,uboot,UBOOT,OS))
$(eval $(call genbuildenv,qemu,QEMU,OS))
$(eval $(call genbuildenv,root,BUILDROOT,OS))

ifneq ($(LD_LIBRARY_PATH),)
  ifneq ($(LLPATH),)
    L_PATH := LD_LIBRARY_PATH=$(LLPATH):$(LD_LIBRARY_PATH)
  else
    L_PATH := LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)
  endif
else
  ifneq ($(LLPATH),)
    L_PATH := LD_LIBRARY_PATH=$(LLPATH)
  endif
endif

C_PATH    ?= env PATH=$(if $(CCPATH),$(CCPATH):)$(PATH)$(if $(RUST_PATH),:$(RUST_PATH)) $(L_PATH)

#$(info Using gcc: $(CCPATH)/$(CCPRE)gcc, $(CCORI))

TOOLCHAIN ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)

# Parallel Compiling threads
HOST_CPU_THREADS := $$(nproc)
JOBS             ?= $(HOST_CPU_THREADS)

# Emulator configurations
ifeq ($(KERNEL_BIOS),0)
ifneq ($(BIOS),)
  BIOS_ARG       := -bios $(BIOS)
endif
endif

# Another qemu-system-$(ARCH)
QEMU_SYSTEM      ?= $(QEMU_BUILD)/$(XARCH)-softmmu/qemu-system-$(XARCH)

ifneq ($(wildcard $(QEMU_SYSTEM)),)
  PBQ ?= 0
else
  PBQ := 1
endif

ifeq ($(PBQ), 1)
  ifneq ($(QTOOL),)
    ifneq ($(wildcard $(QTOOL)),)
      QEMU_SYSTEM := $(QTOOL)
    endif
  endif

  QTOOL_LINUX ?= $(call __v,QTOOL,LINUX)
  ifneq ($(QTOOL_LINUX),)
    ifneq ($(wildcard $(QTOOL_LINUX)),)
      QEMU_SYSTEM := $(QTOOL_LINUX)
    endif
  endif
endif

ifneq ($(QEMU),)
  ifneq ($(wildcard $(QEMU_SYSTEM)),)
    QEMU_PATH := env PATH=$(dir $(QEMU_SYSTEM)):$(PATH)
  endif
endif

EMULATOR       := $(QEMU_PATH) $(XENVS) qemu-system-$(XARCH) $(BIOS_ARG)

# Linux configurations
LINUX_PKIMAGE  := $(ROOT_BUILD)/images/$(PORIIMG)
LINUX_KIMAGE   := $(KERNEL_BUILD)/$(ORIIMG)
LINUX_UKIMAGE  := $(KERNEL_BUILD)/$(or $(UORIIMG),$(notdir $(UKIMAGE)))
LINUX_KRELEASE := $(KERNEL_BUILD)/include/config/kernel.release

ifneq ($(wildcard $(LINUX_KIMAGE)),)
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
  DTB_TARGET ?= $(patsubst %.dts,%.dtb,$(lastword $(subst /dts/,$(space),$(DTS))))
  LINUX_DTB  := $(KERNEL_BUILD)/$(ORIDTB)
  ifneq ($(wildcard $(LINUX_DTB)),)
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
ifeq ($(U),0)
  override UBOOT :=
endif

ifneq ($(UBOOT),)

ifeq ($(SHARE),1)
  ifeq ($(call _v,UBOOT,SHARE),disabled)
    # FIXME: Disable uboot by default, vexpress-a9 boot with uboot can not use this feature, so, disable it if SHARE=1 give
    #        versatilepb works with 9pnet + uboot?
    $(info LOG: 9pnet file sharing enabled with SHARE=1, disable uboot for it breaks sharing)
    UBOOT :=
  endif
endif

UBOOT_BIMAGE    := $(UBOOT_BUILD)/$(notdir $(BIMAGE))
PREBUILT_BIMAGE := $(PREBUILT_UBOOT_DIR)/$(notdir $(BIMAGE))

ifneq ($(wildcard $(UBOOT_BIMAGE)),)
  PBU ?= 0
else
  PBU := 1
endif

ifneq ($(wildcard $(UBOOT_BIMAGE)),)
  U ?= 1
else
  ifneq ($(wildcard $(PREBUILT_BIMAGE)),)
    U ?= 1
  else
    U := 0
  endif
endif

BIMAGE ?= $(UBOOT_BIMAGE)
ifeq ($(PBU),0)
  BIMAGE := $(UBOOT_BIMAGE)
endif

ifneq ($(MAKECMDGOALS),)
 ifneq ($(filter $(MAKECMDGOALS),boot test),)
  ifeq ($(U),1)
    app := uboot
  endif
  ifneq ($(U),0)
    ifneq ($(filter command line,$(foreach i,PBU u uboot,$(origin $i))),)
      app := uboot
    endif
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
  ifeq ($(findstring /dev/,$(ROOTDEV)),)
    override ROOTDEV := /dev/$(ROOTDEV)
  endif
endif

ROOTDEV ?= /dev/ram0
$(eval $(call _vs,ROOTDEV,LINUX))

# Verify rootdev argument
# use /dev/null to embeded initrd in kernel image
ifeq ($(findstring null,$(ROOTDEV_LIST)),)
  ROOTDEV_LIST += /dev/null
endif
#$(warning $(call genverify,ROOTDEV,ROOTDEV,,0))
$(eval $(call genverify,ROOTDEV,ROOTDEV,,0))

FSTYPE  ?= ext2

ROOTFS_UBOOT_SUFFIX    := .cpio.uboot
ROOTFS_HARDDISK_SUFFIX := .$(FSTYPE)
ROOTFS_INITRD_SUFFIX   := .cpio.gz

# Real one
BUILDROOT_ROOTDIR   :=  $(ROOT_BUILD)/target
# As a temp variable
_BUILDROOT_ROOTDIR  :=  $(ROOT_BUILD)/images/rootfs

BUILDROOT_UROOTFS   := $(_BUILDROOT_ROOTDIR)$(ROOTFS_UBOOT_SUFFIX)
BUILDROOT_HROOTFS   := $(_BUILDROOT_ROOTDIR)$(ROOTFS_HARDDISK_SUFFIX)
BUILDROOT_IROOTFS   := $(_BUILDROOT_ROOTDIR)$(ROOTFS_INITRD_SUFFIX)

PREBUILT_ROOT_DIR   ?= $(BSP_ROOT)/$(BUILDROOT)
PREBUILT_KERNEL_DIR ?= $(BSP_KERNEL)/$(LINUX)
PREBUILT_UBOOT_DIR  ?= $(BSP_UBOOT)/$(UBOOT)/$(LINUX)
PREBUILT_QEMU_DIR   ?= $(BSP_QEMU)/$(QEMU)

PREBUILT_IROOTFS    ?= $(PREBUILT_ROOT_DIR)/rootfs$(ROOTFS_INITRD_SUFFIX)

# Check default rootfs type: dir, hardisk (.img, .ext*, .vfat, .f2fs, .cramfs...), initrd (.cpio.gz, .cpio), uboot (.uboot)
ROOTFS_TYPE_TOOL    := tools/root/rootfs_type.sh
ROOTDEV_TYPE_TOOL   := tools/root/rootdev_type.sh

PBR ?= 0
_PBR := $(PBR)

ifneq ($(findstring nolibc,$(FEATURE)),)
  ifeq ($(findstring nolibcy,$(addsuffix y,$(TEST)$(PREPARE)$(TEST_PREPARE))),)
    export nolibc=1
    override TEST_PREPARE := $(TEST_PREPARE) root-rebuild
    # If no nolibc_src manual setting, use nolibc-test by default
    ifneq ($(origin nolibc_src),command line)
      export nolibc_src=test
    endif
  endif
endif

ifeq ($(NOLIBC),1)
# Allow build and embed minimal initramfs with nolibc from tools/include/nolibc to kernel image
NOLIBC_DIR          := $(KERNEL_ABS_SRC)/tools/include/nolibc
NOLIBC_H            := $(NOLIBC_DIR)/nolibc.h
# The 'init' source code for initramfs, customize it for your own project
nolibc-hello        ?= $(TOP_DIR)/src/examples/nolibc/hello.c
nolibc-test         ?= $(KERNEL_ABS_SRC)/tools/testing/selftests/nolibc/nolibc-test.c
nolibc_src          ?= $(nolibc-hello)
NOLIBC_BIN          := $(KERNEL_BUILD)/nolibc/init
NOLIBC_OBJ          := $(KERNEL_BUILD)/nolibc/init.o
NOLIBC_FLT          := $(KERNEL_BUILD)/nolibc/init.flt
NOLIBC_PGC          := $(KERNEL_BUILD)/nolibc/init.pgc
NOLIBC_SCALL        := $(KERNEL_BUILD)/nolibc/init.scall
NOLIBC_SYSROOT      := $(KERNEL_BUILD)/nolibc/sysroot
NOLIBC_SYSROOT_ARCH := $(NOLIBC_SYSROOT)/$(ARCH)
NOLIBC_INITRAMFS    := $(KERNEL_BUILD)/nolibc/initramfs
NOLIBC_FILES        := $(wildcard $(NOLIBC_DIR)/*.h)

ifeq ($(nolibc_src),test)
  override nolibc_src := $(nolibc-test)
endif
ifeq ($(nolibc_src),hello)
  override nolibc_src := $(nolibc-hello)
endif
NOLIBC_SRC          ?= $(nolibc_src)

ifneq ($(nolibc_test),)
  XKCLI += NOLIBC_TEST=$(nolibc_test)
endif

ifeq ($(NOMMU),1)
  _NOLIBC_BIN :=  $(NOLIBC_FLT)
else
  _NOLIBC_BIN :=  $(NOLIBC_BIN)
endif

ifeq ($(NOMMU),1)
  KCFGS += -d MMU -e BINFMT_FLAT
else
  KCFGS += -e MMU -d BINFMT_FLAT
endif

# Prefer nolibc initramfs
ifneq ($(wildcard $(NOLIBC_SRC)),)
  # Override ROOTFS and ROOTDEV setting to embed nolibc initramfs automatically, no extra rootfs required
  # Use initramfs generated from nolibc instead of the others
  override ROOTFS := $(NOLIBC_INITRAMFS)
  # Build initramfs into kernel image with CONFIG_INITRAMFS_SOURCE
  override ROOTDEV := /dev/null
endif

# Tag defconfig
KTAG := nolibc$(if $(KTAG),_$(KTAG))

# Set TEST_ROOTDEV
TEST_ROOTDEV ?= $(ROOTDEV)
endif

ifeq ($(_PBR), 0)
  ifeq ($(wildcard $(BUILDROOT_IROOTFS)),)
    ifneq ($(wildcard $(PREBUILT_IROOTFS)),)
      PBR := 1
    endif
    ifneq ($(wildcard $(ROOTFS)),)
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
  ifneq ($(wildcard $(BUILDROOT_IROOTFS)),)
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

ifeq ($(origin ROOTFS),command line)
  ifeq ($(wildcard $(ROOTFS)),)
    $(error rootfs: $(ROOTFS) not exists)
  endif
endif

# FIXME: workaround if the .cpio.gz or .ext2 are removed and only rootfs/ exists
ifneq ($(findstring not invalid or not exists,$(ROOTFS_TYPE)),)
  ROOTFS          := $(dir $(ROOTFS))
  ROOTFS_TYPE     := $(shell $(ROOTFS_TYPE_TOOL) $(ROOTFS))
endif

ifneq ($(findstring not invalid or not exists,$(ROOTFS_TYPE)),)
  INVALID_ROOTFS  := 1
  INVALID_ROOT    := 1
endif

ifneq ($(findstring not support yet,$(ROOTDEV_TYPE)),)
  INVALID_ROOTDEV := 1
  INVALID_ROOT    := 1
endif

ifneq ($(MAKECMDGOALS),)
 ifneq ($(filter $(MAKECMDGOALS),_boot root-dir-rebuild root-rd-rebuild root-hd-rebuild),)
  ifeq ($(INVALID_ROOTFS),1)
    $(error rootfs: $(ROOTFS_TYPE), try run 'make bsp' to get newer rootfs.)
  endif
  ifeq ($(INVALID_ROOTDEV),1)
    $(error rootdev: $(ROOTDEV_TYPE), try run 'make bsp' to get newer rootfs.)
  endif
 endif
endif

ifneq ($(INVALID_ROOT),1)
_ROOTFS_TYPE := $(subst $(comma),$(space),$(ROOTFS_TYPE))

FS_TYPE      := $(firstword $(_ROOTFS_TYPE))
FS_PATH      := $(word 2,$(_ROOTFS_TYPE))
FS_SUFFIX    := $(word 3,$(_ROOTFS_TYPE))

# Buildroot use its own ROOTDIR in /target, not in images/rootfs
ifneq ($(ROOTFS), $(BUILDROOT_IROOTFS))
  ifeq ($(PREBUILT_IROOTFS),$(ROOTFS))
    ifneq ($(findstring $(BSP_ROOT),$(PREBUILT_IROOTFS)),)
      BSP_ROOTDIR ?= $(subst $(BSP_ROOT),$(BSP_BUILD)/root,$(PREBUILT_ROOT_DIR))/rootfs
    else
      BSP_ROOTDIR ?= $(subst $(TOP_DIR),$(BSP_BUILD)/root,$(PREBUILT_ROOT_DIR))/rootfs
    endif
    # use one copy in the bsp build directory if exist
    ifneq ($(wildcard $(BSP_ROOTDIR)$(ROOTFS_INITRD_SUFFIX)),)
      ROOTFS    := $(BSP_ROOTDIR)$(ROOTFS_INITRD_SUFFIX)
    endif
  else
    BSP_ROOTDIR ?= $(BSP_BUILD)/$(subst $(TOP_DIR),root,$(PREBUILT_ROOT_DIR))/rootfs
  endif

  ifeq ($(FS_TYPE),dir)
    ROOTDIR := $(FS_PATH)
  else
    ROOTDIR := $(BSP_ROOTDIR)
  endif

  ifeq ($(FS_TYPE),rd)
    IROOTFS := $(ROOTFS)
  else
    ifeq ($(NOLIBC),1)
      IROOTFS := $(ROOTFS)
    else
      IROOTFS := $(ROOTDIR)$(ROOTFS_INITRD_SUFFIX)
    endif
  endif

  ifeq ($(FS_TYPE),hd)
    HROOTFS := $(ROOTFS)
  else
    HROOTFS := $(ROOTDIR)$(ROOTFS_HARDDISK_SUFFIX)
  endif

  UROOTFS   := $(ROOTDIR)$(ROOTFS_UBOOT_SUFFIX)
endif

_ROOTDEV_TYPE := $(subst $(comma),$(space),$(ROOTDEV_TYPE))
DEV_TYPE      := $(firstword $(_ROOTDEV_TYPE))
endif # INVALID ROOT

# Board targets

BOARD_TOOL := ${TOOL_DIR}/board/show.sh

export GREP_COLOR=32;40
# FILTER for board name
FILTER     ?= .*
# FILTER for board settings
VAR_FILTER ?= ^[ [\./_a-z0-9-]* \]|^ *[\_a-zA-Z0-9]* *

define getboardvars
cat $(BOARD_MAKEFILE) | grep -E -v "^ *\#|ifeq|ifneq|else|endif|include |call |eval |_BASE|_PLUGIN|override |export|PHONY|^$$|:$$|: " | grep -P -v "\t" | tr -d '?: ' | cut -d '=' -f1 | uniq
endef

define showboardvars
echo [ $(BOARD) ]:"\n" $(foreach v,$(or $(VAR),$(or $1,$(shell $(call getboardvars)))),"    $(v) = $($(v)) \n") | tr -s '/' | grep -E --colour=auto "$(VAR_FILTER)"
endef

BSP_CHECKOUT ?= bsp-checkout
ifeq ($(wildcard $(BSP_CONFIG)),)
  ifneq ($(app),default)
    BOARD_DOWNLOAD := $(BSP_CHECKOUT)
  endif
endif

ifneq ($(BOARD),)
  ifeq ($(board),)
    ifneq ($(BOARD),$(BOARD_CONFIG))
      BOARD_SAVE := board-save
      # Remove circular dep
      ifneq ($(MAKECMDGOALS),)
	ifneq ($(MAKECMDGOALS),board)
          BOARD_GOAL := board
        endif
      endif
    endif
  endif
endif

ifneq ($(first_target),list)
board: $(BOARD_SAVE) plugin-save board-show default-config $(BOARD_DOWNLOAD)
endif

CLEAN_STAMP := $(call gengoalslist,cleanstamp)
ifneq ($(BOARD),$(BOARD_CONFIG))
  BOARD_CLEAN_STAMP := $(CLEAN_STAMP)
endif

board-cleanstamp:
	$(Q)[ -n "$(BOARD_CLEAN_STAMP)" ] && make $(NPD) $(BOARD_CLEAN_STAMP) || true

board-show:
	$(Q)$(call showboardvars)

board-init:

board-clean: board-cleanstamp
	$(Q)rm -rvf .board_config

board-save .board_config:
	$(Q)echo "$(BOARD)" > .board_config

PHONY += board $(addprefix board-,init show save clean cleanstamp)

board-edit:
	$(Q)vim $(BOARD_MAKEFILE)

board-config: $(BOARD_GOAL)
	$(Q)$(foreach vs, $(MAKEOVERRIDES), tools/board/config.sh $(vs) $(BOARD_MAKEFILE) $(LINUX);)

BOARD_LABCONFIG := $(BOARD_DIR)/.labconfig

# Trace the changes of the frequently used config files automatically, the changes will trigger remake of some targets
# TODO: more config files should be added, but some of the files may have some issues, which changes all the time and breaks the remake logic
ENV_FILES := .board_config $(wildcard $(BOARD_LABCONFIG))
$(ENV_FILES):

edit: local-edit

ifeq ($(MAKECMDGOALS),config)
config: default-config
endif

local-edit:
	$(Q)touch $(BOARD_LABCONFIG)
	$(Q)vim $(BOARD_LABCONFIG)

default-config: local-config
local-config: $(BOARD_GOAL)
	$(Q)$(foreach vs, $(MAKEOVERRIDES), tools/board/config.sh $(vs) $(BOARD_LABCONFIG) $(LINUX);)

PHONY += config edit default-config $(addprefix board-,config edit) $(addprefix local-,config edit)

# Plugin targets

ifneq ($(filter command line, $(origin P) $(origin PLUGIN)),)
  ifeq ($(PLUGIN),)
    PLUGIN_CLEAN := plugin-clean
  endif
endif

plugin-save: $(PLUGIN_CLEAN)
ifneq ($(PLUGIN),)
  ifeq ($(plugin),)
	$(Q)echo "$(PLUGIN)" > .plugin_config
  endif
endif

plugin-clean:
	$(Q)rm -rvf .plugin_config

plugin: plugin-save
	$(Q)echo $(PLUGIN)

plugin-list:
	$(Q)find $(BOARDS_DIR) -maxdepth 3 -name ".plugin" | xargs -i dirname {} | xargs -i basename {} | cat -n

plugin-list-full:
	$(Q)find $(BOARDS_DIR) -maxdepth 3 -name ".plugin" | xargs -i dirname {} | cat -n

PHONY += plugin $(addprefix plugin-,save clean list list-full)

ifneq ($(findstring xlist,x$(first_target)),)
  # all: 0, plugin: 1, noplugin: 2
  LIST_GOAL := $(subst xlist,,x$(MAKECMDGOALS))
  LIST_GOAL := $(if $(LIST_GOAL),$(strip $(subst -,,$(LIST_GOAL))),default)

  ifneq ($(filter $(LIST_GOAL),default real virt base plugin full board short),)
    BOARD :=
    BTYPE ?= ^_BASE|^_PLUGIN
    VAR_FILTER ?= ^ *ARCH |^\[ [\./_a-z0-9-]* \]|^ *CPU|^ *LINUX|^ *ROOTDEV
    ifeq ($(LIST_GOAL),board)
      VAR_FILTER := ^\[ [\./_a-z0-9-]* \]|^ *ARCH
    endif
    ifeq ($(LIST_GOAL),short)
      VAR_FILTER := ^\[ [\./_a-z0-9-]* \]|^ *LINUX|^ *ARCH
    endif
    ifeq ($(LIST_GOAL),real)
      BTYPE := ^_BASE *[:]= 2|^_PLUGIN *[:]= 2
    endif
    ifeq ($(LIST_GOAL),virt)
      BTYPE := ^_BASE *[:]= 1|^_PLUGIN *[:]= 1
    endif
    ifeq ($(LIST_GOAL),base)
      BTYPE := ^_BASE
    endif
    ifeq ($(LIST_GOAL),plugin)
      BTYPE := ^_PLUGIN
    endif

    ifeq ($(origin ARCH),command line)
      ARCH_FILTER := $(ARCH)
    endif
  endif
endif
# List targets for boards and plugins
board-info:
	$(Q)find $(BOARDS_DIR)/$(BOARD)/$(or $(ARCH_FILTER),) -maxdepth 3 -name "Makefile" -exec grep -E -H "$(BTYPE)" {} \; \
		| tr -s '/' | grep -E "$(FILTER)" \
		| sort -t':' -k2 | cut -d':' -f1 | xargs -i $(BOARD_TOOL) {} $(PLUGIN) \
		| grep -E -v "/module" \
		| sed -e "s%boards/\(.*\)/Makefile%\1%g;s/[[:digit:]]\{2,\}\t/  /g;s/[[:digit:]]\{1,\}\t/ /g;s/^ \{1,\}/      /g" \
		| grep -E -v " *_BASE| *_PLUGIN| *#|^[[:space:]]*$$|^[[:space:]]*include |call |eval |ifeq|ifneq|else|endif|export|override |PHONY|: |[^]]:$$" \
		| grep -P -v "\t" \
		| grep -E --colour=auto "$(VAR_FILTER)"

BOARD_INFO_TARGETS := $(addprefix list-,default board short real virt base plugin full)

$(BOARD_INFO_TARGETS): board-info

PHONY += $(BOARD_INFO_TARGETS) board-info list

list-%: FORCE
	$(Q)list="$($(call _uc,$(subst list-,,$@))_LIST)"; \
	if [ -n "$$list" ]; then \
	  echo " $$list " | sed -e 's%\([ ]\{1,\}\)\($($(call _uc,$(subst list-,,$@)))\)\([ ]\{1,\}\)%\1[\2]\3%g;s%^ %%g;s% $$%%g'; \
	else \
	  make -s $(subst list-,,$@)-list 2>/dev/null || true; \
	fi

# Define generic license check support
define check_license
sudo tools/license $1 "$(BOARD)" "$(BOARD_FREE)" "$($(call _uc,$1)_ABS_SRC)" $(vip) $(TOP_LICENSE)/$(BOARD)/$1/.license
endef

# Define generic target deps support
define make_qemu
$(C_PATH) make $(NPD) -C $(QEMU_BUILD)/$2 -j$(JOBS) V=$(V) $1
endef

# Customize make-3.81 for old kernel <= v2.6.29
$(eval $(call __vs,MAKE,LINUX))

define make_kernel
$(C_PATH) $(MAKE) $(NPD) O=$(KERNEL_BUILD) -C $(KERNEL_ABS_SRC)/$2 $(if $(LLVM),LLVM=$(LLVM)) $(if $(CLANG),CC=clang) ARCH=$(ARCH) LOADADDR=$(KRN_ADDR) CROSS_COMPILE=$(CCPRE) V=$(V) $(KOPTS) -j$(JOBS) $1
endef

define make_root
make $(NPD) O=$(ROOT_BUILD) -C $(ROOT_ABS_SRC)/$2 V=$(V) -j$(JOBS) $1
endef

define make_uboot
$(C_PATH) make $(NPD) O=$(UBOOT_BUILD) -C $(UBOOT_ABS_SRC)/$2 ARCH=$(subst arm64,arm,$(ARCH)) CROSS_COMPILE=$(CCPRE) -j$(JOBS) $1
endef

# generate target dependencies
define gendeps

$1-patch: $1-checkout
$1-defconfig: $1-patch
$1-defconfig: $1-env
ifeq ($1,kernel)
$1-modules-install: $1-modules
$1-modules-install-km: $1-modules-km
endif
$1-help: $1-defconfig

$1_defconfig_childs := $(addprefix $1-,config getconfig saveconfig menuconfig oldconfig oldnoconfig olddefconfig build buildroot modules modules-km do)
ifeq ($(firstword $(MAKECMDGOALS)),$1)
  $1_defconfig_childs := $1
endif

$$($1_defconfig_childs): $1-defconfig

$1-saveall: $1-save $1-saveconfig

$1-save $1-saveconfig: $1-build

$1_APP_TYPE := $(subst x,,$(firstword $(foreach i,K U R Q,$(findstring x$i,x$(call _uc,$1)))))

ifeq ($$(PB$$($1_APP_TYPE)),0)
  ifeq ($$(origin PB$$($1_APP_TYPE)),command line)
    boot_deps += $1-build
  endif
endif

$1_app_type := $(subst x,,$(firstword $(foreach i,k u r q,$(findstring x$i,x$1))))

ifeq ($$($$($1_app_type)),1)
  ifeq ($$(origin $$($1_app_type)),command line)
    boot_deps += $1-build
  endif
endif

ifeq ($$($1),1)
  ifeq ($$(origin $1),command line)
    boot_deps += $1-build
  endif
endif

ifneq ($(filter $1,$(BUILD)),)
  boot_deps   += $1-build
endif

ifneq ($(filter $(BOARD),$(BOARD_FREE)),)

$1_bsp_childs := $(addprefix $1-,defconfig patch saveall save saveconfig clone)
$$($1_bsp_childs): $(BSP_CHECKOUT)

endif

_boot: $$(boot_deps)

$$(call _stamp,$1,build): $$(if $$($(call _uc,$1)_CONFIG_STATUS),,$$($(call _uc,$1)_BUILD)/$$(or $$($(call _uc,$1)_CONFIG_STATUS),.config))
	$$(Q)make $$(NPD) _$1
	$$(Q)touch $$@

ifneq ($$(findstring $1,$$(firstword $$(MAKECMDGOALS))),)
$1: $(if $(x),_$1,$1-build)
endif

# Force app building for current building targets can not auto detect code update
ifneq ($(filter $(first_target),$1 $1-build build),)
$1-build: _$1
else
$1-build: $$(call __stamp,$1,build)
endif

$1-release: $1 $1-save $1-saveconfig

$1-new $1-clone: $1-cloneconfig $1-clonepatch

PHONY += _$1 $(addprefix $1-,save saveall saveconfig savepatch build release new clone)

endef # gendeps

# generate xxx-source target
define gensource

$(call _uc,$1)_SRC_DEFAULT := 1

ifneq ($$(notdir $(patsubst %/,%,$$($(call _uc,$1)_SRC))),$$($(call _uc,$1)_SRC))
  ifneq ($$(findstring x$$(BSP_DIR),x$$($(call _uc,$1)_SRC)),)
    $(call _uc,$1)_SROOT := $$(BSP_DIR)
    $(call _uc,$1)_SPATH := $$(subst $$(BSP_DIR)/,,$$($(call _uc,$1)_SRC))
    $(call _uc,$1)_SRC_DEFAULT := 0
  else
    ifneq ($$(PLUGIN_DIR),)
      ifneq ($$(findstring x$$(PLUGIN_DIR),x$$(TOP_DIR)/$$($(call _uc,$1)_SRC)),)
        $(call _uc,$1)_SROOT := $$(PLUGIN_DIR)
        $(call _uc,$1)_SPATH := $$(subst $$(PLUGIN_DIR),,$$(TOP_DIR)/$$($(call _uc,$1)_SRC))
        $(call _uc,$1)_SRC_DEFAULT := 0
      endif
    endif
  endif
endif

ifeq ($$($(call _uc,$1)_SRC_DEFAULT),1)
  # Put submodule is root of linux-lab if no directory specified or if not the above cases
  ifneq ($1, bsp)
    $(call _uc,$1)_SROOT := $$(TOP_SRC)
    $(call _uc,$1)_SPATH := $$(subst $$(TOP_SRC)/,,$$($(call _uc,$1)_SRC))
  else
    $(call _uc,$1)_SROOT := $$(TOP_DIR)
    $(call _uc,$1)_SPATH := $$(subst $$(TOP_DIR)/,,$$($(call _uc,$1)_DIR))
  endif
endif

$(call _uc,$1)_GITADD := git remote -v
ifneq ($$(_$(call _uc,$1)_SRC), $$($(call _uc,$1)_SRC))
  ifeq ($$(_$(call _uc,$1)_GIT), $$($(call _uc,$1)_GIT))
    $(call _uc,$1)_GETGITURL := 1
  endif
else
  ifneq ($$(_$(call _uc,$1)_GIT), $$($(call _uc,$1)_GIT))
    $(call _uc,$1)_GITREPO := $1-$$(subst /,-,$$(BOARD))-$$(notdir $$(patsubst %/,%,$$($(call _uc,$1)_SPATH)))
    $(call _uc,$1)_GITADD  := git remote | grep -q $$($(call _uc,$1)_GITREPO) || git remote add $$($(call _uc,$1)_GITREPO) $$($(call _uc,$1)_GIT)
  endif
endif

ifeq ($$($(call _uc,$1)_GIT),)
  $(call _uc,$1)_GETGITURL := 1
endif

ifeq ($$($(call _uc,$1)_GETGITURL),1)
  __$(call _uc,$1)_GIT  := $$(shell [ -f $$($(call _uc,$1)_SROOT)/.gitmodules ] && sed -ne "/path = $$(subst /,\/,$$($(call _uc,$1)_SPATH))/{n;s/.*url[ ]*=[ ]*//g;p}" $$($(call _uc,$1)_SROOT)/.gitmodules)
  ifneq ($$(__$(call _uc,$1)_GIT),)
    _$(call _uc,$1)_GIT := $$(__$(call _uc,$1)_GIT)
    $(call _uc,$1)_GIT  := $$(__$(call _uc,$1)_GIT)
  endif
else
  _$(call _uc,$1)_GIT   := $$($(call _uc,$1)_GIT)
endif

# Build the full src directory
$(call _uc,$1)_SRC_FULL := $$($(call _uc,$1)_SROOT)/$$($(call _uc,$1)_SPATH)

$1-license: $(TOP_LICENSE)/$(BOARD)/$1/.license

$(TOP_LICENSE)/$(BOARD)/$1/.license:
	$$(Q)$(call check_license,$1)

# Get the target tag
$1_tag := $$(or $$(__$(call _uc,$2)),$$(_$(call _uc,$2)))

# Build _PKG_ABS_SRC for local fetch
ifneq ($(_TOP_SRC),)
  __$(call _uc,$1)_ABS_SRC  := $$(_TOP_SRC)/$$($(call _uc,$1)_SRC)/
  __$(call _uc,$1)_ABS_TAG  := $$(__$(call _uc,$1)_ABS_SRC)/.git/packed-refs
  ifneq ($$(wildcard $$(__$(call _uc,$1)_ABS_TAG)),)
    _$(call _uc,$1)_ABS_SRC := $$$$(cd $$(__$(call _uc,$1)_ABS_SRC); git cat-file -e $$($1_tag) 2>/dev/null && echo $$(__$(call _uc,$1)_ABS_SRC); cd $$($(call _uc,$1)_SRC_FULL))
  endif
endif

$$(call _stamp,$1,source): $$(call __stamp,$1,outdir) $1-license $$(ENV_FILES)
	$$(Q)if [ -e $$($(call _uc,$1)_SRC_FULL)/.git ]; then \
	  if [ -d $$($(call _uc,$1)_SRC_FULL) ]; then \
	    cd $$($(call _uc,$1)_SRC_FULL); \
	    git cat-file -e $$($1_tag) 2>/dev/null; \
	    if [ $$$$? -ne 0 ]; then \
	       echo "Updating $1 source ..."; \
	       REMOTE_REPO="$$(_$(call _uc,$1)_ABS_SRC)"; \
	       cd $$($(call _uc,$1)_SRC_FULL); \
	       if [ -z "$$$$REMOTE_REPO" ]; then \
		 REMOTE_REPO="$$($(call _uc,$1)_GITREPO)"; \
		 if [ -n "$$$$REMOTE_REPO" ]; then \
	           $$($(call _uc,$1)_GITADD); \
		 else \
	           REMOTE_REPO=$$$$(git remote -v | grep fetch | tr '\t' ' ' | cut -d' ' -f2); \
		 fi ; \
	       fi ; \
	       echo "From: $$$$REMOTE_REPO"; \
	       echo "To: $$$$PWD"; \
	       echo "Target: $$($1_tag)"; \
	       echo "Progress:"; \
	       git fetch --verbose --progress "$$(or $$$$REMOTE_REPO,origin)" \
	          $$(if $$(if $$(__$(call _uc,$2)),,$$(GIT_FETCH_SHALLOW)),--depth 1 tag $$($1_tag) && (git tag $$($1_tag) FETCH_HEAD || true),--tags); \
	       touch $$@; \
	    fi ; \
	  fi ; \
	else		\
	  echo "Downloading $1 source ..."; \
	  [ ! -d $$($(call _uc,$1)_SROOT) ] && mkdir -p $$($(call _uc,$1)_SROOT); \
	  cd $$($(call _uc,$1)_SROOT) \
	    && mkdir -p $$($(call _uc,$1)_SPATH) \
	    && cd $$($(call _uc,$1)_SPATH) \
	    && git init 		\
	    && REMOTE_REPO="$$(_$(call _uc,$1)_ABS_SRC)" \
	    && if [ -z "$$$$REMOTE_REPO" ]; then REMOTE_REPO="$$(_$(call _uc,$1)_GIT)"; fi \
	    && cd $$($(call _uc,$1)_SRC_FULL) \
	    && echo "From: $$$$REMOTE_REPO" \
	    && echo "To: $$$$PWD" \
	    && echo "Target: $$($1_tag)" \
	    && echo "Progress:" \
	    && git remote add origin "$$$$REMOTE_REPO" \
	    && git fetch --progress origin \
	       $$(if $$(if $$(__$(call _uc,$2)),,$$(GIT_FETCH_SHALLOW)),--depth 1 tag $$($1_tag) && (git tag $$($1_tag) FETCH_HEAD || true),--tags) \
	    && touch $$@; \
	fi

$1-source: $$(call __stamp,$1,source)

$1-checkout: $1-source

$$($(call _uc,$1)_SRC_FULL)/.git: $$(call __stamp,$1,source)

$$(call _stamp,$1,checkout): $$(ENV_FILES) $$($(call _uc,$1)_SRC_FULL)/.git
	$$(Q)if [ -z "$(SKIP_CHECKOUT)" ]; then \
	  [ -d $$($(call _uc,$1)_SRC_FULL) -a -e $$($(call _uc,$1)_SRC_FULL)/.git ] \
	  && cd $$($(call _uc,$1)_SRC_FULL) \
	  && git cat-file -e HEAD 2>/dev/null && git log -1 --oneline HEAD 2>/dev/null || true \
	  && echo "Checking out $$(if $$(__$(call _uc,$2)),FETCH_HEAD,$$(_$2)) ..." \
	  && git checkout --progress $$(GIT_CHECKOUT_FORCE) $$(if $$(__$(call _uc,$2)),FETCH_HEAD,$$(_$2)) \
	  && touch $$@ \
	  || (echo "ERR: Failed to checkout $$(_$2) of $1 in $$($(call _uc,$1)_SRC_FULL)" \
	     && echo "ERR: Please backup important changes on demand and run 'make $1-cleanup' or simply do a 'make $1-checkout -t'." \
	     && exit 1); \
	else \
	  touch $$@; \
	fi

$1-checkout: $$(call __stamp,$1,checkout)

$$(call _stamp,$1,outdir): $$(BUILD_CACHE_TAG)
	$$(Q)mkdir -p $$($(call _uc,$1)_BUILD)
	$$(Q)touch $$@

$1-outdir: $$(call __stamp,$1,outdir)

$1_source_childs := $1-download download-$1

$$($1_source_childs): $1-source

PHONY += $(addprefix $1-,license source checkout outdir download) download-$1

$1-%-cleanstamp:
	$$(Q)rm -vf $$(call _stamp,$1,$$(subst $1-,,$$(subst -cleanstamp,,$$@)))

$1-cleanstamp:
	$$(Q)rm -rvf $$(addprefix $$($(call _uc,$1)_BUILD)/.stamp_$1-,outdir source checkout patch env modules modules-km defconfig olddefconfig menuconfig build bsp license)

## clean up $1 source code
$1-cleansrc: $1-cleanup
$1-cleanup: $1-cleanstamp
	$$(Q)[ -d $$($(call _uc,$1)_SRC_FULL) -a -e $$($(call _uc,$1)_SRC_FULL)/.git ] \
	  && cd $$($(call _uc,$1)_SRC_FULL) \
	  && echo "Cleaning up $$($(call _uc,$1)_SRC) ..." \
	  && git reset --hard \
	  && git clean -fdx $$(GIT_CLEAN_EXTRAFLAGS[$1]) || true

$1-mrproper:
	$$(Q)[ "$1" = "kernel" -a "$1" = "u-boot" -a -d $$($(call _uc,$1)_SRC_FULL) -a -e $$($(call _uc,$1)_SRC_FULL)/.git ] \
	  && cd $$($(call _uc,$1)_SRC_FULL) \
	  && echo "Removing all generated files + config + various backup files in $$($(call _uc,$1)_SRC) ..." \
	  && make ARCH=$(ARCH) mrproper || true

$1-clean: $1-rawclean
$1-cleanall: $1-clean $1-cleansrc

$1-rawclean: $$($(call _uc,$1)_CLEAN_DEPS)
	$$(Q)[ -f $$($(call _uc,$1)_BUILD)/Makefile ] && $$(or $$(call make_$1,clean),true) || true

$1-distclean:
	$$(Q)if [ -f $$($(call _uc,$1)_BUILD)/Makefile ]; then \
	  $$(or $$(call make_$1,distclean),true); \
	  rm -rvf $$($(call _uc,$1)_BUILD); \
	fi

PHONY += $(addprefix $1-,cleanstamp cleanup cleansrc clean cleanall rawclean distclean mrproper)

endef # gensource

# Generate basic goals
define gengoals

$1-list:
	$$(Q)echo " $$($2_LIST) " | sed -e 's%\($$($2)\)\([ ]\{1,\}\)%[\1]\2%g;s%^ %%g;s% $$$$%%g'

$1-help:
	$$(Q)$$(or $$(call $1_make_help),$$(call make_$1,help))

$1_feature_patch_require := $$(subst $$(comma),_,$$(filter-out boot debug initrd module nfsroot,$$(subst $$(comma), ,$$(FEATURE))))
$1_feature_patched_goals := $$($(call _uc,$1)_SRC_FULL)/.$$(subst /,.,$(BOARD)).$1.$$($2).$$(if $$($1_feature_patch_require),$$($1_feature_patch_require).)feature.patched

$$($1_feature_patched_goals):
	$$(Q)$($(call _uc,$1)_PATCH_EXTRAACTION)
	$$(Q)touch $$@

$1_patched_goals := $$($(call _uc,$1)_SRC_FULL)/.$$(subst /,.,$(BOARD)).$1.$$($2).patched

$$($1_patched_goals):
	$$(Q)if [ -f tools/$1/patch.sh ]; then tools/$1/patch.sh $$(BOARD) $$($2) $$($(call _uc,$1)_SRC_FULL) $$($(call _uc,$1)_BUILD); fi
	$$(Q)touch $$@

$1-verify:
	$$(Q)if [ "$(SKIP_VERIFY)" != "1" -a -d $$($(call _uc,$1)_SRC_FULL) -a -e $$($(call _uc,$1)_SRC_FULL)/.git ]; then \
	  find $$($(call _uc,$1)_SRC_FULL) -maxdepth 1 -name "*.patched" | grep -E -qv "$$(subst /,.,$(BOARD)).$1.$$($2)|$1.patched"; \
	  if [ $$$$? -eq 0 ]; then \
	    echo "ERR: the other $1 patches applied? If so, backup changes and 'make $1-cleanup', otherwise, ignore via 'SKIP_VERIFY=1' or 'make $1-patch -t'."; \
	    exit 1; \
	  fi; \
	fi

$$(call _stamp,$1,patch): $1-verify $$($1_feature_patched_goals) $$($1_patched_goals) $$(ENV_FILES)
	$$(Q)touch $$@

$1-patch: $$(call __stamp,$1,patch)

$1-savepatch:
	$(Q)cd $$($(call _uc,$1)_SRC_FULL) && git format-patch $$(_$2)
	$(Q)mkdir -p $$(BSP_PATCH)/$(call _lc,$2)/$$($2)/
	$(Q)cp $$($(call _uc,$1)_SRC_FULL)/*.patch $$(BSP_PATCH)/$(call _lc,$2)/$$($2)/

debug-$1: $1-debug

ifeq ($(_VIRT),1)
$1-debug: _boot
else
$1-debug: _debug
endif

$1-boot: _boot

$1-test: _test

$1-test-debug:
	$$(Q)make _test DEBUG=$1

PHONY += $(addprefix $1-,list help verify patch savepatch debug boot test test-debug) debug-$1

endef # gengoals

# Allow force enable the default config
ifneq ($(findstring force-,$(MAKECMDGOALS)),)
  ifneq ($(findstring -defconfig,$(MAKECMDGOALS)),)
    FORCE_DEFCONFIG ?= 1
    export FORCE_DEFCONFIG
  endif
endif

define gencfgs

$(call _uc,$1)_CONFIG_FILE ?= $$($(call _uc,$1)_FORK_)$2_$$($(call _uc,$2))_defconfig
$(call _uc,$1)_CONFIG_FILE_NOCONFIG ?= $$($(call _uc,$1)_FORK_)$2.config
$3CFG ?= $$($(call _uc,$1)_CONFIG_FILE)
$3CFG_NOCONFIG ?= $$($(call _uc,$1)_CONFIG_FILE_NOCONFIG)

ifneq ($$($3TAG),)
$(call _uc,$1)_CONFIG_FILE_TAG ?= $$($(call _uc,$1)_FORK_)$2_$$($(call _uc,$2))_$$(if $$($3TAG),$$($3TAG)_)defconfig
$(call _uc,$1)_CONFIG_FILE_TAG_NOCONFIG ?= $$($(call _uc,$1)_FORK_)$2.$$(if $$($3TAG),$$($3TAG).)config
$3CFG_TAG ?= $$($(call _uc,$1)_CONFIG_FILE_TAG)
$3CFG_TAG_NOCONFIG ?= $$($(call _uc,$1)_CONFIG_FILE_TAG_NOCONFIG)

# Configs search order: TAGGED > Version Specific > TAGGED generic > Version generic
ifeq ($$($3CFG_TAG),$$($(call _uc,$1)_CONFIG_FILE_TAG))
  $3CFG_FILE   := $$(BSP_CONFIG)/$$($3CFG_TAG)
endif
else
# Configs search order: User Specified > Version generic
ifeq ($$($3CFG),$$($(call _uc,$1)_CONFIG_FILE))
  $3CFG_FILE   := $$(BSP_CONFIG)/$$($3CFG)
endif
endif

# $$(warning $3CFG_FILE: $$($3CFG_FILE))

ifneq ($$($(call _uc,$1)_CONFIG_DIR),)
 ifeq ($$(wildcard $$($3CFG_FILE)),)
  ifneq ($$($3TAG),)
    $3CFG_FILES := $$($3CFG_TAG) $$(addsuffix /$$($3CFG_TAG),$(BSP_CONFIG) $$($(call _uc,$1)_CONFIG_DIR) $$($(call _uc,$1)_SRC_FULL)/arch/$$(ARCH))
    $3CFG_FILES += $$($3CFG_TAG_NOCONFIG) $$(addsuffix /$$($3CFG_TAG_NOCONFIG),$(BSP_CONFIG) $$($(call _uc,$1)_CONFIG_DIR) $$($(call _uc,$1)_SRC_FULL)/arch/$$(ARCH))
  endif
  $3CFG_FILES += $$($3CFG) $$(addsuffix /$$($3CFG),$(BSP_CONFIG) $$($(call _uc,$1)_CONFIG_DIR) $$($(call _uc,$1)_SRC_FULL)/arch/$$(ARCH))
  $3CFG_FILES += $$($3CFG_NOCONFIG) $$(addsuffix /$$($3CFG_NOCONFIG),$(BSP_CONFIG) $$($(call _uc,$1)_CONFIG_DIR) $$($(call _uc,$1)_SRC_FULL)/arch/$$(ARCH))

  _$3CFG_FILE := $$(firstword $$(strip $$(foreach i,$$($3CFG_FILES),$$(wildcard $$i) )))
  ifneq ($$(_$3CFG_FILE),)
    $3CFG_FILE := $$(subst //,/,$$(_$3CFG_FILE))
  else
    ifneq ($$(wildcard $$(call __stamp,bsp,source)),)
      ifneq ($$($3CFG_FILE),)
        ifneq ($$(notice),ignore)
          ifeq ($$(notice),error)
            $$(error ERR: $$($3CFG_FILE): can not be found, please pass a valid $1 defconfig)
          else
            $$(warning WARN: $$($3CFG_FILE): can not be found, please pass a valid $1 defconfig)
          endif
        endif
      endif
    endif
  endif
 endif
endif

ifeq ($$($(call _uc,$1)_CONFIG_DIR),)
  # For qemu, which use command line configuration
  $3CFG_BUILTIN := 1
else
  ifneq ($$(findstring $$($(call _uc,$1)_CONFIG_DIR),$$($3CFG_FILE)),)
    $3CFG_BUILTIN := 1
  endif
endif

# different boards should not use the same name of defconfig, add $(XARCH)_$(MACH) as the prefix
_$3CFG_FILE := $$(notdir $$($3CFG_FILE))
_$3CFG_UNIQ := $(XARCH)_$(MACH)_$$(if $$(findstring $$($(call _uc,$2)),$$(_$3CFG_FILE)),,$$($(call _uc,$2))_)$$(_$3CFG_FILE)
_$3CFG_FULL := $$($(call _uc,$1)_CONFIG_DIR)/$$(_$3CFG_UNIQ)

# update variable XXX_CONFIG_FILE
$(call _uc,$1)_CONFIG_FILE := $$(_$3CFG_FILE)

ifneq ($$($3CFG_BUILTIN),)
$$($3CFG_FILE)): $$(call __stamp,$1,source)
endif

$(call _uc,$1)_NOCONFIG := $$$$([ "allnoconfig" = $$($(call _uc,$1)_OLDDEFCONFIG) ] && echo KCONFIG_ALLCONFIG=$$($(call _uc,$1)_BUILD)/.config)

$$(_$3CFG_FULL): $$(if $$($3CFG_BUILTIN),,$$($3CFG_FILE)) $$(ENV_FILES) $$(if $$(FORCE_DEFCONFIG),FORCE)
	$$(Q)$$(if $$($(call _uc,$1)_CONFIG_DIR),mkdir -p $$($(call _uc,$1)_CONFIG_DIR))
	$$(Q)$$(if $$($3CFG_BUILTIN),,cp $$($3CFG_FILE) $$@)

$$(call _stamp,$1,defconfig): $$(call __stamp,$1,outdir) $$(call _stamp,$1,env) $$(_$3CFG_FULL)
	$$(Q)make $(S) $1-mrproper
	$$(if $$(findstring _defconfig,$$(_$3CFG_FILE)),$$(or $$(call $1_make_defconfig),$$(call make_$1,$$(_$3CFG_UNIQ) $$($(call _uc,$1)_CONFIG_EXTRAFLAG))),$$(call make_$1,allnoconfig $$($(call _uc,$1)_CONFIG_EXTRAFLAG) KCONFIG_ALLCONFIG=$$(_$3CFG_FULL)))
	$$(Q)$$(if $$($3CFGS),$$(SCRIPTS_$3CONFIG) --file $$($(call _uc,$1)_BUILD)/.config $$($3CFGS))
	$$(if $$($3CFGS),$$($(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,$$(or $$($(call _uc,$1)_OLDDEFCONFIG),olddefconfig) $$($(call _uc,$1)_CONFIG_EXTRAFLAG) $$($(call _uc,$1)_NOCONFIG)))
	$$(Q)touch $$@

$(call _uc,$1)_CONFIG = $$(if $$($(call _uc,$1)_CONFIG_STATUS),,$$($(call _uc,$1)_BUILD)/$$(or $$($(call _uc,$1)_CONFIG_STATUS),.config))

$$($(call _uc,$1)_CONFIG): $$(call _stamp,$1,defconfig)

$1-defconfig: $$(call _stamp,$1,defconfig)

$1-oldefconfig: $1-olddefconfig
$1-olddefconfig: $$(call __stamp,$1,olddefconfig)

$$(call _stamp,$1,olddefconfig): $$($(call _uc,$1)_CONFIG)
	$$($(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,$$(or $$($(call _uc,$1)_OLDDEFCONFIG),olddefconfig) $$($(call _uc,$1)_CONFIG_EXTRAFLAG) $$($(call _uc,$1)_NOCONFIG))
	$$(Q)touch $$@

$1-oldconfig: $$(call __stamp,$1,oldconfig)

$$(call _stamp,$1,oldconfig): $$($(call _uc,$1)_CONFIG)
	$$($(call _uc,$1)_CONFIG_EXTRACMDS)$$(call make_$1,oldconfig $$($(call _uc,$1)_CONFIG_EXTRAFLAG))
	$$(Q)touch $$@

$1-menuconfig: $$($(call _uc,$1)_CONFIG)
	$$(call make_$1,menuconfig $$($(call _uc,$1)_CONFIG_EXTRAFLAG))

PHONY += $(addprefix $1-,defconfig olddefconfig oldefconfig oldconfig menuconfig)

endef # gencfgs

define genclone
ifneq ($$($(call _uc,$2)_NEW),)

ifneq ($$($(call _uc,$2)_NEW),$$($(call _uc,$2)))
NEW_$3CFG_FILE := $$(BSP_CONFIG)/$$($(call _uc,$1)_FORK_)$2_$$($(call _uc,$2)_NEW)_$$(if $$($3TAG),$$($3TAG)_)defconfig
NEW_PREBUILT_$(call _uc,$1)_DIR := $$(subst $$($(call _uc,$2)),$$($(call _uc,$2)_NEW),$$(PREBUILT_$(call _uc,$1)_DIR))

ifeq ($$(wildcard $$(NEW_PREBUILT_$(call _uc,$1)_DIR)),)

OLD_$(call _uc,$1)_PATCH_DIR := $$(BSP_PATCH)/$$($(call _uc,$1)_FORK_)$2/$$($(call _uc,$2))
NEW_$(call _uc,$1)_PATCH_DIR := $$(BSP_PATCH)/$$($(call _uc,$1)_FORK_)$2/$$($(call _uc,$2)_NEW)
NEW_$(call _uc,$1)_GCC := $$(if $$(call __v,GCC,$(call _uc,$2)),GCC[$(call _uc,$2)_$$($(call _uc,$2)_NEW)] = $$(call __v,GCC,$(call _uc,$2)))

$1-cloneconfig:
	$$(Q)[ -f "$$($3CFG_FILE)" ] && cp $$($3CFG_FILE) $$(NEW_$3CFG_FILE) || true
	$$(Q)tools/board/config.sh $(call _uc,$2)=$$($(call _uc,$2)_NEW) $$(BOARD_LABCONFIG)
	$$(Q)grep -q "GCC\[$(call _uc,$2)_$$($(call _uc,$2)_NEW)" $$(BOARD_LABCONFIG) \
	       || ([ -n "$$(NEW_$(call _uc,$1)_GCC)" ] && sed -i -e "/GCC\[$(call _uc,$2)_$$($(call _uc,$2))/a $$(NEW_$(call _uc,$1)_GCC)" $$(BOARD_LABCONFIG) || true)
	$$(Q)mkdir -p $$(NEW_PREBUILT_$(call _uc,$1)_DIR)

$1-clonepatch:
	$$(Q)mkdir -p $$(NEW_$(call _uc,$1)_PATCH_DIR)
	$$(Q)[ "$(PATCH_CLONE)" != "0" -a -d $$(OLD_$(call _uc,$1)_PATCH_DIR) ] && find $$(OLD_$(call _uc,$1)_PATCH_DIR)/ -name "*.patch" -exec cp -rf {} $$(NEW_$(call _uc,$1)_PATCH_DIR) \; || true

else
$1-cloneconfig:
	$$(Q)echo $$($(call _uc,$2)_NEW) already exists!
	$$(Q)tools/board/config.sh $(call _uc,$2)=$$($(call _uc,$2)_NEW) $$(BOARD_LABCONFIG)
	$$(Q)grep -q "GCC\[$(call _uc,$2)_$$($(call _uc,$2)_NEW)" $$(BOARD_LABCONFIG) \
	       || ([ -n "$$(NEW_$(call _uc,$1)_GCC)" ] && sed -i -e "/GCC\[$(call _uc,$2)_$$($(call _uc,$2))/a $$(NEW_$(call _uc,$1)_GCC)" $$(BOARD_LABCONFIG) || true)

$1-clonepatch:
endif

else  # X_NEW = X

$1-cloneconfig $1-clonepatch:
	$(Q)l=$$$$(grep -r $$($(call _uc,$2)) $$(BOARD_LABCONFIG)) && echo "Please remove $$$$l from $$(BOARD_LABCONFIG)"
	$(Q)echo "ERR: Not able to clone from $$($(call _uc,$2)) to $$($(call _uc,$2)_NEW)" && false

endif # X_NEW = X

else
$1-cloneconfig $1-clonepatch:

  ifneq ($$(findstring clone,$$(MAKECMDGOALS)),)
    ifneq ($$(findstring $1,$$(MAKECMDGOALS)),)
      $$(error Usage: make $$(MAKECMDGOALS) [$(call _uc,$2)=<old-$2-version>] $(call _uc,$2)_NEW=<new-$2-version>)
    endif
    ifneq ($$(findstring $2,$$(MAKECMDGOALS)),)
      $$(error Usage: make $$(MAKECMDGOALS) [$(call _uc,$2)=<old-$2-version>] $(call _uc,$2)_NEW=<new-$2-version>)
    endif
  endif
endif


PHONY += $(addprefix $1-,cloneconfig clonepatch)

endef #genclone

define genenvdeps

# This allows to install extra tools has not been installed
$$(eval $$(call __vsp,PKGS,$2))

$1-tools: $$(if $$($2_PKGS),FORCE)
	$$(Q)[ -n "$$($2_PKGS)" ] && tools/deps/install.sh '$$($2_PKGS)' || true

$1-deps: $1-tools _env

$1-gcc:
	$(Q)[ "$$(GCC_$2_SWITCH)" = "1" ] && make $$(S) gcc-switch $$(if $$(CCORI_$2),CCORI=$$(CCORI_$2)) $$(if $$(GCC_$2),GCC=$$(GCC_$2)) \
	     $$(if $(LDT)$(LDT[GCC_$(GCC_$2)]),LDT="$(or $(LDT[GCC_$(GCC_$2)]),$(LDT))") || true

$1-hostgcc:
	$$(Q)if [ -z "$(filter $(XARCH),x86_64 i386)" ]; then \
	  [ "$$(HOST_GCC_$2_SWITCH)" = "1" ] && \
	  make $$(S) gcc-switch $$(if $$(HOST_CCORI_$2),CCORI=$$(HOST_CCORI_$2)) $$(if $$(HOST_GCC_$2),GCC=$$(HOST_GCC_$2)) b=i386/pc ROOTDEV=/dev/ram0 || true; \
	fi

$$(call _stamp,$1,env):
	$$(Q)make $(S) $1-deps $1-gcc $1-hostgcc
	$$(Q)touch $$@

$1-env: $$(call __stamp,$1,env)

PHONY += $(addprefix $1-,tools deps gcc hostgcc env)

endef #genenvdeps

# Build bsp targets
# Always checkout the latest commit for bsp

ifneq ($(_PLUGIN),)
  BSP_SRC  := $(subst x$(TOP_DIR)/,,x$(PLUGIN_DIR))
else
  BSP_SRC  := $(subst x$(TOP_DIR)/,,x$(BSP_DIR))
endif

ifeq ($(wildcard $(BSP_SRC)/.git),)
  # First init
  BSP ?= FETCH_HEAD
else
  ifeq ($(wildcard $(BSP_CONFIG)),)
    # Already fetched
    BSP_MASTER := $(BSP_SRC)/.git/refs/remotes/origin/master
    BSP_HEAD := $(if $(wildcard $(BSP_SRC)/.git/HEAD),HEAD,FETCH_HEAD)
    BSP ?= $(if $(wildcard $(BSP_MASTER)),origin/master,$(BSP_HEAD))
  else
    BSP ?= origin/master
  endif
endif
_BSP ?= $(BSP)

# NOTE: No tag or version defined for bsp repo currently, -source target need fetch latest all the time
# Skip update of bsp repo for !vip user
vip ?= 0
ifneq ($(vip),0)
  __BSP := latest
endif
# Always update the free boards
ifneq ($(filter $(BOARD),$(BOARD_FREE)),)
  __BSP := latest
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
$(eval $(call gensource,bsp,BSP,B))
$(eval $(call genenvdeps,bsp,BSP,B))

# Enable targets required
general_targets ?= 1

ifneq ($(general_targets),)
 ifneq ($(filter $(general_targets),0 1),)
  kernel_targets ?= $(general_targets)
  module_targets ?= $(general_targets)
  root_targets   ?= $(general_targets)
  toolchain_targets ?= $(general_targets)
  ifneq ($(UBOOT),)
    ifneq ($(U),0)
      uboot_targets ?= $(general_targets)
    endif
  endif
  qemu_targets ?= $(general_targets)
 endif
endif

# Qemu targets
ifneq ($(findstring qemu,$(MAKECMDGOALS)),)
  qemu_targets ?= 1
endif

ifeq ($(qemu_targets),1)
# Notes:
#
# 1. --enable-curses is required for G=2, boot with LCD/keyboard from ssh login
#    deps: sudo apt install -y libncursesw5-dev
# 2. --enable-sdl is required for G=1, but from v4.0.0, it requires libsdl2-dev,
# 3. --disable-vnc disable vnc graphic support, this is not that friendly because
#    it requires to install a vnc viewer, such as vinagre.
#    TODO: start vnc viewer automatically while qemu boots and listen on vnc port.
# 4. --disable-kvm is used to let qemu boot in docker environment which not have kvm.
# 5. --enable-virtfs adds 9pnet sharing support, depends on libattr1-dev libcap-dev
# 6. --disable-docs is used to not build the docs
#


ifneq ($(findstring qemu,$(MAKECMDGOALS)),)
 ifeq ($(QEMU),)
  $(error ERR: No qemu version specified, please configure QEMU= in $(BOARD_MAKEFILE) or pass it manually)
 endif
endif

ifneq ($(QEMU),)
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
  QEMU_BUILD        := $(TOP_BUILD)/qemu-$(QEMU)-all
  QEMU_ARCH         := $(ARCH_LIST)
else
  QEMU_ARCH         := $(XARCH)
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
    QEMU_SDL    ?= 1
    QEMU_CURSES ?= 1
    QEMU_DOCS   ?= 0
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
      QEMU_CONF   += --enable-virtfs
    endif

    ifeq ($(QEMU_CURSES),1)
      QEMU_CONF   += --enable-curses
    endif

    ifneq ($(QEMU_DOCS),)
      ifeq ($(QEMU_DOCS),1)
        QEMU_CONF   += --enable-docs
      else
        QEMU_CONF   += --disable-docs
      endif
    endif
  endif

  QEMU_TARGET ?= $(subst $(space),$(comma),$(addsuffix -softmmu,$(QEMU_ARCH)))
  QEMU_CONF   += --target-list=$(QEMU_TARGET)
endif

QEMU_CONFIG_STATUS  := config.log
QEMU_PREFIX         ?= $(PREBUILT_QEMU_DIR)
QEMU_CONF_CMD       := $(QEMU_ABS_SRC)/configure $(QEMU_CONF) --disable-werror --prefix=$(QEMU_PREFIX)
qemu_make_help      := cd $(QEMU_BUILD) && $(QEMU_CONF_CMD) --help
qemu_make_defconfig := $(Q)cd $(QEMU_BUILD) && $(QEMU_CONF_CMD)

_QEMU  ?= $(call _v,QEMU,QEMU)

#$(warning $(call gensource,qemu,QEMU))
$(eval $(call gensource,qemu,QEMU))
# Add basic qemu dependencies
#$(warning $(call gendeps,qemu))
$(eval $(call gendeps,qemu))
#$(warning $(call gengoals,qemu,QEMU))
$(eval $(call gengoals,qemu,QEMU))
#$(warning $(call gencfgs,qemu,QEMU,Q))
$(eval $(call gencfgs,qemu,QEMU,Q))
#$(warning $(call genenvdeps,qemu,QEMU,Q))
$(eval $(call genenvdeps,qemu,QEMU,Q))
#$(warning $(call genclone,qemu,qemu,Q))
$(eval $(call genclone,qemu,qemu,Q))

QT ?= $(x)

QEMU_UPDATE_GITMODULES := tools/qemu/update-submodules.sh

_qemu_update_submodules:
	[ -f $(QEMU_ABS_SRC)/.gitmodules ] && $(QEMU_UPDATE_GITMODULES) $(QEMU_ABS_SRC)/.gitmodules || true

_qemu: _qemu_update_submodules
	$(call make_qemu,$(QT))
	$(Q)if [ ! -L  $(QEMU_BUILD)/../etc/qemu-ifup ]; then \
	  mkdir -p $(QEMU_BUILD)/../etc/; \
	  ln -sf /etc/qemu-ifup $(QEMU_BUILD)/../etc/qemu-ifup; \
	  ln -sf /etc/qemu-ifdown $(QEMU_BUILD)/../etc/qemu-ifdown; \
	fi
	$(Q)if [ ! -L  $(QEMU_BUILD)/qemu-bundle$(PREBUILT_QEMU_DIR)/etc/qemu-ifup ]; then \
	  mkdir -p $(QEMU_BUILD)/qemu-bundle$(PREBUILT_QEMU_DIR)/etc/; \
	  ln -sf /etc/qemu-ifup $(QEMU_BUILD)/qemu-bundle$(PREBUILT_QEMU_DIR)/etc/qemu-ifup; \
	  ln -sf /etc/qemu-ifdown $(QEMU_BUILD)/qemu-bundle$(PREBUILT_QEMU_DIR)/etc/qemu-ifdown; \
	fi

PHONY += _qemu _qemu_update_submodules

endif # Qemu targets

# Toolchains targets

toolchain_targets ?= $(strip $(foreach t,gcc toolchain env,$(if $(findstring $t,$(MAKECMDGOALS)),1)))

ifeq ($(toolchain_targets),1)

toolchain-source: toolchain
toolchain-download: toolchain
gcc: toolchain

PHONY += toolchain-source toolchain-download toolchain gcc

include $(PREBUILT_TOOLCHAINS)/Makefile

ifeq ($(CCORI),internal)
  # Get the real version of the file name: which gcc-$(CCVER)
  CCVER  := $$($(SCRIPT_GETCCVER) $(CCPATH) $(CCPRE))
  LDTVER := $$($(CCPRE)ld -v | tr -d -c '[0-9.]')
endif

ifeq ($(CCORI),internal)
  TOOLCHAIN_INSTALL := toolchain-install-internal
  TOOLCHAIN_CLEAN   := toolchain-clean-internal
  TOOLCHAIN_SWITCH  := toolchain-switch-internal
else
  TOOLCHAIN_INSTALL := toolchain-install-external
  TOOLCHAIN_CLEAN   := toolchain-clean-external
endif

gcc-install: toolchain-install
toolchain-install: $(TOOLCHAIN_INSTALL)

toolchain-install-internal:
	$(Q)if ! which $(CCPRE)gcc-$(GCC) >/dev/null; then \
	  gcc_pkg=$(subst -xyz,,gcc-$(GCC)-$(CCPRE)xyz); \
	  echo "Installing internal toolchain: $$gcc_pkg ...";  \
	  [ "$(XARCH)" = "i386" -o "$(XARCH)" = "x86_64" ] && sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test; \
	  sudo apt-get -y update \
	  && sudo apt install -y $$gcc_pkg \
	  && sudo update-alternatives --install /usr/bin/$(CCPRE)gcc $(CCPRE)gcc /usr/bin/$(CCPRE)gcc-$(GCC) $$((50+RANDOM%50)); \
	fi

toolchain-install-external:
	$(Q)if [ -z "$(CCPATH)" -o ! -d "$(CCPATH)" ]; then \
	  echo "Downloading or decompressing prebuilt toolchain from $(CCURL) ..."; \
	  cd $(TOOLCHAIN) && \
	  if [ "$(CCORI)" != "builtin" ]; then wget -c $(CCURL); fi && \
	  tar $(TAR_OPTS) $(CCTAR) -C $(TOOLCHAIN); \
	fi

PHONY += gcc-install toolchain-install toolchain-install-internal toolchain-install-external

toolchain: toolchain-install gcc-info

toolchain-list:
	@echo
	@echo "Listing prebuilt toolchain ..."
	@echo
	$(Q)$(foreach ccori, $(CCORI_LIST), make $(S) gcc-info CCORI=$(ccori);)

gcc-list: toolchain-list

PHONY += toolchain-list gcc-list toolchain

toolchain-info:
	@echo
	@echo [ $(CCORI) $(CCVER) ]:
	@echo
	@echo Remote.: $(CCURL)
	@echo Local..: $(CCPATH)
	@echo Tool...: $(CCPRE)gcc
	@[ -z "$(CCPATH)" -o -d "$(CCPATH)" ] \
	    && echo Version: `/usr/bin/env PATH=$(CCPATH):$(PATH) $(CCPRE)gcc --version | head -1` \
	    || echo Version: Not downloaded, please download it: make toolchain CCORI=$(CCORI)
	@[ "$(CCORI)" = "internal" ] && echo More...: `/usr/bin/update-alternatives --list $(CCPRE)gcc` || true

gcc-info: toolchain-info
gcc-version: toolchain-info
toolchain-version: toolchain-info

PHONY += gcc-info gcc-version toolchain-version toolchain-info

toolchain-clean: $(TOOLCHAIN_CLEAN)

toolchain-clean-internal:
	$(Q)gcc=$$(which $(CCPRE)gcc-$(GCC)) >/dev/null \
	  && gcc_pkg=$$(dpkg -S $$gcc | cut -d ':' -f1) \
	  && echo "Removing $$gcc_pkg ..." \
	  && sudo apt remove --purge --yes $$gcc_pkg \
	  && echo "Update alternativies for $(CCPRE)gcc" \
	  && update-alternatives --remove $(CCPRE)gcc /usr/bin/$(CCPRE)gcc-$(GCC) \
	  && update-alternatives --verbose --set $(CCPRE)gcc $$(update-alternatives --list $(CCPRE)gcc | sort -u | tail -1) || true

toolchain-clean-external:
	$(Q)[ -n "$(TOOLCHAIN)" -a -d "$(TOOLCHAIN)" -a -n "$(CCBASE)" ] \
	  && echo "Removing $(TOOLCHAIN)/$(CCBASE) ..." \
	  && rm -rvf $(TOOLCHAIN)/$(CCBASE) || true

gcc-remove: gcc-clean
gcc-uninstall: gcc-clean
gcc-clean: toolchain-clean

PHONY += toolchain-clean toolchain-clean-internal toolchain-clean-external gcc-clean gcc-uninstall gcc-remove

toolchain-switch: $(TOOLCHAIN_SWITCH) toolchain-switch-ccori

toolchain-switch-internal:
	$(Q)[ -n "$(GCC)" -a "$(CCVER)" != "$(GCC)" ] && update-alternatives --verbose --set $(CCPRE)gcc /usr/bin/$(CCPRE)gcc-$(GCC) || true
	$(Q)[ -n "$(LDT)" -a "$(LDTVER)" != "$(LDT)" ] && update-alternatives --verbose --set $(CCPRE)ld /usr/bin/$(CCPRE)ld-$(LDT) || true

toolchain-switch-ccori:
	$(Q)if [ -f "$(BOARD_LABCONFIG)" ]; then board_config=$(BOARD_LABCONFIG); else board_config=$(BOARD_MAKEFILE); fi ; \
	_CCORI=$$(grep ^CCORI $$board_config | cut -d '=' -f2 | tr -d ' '); \
	[ "$$_CCORI" != "$(CCORI)" ] && tools/board/config.sh CCORI=$(CCORI) $(BOARD_LABCONFIG) >/dev/null || true

gcc-switch: toolchain-switch

PHONY += toolchain-switch gcc-switch toolchain-switch-internal toolchain-switch-ccori

endif # toolchain targets

# Root targets
ifneq ($(findstring root,$(MAKECMDGOALS)),)
 root_targets ?= 1
endif
ifneq ($(findstring nolibc,$(MAKECMDGOALS)),)
 root_targets ?= 1
endif

ifeq ($(root_targets),1)
ifeq ($(NOLIBC),1)

root-nolibc: env-prepare nolibc-initramfs
root-nolibc-distclean: root-nolibc-clean
	$(Q)echo "Cleaning nolibc output"
	$(Q)rm -rf $(NOLIBC_SYSROOT)

root-nolibc-clean:
	$(Q)rm -rf $(NOLIBC_BIN)
	$(Q)rm -rf $(NOLIBC_OBJ)
	$(Q)rm -rf $(NOLIBC_FLT)
	$(Q)rm -rf $(NOLIBC_PGC)
	$(Q)rm -rf $(NOLIBC_INITRAMFS)

root-nolibc-rebuild: root-nolibc-clean root-nolibc

nolibc: root-nolibc
nolibc-distclean: root-nolibc-distclean
nolibc-clean: root-nolibc-clean
nolibc-rebuild: root-nolibc-rebuild

root root-rd: root-nolibc
root-clean root-rd-clean: root-nolibc-clean
root-distclean root-rd-distclean: root-nolibc-distclean
root-rebuild root-rd-rebuild: root-nolibc-rebuild

NOLIBC_TARGETS := root-nolibc nolibc root root-rd
PHONY += $(NOLIBC_TARGETS) $(foreach x,clean distclean rebuild,$(addsuffix -$x,$(NOLIBC_TARGETS)))

# Nolibc build support, based on src/linux-stable/tools/testing/selftests/nolibc/Makefile

# Apply -std=c89 when LINUX >= v6.4
NOLIBC_STD[LINUX_$(call _any,LINUX,>=,v6.4)] := -std=c89
$(eval $(call __vs,NOLIBC_STD,LINUX))

NOLIBC_CFLAGS  += -Os -ffreestanding -fno-ident -fno-asynchronous-unwind-tables $(NOLIBC_STD) -DRECORD_SYSCALL #-Wl,-s
NOLIBC_LDFLAGS += #-s

ifeq ($(nolibc_stkp),1)
  NOLIBC_CFLAGS  += -fno-stack-protector -mstack-protector-guard=global -fstack-protector-all
endif

ifneq ($(findstring .sx,$(NOLIBC_SRC)x),)
  NOLIBC_CFLAGS += -fno-pic
endif

# nolibc use method: header or sysroot
ifeq ($(nolibc_inc),header)
  NOLIBC_INC := -include $(NOLIBC_H)
else
  NOLIBC_CFLAGS += -D__NOLIBC__
  NOLIBC_DEP := $(NOLIBC_SYSROOT_ARCH)
  NOLIBC_INC := -I$(NOLIBC_SYSROOT_ARCH)/include
endif

# nolibc gc sections and debug support
nolibc_gc       ?= 1
nolibc_gc_debug ?= 1

ifeq ($(nolibc_gc),1)
  NOLIBC_CFLAGS  += -ffunction-sections -fdata-sections -Wl,--gc-sections
  NOLIBC_LDFLAGS += --gc-sections
endif

ifeq ($(nolibc_gc_debug),1)
  NOLIBC_CFLAGS  += -Wl,--print-gc-sections
  NOLIBC_LDFLAGS += --print-gc-sections
endif

# ref: elf2flt.ld.in from https://github.com/uclinux-dev/elf2flt
NOLIBC_FLT_LDFLAGS := -Ttools/nolibc/elf2flt.ld
ifeq ($(nolibc_gc),1)
  NOLIBC_FLT_LDFLAGS += -e _start
endif

nolibc_comp ?= 0
ifeq ($(nolibc_comp),1)
  NOLIBC_E2FFLAGS := -z
endif

# Use UAPI headers from kernel source code
$(NOLIBC_SYSROOT_ARCH): $(NOLIBC_FILES)
	$(Q)echo "Generating $@"
	$(Q)rm -rf $(NOLIBC_SYSROOT)
	$(Q)mkdir -p $(NOLIBC_SYSROOT)
	$(Q)$(call make_kernel,headers_standalone OUTPUT=$(NOLIBC_SYSROOT)/,tools/include/nolibc)
	$(Q)mv $(NOLIBC_SYSROOT)/sysroot $(NOLIBC_SYSROOT_ARCH)

# With the -include $(NOLIBC_H) option, use UAPI headers provided by the toolchain
$(NOLIBC_OBJ): $(NOLIBC_SRC) $(NOLIBC_DEP)
	$(Q)echo "Building $@"
	$(Q)mkdir -p $(dir $@)
	$(Q)$(C_PATH) $(CCPRE)gcc $(NOLIBC_CFLAGS) -E -o $@.i \
	  -nostdlib -static $(NOLIBC_INC) $< -lgcc
	$(Q)$(C_PATH) $(CCPRE)gcc $(NOLIBC_CFLAGS) -S -o $@.s \
	  -nostdlib -static $(NOLIBC_INC) $< -lgcc
	$(Q)$(C_PATH) $(CCPRE)gcc $(NOLIBC_CFLAGS) -c -o $@ \
	  -nostdlib -static $(NOLIBC_INC) $< -lgcc

$(NOLIBC_BIN): $(NOLIBC_OBJ)
	$(Q)echo "Building $@"
	$(Q)mkdir -p $(dir $@)
	$(Q)$(C_PATH) $(CCPRE)gcc $(NOLIBC_CFLAGS) -o $@ \
	  -nostdlib -static $< -lgcc 2>&1 | tee $(NOLIBC_PGC)

# ref: ld-elf2flt.in from https://github.com/uclinux-dev/elf2flt
$(NOLIBC_FLT): $(NOLIBC_OBJ)
	$(Q)echo "Building $@"
	$(Q)mkdir -p $(dir $@)
	$(Q)$(C_PATH) $(CCPRE)ld $(NOLIBC_LDFLAGS) $(NOLIBC_FLT_LDFLAGS) -r -d -o $@.elf2flt $< 2>&1 | tee $(NOLIBC_PGC)
	$(Q)$(C_PATH) $(CCPRE)ld $(NOLIBC_FLT_LDFLAGS) -Ur -o $@.elf $@.elf2flt
	$(Q)$(C_PATH) $(CCPRE)ld $(NOLIBC_FLT_LDFLAGS) -o $@.gdb $@.elf2flt
	$(Q)tools/nolibc/elf2flt.$(XARCH) $(NOLIBC_E2FFLAGS) -a -v -p $@.gdb $@.elf -o $@
	$(Q)rm -rf $@.elf2flt $@.gdb $@.elf
	$(Q)$(C_PATH) $(CCPRE)ld $(NOLIBC_LDFLAGS) -o $(NOLIBC_BIN) $< >/dev/null

$(NOLIBC_INITRAMFS)/init: $(_NOLIBC_BIN)
	$(Q)echo "Creating $(NOLIBC_INITRAMFS)"
	$(Q)mkdir -p $(NOLIBC_INITRAMFS) $(NOLIBC_INITRAMFS)/dev
	$(Q)cp $< $@
	$(Q)[ -c $(NOLIBC_INITRAMFS)/dev/console ] || sudo mknod $(NOLIBC_INITRAMFS)/dev/console c 5 1
	$(Q)[ -c $(NOLIBC_INITRAMFS)/dev/null ] || sudo mknod $(NOLIBC_INITRAMFS)/dev/null c 1 3

$(NOLIBC_INITRAMFS): $(NOLIBC_INITRAMFS)/init $(NOLIBC_SCALL)

nolibc-initramfs: $(NOLIBC_INITRAMFS)

$(NOLIBC_SCALL): $(_NOLIBC_BIN)
	$(Q)$(C_PATH) tools/nolibc/dump.sh $(NOLIBC_BIN) $(XARCH) $(KERNEL_ABS_SRC) "$(NOLIBC_INC)" $(CCPRE) | \
		cut -d ' ' -f2 > $(NOLIBC_SCALL)
	$(Q)echo "Used system calls: $$(cat $(NOLIBC_SCALL) | tr '\n' ' ')"

nolibc-syscall: $(NOLIBC_SCALL)

PHONY += nolibc-initramfs nolibc-syscall

else # !NOLIBC
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
$(eval $(call genenvdeps,root,BUILDROOT,R))

# Build Buildroot
root-buildroot:
	$(call make_root,$(RT))

PHONY += root-buildroot

build_root_uboot ?= 0
ifeq ($(U),1)
  ifeq ($(DEV_TYPE),rd)
    build_root_uboot := 1
  endif
endif

# root ramdisk image
ifneq ($(FS_TYPE),rd)
  ROOT_GENRD_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2rd.sh
  ifeq ($(FS_TYPE),hd)
    IROOTFS_DEPS    := $(HROOTFS)
  else
    ifneq ($(wildcard $(ROOTDIR)),)
      IROOTFS_DEPS  := $(ROOTDIR)
    endif
  endif
else
  ifneq ($(wildcard $(ROOTDIR)),)
    ROOT_GENRD_TOOL := $(TOOL_DIR)/root/dir2rd.sh
    IROOTFS_DEPS    := $(ROOTDIR)
  endif
endif

$(IROOTFS): bsp-outdir $(IROOTFS_DEPS)
ifneq ($(IROOTFS_DEPS),)
 ifneq ($(FS_TYPE),)
	@echo "LOG: Generating ramdisk image with $(ROOT_GENRD_TOOL) ..."
	$(Q)rm -rf $(IROOTFS).tmp
	$(Q)ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS).tmp USER=$(USER) $(ROOT_GENRD_TOOL) || (rm $(IROOTFS) && exit 1)
	$(Q)mv $(IROOTFS).tmp $(IROOTFS)
 endif
endif

root-rd: $(IROOTFS)

root-rd-rebuild: root-dir root-rd-clean $(IROOTFS) FORCE

root-rd-clean:
	$(Q)[ "$(IROOTFS)" != "$(PREBUILT_IROOTFS)" ] && rm -vf $(IROOTFS) || true

PHONY += root-rd $(addprefix root-rd-,rebuild clean)

ROOT_GENDISK_TOOL       := $(TOOL_DIR)/root/dir2$(DEV_TYPE).sh

ROOTDIR_GOAL            := root-dir-prebuilt
ROOT_REBUILD_TARGET     := root-rebuild-prebuilt

ifeq ($(PBR), 0)
  ifeq ($(wildcard $(BUILDROOT_IROOTFS)),)
    ROOTDIR_GOAL        := root-dir-buildroot
  endif
  ifneq ($(FS_TYPE),dir)
    ROOT_REBUILD_TARGET := root-rebuild-buildroot
  endif
endif
ROOT_REBUILD_DEPS       := $(ROOTDIR_GOAL)

# No need to rebuild all the time
ifeq ($(wildcard $(ROOTDIR)),)
  MODULE_ROOTDIR_GOAL   := $(ROOTDIR_GOAL)
endif

ifeq ($(DEV_TYPE),rd)
  XROOTFS := $(IROOTFS)
else
  XROOTFS := $(HROOTFS)
endif

# This is used to repackage the updated root directory, for example, `make r-i` just executed.
root-rebuild: $(ROOT_REBUILD_DEPS) root-dir-install $(ROOT_REBUILD_TARGET)

root-rebuild-prebuilt:
	@echo "LOG: Generating $(DEV_TYPE) with $(ROOT_GENDISK_TOOL) ..."
	$(Q)rm -rf $(XROOTFS).tmp
	$(Q)ROOTDIR=$(ROOTDIR) INITRD=$(IROOTFS).tmp HROOTFS=$(HROOTFS).tmp FSTYPE=$(FSTYPE) USER=$(USER) $(ROOT_GENDISK_TOOL)
	$(Q)[ -f $(XROOTFS).tmp ] && mv $(XROOTFS).tmp $(XROOTFS) || true
	$(Q)[ $(build_root_uboot) -eq 1 ] && make $(S) root-ud-rebuild || true

root-rebuild-buildroot:
	$(call make_root)
	$(Q)chown -R $(USER):$(USER) $(BUILDROOT_ROOTDIR)
	$(Q)[ $(build_root_uboot) -eq 1 ] && make $(S) $(BUILDROOT_UROOTFS) || true

PHONY += root-rebuild $(addprefix root-rebuild-,prebuilt buildroot)

ROOT ?= $(ROOTDIR)
ifeq ($(_PBR), 0)
  ifeq ($(wildcard $(BUILDROOT_IROOTFS)),)
    ROOT := root-buildroot
  endif
endif

# Specify buildroot target

RT ?= $(x)

ifneq ($(RT),)
_root:
	$(Q)$(call make_root,$(RT))
else
_root: $(ROOT)
	$(Q)make $(S) root-rebuild
endif

root-clean: $(addsuffix -clean,$(addprefix root-,dir hd $(if $(UBOOT),ud) rd))

# root directory
ifneq ($(FS_TYPE),dir)
  ROOT_GENDIR_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2dir.sh
  ifeq ($(FS_TYPE),rd)
    # Fix up circular deps, if rootdir is there, remove dep from irootfs
    ifeq ($(wildcard $(ROOTDIR)),)
      ROOTDIR_DEPS := $(IROOTFS)
    endif
  endif
  ifeq ($(FS_TYPE),hd)
    ROOTDIR_DEPS := $(HROOTFS)
  endif
endif

root-dir rootdir: $(ROOTDIR)
root-dir-rebuild rootdir-rebuild: root-dir-clean $(ROOTDIR) FORCE

PHONY += root-dir rootdir $(addsuffix -rebuild,root-dir rootdir)

# Install src/system, $(BSP_ROOT)/system and $(BSP_ROOT)/$(BUILDROOT)/system

ROOT_SYSTEM_OVERLAY := src/system $(wildcard $(BSP_ROOT)/system) $(wildcard $(BSP_ROOT)/$(BUILDROOT)/system)
ROOT_INSTALL_TOOL := $(TOOL_DIR)/root/install.sh

ifneq ($(wildcard $(KERNEL_BUILD)),)
  ROOT_DIR_INSTALL_MODULES := root-dir-install-modules
endif

root-dir-install: root-dir-install-system $(ROOT_DIR_INSTALL_MODULES)

root-dir-install-system: $(ROOT_SYSTEM_OVERLAY)
	$(Q)echo "LOG: Install system" && ROOTDIR=$(ROOTDIR) SYSTEM="$(ROOT_SYSTEM_OVERLAY)" $(ROOT_INSTALL_TOOL)

root-dir-install-modules: $(KERNEL_BUILD)
	$(Q)echo "LOG: Install modules" && make $(S) module-install || true

PHONE += root-dir-install $(addprefix root-dir-install-,system modules)

$(ROOTDIR): $(ROOTDIR_GOAL) root-dir-install

root-dir-prebuilt: bsp-outdir $(ROOTDIR_DEPS)
	$(Q)if [ ! -d $(ROOTDIR)/bin -a -f $(ROOT_GENDIR_TOOL) ]; then \
	  echo "LOG: Generating rootfs directory with $(ROOT_GENDIR_TOOL) ..."; \
	  rm -rf $(ROOTDIR).tmp; \
	  rm -rf $(ROOTDIR); \
	  ROOTDIR=$(ROOTDIR).tmp USER=$(USER) HROOTFS=$(HROOTFS) INITRD=$(IROOTFS) $(ROOT_GENDIR_TOOL); \
	  mv $(ROOTDIR).tmp $(ROOTDIR); \
	fi

root-dir-buildroot: root-buildroot

root-dir-clean rootdir-clean:
	$(Q)[ "$(ROOTDIR)" = "$(BSP_ROOTDIR)" ] && rm -rvf $(ROOTDIR) || true

root-dir-distclean rootdir-distclean: rootdir-clean

PHONY += $(addprefix root-dir-,prebuilt buildroot clean distclean) $(addprefix rootdir-,clean distclean)

fullclean: $(call gengoalslist,distclean)
	$(Q)git clean -fdx -e licenses/ -e src/

PHONY += fullclean

ifeq ($(FS_TYPE),dir)
  HROOTFS_DEPS  := $(ROOTDIR)
endif
ifeq ($(FS_TYPE),rd)
  HROOTFS_DEPS  := $(IROOTFS)
endif

ROOT_GENHD_TOOL := $(TOOL_DIR)/root/$(FS_TYPE)2hd.sh

$(HROOTFS): bsp-outdir $(HROOTFS_DEPS)
	$(Q)if [ -n "$(HROOTFS_DEPS)" ]; then \
	  echo "LOG: Generating harddisk image with $(ROOT_GENHD_TOOL) ..."; \
	  rm -rf $(HROOTFS).tmp; \
	  ROOTDIR=$(ROOTDIR) FSTYPE=$(FSTYPE) HROOTFS=$(HROOTFS).tmp INITRD=$(IROOTFS) $(ROOT_GENHD_TOOL) || (rm $(HROOTFS) && exit 1); \
	  mv $(HROOTFS).tmp $(HROOTFS); \
	fi

root-hd: $(HROOTFS)

root-hd-rebuild: root-hd-clean $(HROOTFS) FORCE

root-hd-clean:
	-$(Q)rm -vf $(HROOTFS)

PHONY += root-hd $(addprefix root-hd-,rebuild clean)

endif # !NOLIBC
endif # Root targets

# Linux Kernel targets
kernel_targets ?= $(strip $(foreach t,linux kernel module,$(if $(findstring $t,$(MAKECMDGOALS)),1)))

ifeq ($(kernel_targets),1)
_LINUX  := $(call _v,LINUX,LINUX)
_KERNEL ?= $(_LINUX)

# kernel remove oldnoconfig after 4.19 and use olddefconfig instead,
# see commit: 312ee68752faaa553499775d2c191ff7a883826f kconfig: announce removal of oldnoconfig if used
#        and: 04c459d204484fa4747d29c24f00df11fe6334d4 kconfig: remove oldnoconfig target
KERNEL_OLDDEFCONFIG     := $$(tools/kernel/olddefconfig.sh $(KERNEL_ABS_SRC)/scripts/kconfig/Makefile)
KERNEL_CONFIG_DIR       := $(KERNEL_ABS_SRC)/arch/$(ARCH)/configs
KERNEL_CONFIG_EXTRAFLAG := M=
KERNEL_CONFIG_EXTRACMDS := yes N | $(empty)
KERNEL_CLEAN_DEPS       := kernel-modules-clean
# Must be assigned before gengoals
ifneq ($(FEATURE),)
KERNEL_PATCH_EXTRAACTION := [ -n "$$(FEATURE)" ] && $$(KERNEL_FEATURE_PATCH_TOOL) $$(ARCH) $$(XARCH) $$(BOARD) $$(LINUX) $$(KERNEL_ABS_SRC) $$(KERNEL_BUILD) "$$(FEATURE)" || true;
endif

kernel-oldnoconfig: kernel-olddefconfig

PHONY += kernel-oldnoconfig

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
#$(warning $(call genenvdeps,kernel,LINUX,K))
$(eval $(call genenvdeps,kernel,LINUX,K))
# Get configs must be enabled/disabled for target toolchain and kernel versions
$(eval $(call __vs,KCFGS,GCC,LINUX))

# kernel features support
KERNEL_FEATURE_ENV_TOOL := tools/kernel/feature-env.sh
KERNEL_FEATURE_DOWNLOAD_TOOL := tools/kernel/feature-download.sh
KERNEL_FEATURE_CONFIG_TOOL := tools/kernel/feature-config.sh
KERNEL_FEATURE_PATCH_TOOL := tools/kernel/feature-patch.sh

ifneq ($(FEATURE),)
kernel-source: $(call __stamp,kernel,outdir) $(call __stamp,kernel,source.feature)

$(call __stamp,kernel,source.feature): $(call __stamp,kernel,feature.downloaded) $(ENV_FILES)
	$(Q)touch $@

$(call __stamp,kernel,feature.downloaded):
	$(Q)echo "Downloading kernel feature patchset: $(FEATURE)"
	$(Q)$(KERNEL_FEATURE_DOWNLOAD_TOOL) $(ARCH) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_BUILD) "$(FEATURE)"
	$(Q)touch $@

kernel-env: $(call __stamp,kernel,env.feature)

$(call __stamp,kernel,env.feature):
	$(Q)echo "Appling kernel feature envs: $(FEATURE)"
	$(Q)$(KERNEL_FEATURE_ENV_TOOL) $(ARCH) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_BUILD) "$(FEATURE)" || true
	$(Q)touch $@

kernel-olddefconfig kernel-menuconfig: $(call __stamp,kernel,defconfig) $(call __stamp,kernel,defconfig.feature)
$(call __stamp,kernel,defconfig.feature): $(ENV_FILES)
	$(Q)echo "Appling kernel feature configs: $(FEATURE)"
	$(Q)$(KERNEL_FEATURE_CONFIG_TOOL) $(ARCH) $(XARCH) $(BOARD) $(LINUX) $(KERNEL_ABS_SRC) $(KERNEL_BUILD) "$(FEATURE)" || true
	$(call make_kernel,$(or $(KERNEL_OLDDEFCONFIG),olddefconfig) $(KERNEL_NOCONFIG))
	$(Q)touch $@
endif

kernel-feature-cleanstamp:
	$(Q)rm -rvf $(addprefix $(KERNEL_BUILD)/.stamp_kernel-,source.feature defconfig.feature env.feature feature.downloaded)

kernel-cleanstamp: kernel-feature-cleanstamp

FCS ?= 0
ifneq ($(filter command line,$(foreach i,F FEATURE FEATURES,$(origin $i))),)
  FCS := 1
endif

kernel-feature:
	$(Q)[ $(FCS) -eq 1 ] && tools/board/config.sh FEATURE=$(FEATURE) $(BOARD_LABCONFIG) $(LINUX) || true

ifneq ($(firstword $(MAKECMDGOALS)),list)
feature: kernel-feature
features: feature
endif

kernel-features: kernel-feature

kernel-feature-list:
	$(Q)echo [ $(FEATURE_DIR) ]:
	$(Q)find $(FEATURE_DIR) -mindepth 1 | sed -e "s%$(FEATURE_DIR)/%%g" | sort | grep -E "$(FILTER)$(if $(FEATURE),$(subst $(comma),|,$(FEATURE)))" | grep -E -v ".gitignore|downloaded" | sed -e "s%\(^[^/]*$$\)%  + \1%g;s%[^/]*/.*/%      * %g;s%[^/]*/%    - %g"

kernel-features-list: kernel-feature-list
features-list: kernel-feature-list
feature-list: kernel-feature-list

FEATURES_TARGETS := feature features kernel-feature kernel-features
PHONY += $(addsuffix -list,$(FEATURES_TARGETS)) $(FEATURES_TARGETS) kernel-feature-cleanstamp

kernel-feature-test: kernel-test
kernel-features-test: kernel-feature-test
features-test: kernel-feature-test
feature-test: kernel-feature-test

PHONY += $(addsuffix -test,$(FEATURES_TARGETS))

# Module targets
ifneq ($(findstring module,$(MAKECMDGOALS)),)
  module_targets ?= 1
endif

ifeq ($(module_targets),1)

TOP_MODULE_DIR := $(or $(_TOP_SRC),$(TOP_SRC))/modules
ifneq ($(PLUGIN),)
  TMP := $(TOP_DIR)/boards/$(PLUGIN)/modules
  ifneq ($(wildcard $(TMP)),)
    PLUGIN_MODULE_DIR := $(TMP)
  endif
else
  ifneq ($(findstring module,$(MAKECMDGOALS)),)
    PLUGIN_MODULE_DIR := $$(find $(TOP_DIR)/boards -maxdepth 5 -type d -name "modules")
  endif
endif

EXT_MODULE_DIR := $(TOP_MODULE_DIR) $(PLUGIN_MODULE_DIR)
KERNEL_MODULE_DIR := $(KERNEL_ABS_SRC)
KERNEL_SEARCH_PATH := $(addprefix $(KERNEL_MODULE_DIR)/,drivers kernel fs block crypto mm net security sound samples)

modules  ?= $(m)
module   ?= $(modules)
ifeq ($(module),all)
  module := $(shell find $(EXT_MODULE_DIR) -name "Makefile" | xargs -i dirname {} | xargs -i basename {} | tr '\n' ',')
endif

ifneq ($(module),)
  ifneq ($(FEATURE),)
    ifeq ($(findstring module,$(FEATURE)),)
      FEATURE := $(FEATURE),module
    endif
  else
    FEATURE := module
  endif
endif

internal_module := 0
ifneq ($(M),)
  ifneq ($(M),)
    override M := $(subst //,/,$(patsubst %/,%,$(M)))
  endif
  ifneq ($(wildcard $(M)),)
    ifneq ($(findstring $(KERNEL_MODULE_DIR),$(M)),)
      # Convert to relative path: must related to top dir of linux kernel, otherwise, will be compiled in source directory
      M_PATH = $(subst $(KERNEL_MODULE_DIR)/,,$(M))
      internal_module := 1
    else
      ifneq ($(findstring $(TOP_DIR),$(M)),)
        M_PATH ?= $(M)
      else
        M_PATH ?= $(TOP_DIR)/$(M)
      endif
    endif
  else
    ifneq ($(wildcard $(KERNEL_MODULE_DIR)/$(M)),)
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
  ifneq ($(findstring _module,$(MAKECMDGOALS)),)
    one_module := 1
  endif
endif

ifeq ($(one_module),1)
  ifeq ($(module),)
    # Prefer user input instead of preconfigured
    ifeq ($(wildcard $(M_PATH)),)
      ifneq ($(MODULE_CONFIG),)
        module := $(MODULE_CONFIG)
      endif
      ifneq ($(MPATH_CONFIG),)
        M_PATH ?= $(MPATH_CONFIG)
      endif
    endif
  else
    M_PATH := $(shell find $(EXT_MODULE_DIR) -name "Makefile" | xargs -i grep -E -iH "^obj-m[[:space:]]*[+:]*=[[:space:]]*($(module))\.o" {} | sed -e "s%\(.*\)/Makefile.*%\1%g" | head -1)
    ifeq ($(M_PATH),)
      M_PATH := $(shell find $(KERNEL_SEARCH_PATH) -name "Makefile" | xargs -i grep -E -iH "^obj-.*[[:space:]]*[+:]*=[[:space:]]*($(module))\.o" {} | sed -e "s%\(.*\)/Makefile.*%\1%g" | head -1)
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
	$(Q)echo "$(M_PATH)" > .mpath_config
	$(Q)echo "$(module)" > .module_config


KM ?= M=$(M_PATH)
KERNEL_MODULES_DEPS := modules-prompt kernel-modules-save

export KM
endif

PHONY += modules-prompt $(addprefix kernel-modules-,save)

# Both internal and external modules require modules_prepare (prepare and scripts, such as scripts/mod/modpost)
MODULE_PREPARE := modules_prepare

kernel-modules-config: $(DEFAULT_KCONFIG)
	$(Q)if [ "$$($(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" != "y" ]; then  \
	  $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -e MODULES; \
	  $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -e MODULES_UNLOAD; \
	fi

kernel-modules-defconfig: $(DEFAULT_KCONFIG)
	$(Q)make -s $(NPD) kernel-olddefconfig

PHONY += $(addprefix kernel-modules-,config defconfig)

kernel-modules-km: kernel-modules-config $(if $(m),kernel-config) kernel-modules-defconfig $(KERNEL_MODULES_DEPS)
	@# M variable can not be set for modules_prepare target
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
  MF  ?= grep -E "$(IMF)"
  internal_search := 1
else
  IMF :=.*
  MF  := cat
endif

# If m or M argument specified, search modules in kernel source directory
ifneq ($(M),)
  PF ?= grep -E "$(subst $(comma),|,$(M))"
  internal_search := 1
else
  PF := cat
endif

kernel-modules-list: kernel-modules-list-full

kernel-modules-list-full:
	$(Q)find $(EXT_MODULE_DIR) -name "Makefile" | $(PF) | xargs -i grep -E -iH "^obj-m[[:space:]]*[+:]*=[[:space:]]*.*($(IMF)).*\.o" {} | sed -e "s%$(PWD)\(.*\)/Makefile:obj-m[[:space:]]*[+:]*=[[:space:]]*\(.*\).o%m=\2 ; M=$$PWD/\1%g" | tr -s '/' | cat -n
	$(Q)[ "$(internal_search)" = "1" ] && find $(KERNEL_SEARCH_PATH) -name "Makefile" | $(PF) | xargs -i grep -E -iH "^obj-.*_($(IMF))(\)|_).*[[:space:]]*[+:]*=[[:space:]]*($(IMF)).*\.o" {} | sed -e "s%$(KERNEL_MODULE_DIR)/\(.*\)/Makefile:obj-\$$(CONFIG_\(.*\))[[:space:]]*[+:]*=[[:space:]]*\(.*\)\.o%c=\2 ; m=\3 ; M=\1%g" | tr -s '/' | cat -n || true

PHONY += kernel-modules $(addprefix kernel-modules-,km list list-full)

# From linux-stable/scripts/depmod.sh, v5.1
SCRIPTS_DEPMOD := $(TOP_DIR)/tools/kernel/depmod.sh

kernel-modules-install-km: $(MODULE_ROOTDIR_GOAL)
	$(Q)if [ "$$($(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" = "y" -a -n "$(KM)" ]; then \
	  echo Module path: $(M_ABS_PATH); \
	  modules_order=$(M_ABS_PATH)/modules.order; \
	  module_symvers=$(M_ABS_PATH)/Module.symvers; \
	  if [ -f "$$modules_order" -o "$$module_symvers" ]; then \
	    $(call make_kernel,modules_install $(KM) INSTALL_MOD_PATH=$(ROOTDIR)); \
	    KERNEL_RELEASE=$$(grep UTS_RELEASE -ur $(KERNEL_BUILD)/include |  cut -d ' ' -f3 | tr -d '"'); \
	    [ ! -f $(KERNEL_ABS_SRC)/scripts/depmod.sh ] \
	      && cd $(KERNEL_BUILD) \
	      && INSTALL_MOD_PATH=$(ROOTDIR) $(SCRIPTS_DEPMOD) /sbin/depmod $$KERNEL_RELEASE || true; \
	    echo "\nChecking module:\n"; \
	    MOD_INSTALL_PATH=$(ROOTDIR)/lib/modules/$$KERNEL_RELEASE; \
	    for d in $(subst M=,,$(KM)) extra; do \
	      [ -d $$MOD_INSTALL_PATH/$$d/ ] && ls $$MOD_INSTALL_PATH/$$d/; \
	    done ; \
	  fi ; \
	fi

kernel-modules-install: $(MODULE_ROOTDIR_GOAL)
	$(Q)[ "$$($(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s MODULES)" = "y" ] \
	  && $(call make_kernel,modules_install INSTALL_MOD_PATH=$(ROOTDIR)) \
	  && rm $(ROOTDIR)/lib/modules/*/build \
	  && rm $(ROOTDIR)/lib/modules/*/source || true

ifeq ($(internal_module),1)
  M_ABS_PATH := $(KERNEL_BUILD)/$(M_PATH)
else
  M_ABS_PATH := $(wildcard $(M_PATH))
endif

KERNEL_MODULE_CLEAN := tools/module/clean.sh
kernel-modules-clean-km:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_BUILD) $(M_ABS_PATH)
	$(Q)rm -rvf .module_config

kernel-modules-clean:
	$(Q)$(KERNEL_MODULE_CLEAN) $(KERNEL_BUILD)

PHONY += $(addprefix kernel-modules-,install install-km clean clean-km)

_module: kernel-modules-km plugin-save
module-list: kernel-modules-list plugin-save
module-list-full: kernel-modules-list-full plugin-save
_module-install: kernel-modules-install-km
_module-clean: kernel-modules-clean-km

modules-list: module-list
modules-list-full: module-list-full

module-test: kernel-test
modules-test: module-test

PHONY += _module $(addprefix _module-,install clean) $(addprefix module-,list list-full) $(addprefix modules-,list list-full)

kernel-module: module
module: FORCE
	$(Q)$(if $(module), $(foreach _m, $(subst $(comma),$(space),$(module)), \
		echo "\nBuilding module: $(_m) ...\n" && make $(NPD) _module m=$(_m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(subst $(comma),$(space),$(M)), \
		echo "\nBuilding module: $(_M) ...\n" && make $(NPD) _module M=$(_M);) echo '')

kernel-module-install: module-install
module-install: FORCE
	$(Q)$(if $(module), $(foreach _m, $(subst $(comma),$(space),$(module)), \
		echo "\nInstalling module: $(_m) ...\n" && make $(NPD) _module-install m=$(_m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(subst $(comma),$(space),$(M)), \
		echo "\nInstalling module: $(_M) ...\n" && make $(NPD) _module-install M=$(_M);) echo '')

kernel-module-clean: module-clean
module-clean: FORCE
	$(Q)$(if $(module), $(foreach _m, $(subst $(comma),$(space),$(module)), \
		echo "\nCleaning module: $(_m) ...\n" && make $(NPD) _module-clean m=$(_m);) echo '')
	$(Q)$(if $(M), $(foreach _M, $(subst $(comma),$(space),$(M)), \
		echo "\nCleaning module: $(_M) ...\n" && make $(NPD) _module-clean M=$(_M);) echo '')

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

MODULE_TARGETS := kernel-module module modules
PHONY += $(MODULE_TARGETS) $(addsuffix -clean,$(MODULE_TARGETS)) $(addsuffix -install,$(MODULE_TARGETS))

endif # module targets

# Build Kernel
IMAGE := $(notdir $(ORIIMG))

# aarch64 not add uboot header for kernel image
ifeq ($(U),1)
  IMAGE := $(notdir $(UKIMAGE))
endif

# Default kernel target is kernel image
KT ?= $(IMAGE)
ifneq ($(x),)
  KT := $(x)
endif

# Allow to accept external kernel compile options, such as XXX_CONFIG=y
KOPTS ?=

# Allow configure INITRAMFS_SOURCE, prefer menuconfig to commandline
INITRAMFS_SOURCE_CONFIG = $$($(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s INITRAMFS_SOURCE 2>/dev/null | tr -d '\n')
ifneq ($(findstring /dev/null,$(ROOTDEV)),)
  # directory is ok, but is not compressed cpio
  ifneq ($(wildcard $(IROOTFS)),)
    KOPTS   += $$([ -z "$(INITRAMFS_SOURCE_CONFIG)" ] && echo CONFIG_INITRAMFS_SOURCE="$(or $(CONFIG_INITRAMFS_SOURCE),$(IROOTFS))")
    ROOT_RD := $(IROOTFS)
  else
    KOPTS   += $$([ -z "$(INITRAMFS_SOURCE_CONFIG)" ] && echo CONFIG_INITRAMFS_SOURCE="$(or $(CONFIG_INITRAMFS_SOURCE),$(ROOTFS))")
    ROOT_RD := $(ROOTFS)
  endif
else
  KOPTS   += $$([ -z "$(INITRAMFS_SOURCE_CONFIG)" ] && echo CONFIG_INITRAMFS_SOURCE="$(or $(CONFIG_INITRAMFS_SOURCE))")
endif

# Allow configure INITRAMFS_SOURCE, prefer menuconfig to commandline
USED_SYSCALLS_CONFIG = $$($(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) -s USED_SYSCALLS 2>/dev/null | tr -d '\n')
ifeq ($(NOLIBC),1)
  KOPTS   += $$([ -z "$(USED_SYSCALLS_CONFIG)" ] && echo CONFIG_USED_SYSCALLS="$(or $(CONFIG_USED_SYSCALLS),$$(scall=$(NOLIBC_SCALL) && [ -s $$scall ] && echo $$scall))")
endif

DTC := tools/kernel/dtc

# Update bootargs in dts if exists, some boards not support -append
ifneq ($(DTS),)

# FIXME: must introduce gcc -E to translate #define, #include commands for customized dts at first
# only internal dts requires kernel-defconfig dependency
$(DTS): $(if $(_DTS),,kernel-defconfig)

dtb: $(DTS)
	$(Q)if [ -f "$(DTS)" ]; then \
	  echo "Building dtb ..."; \
	  echo "  DTS: $(DTS)"; \
	  echo "  DTB: $(DTB)"; \
	  sed -i -e "s%.*bootargs.*=.*;%\t\tbootargs = \"$$(eval echo "$(CMDLINE)")\";%g" $(DTS); \
	  if [ -z "$(_DTS)" ]; then \
	    $(call make_kernel,$(DTB_TARGET)); \
	  else \
	    sed -i -e "s%^#include%/include/%g" $(DTS); \
	    mkdir -p $(dir $(DTB)); \
	    $(DTC) -I dts -O dtb -o $(DTB) $(DTS); \
	  fi; \
	fi

# Pass kernel command line in dts, require to build dts for every boot
KCLI_DTS   ?= 0
ifeq ($(KCLI_DTS),1)
  BOOT_DTB := dtb
endif
KERNEL_DTB := dtb

PHONY += dtb
endif

# Ignore DTB and RD dependency if KT is not kernel image
ifeq ($(KT),$(IMAGE))
  KERNEL_DEPS := $(KERNEL_DTB) $(ROOT_RD)
endif

ifneq ($(filter _kernel-setconfig,$(MAKECMDGOALS)),)
  ksetconfig  := 1
endif

# Caching commandline variables
makeclivar    := $(-*-command-variables-*-)

ifeq ($(ksetconfig),1)

# y=MODULE, n=MODULE, m=MODULE, c=MODULE, s=STR, v=VALUE
ifneq ($(m),)
  KCONFIG_SET_OPT := -m $(m)
  KCONFIG_GET_OPT := -s $(m)
  KCONFIG_OPR     := m
  KCONFIG_OPT     := $(m)
endif

# c/o added for module option, when it is not the same as module name
ifneq ($(c),)
  KCONFIG_SET_OPT := -m $(c)
  KCONFIG_GET_OPT := -s $(c)
  KCONFIG_OPR     := m
  KCONFIG_OPT     := $(c)
endif

ifneq ($(o),)
  KCONFIG_SET_OPT := -m $(o)
  KCONFIG_GET_OPT := -s $(o)
  KCONFIG_OPR     := m
  KCONFIG_OPT     := $(o)
endif

ifneq ($(s),)
  tmp             := $(subst =,$(space),$(s))
  KCONFIG_SET_OPT := --set-str $(tmp)
  KCONFIG_OPT     := $(firstword $(tmp))
  KCONFIG_GET_OPT := -s $(KCONFIG_OPT)
  KCONFIG_OPR     := s
endif

ifneq ($(v),)
  tmp             := $(subst =,$(space),$(v))
  KCONFIG_SET_OPT := --set-val $(tmp)
  KCONFIG_OPT     := $(firstword $(tmp))
  KCONFIG_GET_OPT := -s $(KCONFIG_OPT)
  KCONFIG_OPR     := v
endif

ifneq ($(y),)
  KCONFIG_SET_OPT := -e $(y)
  KCONFIG_GET_OPT := -s $(y)
  KCONFIG_OPR     := y
  KCONFIG_OPT     := $(y)
endif

ifneq ($(n),)
  KCONFIG_SET_OPT := -d $(n)
  KCONFIG_GET_OPT := -s $(n)
  KCONFIG_OPR     := n
  KCONFIG_OPT     := $(n)
endif

endif #ksetconfig

ifneq ($(filter _kernel-getconfig,$(MAKECMDGOALS)),)
  ifneq ($(o),)
    KCONFIG_GET_OPT := -s $(o)
  endif
endif

ifneq ($(filter kernel-getconfig,$(MAKECMDGOALS)),)
  o ?= $m
endif

kernel-getconfig: FORCE
	$(Q)$(if $(o), $(foreach _o, $(subst $(comma),$(space),$(o)), \
		__o=$(call _uc,$(_o)) && \
		echo "\nGetting kernel config: $$__o ...\n" && make $(S) _kernel-getconfig o=$$__o;) echo '')
	$(Q)echo

_kernel-getconfig: $(DEFAULT_KCONFIG)
	$(Q)printf "option state: $(o)="&& $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_GET_OPT)
	$(Q)grep -E -iH "_$(o)( |=|_)" $(DEFAULT_KCONFIG) | sed -e "s%$(TOP_DIR)/%%g"
	$(Q)echo

kernel-config: kernel-setconfig
kernel-setconfig: FORCE
	$(Q)$(if $(makeclivar), $(foreach _o, $(foreach setting,$(foreach p,y n m c o s v,$(filter $(p)=%,$(makeclivar))), \
		$(shell p=$(firstword $(subst =,$(space),$(setting))) && \
		echo $(setting) | cut -d'=' -f2- | tr ',' '\n' | xargs -i echo $$p={} | tr '\n' ' ')), \
		echo "\nSetting kernel config: $(_o) ...\n" && make $(S) _kernel-setconfig y= n= m= s= v= c= o= $(_o);), echo '')
	$(Q)echo

_kernel-setconfig: $(DEFAULT_KCONFIG)
	$(Q)$(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_SET_OPT)
	$(Q)echo "Configuring new kernel config: $(KCONFIG_OPT) ..."
	$(Q)echo "\nChecking kernel config: $(KCONFIG_OPT) ...\n"
	$(Q)printf "option state: $(KCONFIG_OPT)=" && $(SCRIPTS_KCONFIG) --file $(DEFAULT_KCONFIG) $(KCONFIG_GET_OPT)
	$(Q)grep -E -iH "_$(KCONFIG_OPT)(_|=| )" $(DEFAULT_KCONFIG) | sed -e "s%$(TOP_DIR)/%%g"
	$(Q)echo

PHONY += $(addprefix kernel-,config getconfig setconfig) $(addprefix _kernel-,getconfig setconfig)

module-config: module-setconfig
modules-config: module-setconfig

module-getconfig: kernel-getconfig
module-setconfig: kernel-setconfig

PHONY += $(addprefix module-,config getconfig setconfig) modules-config

_kernel: $(KERNEL_DEPS)
	$(Q)$(call check_license,bsp)
	$(call make_kernel,$(KT))

KERNEL_CALLTRACE_TOOL := tools/kernel/calltrace-helper.sh

ifneq ($(findstring calltrace,$(MAKECMDGOALS)),)
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

endif # Kernel targets

# Uboot targets
ifneq ($(UBOOT),)
ifneq ($(findstring uboot,$(MAKECMDGOALS)),)
  uboot_targets ?= 1
endif
ifeq ($(uboot_targets),1)

# Uboot targets
_UBOOT  ?= $(call _v,UBOOT,UBOOT)

PFLASH_BASE ?= 0
PFLASH_SIZE ?= 0
BOOTDEV     ?= none
KRN_ADDR    ?= -
KRN_SIZE    ?= 0
RDK_ADDR    ?= -
RDK_SIZE    ?= 0
DTB_ADDR    ?= -
DTB_SIZE    ?= 0

#$(warning $(call genverify,BOOTDEV,BOOTDEV,UBOOT))
$(eval $(call genverify,BOOTDEV,BOOTDEV,UBOOT))

ifneq ($(findstring sd,$(BOOTDEV)),)
  SD_BOOT ?= 1
endif
ifneq ($(findstring mmc,$(BOOTDEV)),)
  SD_BOOT ?= 1
endif

# By default, boot from tftp
U_BOOT_CMD ?= bootcmd1
ifeq ($(SD_BOOT),1)
  U_BOOT_CMD := bootcmd2
endif
ifneq ($(findstring flash,$(BOOTDEV)),)
  U_BOOT_CMD := bootcmd3
endif
ifeq ($(BOOTDEV),ram)
  U_BOOT_CMD := bootcmd4
  RAM_BOOT   ?= 1
endif

ifeq ($(findstring /dev/ram,$(ROOTDEV)),)
  RDK_ADDR   := -
endif
ifeq ($(DTS),)
  ifneq ($(DTB_ADDR),$$fdtcontroladdr)
    DTB_ADDR   := -
  endif
endif

export U_BOOT_CMD IP ROUTE ROOTDEV BOOTDEV ROOTDIR PFLASH_BASE KRN_ADDR KRN_SIZE RDK_ADDR RDK_SIZE DTB_ADDR DTB_SIZE

UBOOT_CONFIG_TOOL := $(TOOL_DIR)/uboot/config.sh
UBOOT_PATCH_EXTRAACTION := [ -n "$$(UCONFIG)" ] && $$(UBOOT_CONFIG_TOOL) $$(UBOOT_ABS_SRC) $$(UCONFIG) || true;
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
#$(warning $(call genenvdeps,uboot,UBOOT,U))
$(eval $(call genenvdeps,uboot,UBOOT,U))

# Specify uboot targets
UT ?= $(x)

# Build Uboot
_uboot:
	$(call make_uboot,$(UT))

UBOOT_MKIMAGE := tools/uboot/mkimage

# root uboot image
$(UROOTFS): bsp-outdir $(IROOTFS)
	@echo "LOG: Generating rootfs image for uboot ..."
	$(Q)mkdir -p $(dir $(UROOTFS))
	$(Q)$(UBOOT_MKIMAGE) -A $(ARCH) -O linux -T ramdisk -C none -d $(IROOTFS) $(UROOTFS) || (rm $(UROOTFS) && exit 1)

root-ud: $(UROOTFS)

root-ud-rebuild: root-ud-clean $(UROOTFS) FORCE

root-ud-clean:
	$(Q)rm -vf $(UROOTFS) || true

PHONY += root-ud $(addprefix root-ud-,rebuild clean)

# aarch64 and riscv don't add uboot header for kernel image
ifneq ($(UKIMAGE), $(KIMAGE))
$(UKIMAGE): $(KIMAGE)
	$(Q)if [ "$(PBK)" = "0" ]; then \
	  if [ "$(notdir $(UKIMAGE))"  = "uImage" ]; then \
	    $(UBOOT_MKIMAGE) -A $(ARCH) -O linux -T kernel -C none -a $(KRN_ADDR) -e $(KRN_ADDR) -n 'Linux-$(LINUX)' -d $(KIMAGE) $(UKIMAGE) || (rm $(UKIMAGE) && exit 1); \
	  else \
	    cp -v $(KIMAGE) $(UKIMAGE); \
	  fi; \
	fi
else
$(UKIMAGE):
endif

ifneq ($(INVALID_ROOTFS),1)
  U_ROOT_IMAGE := $(UROOTFS)
endif

U_KERNEL_IMAGE := $(UKIMAGE)

ifneq ($(wildcard $(DTB)),)
  U_DTB_IMAGE  := $(DTB)
endif

ifeq ($(UKIMAGE),$(KIMAGE))
  BOOTX := booti
else
  BOOTX := bootm
endif

export CMDLINE PFLASH_IMG PFLASH_SIZE PFLASH_BS ENV_ADDR ENV_OFFSET ENV_SIZE BOOTX BOOTDEV_LIST SD_IMG U_ROOT_IMAGE RDK_SIZE U_DTB_IMAGE DTB_SIZE U_KERNEL_IMAGE KRN_SIZE TFTPBOOT BIMAGE ROUTE BOOTDEV

UBOOT_TFTP_TOOL   := $(TOOL_DIR)/uboot/tftp.sh
UBOOT_SD_TOOL     := $(TOOL_DIR)/uboot/sd.sh
UBOOT_PFLASH_TOOL := $(TOOL_DIR)/uboot/pflash.sh
UBOOT_ENV_TOOL    := $(TOOL_DIR)/uboot/env.sh

TFTP_IMGS  := $(addprefix $(TFTPBOOT)/,ramdisk dtb uImage)

# require by env saving, whenever boot from pflash
PFLASH_IMG := $(TFTPBOOT)/pflash.img

SD_IMG     := $(TFTPBOOT)/sd.img
ENV_IMG    := $(TFTPBOOT)/env.img

export ENV_IMG

UBOOT_DEPS := $(U_DTB_IMAGE)
ifneq ($(findstring /dev/ram,$(ROOTDEV)),)
  UBOOT_DEPS += $(UROOTFS)
endif
UBOOT_DEPS += $(UKIMAGE)

_uboot-images: $(UBOOT_DEPS)
	$(Q)[ "$(BOOTDEV)" = "tftp" ] && $(UBOOT_TFTP_TOOL) || true
	$(Q)[ "$(BOOTDEV)" = "flash" -o "$(BOOTDEV)" = "pflash" ] && $(UBOOT_PFLASH_TOOL) || true
	$(Q)[ "$(SD_BOOT)" = "1" ] && $(UBOOT_SD_TOOL) || true

uboot-images: _uboot-images
	$(Q)$(UBOOT_CONFIG_TOOL)
	$(Q)[ "$(BOOTDEV)" != "none" ] && $(UBOOT_ENV_TOOL) || true

uboot-images-clean:
	$(Q)rm -rvf $(TFTP_IMGS) $(PFLASH_IMG) $(SD_IMG) $(ENV_IMG)

uboot-images-distclean: uboot-images-clean
	$(Q)rm -rvf $(UROOTFS)
	$(Q)[ "$(PBK)" = "0" ] && rm -rvf $(UKIMAGE) || true

UBOOT_IMGS := uboot-images
UBOOT_IMGS_DISTCLEAN := uboot-images-distclean

PHONY += _uboot-images uboot-images $(addprefix uboot-images-,clean distclean)

endif # Uboot specific part
endif # Uboot targets

# strip breaks wsl2 kernel, don't apply with it
ifneq ($(KERNEL_FORK),wsl2)
  STRIP_CMD := $(C_PATH) $(CCPRE)strip -s
endif

# Save the built images
root-save:
	$(Q)mkdir -p $(PREBUILT_ROOT_DIR)
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	$(Q)[ "$(IROOTFS)" != "$(PREBUILT_IROOTFS)" ] && cp -v $(IROOTFS) $(PREBUILT_ROOT_DIR) || true
	$(Q)if [ -n "$(PORIIMG)" ]; then \
	  cp -v $(LINUX_PKIMAGE) $(PREBUILT_KERNEL_DIR); \
	  $(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(PORIIMG)) 2>/dev/null; \
	fi

kernel-save:
	$(Q)mkdir -p $(PREBUILT_KERNEL_DIR)
	$(Q)cp -v $(LINUX_KIMAGE) $(PREBUILT_KERNEL_DIR) || true
	$(Q)cp -v $(LINUX_KRELEASE) $(PREBUILT_KERNEL_DIR) || true
	$(Q)[ -n "$(STRIP_CMD)" ] && $(STRIP_CMD) $(PREBUILT_KERNEL_DIR)/$(notdir $(ORIIMG)) 2>/dev/null || true
	$(Q)[ -n "$(UORIIMG)" -a -f "$(LINUX_UKIMAGE)" ] && cp -v $(LINUX_UKIMAGE) $(PREBUILT_KERNEL_DIR) || true
	$(Q)[ -n "$(DTS)" -a -f "$(LINUX_DTB)" ] && cp -v $(LINUX_DTB) $(PREBUILT_KERNEL_DIR) || true

# Targets for real boards
ifeq ($(_VIRT),0)

# Remote automatical login related parts
COM ?= ssh

# The ip address of target board, must make sure python3-serial is installed
ifeq ($(shell [ -c $(BOARD_SERIAL) ] && sudo sh -c 'echo > $(BOARD_SERIAL)' 2>/dev/null; echo $$?),0)
  GETIP_TOOL     ?= $(TOP_DIR)/tools/helper/getip.py
  GETIP_TIMEOUT  ?= 2
  BOARD_IP       ?= $$(sudo timeout $(GETIP_TIMEOUT) python3 $(GETIP_TOOL) $(BOARD_SERIAL) $(BOARD_BAUDRATE))
else
  BOARD_IP ?= $$(for ip in $(BOARD_IP_LIST); do ping -c1 -W1 $$ip >/dev/null 2>&1 && echo $$ip && break; done)
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

SSH_PASS  := sshpass -p $(BOARD_PASS)
SSH_CMD   := $(SSH_PASS) ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t $(BOARD_USER)@$(BOARD_IP)
SCP_CMD   := $(SSH_PASS) scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

SSH_RSH   := --rsh='sshpass -e ssh -l $(BOARD_USER) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no '
RSYNC_CMD ?= SSHPASS=$(BOARD_PASS) rsync -av $(SSH_RSH)

# KERNEL_RELEASE version info required by -upload and boot-config targets
ifneq ($(MAKECMDGOALS),)
 ifneq ($(filter $(firstword $(MAKECMDGOALS)),$(addsuffix -upload,kernel dtb module modules) boot-config boot upload),)
  KERNEL_RELEASE ?= $(shell cat $(KRELEASE))
  ifeq ($(KERNEL_RELEASE),)
    $(error Linux must be compiled before uploading)
  endif
 endif
endif

# Check ip variable
PING_RETRIES ?= 10

getip:
	$(Q)if [ -z "$(BOARD_IP)" ]; then \
	  echo "ERR: getip failed, $(BOARD_SERIAL) may not be there or connected by another client."; \
	  echo "ERR: If not have a serial cable, please configure IP manually via 'make local-config BOARD_IP=ip'"; \
	  false; \
	else \
	  ping -c1 -W1 $(BOARD_IP) >/dev/null 2>&1; \
          if [ $$? -ne 0 ]; then \
	    read -p "LOG: Please plugin or replug usb data cable between main board and host ..." tmp; \
	    echo "LOG: Waiting for $(BOARD_IP)"; ping_retries=$(PING_RETRIES); \
	    for i in `seq 1 $$ping_retries`; do ping -c1 -W1 $(BOARD_IP) && break; done; \
	    if [ $$i -eq $$ping_retries ]; then echo "ERR: Failed to connect $(BOARD_IP), please try again or plugin serial cable instead."; false; fi; \
	  fi; \
	fi

PHONY += getip

# Upload images to remote board

ifneq ($(findstring load,$(MAKECMDGOALS)),)
  FILE_UPDOWN := 1
endif
ifneq ($(findstring push,$(MAKECMDGOALS)),)
  FILE_UPDOWN := 1
endif
ifneq ($(findstring pull,$(MAKECMDGOALS)),)
  FILE_UPDOWN := 1
endif

ifeq ($(FILE_UPDOWN),1)
LOCAL_MODULES  ?= $(ROOTDIR)/lib/modules/$(KERNEL_RELEASE)
LOCAL_KIMAGE   ?= $(KIMAGE)
LOCAL_DTB      ?= $(DTB)
LOCAL_BIMAGE   ?= $(BIMAGE)
REMOTE_MODULES ?= /lib/modules/$(KERNEL_RELEASE)
REMOTE_KIMAGE  ?= /boot/vmlinuz-$(KERNEL_RELEASE)
REMOTE_DTB     ?= /boot/dtbs/$(KERNEL_RELEASE)/$(DIMAGE)
REMOTE_BIMAGE  ?= /boot/$(BIMAGE)

uboot-upload: getip $(LOCAL_BIMAGE)
	$(Q)echo "LOG: Upload uboot image from $(LOCAL_BIMAGE) to $(BOARD_IP):$(REMOTE_BIMAGE)"
	$(Q)$(SSH_CMD) 'rm -f $(REMOTE_IMAGE); mkdir -p $(dir $(REMOTE_BIMAGE))'
	$(Q)$(SCP_CMD) $(LOCAL_BIMAGE) $(BOARD_USER)@$(BOARD_IP):$(REMOTE_BIMAGE)

ifneq ($(DTS),)
dtb-upload: getip $(LOCAL_DTB)
	$(Q)echo "LOG: Upload dtb image from $(LOCAL_DTB) to $(BOARD_IP):$(REMOTE_DTB)"
	$(Q)$(SSH_CMD) 'rm -f $(REMOTE_DTB); mkdir -p $(dir $(REMOTE_DTB))'
	$(Q)$(SCP_CMD) $(LOCAL_DTB) $(BOARD_USER)@$(BOARD_IP):$(REMOTE_DTB)
endif

kernel-upload: getip $(LOCAL_KIMAGE)
	$(Q)echo "LOG: Upload kernel image from $(LOCAL_KIMAGE) to $(BOARD_IP):$(REMOTE_KIMAGE)"
	$(Q)$(SSH_CMD) 'rm -f $(REMOTE_IMAGE); mkdir -p $(dir $(REMOTE_KIMAGE))'
	$(Q)$(SCP_CMD) $(LOCAL_KIMAGE) $(BOARD_USER)@$(BOARD_IP):$(REMOTE_KIMAGE)

module-upload: modules-upload

modules-upload: getip modules-install
	$(Q)echo "LOG: Upload modules from $(LOCAL_MODULES) to $(BOARD_IP):$(REMOTE_MODULES)"
	$(Q)rm -f $(LOCAL_MODULES)/source $(LOCAL_MODULES)/build
	$(Q)$(SSH_CMD) 'mkdir -p $(REMOTE_MODULES)'
	$(Q)if echo $(RSYNC_CMD) | grep -q rsync; then \
	  $(RSYNC_CMD) $(LOCAL_MODULES)/* $(BOARD_IP):$(REMOTE_MODULES)/; \
	else \
	  $(RSYNC_CMD) $(LOCAL_MODULES)/* $(BOARD_USER)@$(BOARD_IP):$(REMOTE_MODULES)/; \
	fi

# Both push and pull have only two arguments
ifeq ($(filter $(first_target),push pull file-upload file-download),$(first_target))
ARGS := $(strip $(subst xyz$(first_target),,xyz$(MAKECMDGOALS)))
ONE := $(firstword $(ARGS))
ANOTHER := $(lastword $(ARGS))

ifeq ($(ARGS),)
  $(error ERR: At least one file argument must be specified to push or pull, for example, make push ./local-file; make pull /remote-file)
endif

# Ignore 'targets' of push and pull
$(eval $(ARGS):FORCE;@:)
PHONY += $(ARGS)

ifeq ($(filter $(first_target),push file-upload),$(first_target))
  ifeq ($(ANOTHER),$(ONE))
    ANOTHER := /
  endif
endif
ifeq ($(filter $(first_target),pull file-download),$(first_target))
  ifeq ($(ANOTHER),$(ONE))
    ANOTHER := ./
  endif
endif

endif

push: file-upload
file-upload: getip
	$(Q)echo "LOG: Pushing local '$(ONE)' to remote '$(ANOTHER)'"
	$(Q)$(SSH_CMD) 'mkdir -p $(dir $(ANOTHER))'
	$(Q)if echo $(RSYNC_CMD) | grep -q rsync; then \
	  $(RSYNC_CMD) $(ONE) $(BOARD_IP):$(ANOTHER); \
	else \
	  $(RSYNC_CMD) $(ONE) $(BOARD_USER)@$(BOARD_IP):$(ANOTHER); \
	fi

pull: file-download
file-download: getip
	$(Q)echo "LOG: Pulling remote '$(ONE)' to local '$(ANOTHER)'"
	$(Q)$(SSH_CMD) 'mkdir -p $(dir $(ANOTHER))'
	$(Q)if echo $(RSYNC_CMD) | grep -q rsync; then \
	  $(RSYNC_CMD) $(BOARD_IP):$(ONE) $(ANOTHER); \
	else \
	  $(RSYNC_CMD) $(BOARD_USER)@$(BOARD_IP):$(ONE) $(ANOTHER); \
	fi

# Add dummmy entries for upload target
ifeq ($(first_target), upload)
$(addsuffix -upload, root qemu):
endif

PHONY += $(addsuffix -upload,kernel dtb module modules root uboot qemu file) upload push pull file-download

endif # -upload

BOOT_CONFIG ?= uEnv
ifneq ($(BOOT_CONFIG),uEnv)
  $(error Only support uEnv configure method currently)
endif

ifeq ($(shell [ -c $(BOARD_SERIAL) -a $(COM) != "ssh" ] && sudo sh -c 'echo > $(BOARD_SERIAL)' 2>/dev/null; echo $$?),0)
  COM ?= serial
else
  COM ?= ssh
endif

ifeq (run,$(first_target))
CMD := $(strip $(subst xyz$(first_target),,xyz$(MAKECMDGOALS)))

ifeq ($(CMD),)
  $(error ERR: At least one command must be specified to run, for example, make run ls /)
endif

# Ignore 'targets' of run
$(eval $(CMD):FORCE;@:)
PHONY += $(CMD)
endif

ifneq ($(COM),serial)
boot-config: getip
	$(Q)echo "LOG: Configure new kernel and dtbs images"
	$(Q)$(SSH_CMD) 'if [ -f /boot/uEnv.txt ]; then sed -i -e "s/uname_r=.*/uname_r=$(KERNEL_RELEASE)/g" /boot/uEnv.txt; fi'
	$(Q)$(SSH_CMD) 'if [ -f /boot/uEnv.txt ]; then sed -i -e "s/dtb=.*/dtb=$(DIMAGE)/g" /boot/uEnv.txt; fi'

reboot: getip
	$(Q)echo "LOG: Rebooting via ssh"
	$(Q)$(SSH_CMD) 'sudo reboot 2>/dev/null | reboot' || true
	$(Q)sleep 1

poweroff: shutdown
shutdown: getip
	$(Q)echo "LOG: Powering off via ssh"
	$(Q)$(SSH_CMD) 'sudo poweroff 2>/dev/null | poweroff' || true
	$(Q)sleep 1

run: getip
	$(Q)echo "LOG: Running command via ssh: $(CMD)"
	$(Q)$(SSH_CMD) '$(CMD)' || true
else

REBOOT_CMD = sudo tools/helper/reboot.py $(BOARD_SERIAL) $(BOARD_BAUDRATE)
SHUTDOWN_CMD = sudo tools/helper/poweroff.py $(BOARD_SERIAL) $(BOARD_BAUDRATE)
RUN_CMD = sudo tools/helper/run.py $(BOARD_SERIAL) $(BOARD_BAUDRATE) $(BOARD_USER) $(BOARD_PASS)

boot-config:
	$(Q)echo "LOG: Before booting, please upload or burn images manually"
reboot:
	$(Q)echo "LOG: Rebooting via serial"
	$(Q)$(REBOOT_CMD) || true
	$(Q)sleep 1

poweroff: shutdown
shutdown:
	$(Q)echo "LOG: Powering off via serial"
	$(Q)$(SHUTDOWN_CMD) || true
	$(Q)sleep 1

run:
	$(Q)echo "LOG: Running command via serial: $(CMD)"
	$(Q)$(RUN_CMD) '$(CMD)' || true
endif

PHONY += boot-config reboot

endif # for real boards

uboot-save:
	$(Q)mkdir -p $(PREBUILT_UBOOT_DIR)
	$(Q)cp -v $(UBOOT_BIMAGE) $(PREBUILT_UBOOT_DIR) || true


qemu-save:
	$(Q)mkdir -p $(PREBUILT_QEMU_DIR)
	$(Q)$(call make_qemu,install) || true
	$(Q)$(foreach _QEMU_TARGET,$(subst $(comma),$(space),$(QEMU_TARGET)),$(call make_qemu,install,$(_QEMU_TARGET)) || true;echo '';)

uboot-saveconfig:
	$(Q)$(call make_uboot,savedefconfig) || true
	$(Q)if [ -f $(UBOOT_BUILD)/defconfig ]; then \
	  cp -v $(UBOOT_BUILD)/defconfig $(BSP_CONFIG)/$(UBOOT_CONFIG_FILE); \
	else \
	  cp -v $(UBOOT_BUILD)/.config $(BSP_CONFIG)/$(UBOOT_CONFIG_FILE); \
	fi

# kernel < 2.6.36 doesn't support: `make savedefconfig`
kernel-saveconfig:
	$(Q)$(call make_kernel,savedefconfig M=) || true
	$(Q)if [ -f $(KERNEL_BUILD)/defconfig ]; then \
	  cp -v $(KERNEL_BUILD)/defconfig $(BSP_CONFIG)/$(KERNEL_CONFIG_FILE); \
	else \
	  cp -v $(KERNEL_BUILD)/.config $(BSP_CONFIG)/$(KERNEL_CONFIG_FILE); \
	fi

root-saveconfig:
	$(Q)$(call make_root,savedefconfig) || true
	$(Q)defconfig=$$(grep BR2_DEFCONFIG $(ROOT_BUILD)/.config | cut -d '=' -f2 | tr -d '"'); \
	if [ $$? -eq 0 -a -n "$$defconfig" -a -f "$$defconfig" ]; then \
	  cp -v $$defconfig $(BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	elif [ -f $(ROOT_BUILD)/defconfig ]; then \
	  cp -v $(ROOT_BUILD)/defconfig $(BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	else \
	  cp -v $(ROOT_BUILD)/.config $(BSP_CONFIG)/$(ROOT_CONFIG_FILE); \
	fi

# For virtual boards
ifeq ($(_VIRT),1)

# Qemu options and kernel command lines

# Network configurations

# Verify NETDEV argument
define netdev_help
 ifeq ($$(MACH), malta)
  EMULATOR += -kernel $(_KIMAGE)
 endif
 ifeq ($$(filter $(BOARD),riscv32/virt riscv64/virt loongson/ls1b loongson/ls2k),)
  $$(info $$(shell $(EMULATOR) -M $$(MACH) -net nic,model=?))
 endif
endef

$(eval $(call genverify,NETDEV,NETDEV,,netdev_help))

# TODO: net driver for $BOARD
ifneq ($(NETDEV),)
NET ?=  -net nic,model=$(call _v,NETDEV,LINUX) -net tap,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown
endif

ifeq ($(NETDEV), virtio)
  MACADDR_TOOL   := tools/qemu/macaddr.sh
  RANDOM_MACADDR := $$($(MACADDR_TOOL))
  VIRTIO_NET_DEVICE ?= virtio-net-device
  NET += -device $(VIRTIO_NET_DEVICE),netdev=net0,mac=$(RANDOM_MACADDR) -netdev tap,id=net0,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown
endif

# Kernel command line configuration
CMDLINE :=

# Init route and ip for guest
ROUTE := $$(ifconfig br0 | grep 'inet ' | tr -d -c '^[0-9. ]' | awk '{print $$1}')
TMP   := $$(bash -c 'echo $$(($$RANDOM%230+11))')
IP    := $$(echo $(ROUTE) | cut -d'.' -f1-3).$(TMP)

CMDLINE += route=$(ROUTE)

# Default iface
IFACE   ?= eth0
CMDLINE += iface=$(IFACE)

# New version of rpc.nfsd in nfs-kernel-server not support old nfs version 2, force using newer nfsver 3
ifneq ($(OS), trusty)
  NFSROOT_EXTRA ?= ,nolock,v3
endif

ifeq ($(ROOTDEV),/dev/nfs)
  nfsd=1
  ifeq ($(wildcard /proc/fs/nfsd),)
    nfsd=0
  endif
  ifeq ($(wildcard /proc/fs/nfs/exports),)
    nfsd=0
  endif
  ifeq ($(nfsd),0)
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

ifneq ($(findstring /dev/null,$(ROOTDEV)),)
  CMDLINE += rdinit=$(RDINIT)
else
  CMDLINE += root=$(ROOTDEV)
endif

# Extra kernel command line
CMDLINE += $(call _v,XKCLI,LINUX)
CMDLINE += $(call _v,KCLI,LINUX)

# Graphic output? we prefer Serial port ;-)
G ?= 0

# Force using curses based graphic mode for bash/ssh login
ifneq ($(shell env | grep -q ^DISPLAY; echo $$?), 0)
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
ifneq ($(findstring force-,$(MAKECMDGOALS)),)
  ifneq ($(findstring -checkout,$(MAKECMDGOALS)),)
    FORCE_CHECKOUT ?= 1
  endif
endif
ifeq ($(FORCE_CHECKOUT),1)
  GIT_CHECKOUT_FORCE ?= -f
endif
ifeq ($(FAST_FETCH),1)
  GIT_FETCH_SHALLOW ?= 1
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
  TEST_FINISH   := poweroff
endif

ifeq ($(findstring reboot,$(TEST_FINISH)),)
  EXIT_ACTION ?= -no-reboot
endif

# SMP configuration
SMP ?= 1

# If proxy kernel exists, hack the default -kernel option
ifneq ($(PORIIMG),)
  KERNEL_OPT   ?= -kernel $(PKIMAGE) -device loader,file=$(QEMU_KIMAGE),addr=$(KRN_ADDR)
else
  ifeq ($(U),1)
    KERNEL_OPT ?= $(if $(findstring 1,$(UBOOT_BIOS)),-bios,-kernel) $(QEMU_KIMAGE)
  else
    KERNEL_OPT ?= $(if $(findstring 1,$(KERNEL_BIOS)),-bios,-kernel) $(QEMU_KIMAGE)
  endif
endif

ifeq ($(DUMPDTB), 1)
  QEMU_DTB ?= $(BSP_KERNEL)/$(LINUX)/qemu-$(XARCH)-$(MACH).dtb
  QEMU_DTS := $(QEMU_DTB:.dtb=.dts)
  DUMPDTB_OPT ?= dumpdtb=$(QEMU_DTB)
  DUMPDTB_CMD ?= $(Q)[ -f $(QEMU_DTB) ] && sudo chown $(USER):$(USER) $(QEMU_DTB) && dtc -o $(QEMU_DTS) -O dts -I dtb $(QEMU_DTB)
  MACH_OPT += $(DUMPDTB_OPT)
endif

MACH_OPT := $(subst $(space),,$(addprefix $(comma),$(MACH_OPT)))
EMULATOR_OPTS ?= -M $(MACH)$(MACH_OPT) $(if $(CPU),-cpu $(CPU)) -m $(call _v,MEM,LINUX) $(NET) -smp $(call _v,SMP,LINUX) $(KERNEL_OPT) $(EXIT_ACTION)
EMULATOR_OPTS += $(SHARE_OPT)

D ?= 0
DEBUG ?= $(D)

# Launch Qemu, prefer our own instead of the prebuilt one
BOOT_CMD := sudo prlimit -n1024 $(EMULATOR) $(EMULATOR_OPTS)

ifeq ($(U),1)
  ifeq ($(SD_BOOT),1)
    BOOT_CMD += -drive if=sd,file=$(SD_IMG),format=raw,id=sd0
  endif
  ifeq ($(RAM_BOOT),1)
    BOOT_CMD += -device loader,file=$(UKIMAGE),addr=$(KRN_ADDR)
    ifneq ($(DTB_ADDR),-)
      ifneq ($(DTB_ADDR),$$fdtcontroladdr)
        BOOT_CMD += -device loader,file=$(DTB),addr=$(DTB_ADDR)
      endif
    endif
    ifneq ($(findstring /dev/ram,$(ROOTDEV)),)
      ifneq ($(RDK_ADDR),-)
        BOOT_CMD += -device loader,file=$(UROOTFS),addr=$(RDK_ADDR)
      endif
    endif
  endif
  ifeq ($(ENV_DEV),ram)
    BOOT_CMD += -device loader,file=$(ENV_IMG),addr=$(ENV_ADDR)
  endif

  ifneq ($(PFLASH_SIZE),0)
    # Load pflash for booting with uboot every time
    # pflash is at least used as the env storage
    # unit=1 means the second pflash, the first one is unit=0
    BOOT_CMD += -drive if=pflash,file=$(PFLASH_IMG),format=raw$(if $(findstring 1,$(UBOOT_BIOS)),$(comma)unit=1)
  endif
else # U != 1
  ifneq ($(findstring /dev/ram,$(ROOTDEV)),)
    INITRD ?= 1
  endif

  ifneq ($(INITRD),)
    ifneq ($(wildcard $(INITRD)),)
      BOOT_CMD += -initrd $(INITRD)
    else
      BOOT_CMD += -initrd $(IROOTFS)
    endif
  endif

  ifneq ($(DTB),)
    ifneq ($(wildcard $(DTB)),)
      BOOT_CMD += -dtb $(DTB)
    endif
  endif
endif # U != 1

ifneq ($(findstring /dev/hda,$(ROOTDEV)),)
  BOOT_CMD += -hda $(HROOTFS)
endif

ifneq ($(findstring /dev/sda,$(ROOTDEV)),)
  # Ref: https://blahcat.github.io/2018/01/07/building-a-debian-stretch-qemu-image-for-aarch64/
  ifeq ($(MACH), virt)
    BOOT_CMD += -drive if=none,file=$(HROOTFS),format=raw,id=virtio-sda -global virtio-blk-device.scsi=off -device virtio-scsi-device,id=scsi -device scsi-hd,drive=virtio-sda
  else
    BOOT_CMD += -hda $(HROOTFS)
  endif
endif

# FIXME: Currently, BOOTDEV and ROOTDEV can not be sed to sd/mmc at the same time
# but it should work when the rootfs is put in a specified partition of the same sdcard.
ifneq ($(findstring /dev/mmc,$(ROOTDEV)),)
  BOOT_CMD += -drive if=sd,file=$(HROOTFS),format=raw,id=mmc0
endif

ifneq ($(findstring /dev/vda,$(ROOTDEV)),)
  # Ref: https://wiki.debian.org/Arm64Qemu
  BOOT_CMD += -drive if=none,file=$(HROOTFS),format=raw,id=virtio-vda -device virtio-blk-device,drive=virtio-vda
endif

ifeq ($(G),0)
  BOOT_CMD   += -nographic
else
  ifeq ($(G), 2)
    BOOT_CMD += -curses
  endif
endif

# Frame buffer device support
ifeq ($(G),1)
  ifeq ($(FBDEV), virtio)
    BOOT_CMD += -device virtio-gpu-pci
  endif
  ifneq ($(filter $(FBDEV),bochs stdvga),)
    BOOT_CMD += -device VGA
  endif

  ifeq ($(KBDEV),virtio)
    BOOT_CMD += -device virtio-keyboard
  endif
endif # G=1

# Add extra qemu options
BOOT_CMD += $(XOPTS) $(XQOPT) $(QOPTS)

# Get DEBUG option if -debug found in goals
ifeq (debug,$(firstword $(MAKECMDGOALS)))
  DEBUG := $(app)
else
  ifneq ($(findstring debug,$(firstword $(MAKECMDGOALS))),)
    DEBUG := $(subst -,,$(subst debug,,$(firstword $(MAKECMDGOALS))))
  endif
endif

# Must disable the kaslr feature while debugging, otherwise, breakpoint will not stop and just continue
# ref: https://unix.stackexchange.com/questions/396013/hardware-breakpoint-in-gdb-qemu-missing-start-kernel
#      https://www.spinics.net/lists/newbies/msg59708.html
ifneq ($(DEBUG),0)
  BOOT_CMD   += -s
  # workaround error of x86_64: "Remote 'g' packet reply is too long:", just skip the "-S" option
  ifneq ($(XARCH),x86_64)
    BOOT_CMD += -S
  endif
  CMDLINE    += nokaslr
endif

# Debug not work with -enable-kvm
# KVM speedup for x86 architecture, assume our host is x86 currently
ifeq ($(DEBUG),0)
  KVM_DEV ?= /dev/kvm
  ifneq ($(filter $(XARCH),i386 x86_64),)
    ifneq ($(wildcard $(KVM_DEV)),)
      BOOT_CMD += -enable-kvm
    endif
  endif
endif

# ROOTDEV=/dev/nfs for file sharing between guest and host
# SHARE=1 is another method, but only work on some boards

SYSTEM_TOOL_DIR := $(TOP_SRC)/system/tools

boot-init: FORCE
	$(Q)echo "Running $@"
	$(Q)$(if $(FEATURE),$(foreach i, $(subst $(comma),$(space),$(FEATURE)), \
		[ -x $(SYSTEM_TOOL_DIR)/$i/test_host_before.sh ] && \
		$(SYSTEM_TOOL_DIR)/$i/test_host_before.sh $(ROOTDIR);) echo '')

boot-finish: FORCE
	$(Q)echo "Running $@"
	$(Q)$(if $(FEATURE),$(foreach i, $(subst $(comma),$(space),$(FEATURE)), \
		[ -x $(SYSTEM_TOOL_DIR)/$i/test_host_after.sh ] && \
		$(SYSTEM_TOOL_DIR)/$i/test_host_after.sh $(ROOTDIR);) echo '')

PHONY += boot-init boot-finish

# Test support
ifneq ($(TEST),)
 ifneq ($(filter _boot, $(MAKECMDGOALS)),)
  TEST_KCLI :=
  ifneq ($(FEATURE),)
    TEST_KCLI += feature=$(subst $(space),$(comma),$(strip $(FEATURE)))
    ifneq ($(findstring module,$(FEATURE)),)
      TEST_KCLI += module=$(subst $(space),$(comma),$(strip $(MODULE)))
    endif
  endif
  ifeq ($(REBOOT_TYPE), reboot)
    ifneq ($(TEST_REBOOT),0)
      TEST_KCLI += reboot=$(TEST_REBOOT)
    endif
  endif
  ifneq ($(TEST_BEGIN),)
    TEST_KCLI += test_begin='$(TEST_BEGIN)'
  endif
  ifneq ($(TEST_END),)
    TEST_KCLI += test_end='$(TEST_END)'
  endif
  ifneq ($(TEST_FINISH),)
    TEST_KCLI += test_finish='$(TEST_FINISH)'
  endif

  TEST_CASE ?= $(TEST_CASES)
  ifneq ($(TEST_CASE),)
    TEST_KCLI += test_case='$(TEST_CASE)'
  endif

  MODULE_ARGS := $(foreach m_args,$(addsuffix _args,$(subst $(comma),$(space),$(MODULE))), $(shell eval "echo $(m_args)=\"'\$$$(m_args)'\""))

  TEST_KCLI += $(MODULE_ARGS)

  CMDLINE += $(TEST_KCLI)
 endif
endif

# Strip begin,end and duplicated spaces
CMDLINE  := $(subst $space$space,$space,$(strip $(CMDLINE)))

ifneq ($(U),1)
  BOOT_CMD += $(if $(findstring -kernel,$(BOOT_CMD)),-append "$(CMDLINE)")
endif

ifneq ($(TEST_REBOOT), 0)
  ifneq ($(findstring power,$(REBOOT_TYPE)),)
    BOOT_TEST := loop
  endif
else
    BOOT_TEST := default
endif

# By default, seconds
TIMEOUT      ?= 0
TEST_TIMEOUT ?= $(TIMEOUT)
TEST_UBOOT   ?= $(U)

ifneq ($(TEST_TIMEOUT),0)
  TEST_ENV        ?= $$TEST_LOGGING/boot.env
  TEST_LOG        ?= $$TEST_LOGGING/boot.log
  TEST_RET        ?= $$TEST_LOGGING/boot.ret

  # Allow test continue if the board always hang after poweroff, please pass TIMEOUT_CONTINUE=1
  TIMEOUT_CONTINUE ?= 0

  KERNEL_OFF  = reboot: System halted|reboot: Power down|Kernel panic|Rebooting
  KERNEL_INIT = Linux Version
  KERNEL_FINI = Freeing .* memory
  INIT_RUN    = Run .* as init process

  TEST_EXPECTED ?= $(KERNEL_OFF)

  TIMEOUT_CMD = t=$(TEST_TIMEOUT); \
	while [ $$t -gt 0 ]; do                                                        \
	    echo "detecting $(TEST_EXPECTED) ...";                                     \
	    if grep -qE "$(TEST_EXPECTED)" "$(TEST_LOG)"; then                         \
		sudo pkill -15 qemu-system-$(XARCH);                                   \
		echo "test finish"; t=1; TIMEOUT_RET=0; break;                         \
	    fi;                                                                        \
	    sleep 1; t=$$(expr $$t - 1);                                               \
	done;                                                                          \
	if [ $$t -le 0 ]; then sudo pkill -15 qemu-system-$(XARCH); echo "qemu-system-$(XARCH) timeout"; TIMEOUT_RET=1; fi

  TEST_LOGGING ?= TEST_LOGGING=$(TOP_DIR)/logging/$(XARCH)-$(MACH)-linux-$(LINUX)/$$(date +"%Y%m%d-%H%M%S")
  TEST_BEFORE ?= $(TEST_LOGGING); mkdir -p $$TEST_LOGGING && sync && make env-dump > $(TEST_ENV) && (
  TEST_AFTER  ?= | tee $(TEST_LOG) &); $(TIMEOUT_CMD); echo $$TIMEOUT_RET > $(TEST_RET); [ $(TIMEOUT_CONTINUE) -eq 1 ] && echo 0 > $(TEST_RET); \
	ret=$$(cat $(TEST_RET)) && rm $(TEST_RET) && [ $$ret -ne 0 ] && echo "ERR: Boot timeout in $(TEST_TIMEOUT)." && echo "ERR: Log saved in $(TEST_LOG)" && exit $$ret; \
	if [ $(TIMEOUT_CONTINUE) -eq 1 ]; then echo "LOG: Test continue after timeout kill in $(TEST_TIMEOUT)."; else echo "LOG: Boot run successfully."; fi; \
	if [ $(TIMEOUT_CONTINUE) -eq 1 ]; then sleep 2; fi
  # If not support netowrk, should use the other root device
endif

TEST_XOPTS ?= $(XOPTS)
TEST_RD    ?= $(or $(TEST_ROOTDEV),nfs)
# Override TEST_RD if ROOTDEV specified
ifeq ($(origin ROOTDEV), command line)
  TEST_RD  := $(ROOTDEV)
endif

export BOARD TEST_TIMEOUT TEST_LOGGING TEST_LOG TEST_LOG_PIPE TEST_LOG_PID TEST_XOPTS TEST_RET TEST_RD TEST_LOG_READER V

boot-test: bsp-checkout
	$(Q)echo "Running $@" ; \
	if [ "$(BOOT_TEST)" = "default" ]; then \
	  $(TEST_BEFORE) make $(NPD) _boot U=$(TEST_UBOOT) XOPTS="$(TEST_XOPTS)" TEST=default ROOTDEV=$(TEST_RD) FEATURE=boot$(if $(FEATURE),$(comma)$(FEATURE)) $(TEST_AFTER); \
	else \
	  for r in $$(seq 0 $(TEST_REBOOT)); do \
	    echo "\nRebooting test: $$r\n"; \
	    $(TEST_BEFORE) make $(NPD) _boot U=$(TEST_UBOOT) XOPTS="$(TEST_XOPTS)" TEST=default ROOTDEV=$(TEST_RD) FEATURE=boot$(if $(FEATURE),$(comma)$(FEATURE)) $(TEST_AFTER); \
	  done ; \
	fi

raw-test: $(TEST_PREPARE) boot-init boot-test boot-finish FORCE

PHONY += raw-test boot-test

# Allow to disable feature-init

TEST_INIT    ?= 1
TI           ?= $(TEST_INIT)
FEATURE_INIT ?= $(TI)
FI           ?= $(FEATURE_INIT)

KERNEL_INIT_DEPS := kernel-olddefconfig
# without obvious defconfig trigger, olddefconfig may not work when the source is not downloaded.
ifeq ($(wildcard $(KERNEL_CONFIG_DIR)),)
  KERNEL_INIT_DEPS := kernel-defconfig kernel-olddefconfig
endif

ifeq ($(MENUCONFIG),1)
  KERNEL_INIT_DEPS += kernel-menuconfig
endif
ifeq ($(SAVECONFIG),1)
  KERNEL_INIT_DEPS += kernel-saveconfig
endif

kernel-init: $(KERNEL_INIT_DEPS) $(KERNEL_DEPS)
	$(call make_kernel,$(IMAGE))

feature-init: $(if $(FEATURE),feature kernel-init) FORCE

PHONY += kernel-init feature-init

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
ifneq ($(shell which gdb-multiarch),)
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

ifneq ($(wildcard $(GDBINIT_DIR)/kernel.user),)
  GDB_INIT_KERNEL ?= kernel.user
else
  GDB_INIT_KERNEL ?= kernel.default
endif

ifneq ($(wildcard $(GDBINIT_DIR)/uboot.user),)
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

HOME_GDB_INIT  ?= $(HOME)/.gdbinit
# Force run as ubuntu to avoid permission issue of .gdbinit and ~/.gdbinit
GDB_USER       ?= $(USER)

# FIXME: gdb not continue the commands in .gdbinit while runing with 'CASE=debug tools/testing/run.sh'
#        just ignore the do_fork breakpoint to workaround it.
_debug:
	$(Q)cp -v $(notdir $(GDBINIT_DIR))/$(notdir $(GDB_INIT)) .gdbinit
	$(Q)sudo -u $(GDB_USER) echo "add-auto-load-safe-path .gdbinit" > $(HOME_GDB_INIT)

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
# Always update initrd with src/system
ifneq ($(INITRD),)
  _BOOT_DEPS += root-rd-rebuild
endif
ifneq ($(BOOT_PREPARE),)
  override BOOT_PREPARE := $(subst $(comma),$(space),$(BOOT_PREPARE))
  _BOOT_DEPS += $(BOOT_PREPARE)
endif
_BOOT_DEPS += $(BOARD_SAVE)
# kernel builtin initramfs must be prepared before building kernel image
ifneq ($(ROOTDEV),/dev/null)
_BOOT_DEPS += root-$(DEV_TYPE)
endif
_BOOT_DEPS += $(UBOOT_IMGS)
_BOOT_DEPS += $(DEBUG_CLIENT)
_BOOT_DEPS += $(BOOT_DTB)

ifneq ($(DEBUG),0)
  # Debug listen on a unqiue port, should run exclusively
  DEBUG_LOCK   := $(GDBINIT_DIR)/.lock
  KEEP_UNIQUE  := flock -n -x $(DEBUG_LOCK)
  RUN_BOOT_CMD := tmux new-session -d '$(KEEP_UNIQUE) $(BOOT_CMD)' \; split-window -h '$(GDB_CMD)' \; attach
else
  RUN_BOOT_CMD := $(BOOT_CMD)
endif

# just map reboot to boot for virtual board
reboot login: _boot

PHONY += reboot login

else

# For real boards

# FIXME: The real boot should be able to control the power button Here it is
# only connect or login.

ifeq ($(shell [ -c $(BOARD_SERIAL) -a $(COM) != "ssh" ] && sudo sh -c 'echo > $(BOARD_SERIAL)' 2>/dev/null; echo $$?),0)
  RUN_BOOT_CMD ?= $(Q)echo "LOG: Login via serial port" && sudo minicom -D $(BOARD_SERIAL) -b $(BOARD_BAUDRATE)
else
  ifneq ($(findstring boot,$(MAKECMDGOALS)),)
    RUN_BOOT_CMD ?= $(Q)echo "LOG: Please run 'make login' manually after board rebooted" || true
  else
    RUN_BOOT_CMD ?= $(Q)echo "LOG: Login via ssh protocol" && $(SSH_CMD) -t '/bin/sh' || true
  endif
  GETIP := getip
endif

ifneq ($(findstring boot,$(MAKECMDGOALS)),)
  _BOOT_DEPS := $(GETIP) boot-config reboot
endif
ifneq ($(findstring login,$(MAKECMDGOALS)),)
  _BOOT_DEPS := $(GETIP)
endif

_test _debug:
	$(Q)echo "LOG: This feature is not implemented for real boards."

login: _boot

PHONY += login

endif

_boot: $(_BOOT_DEPS)
	$(Q)$(call check_license,bsp)
	$(RUN_BOOT_CMD)
	$(DUMPDTB_CMD)

PHONY += boot-test _boot

# Show the variables
ifneq ($(filter env-dump,$(MAKECMDGOALS)),)
VARS := $(shell $(call getboardvars))
VARS += PBK PBR PBD PBQ PBU
VARS += BOARD FEATURE TFTPBOOT
VARS += ROOTDIR ROOT_SRC ROOT_BUILD ROOT_GIT
VARS += KERNEL_SRC KERNEL_BUILD KERNEL_GIT KERNEL_FORK UBOOT_SRC UBOOT_BUILD UBOOT_GIT
VARS += ROOT_CONFIG_PATH KERNEL_CONFIG_PATH UBOOT_CONFIG_PATH
VARS += IP ROUTE BOOT_CMD
VARS += LINUX_DTB QEMU_PATH QEMU_SYSTEM
VARS += TEST_TIMEOUT TEST_RD
endif

tools-install:
	$(Q)[ -n "$(PKGS)" ] && tools/deps/install.sh '$(PKGS)' || true

_env: env-prepare
env-prepare: toolchain-install tools-install

env-list: env-dump
env-dump:
	@echo \#[ $(BOARD) ]:
	@echo -n " "
	@echo $(foreach v,$(or $(VAR),$(VARS)),"    $(v)=\"$($(v))\"\n") | tr -s '/' | uniq || true

env-save: board-config

default-help:
	$(Q)less README_zh.md

PHONY += _env env $(addprefix env-,list prepare dump save) default-help tools-install

# memory building support
BUILD_CACHE_TOOL   := tools/build/cache
BUILD_FREE_TOOL    := tools/build/free
BUILD_UNCACHE_TOOL := tools/build/uncache
BUILD_BACKUP_TOOL  := tools/build/backup

BUILD_CACHE_TAG := $(TOP_BUILD)/linux-lab.cache.signed

ifeq ($(MAKECMDGOALS),cache-build)
cache-build: status-build
endif
ifeq ($(MAKECMDGOALS),build cache)
cache-build: status-build
endif

cache-build: $(BUILD_CACHE_TAG)

$(BUILD_CACHE_TAG):
	@echo "Cache building ..."; echo; \
	sudo service nfs-kernel-server stop;   \
	sudo $(BUILD_CACHE_TOOL) && touch $(BUILD_CACHE_TAG) || true; \
	sudo service nfs-kernel-server start

status-build:
	@if grep -q $(TOP_BUILD) /proc/mounts >/dev/null 2>&1; then \
	  echo "Building cache free status:"; \
	  sudo $(BUILD_FREE_TOOL) || true; \
	else \
	  echo "No cache created for building"; echo; \
	fi

uncache-build:
	@echo "Uncache building ..."; echo; \
	sudo service nfs-kernel-server stop;   \
	sudo $(BUILD_UNCACHE_TOOL) || true; \
	[ "x$(HOST_OS)" != "xWindows" ] && sudo service nfs-kernel-server start || true

backup-build:
	@echo "Backing up Cache ..."; echo; \
	sudo $(BUILD_BACKUP_TOOL) || true

PHONY += $(addsuffix -build,cache status uncache backup)

# include $(TOP_DIR)/.labend if exist
$(eval $(call _ti,labend))

# include $(TOP_DIR)/.labfini if exist
$(eval $(call _ti,labfini))

# add alias for linux and buildroot targets
aliastarget := $(if $(APP_ARGS),$(filter $APP_ARGS,$(call genaliastarget)),$(call genaliastarget))
ifneq ($(aliastarget),)
$(aliastarget):
	$(Q)make $(NPD) $(call genaliassource,$@)
PHONY += $(aliastarget)
endif

$(addsuffix -%,$(call genaliastarget)): FORCE
	$(Q)$(if $(findstring /,$@),,make $(NPD) $(call genaliassource,$@))

ifeq ($(findstring n,$(MFLAGS)),)
$(addsuffix -%,$(APPS)):
	$(Q)$(if $(word 2,$(subst -,$(space),$@)),make $(S) -n $@ >/dev/null 2>&1 || make $(NPD) $(firstword $(subst -,$(space),$@)) x=$(subst $(firstword $(subst -,$(space),$@))-,,$@) || true)
endif

ifneq ($(APP_ARGS),)
# ...and turn them into do-nothing targets
$(eval $(APP_ARGS):FORCE;@:)
PHONY += $(APP_ARGS)
endif

ifneq ($(filter $(first_target),$(APP_TARGETS)),)
PREFIX_TARGETS := list
define real_target
$(if $(filter $1,$(PREFIX_TARGETS)),$1-$2,$2-$1)
endef

ifneq ($(BOARD_DOWNLOAD),)
$(APP_TARGETS): $(BOARD_DOWNLOAD)
	$(Q)make $(NPD) $(foreach a,$(app),$(call real_target,$(first_target),$(a)) )
else
$(APP_TARGETS): $(foreach a,$(app),$(call real_target,$(first_target),$(a)) )
endif

PHONY += $(APP_TARGETS)
endif

PHONY += $(APPS) $(patsubst %,_%,$(APPS))

# Allow cleanstamp and run a target
force-%:
	$(Q)make $(NPD) $(subst force-,,$@)-cleanstamp
	$(Q)make $(NPD) $(subst force-,,$@)

FORCE:

PHONY += FORCE

.PHONY: $(PHONY)
