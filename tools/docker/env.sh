#!/bin/bash
#
# env -- list current system information of running docker
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

uname | grep -q MINGW && PWD_OPT="-W"
CLOUD_LAB_DIR="$(cd "$(dirname "$0")"/../../../../ && pwd $PWD_OPT)"

# dump system information of lab is not meaningful
if [ -d '/configs' ]; then
    echo "ERR: Please run this in host system, not in lab."
    exit 1
fi

ENV_TOOL=$CLOUD_LAB_DIR/tools/docker/env

if [ -f $ENV_TOOL ]; then
  $ENV_TOOL
else
  echo "LOG: $ENV_TOOL not exist, please update your cloud lab:"
  echo
  echo "    $ cd $CLOUD_LAB_DIR"
  echo "    $ git pull"
  echo "    $ ls tools/docker/env.sh"
  echo
fi
