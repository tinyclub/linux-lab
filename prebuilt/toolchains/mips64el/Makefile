# Makefile

CCORI ?= bootlin
CCORI_LIST ?= internal loongnix bootlin lemote
TOOLCHAIN  ?= $(PREBUILT_TOOLCHAINS)/mips64el

ifeq ($(CCORI), internal)
  CCPRE   ?= mipsel-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
endif

ifeq ($(CCORI), bootlin)
  CCPRE  ?= mips64el-linux-
  CCVER  ?= 2018.11-1
  CCBASE  = mips64el-n32--uclibc--stable-$(CCVER)
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  CCURL   = https://toolchains.bootlin.com/downloads/releases/toolchains/mips64el-n32/tarballs/$(CCBASE).tar.bz2
endif

ifeq ($(CCORI), lemote)
  CCPRE  ?= mips64el-unknown-linux-gnu-
  CCVER  ?= 10
  CCBASE ?= opt/mips64el-toolchain
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  LLPATH ?= $(TOOLCHAIN)/$(CCBASE)/x86_64-unknown-linux-gnu/mips64el-unknown-linux-gnu/lib
  _CCBASE ?= mips64el-toolchain-$(CCVER).x64
  CCURL   = http://mirror.lemote.com:8000/loongson3-toolchain/binaries/v$(CCVER)/$(_CCBASE).tar.xz
endif

ifeq ($(CCORI), loongnix)
  CCPRE  ?= mips64el-redhat-linux-
  CCVER  ?= 4.4.7
  CCBASE ?= gcc-$(CCVER)-7215-n64-loongson
  CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/usr/bin
  LLPATH ?= $(TOOLCHAIN)/$(CCBASE)/usr/x86_64-unknown-linux-gnu/mips64el-redhat-linux/lib:$(TOOLCHAIN)/$(CCBASE)/usr/lib:$(TOOLCHAIN)/$(CCBASE)/usr/mipsel-redhat-linux/lib:$(TOOLCHAIN)/$(CCBASE)/usr/mipsel-redhat-linux/sysroot/lib::$(TOOLCHAIN)/$(CCBASE)/usr/mipsel-redhat-linux/sysroot/usr/lib
  CCURL  ?= http://ftp.loongnix.org/toolchain/gcc/release/$(CCBASE).tar.gz

  #CCPRE  ?= mips-linux-gnu-
  #CCVER  ?= 7.3
  #CCBASE ?= mips-loongson-gcc7.3-linux-gnu/2019.06-29
  #CCPATH ?= $(TOOLCHAIN)/$(CCBASE)/bin
  #_CCBASE ?= mips-loongson-gcc7.3-2019.06-29-linux-gnu
  #CCURL  ?= http://ftp.loongnix.org/toolchain/gcc/release/$(_CCBASE).tar.gz
  #TAR_OPTS ?= jxvf
endif
