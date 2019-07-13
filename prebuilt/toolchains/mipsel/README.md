
# mipsel toolchain

https://codescape.mips.com/

https://toolchains.bootlin.com/

## Download & Decompress

    $ make toolchain

## Configure and use it

  Available CCORI: bootlin, mips

    $ vim boards/mipsel/malta/Makefile
    CCORI ?= bootlin
    include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.lib

## Use it

    $ make kernel-defconfig
    $ make kernel
