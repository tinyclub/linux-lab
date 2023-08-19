# Makefile

CCORI ?= mirrors.edge.kernel.org
CCORI_LIST ?= internal mirrors.edge.kernel.org
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/s390x

ifeq ($(CCORI), internal)
  CCPRE   ?= s390-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
endif

ifeq ($(CCORI), mirrors.edge.kernel.org)
  CCPRE  ?= s390-linux-
  CCVER  ?= 13.1.0
  CCBASE := gcc-$(CCVER)-nolibc/$(subst -x,,$(CCPRE)x)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  _CCBASE := x86_64-$(subst /,-,$(CCBASE))
  CCURL  := https://mirrors.ustc.edu.cn/kernel.org/tools/crosstool/files/bin/x86_64/$(CCVER)/$(_CCBASE).tar.gz
endif
