
# arm toolchain

https://releases.linaro.org/components/toolchain/binaries/

## Download & Decompress

    $ make toolchain

## Configure and use it

    $ vim boards/arm/versatilepb/Makefile
    CCPRE  ?= arm-linux-gnueabi-
    CCVER  ?= 7.4.1-2019.02
    CCPATH ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/gcc-linaro-$(CCVER)-x86_64_$(XARCH)-linux-gnueabi/bin/

## Use it

    $ make kernel-defconfig
    $ make kernel
