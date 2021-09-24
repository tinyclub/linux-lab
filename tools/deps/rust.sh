#!/bin/bash
#
# rust.sh -- rust env for rust-for-kernel project
#
# based on https://gitee.com/tinylab/cloud-lab/issues/I3T3QB, with speedup mirrors in china and fixups for rustc version
#

# Speed up 'Updating crates.io index'
TOP_DIR=$(cd $(dirname $0) && pwd)

[ ! -d $TOP_DIR/rust/.cargo ] && mkdir -p $TOP_DIR/rust/.cargo
[ ! -d $TOP_DIR/rust/.rustup ] && mkdir -p $TOP_DIR/rust/.rustup
[ ! -L $HOME/.cargo ] && ln -sf $TOP_DIR/rust/.cargo $HOME/.cargo
[ ! -L $HOME/.rustup ] && ln -sf $TOP_DIR/rust/.rustup $HOME/.rustup

cat <<EOF > $HOME/.cargo/config
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"

# Replace it with your preferred mirror source
replace-with = 'ustc'

# Tsinghua University
[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

# University of science and technology of China
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

# Shanghai Jiaotong University
[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

# Rustcc community
[source.rustcc]
registry = "git://crates.rustcc.cn/crates.io-index"
EOF

# Install for rustc
# more: RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
#       RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
  RUSTUP_UPDATE_ROOT=https://mirrors.sjtug.sjtu.edu.cn/rust-static/rustup \
  RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static/ \
  sh -s -- -y -v --default-toolchain 1.54-x86_64-unknown-linux-gnu --profile minimal -c rust-src,rustfmt && \
  echo "RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static/" >> $HOME/.cargo/env && \
  bash -c "source $HOME/.cargo/env && cargo install --locked --version 0.56.0 bindgen"
