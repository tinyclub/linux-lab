#!/bin/bash
#
# llvm.sh
#

# Use llvm 12, llvm 13 not work, to be verified
V=12

wget -O - https://apt.llvm.org/llvm.sh | sudo bash -s -- $V

sudo ln -sf /usr/bin/clang-$V /usr/bin/clang
sudo ln -sf /usr/bin/clang-cpp-$V /usr/bin/clang-cpp
sudo ln -sf /usr/bin/clangd-$V /usr/bin/clangd
sudo ln -sf /usr/bin/clang++-$V /usr/bin/clang++
sudo ln -sf /usr/bin/ld.lld-$V /usr/bin/ld.lld
