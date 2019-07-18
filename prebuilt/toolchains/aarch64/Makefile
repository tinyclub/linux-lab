# Makefile

CCORI ?= bootlin
CCORI_LIST ?= internal bootlin linaro arm
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)

ifeq ($(CCORI), internal)
  CCPRE   ?= aarch64-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
  CCTYPE  := internal
else
  CCTYPE  := external
endif

ifeq ($(CCORI), bootlin)
  CCVER   ?= 2018.11-1
  CCPRE   ?= $(XARCH)-linux-
  CCBASE  ?= aarch64--uclibc--stable-$(CCVER)
  CCPATH  ?= $(TOOLCHAIN)/$(CCBASE)/bin
  CCURL    = https://toolchains.bootlin.com/downloads/releases/toolchains/$(XARCH)/tarballs/$(CCBASE).tar.bz2
endif

ifeq ($(CCORI), linaro)
  CCVER   ?= 7.4.1-2019.02
  CCPRE   ?= $(XARCH)-linux-gnu-
  CCBASE   = gcc-linaro-$(CCVER)-x86_64_$(XARCH)-linux-gnu
  CCPATH  ?= $(TOOLCHAIN)/gcc-linaro-$(CCVER)-x86_64_aarch64-linux-gnu/bin

  empty    =
  space    = $(empty) $(empty)
  tmp      = $(subst -,$(space),$(CCVER))
  _CCVER   = $(basename $(firstword $(tmp)))-$(lastword $(tmp))

  CCURL    = https://releases.linaro.org/components/toolchain/binaries/$(_CCVER)/$(XARCH)-linux-gnu/$(CCBASE).tar.xz
endif

ifeq ($(CCORI), arm)
  CCVER   ?= 8.3-2019.03
  CCPRE   ?= $(XARCH)-linux-gnu-
  CCBASE   = gcc-arm-$(CCVER)-x86_64-$(XARCH)-linux-gnu
  CCPATH  ?= $(TOOLCHAIN)/gcc-arm-$(CCVER)-x86_64-aarch64-linux-gnu/bin
  CCURL    = https://developer.arm.com/-/media/Files/downloads/gnu-a/$(CCVER)/binrel/$(CCBASE).tar.xz
endif
