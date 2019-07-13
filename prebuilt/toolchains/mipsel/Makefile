
TC_ORIG ?= bootlin

ifeq ($(TC_ORIG), bootlin)
  TC_VERSION ?= 2018.11-1

  TC_BASE = mips32--uclibc--stable-$(TC_VERSION)
  TC_URL  = https://toolchains.bootlin.com/downloads/releases/toolchains/mips32/tarballs/$(TC_BASE).tar.bz2
endif

ifeq ($(TC_ORIG), mips)
  TC_VERSION ?= 2018.09-03

  TC_BASE = Codescape.GNU.Tools.Package.$(TC_VERSION).for.MIPS.IMG.Bare.Metal.CentOS-6.x86
  TC_URL  = https://codescape.mips.com/components/toolchain/$(TC_VERSION)/$(TC_BASE).tar.gz
endif

include ../Makefile.lib
