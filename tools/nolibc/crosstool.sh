#!/bin/bash
#
# crosstool.sh -- download crosstool from https://mirrors.edge.kernel.org/pub/tools/crosstool/
#
# Copyright (C) 2023 Zhangjin Wu <falcon@tinylab.org>
#
# mirror sites:
#
# 1. https://cdn.kernel.org/pub/tools/crosstool/
# 2. https://mirrors.ustc.edu.cn/kernel.org/tools/crosstool/
#

[ -z "$VERSION" ] && VERSION=13.2.0
[ -z "$MIRROR" ] && MIRROR=https://mirrors.ustc.edu.cn/kernel.org/tools/crosstool/
[ -z "$HOST" ] && HOST=`uname -m`
[ -z "$TOOLCHAINS" ] && TOOLCHAINS="aarch64-linux arm-linux-gnueabi loongarch64-linux mips64-linux powerpc64-linux riscv64-linux s390-linux x86_64-linux"
[ -z "$EXPORT" ] && EXPORT=0

for toolchain in ${TOOLCHAINS[@]}; do
  toolchain_url=$MIRROR/files/bin/${HOST}/${VERSION}/${HOST}-gcc-${VERSION}-nolibc-${toolchain}.tar.xz

  if [ "$EXPORT" == "1" ]; then
    TOOLCHAIN_PATH=$PWD/toolchains/gcc-${VERSION}-nolibc/${toolchain}/bin/:$TOOLCHAIN_PATH
  else
    echo -e "Downloading ${toolchain}-gcc from ${toolchain_url}\n"
    wget -c ${toolchain_url}
    if [ $? -eq 0 ]; then
      mkdir -p toolchains
      echo -e "Decompressing ${toolchain}-gcc to $PWD/toolchains\n"

      tar xf x86_64-gcc-${VERSION}-nolibc-${toolchain}.tar.xz -C toolchains
      [ $? -eq 0 ] && TOOLCHAIN_PATH=$PWD/toolchains/gcc-${VERSION}-nolibc/${toolchain}/bin/:$TOOLCHAIN_PATH
    fi
  fi
done

echo "Toolchains for ${TOOLCHAINS} are stored in $PWD/toolchains."
echo -e "Run and save the following line to your shell configuration file:\n"
echo export PATH=$TOOLCHAIN_PATH\$PATH
