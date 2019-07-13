# ref: https://sifive.com/boards
#      https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v8.2.0-2.2-20190521/gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-centos64.tgz
#      https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs/riscv64--glibc--bleeding-edge-2018.11-1.tar.bz2

TC_ORIG ?= bootlin
TC_ARCH ?= riscv64

ifeq ($(TC_ORIG), bootlin)
  TC_VERSION ?= 2018.11-1

  TC_BASE = $(TC_ARCH)--glibc--bleeding-edge-$(TC_VERSION)
  TC_URL  = https://toolchains.bootlin.com/downloads/releases/toolchains/$(TC_ARCH)/tarballs/$(TC_BASE).tar.bz2
endif

ifeq ($(TC_ORIG), gnu-mcu-eclipse)
  TC_VERSION ?= 8.2.0-2.2-20190521-0004

  empty =
  space = $(empty) $(empty)
  tmp = $(subst -,$(space),$(TC_VERSION))
  _TC_VERSION = v$(subst -$(lastword $(tmp)),,$(TC_VERSION))

  TC_BASE = gnu-mcu-eclipse-riscv-none-gcc-$(TC_VERSION)-centos64
  TC_URL  = https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/$(_TC_VERSION)/$(TC_BASE).tgz
endif

include ../Makefile.lib
