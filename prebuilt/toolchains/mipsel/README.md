
# Loongson MIPS toolchain

This is downloaded from http://dev.lemote.com/files/resource/toolchain/cross-compile/

## Decompress

    tar xf cross-loongson-gcc4_5_2-binutils2_21.tar.bz2 -C /opt

## Seting up environment in ~/.bashrc:

    export PATH=/opt/cross-loongson-4.5.2/bin:$PATH
    export LD_LIBRARY_PATH=/opt/cross-loongson-4.5.2/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/opt/cross-loongson-4.5.2/i686-linux/mips64el-linux/lib:$LD_LIBRARY_PATH
