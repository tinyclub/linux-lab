#!/bin/bash

BOARD_MAKEFILE=$1
BOARD_PLUGIN=$2

if [ -n "$BOARD_PLUGIN" ]; then
  echo $BOARD_MAKEFILE | grep -q $BOARD_PLUGIN
  [ $? -ne 0 ] && exit 0
fi

echo [ $BOARD_MAKEFILE ]:
cat -n $BOARD_MAKEFILE
