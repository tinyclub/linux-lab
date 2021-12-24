#!/bin/bash
#
# wsl.sh -- build latest tag of wsl2 kernel
#

TOP_DIR=$(cd $(dirname $0)/../../ && pwd)

echo "LOG: enable oneshot mode, put everything in memory"
export ONESHOT=1
#echo "LOG: may require vip to download the bsp"
export vip=1
echo "LOG: set board as 64bit x86 pc"
export BOARD=x86_64/pc
echo "LOG: silence version check"
export LINUX_LIST=
echo "LOG: get latest tag, only support gitee.com currently"
export LATEST_TAG=1
echo "LOG: set kernel fork"
export KERNEL_FORK=wsl2
echo "LOG: set kernel git"
export WSL2_GIT=https://gitee.com/mirrors/WSL2-Linux-Kernel.git

TOP_SRC=$TOP_DIR/build/src
WSL_SRC=$TOP_SRC/${KERNEL_FORK}-kernel
CFG_DIR=$TOP_DIR/boards/$BOARD/bsp/configs/${KERNEL_FORK}/
IMG_DIR=$TOP_DIR/boards/$BOARD/bsp/kernel/${KERNEL_FORK}/

echo "LOG: get latest tag"
tag=$(wget ${WSL2_GIT} -q -O - | grep -A1 "scrolling.*data-tab='tags'" | tail -1 | sed -e "s/<[^>]*>//g")

echo "LOG: latest tag is $tag"

if [ -f $CFG_DIR/linux_${tag}_defconfig -a -f $IMG_DIR/${tag}/bzImage ]; then
  echo "LOG: the latest wsl2 kernel has been built yet."
  exit 0
fi

echo "LOG: select board $BOARD"
make BOARD=$BOARD
echo "LOG: clean old source"
make kernel-cleanup
echo "LOG: download target tag"
make kernel-source
echo "LOG: checkout downloaded tag"
make kernel-checkout

#pushd $WSL_SRC >/dev/null
#tag=$(git tag | head -1)
#popd >/dev/null

if [ ! -f $CFG_DIR/linux_${tag}_defconfig ]; then
  cfg_src=$WSL_SRC/Microsoft/config-wsl
  cfg_tgt=$CFG_DIR/linux_${tag}_defconfig
  echo "LOG: save $cfg_src to $cfg_tgt"
  cp $cfg_src $cfg_tgt
fi

if [ ! -f $IMG_DIR/${tag}/bzImage ]; then
  KCFG=linux_${tag}_defconfig
  echo "LOG: use config $KCFG"
  make kernel-defconfig KCFG=$KCFG
  # fix up missing pahole tool
  which pahole >/dev/null
  if [ $? -ne 0 ]; then
    echo "LOG: no pahole found, disable CONFIG_DEBUG_INFO_BTF"
    make kernel-config n=CONFIG_DEBUG_INFO_BTF
  fi
  echo "LOG: compile it"
  time make kernel
  echo "LOG: save kernel image and config"
  make kernel-save
fi

# do boot test with qemu
# make boot-test
