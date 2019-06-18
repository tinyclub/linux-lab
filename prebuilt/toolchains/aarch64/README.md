
# aarch64 toolchain

https://releases.linaro.org/components/toolchain/binaries/

https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads

## Download & Decompress

    $ make toolchain

## Configure and use it

    $ vim boards/aarch64/virt/Makefile
    CCPRE  ?= aarch64-linux-gnu-
    CCVER  ?= 8.3-2019.03
    CCPATH ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/gcc-arm-$(CCVER)-x86_64-aarch64-linux-gnu/bin/

## Use it

    $ make kernel-defconfig
    $ make kernel
