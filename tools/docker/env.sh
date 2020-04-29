#!/bin/bash
#
# env.sh -- list current system information
#

# Hardware
echo "Product: `cat /sys/class/dmi/id/product_name`"

echo "Board: `cat /sys/class/dmi/id/board_name`"

echo "ARCH: `uname -p`"

cpuinfo=`cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | tr -s ' '`
cpunum=`cat /proc/cpuinfo | grep 'model name' | wc -l`
echo "CPU: $cpunum x$cpuinfo"

mem_size=`cat /proc/meminfo | egrep 'MemTotal' | tr -s ' ' | cut -d ' ' -f2 | xargs -i echo "scale=0;{}/1024" | bc -l`
echo "RAM: $mem_size MiB"

# System
system_desc="`lsb_release -d | cut -d':' -f2 | tr -d '\t'`"
system_code="`lsb_release -c | cut -d':' -f2 | tr -d '\t'`"
echo "System: $system_desc, $system_code"

# Kernel
echo "Linux: `uname -r`"

# Docker
echo "Docker: `docker --version`"

# Shell
echo "Shell: $SHELL $BASH_VERSION"
