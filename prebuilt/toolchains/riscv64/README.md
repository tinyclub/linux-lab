
# Riscv toolchain for riscv64/32

https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.2.0-2019.02.0-x86_64-linux-ubuntu14.tar.gz

## Download & Decompress

    $ make toolchain

## Configure and use it

    $ vim boards/virt/Makefile
    CCPRE  ?= riscv64-unknown-elf-
    CCVER  ?= 8.2.0-2019.02.0
    CCPATH ?= $(PREBUILT_TOOLCHAINS)/riscv64/riscv64-unknown-elf-gcc-$(CCVER)-x86_64-linux-ubuntu14/bin/

## Use it

    $ make kernel-defconfig
    $ make kernel
