#!/bin/bash
#
# env.sh -- list current system information of running docker
#

# dump system information of lab is not meaningful
if [ -d '/configs' ]; then
    echo "ERR: Please run this in host system, not in lab."
    exit 1
fi

# must already install docker
docker --version 2>&1 >/dev/null
[ $? -ne 0 ] && echo "ERR: No docker installed?" && exit 2

# Get host os system
HOST_OS=$(uname)

# Hardware
if [ "x$HOST_OS" = "xDarwin" ]; then
  echo "TBD";
elif [ "x$HOST_OS" = "xLinux" ]; then
  vendor="`cat /sys/class/dmi/id/board_vendor`"
  board="`cat /sys/class/dmi/id/board_name`"
  product="`cat /sys/class/dmi/id/product_name`"
  echo "Product: $vendor, $board, $product"
else # Windows
  product=`systeminfo.exe | head -15 | tail -3 | cut -d ':' -f2 | tr -s ' ' | tr '\n' ',' | tr -d -c "[:print:]" | sed -e 's/ ,/,/g;s/,$//g'`
  echo "Product:$product"
fi

echo "ARCH: `uname -m`"

cpuinfo=`cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | tr -s ' '`
cpunum=`cat /proc/cpuinfo | grep 'model name' | wc -l`
echo "CPU: $cpunum x$cpuinfo"

mem_size=`cat /proc/meminfo | egrep 'MemTotal' | tr -s ' ' | cut -d ' ' -f2 | xargs -i sh -c 'echo $(({}/1024))'`
echo "RAM: $mem_size MiB"

# System
if [ "x$HOST_OS" = "xDarwin" ]; then
  echo "TBD";
elif [ "x$HOST_OS" = "xLinux" ]; then
  system_desc="`lsb_release -d | cut -d':' -f2 | tr -d '\t'`"
  system_code="`lsb_release -c | cut -d':' -f2 | tr -d '\t'`"
  echo "System: $system_desc, $system_code"
else # Windows
  echo "System: $HOST_OS, `uname -n`"
fi

# Kernel
echo "Linux: `uname -r`"

# Docker
echo "Docker: `docker --version`"

# Shell
shell=`basename $SHELL`
case $shell in
  bash)
       shell_version=$BASH_VERSION
       ;;
   zsh)
       shell_version=$ZSH_VERSION
       ;;
   *)
       shell_version=
       ;;
esac

echo "Shell: $SHELL $shell_version"
