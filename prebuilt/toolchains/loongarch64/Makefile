# Makefile

CCORI ?= mirrors.edge.kernel.org
CCORI_LIST ?= mirrors.edge.kernel.org
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/loongarch64

ifeq ($(CCORI), mirrors.edge.kernel.org)
  CCPRE  ?= loongarch64-linux-
  CCVER  ?= 13.1.0
  CCBASE := gcc-$(CCVER)-nolibc/$(subst -x,,$(CCPRE)x)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  _CCBASE := x86_64-$(subst /,-,$(CCBASE))
  CCURL  := https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/$(CCVER)/$(_CCBASE).tar.gz
endif
