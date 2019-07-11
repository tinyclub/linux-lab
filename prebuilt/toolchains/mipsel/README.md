
# mipsel toolchain

https://toolchains.bootlin.com/downloads/releases/toolchains/mips32/tarballs/mips32--uclibc--stable-2018.11-1.tar.bz2

## Download & Decompress

    $ make toolchain

## Configure and use it

    $ vim boards/mipsel/malta/Makefile
    CCPRE  ?= mips-linux-
    CCVER  ?= 2018.11-1
    CCPATH ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/mips32--uclibc--stable-$(CCVER)/bin/

## Use it

    $ make kernel-defconfig
    $ make kernel
