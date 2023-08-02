# Makefile

CCORI ?= bootlin
CCORI_LIST ?= internal bootlin mirrors.edge.kernel.org
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)

ifeq ($(CCORI), internal)
  CCPRE   ?= powerpc-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
endif

ifeq ($(CCORI), bootlin)
  CCPRE  ?= powerpc-linux-
  CCVER  ?= 2018.11-1
  CCBASE := powerpc-e500mc--uclibc--stable-$(CCVER)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  CCURL  := https://toolchains.bootlin.com/downloads/releases/toolchains/powerpc-e500mc/tarballs/$(CCBASE).tar.bz2
endif

ifeq ($(CCORI), mirrors.edge.kernel.org)
  CCPRE  ?= powerpc-linux-
  CCVER  ?= 13.1.0
  CCBASE := gcc-$(CCVER)-nolibc/$(subst -x,,$(CCPRE)x)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  _CCBASE := x86_64-$(subst /,-,$(CCBASE))
  CCURL  := https://mirrors.ustc.edu.cn/kernel.org/tools/crosstool/files/bin/x86_64/$(CCVER)/$(_CCBASE).tar.gz
endif
