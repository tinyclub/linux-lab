# Makefile

CCORI ?= gnu-mcu-eclipse
CCORI_LIST ?= internal bootlin gnu-mcu-eclipse
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/riscv64

ifeq ($(CCORI), internal)
  CCPRE   ?= riscv64-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
endif

ifeq ($(CCORI), bootlin)
  CCPRE  ?= riscv64-linux-
  CCVER  ?= 2018.11-1
  CCBASE  = riscv64--glibc--bleeding-edge-$(CCVER)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  CCURL   = https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs/$(CCBASE).tar.bz2
endif

ifeq ($(CCORI), gnu-mcu-eclipse)
  CCPRE  ?= riscv-none-embed-
  CCVER  ?= 8.2.0-2.2-20190521-0004
  CCBASE  = gnu-mcu-eclipse/riscv-none-gcc/$(CCVER)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin

  empty   =
  space   = $(empty) $(empty)
  tmp     = $(subst -,$(space),$(CCVER))
  _CCVER  = v$(subst -$(lastword $(tmp)),,$(CCVER))

  _CCBASE  = gnu-mcu-eclipse-riscv-none-gcc-$(CCVER)-centos64
  CCURL   = https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/$(_CCVER)/$(_CCBASE).tgz
endif
