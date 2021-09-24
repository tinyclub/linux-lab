#!/bin/bash
#
# rust.sh -- rust env for rust-for-kernel project
#
# based on https://gitee.com/tinylab/cloud-lab/issues/I3T3QB, with speedup mirrors in china and fixups for rustc version
#

# Speed up 'Updating crates.io index'
mkdir -p $HOME/.cargo/
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
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
  sed -e "s%RUSTUP_UPDATE_ROOT=.*%RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup%g" | \
  sed -e "s%RUSTUP_DIST_UPDATE=.*%RUSTUP_DIST_UPDATE=https://mirrors.tuna.tsinghua.edu.cn/rustup%g" | \
  sh -s -- -y && \
  echo "RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup" >> $HOME/.cargo/env && \
  bash -c "source $HOME/.cargo/env && \
  rustup default 1.54 && \
  rustup component add rust-src && \
  cargo install --locked --version 0.56.0 bindgen"
