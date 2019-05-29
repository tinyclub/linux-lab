#!/bin/bash
#
# switch.sh -- switch gcc versions
#
# Example: tools/gcc/switch.sh arm 4.3
#
# Check the available versions installed: tools/gcc/list.sh
#

arch=$1
version=$2

[ -z "$arch" ] && echo "Usage: $0 ARCH GCC_VERSION" && exit 1

if [ ${arch} != "x86" ]; then
    name=${arch}-linux-gnu-gcc
    [ "$arch" == "arm" ] && name=${arch}-linux-gnueabi-gcc
    [ "$arch" == "aarch64" ] && name=${arch}-linux-gnu-gcc
    [ "$arch" == "mips" ] && name=mipsel-linux-gnu-gcc
else
    name=gcc
fi

if [ -z "$version" ]; then
    echo -e "\nLOG: Available gcc versions:\n"
    update-alternatives --list $name

    echo -e "\nUsage: $0 ARCH GCC_VERSION"
    exit 1
fi

path=/usr/bin/${name}-${version}

[ ! -f $path ] && echo "ERROR: No such file: $path" && exit 1

update-alternatives --verbose --set ${name} ${path}
