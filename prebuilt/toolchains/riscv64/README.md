
# Riscv toolchain for riscv64/32

https://toolchains.bootlin.com/

https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases

## Download & Decompress

    $ make toolchain

## Configure and use it

  Available CCORI: bootlin, gnu-mcu-eclipse

    $ vim boards/virt/Makefile
    CCORI ?= bootlin
    include $(PREBUILT_TOOLCHAINS)/$(XARCH)/Makefile

## Use it

    $ make kernel-defconfig
    $ make kernel
