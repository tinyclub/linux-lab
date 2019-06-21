
# Riscv toolchain for riscv64/32

https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases

## Download & Decompress

    $ make toolchain

## Configure and use it

    $ vim boards/virt/Makefile
    CCPRE  ?= riscv-none-embed-
    CCVER  ?= 8.2.0-2.2-20190521-0004
    CCPATH ?= $(PREBUILT_TOOLCHAINS)/riscv64/gnu-mcu-eclipse/riscv-none-gcc/$(CCVER)/bin/

## Use it

    $ make kernel-defconfig
    $ make kernel
