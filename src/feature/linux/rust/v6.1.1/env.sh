#!/bin/bash

CURDIR=$(cd $(dirname $0)/ && pwd)

# prepare necessary deps
LABDIR=/labs/linux-lab

# require specific verion?
which clang >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "LOG: Install missing llvm & clang"
    $LABDIR/tools/deps/llvm.sh
fi

if [ ! -f "$HOME/.cargo/bin/rustc" -o ! -d "$HOME/.rustup/toolchains" ]; then
    echo "LOG: Install missing rust environment"
    $LABDIR/tools/deps/rust.sh
    if [ $? -ne 0 ]; then
        echo "ERR: Missing rust environment, please download it manually with"
        echo
        echo "    tools/deps/rust.sh"
        echo
        exit 1
    fi
fi

# load rust env if required
if [ -f "$HOME/.cargo/bin/rustc" -a -d "$HOME/.rustup/toolchains" ]; then
    grep -i ".cargo" $HOME/.bashrc
    if [ $? -ne 0 ]; then
       # remove the old setting
       sed -i -e "/.cargo\/env/d" $HOME/.bashrc
       # add new with file checking
       echo '[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"' >> $HOME/.bashrc
    fi
fi
