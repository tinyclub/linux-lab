#!/bin/bash
#
# patch.sh -- fix up for newest ubuntu 20.04 docker image
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

KSRC=$1

# Fix up deprecated defined() of perl
timeconst_pl=$KSRC/kernel/timeconst.pl
if [ -f $timeconst_pl ]; then
  sed -i -e "s%defined%%g" $timeconst_pl
fi
