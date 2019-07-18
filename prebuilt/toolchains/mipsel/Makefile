# Makefile

CCORI ?= bootlin
CCORI_LIST ?= internal bootlin mips loongnix
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/mipsel

ifeq ($(CCORI), internal)
  CCPRE   ?= mipsel-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
endif

ifeq ($(CCORI), bootlin)
  CCPRE  ?= mipsel-linux-
  CCVER  ?= 2018.11-1
  CCBASE  = mips32el--uclibc--stable-$(CCVER)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  CCURL   = https://toolchains.bootlin.com/downloads/releases/toolchains/mips32el/tarballs/$(CCBASE).tar.bz2
endif

ifeq ($(CCORI), mips)
  CCPRE  ?= mips-img-elf-
  CCVER  ?= 2018.09-03
  CCBASE ?= mips-img-elf/2018.09-03
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  _CCBASE = Codescape.GNU.Tools.Package.$(CCVER).for.MIPS.IMG.Bare.Metal.CentOS-6.x86_64
  CCURL   = https://codescape.mips.com/components/toolchain/$(CCVER)/$(_CCBASE).tar.gz
endif

# Ref: http://www.loongnix.org/index.php/Cross-compile
ifeq ($(CCORI), loongnix)
  CCPRE  ?= mipsel-linux-
  CCVER  ?= 4.3
  CCBASE ?= opt/gcc-$(CCVER)-ls232
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  LLPATH ?= $(TOOLCHAIN)/$(CCBASE)/i486-pc-linux-gnu/mipsel-linux/lib:$(TOOLCHAIN)/$(CCBASE)/lib:$(TOOLCHAIN)/$(CCBASE)/mipsel-linux/lib:$(TOOLCHAIN)/$(CCBASE)/sysroot/lib::$(TOOLCHAIN)/$(CCBASE)/sysroot/usr/lib
  _CCBASE ?= opt/gcc-$(CCVER)-ls232
  CCURL  ?= http://ftp.loongnix.org/toolchain/gcc/release/$(_CCBASE).tar.gz
endif
