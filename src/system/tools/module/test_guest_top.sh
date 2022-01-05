#!/bin/sh
#
# test.sh -- test module, see Documentation/
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

MODULES="$(cat /proc/cmdline | tr ' ' '\n' | grep ^module= | cut -d'=' -f2 | tr ',' ' ')"

[ -z "$MODULES" ] && echo "LOG: no module specified" && exit 0

echo
echo "module: Starting testing: $MODULES ..."
echo

depmod=0
mdir=/lib/modules/`uname -r`/
if [ -d $mdir ]; then
  if [ ! -f $mdir/modules.dep.bin ]; then
    which depmod && depmod -A && depmod=1
  else
    depmod=1
  fi
fi


for m in $MODULES
do

    echo
    echo "module: Starting testing module: $m"
    echo

    # recheck for modprobe available
    [ -f $mdir/modules.dep ] && grep -q $m $mdir/modules.dep 2>/dev/null
    [ $? -ne 0 ] && which depmod && depmod -A && grep -q $m $mdir/modules.dep 2>/dev/null && depmod=1 || depmod=0

    m_args=$(eval echo \$${m}_args)
    echo

    if [ "$depmod" = "1" ]; then
      echo "module: modprobe $m $m_args"
      modprobe $m $m_args
    else
      _m=$(find /lib/modules/`uname -r`/ -name "$m.ko")
      [ $? -ne 0 ] && echo "ERR: No module found for: $m." && exit 1
      m=$_m
      echo "module: insmod $m $m_args"
      insmod $m $m_args
    fi

    echo
    sleep 1

    echo
    echo "module: lsmod $m"
    echo
    lsmod
    sleep 1

done
