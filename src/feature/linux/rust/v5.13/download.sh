#!/bin/bash

CURDIR=$(cd $(dirname $0)/ && pwd)

# prepare necessary deps
LABDIR=/labs/linux-lab

which clang >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "LOG: Install missing llvm & clang"
    $LABDIR/tools/deps/llvm.sh
fi

if [ ! -f "$HOME/.cargo/bin/rustc" -o ! -d "$HOME/.rustup/toolchains" ]; then
    echo "LOG: Install missing rust environment"
    $LABDIR/tools/deps/rust.sh
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

pushd $CURDIR
if [ ! -f feature.downloaded ]; then
    sudo apt update -y && \
    sudo apt install -y python3-pip && \
    sudo pip install b4 && \
    b4 am CANiq72=Q+024x_Bb__RRT9e30QmcTKhzBB2=CmfukJTCjXVY-A@mail.gmail.com
    [ $? -eq 0 ] && touch feature.downloaded
fi
popd
