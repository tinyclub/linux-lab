#!/bin/bash
#
# llvm.sh
#

sudo bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

V=`ls /usr/bin/clang-[0-9]* | sort -u | tail -1 | cut -d '-' -f2`
sudo ln -sf /usr/bin/clang-$V /usr/bin/clang
sudo ln -sf /usr/bin/clang-cpp-$V /usr/bin/clang-cpp
sudo ln -sf /usr/bin/clangd-$V /usr/bin/clangd
sudo ln -sf /usr/bin/clang++-$V /usr/bin/clang++
sudo ln -sf /usr/bin/ld.lld-$V /usr/bin/ld.lld
