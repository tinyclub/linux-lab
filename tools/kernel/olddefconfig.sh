#!/bin/bash
#
# olddefconfig.sh -- get available olddefconfig target
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

makefile=$1

oldconfig=allnoconfig

if [ -n "$makefile" -a -f "$makefile" ]; then
  # allnoconfig only works after supports KCONFIG_ALLNOCONFIG
  grep -w KCONFIG_ALLNOCONFIG "$makefile"
  if [ $? -eq 0 ]; then
    config_options="allnoconfig olddefconfig oldnoconfig oldconfig"
  else
    config_options="olddefconfig oldnoconfig oldconfig"
  fi

  for c in $config_options
  do
    grep -w $c -q $makefile
    if [ $? -eq 0 ]; then
      oldconfig=$c
      break
    fi
  done
fi

echo $oldconfig
