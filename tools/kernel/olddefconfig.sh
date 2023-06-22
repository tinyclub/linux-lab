#!/bin/bash
#
# olddefconfig.sh -- get available olddefconfig target
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

makefile=$1

oldconfig=allnoconfig

if [ -n "$makefile" -a -f "$makefile" ]; then
  for c in allnoconfig olddefconfig oldnoconfig oldconfig
  do
    grep -w $c -q $makefile
    if [ $? -eq 0 ]; then
      oldconfig=$c
      break
    fi
  done
fi

echo $oldconfig
