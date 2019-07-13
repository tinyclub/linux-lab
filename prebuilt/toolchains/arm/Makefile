
TC_ORIG ?= bootlin

ifeq ($(TC_ORIG), bootlin)
  TC_VERSION ?= 2018.11-1
  TC_ARCH ?= armv7-eabihf

  TC_BASE = $(TC_ARCH)--uclibc--stable-$(TC_VERSION)
  TC_URL  = https://toolchains.bootlin.com/downloads/releases/toolchains/$(TC_ARCH)/tarballs/$(TC_BASE).tar.bz2
endif

ifeq ($(TC_ORIG), linaro)
  TC_VERSION ?= 7.4.1-2019.02
  TC_ARCH ?= arm
  
  empty =
  space = $(empty) $(empty)
  tmp = $(subst -,$(space),$(TC_VERSION))
  _TC_VERSION = $(basename $(firstword $(tmp)))-$(lastword $(tmp))
  
  TC_BASE = gcc-linaro-$(TC_VERSION)-x86_64_$(TC_ARCH)-linux-gnueabi
  TC_URL  = https://releases.linaro.org/components/toolchain/binaries/$(_TC_VERSION)/$(TC_ARCH)-linux-gnueabi/$(TC_BASE).tar.xz
endif

ifeq ($(TC_ORIG), arm)
  TC_VERSION ?= 8.3-2019.03
  TC_ARCH ?= arm

  TC_BASE = gcc-arm-$(TC_VERSION)-x86_64-$(TC_ARCH)-linux-gnueabi
  TC_URL  = https://developer.arm.com/-/media/Files/downloads/gnu-a/$(TC_VERSION)/binrel/$(TC_BASE).tar.xz
endif

include ../Makefile.lib
