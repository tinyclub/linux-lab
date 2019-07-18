
# ppc toolchain

https://toolchains.bootlin.com/

## Download & Decompress

    $ make toolchain

## Configure and use it

  Available CCORI: bootlin.

    $ vim boards/ppc/g3beige/Makefile
    include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile

## Use it

    $ make kernel-defconfig
    $ make kernel
