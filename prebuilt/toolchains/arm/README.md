
# arm toolchain

https://toolchains.bootlin.com/

https://releases.linaro.org/components/toolchain/binaries/

## Download & Decompress

    $ make toolchain

## Configure and use it

  Available CCORI: bootlin, arm, linaro.

    $ vim boards/arm/versatilepb/Makefile
    CCORI ?= bootlin
    include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile

## Use it

    $ make kernel-defconfig
    $ make kernel
