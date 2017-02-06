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

[ -z "$arch" ] && "Usage: $0 ARCH VERSION" && exit 1
[ -z "$version" ] && "Usage: $0 ARCH VERSION" && exit 1

if [ ${arch} != "x86" ]; then
    name=${arch}-linux-gnu-gcc
    [ "$arch" == "arm" ] && name=${arch}-linux-gnueabi-gcc
    [ "$arch" == "mips" ] && name=mipsel-linux-gnu-gcc
else
    name=gcc
fi
path=/usr/bin/${name}-${version}

update-alternatives --set ${name} ${path}
