
# TinyLab Riscv Box Usage

## Basic Usage

    # decompress toolchain
    $ cd bsp/toolchains
    $ tar -xf toolchain.tar.xz

    $ cd /path/to/linux-lab
    $ make B=riscv64/tiny-riscv-box
    $ make kernel
    $ make uboot
    $ make root
    # To make opensbi, please read bsp/bios/opensbi/generic/README.md.

    # generate image to burn
    $ cd bsp/tools
    $ bash post-image.sh
    # burn image to SD card (please read tools/README.md first)
    $ bash burn.sh
