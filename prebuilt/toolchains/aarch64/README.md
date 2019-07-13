
# aarch64 toolchain

https://toolchains.bootlin.com/

https://releases.linaro.org/components/toolchain/binaries/

https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads


## Download & Decompress

    $ make toolchain

## Configure and use it

  Please configure the board specific Makefile as following:

    $ vim boards/aarch64/raspi3/Makefile
    CCORI ?= arm
    include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile.lib

  Available 'CCORI's are bootlin, arm, linaro.

## Use it

    $ make kernel-defconfig
    $ make kernel
