
# ppc toolchain

https://toolchains.bootlin.com/downloads/releases/toolchains/powerpc-e500mc/tarballs/powerpc-e500mc--uclibc--stable-2018.11-1.tar.bz2

## Download & Decompress

    $ make toolchain

## Configure and use it

    $ vim boards/ppc/g3beige/Makefile
    CCPRE  ?= powerpc-linux-
    CCVER  ?= 2018.11-1
    CCPATH ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/powerpc-e500mc--uclibc--stable-$(CCVER)/bin/

## Use it

    $ make kernel-defconfig
    $ make kernel
