#!/bin/bash

BOARD_MAKEFILE=$1
BOARD_LOCAL=$2
BOARD_PLUGIN=$3

if [ -n "$BOARD_PLUGIN" ]; then
  echo $BOARD_MAKEFILE | grep -q $BOARD_PLUGIN
  [ $? -ne 0 ] && exit 0
fi

BOARD_GIT=$(echo $BOARD_MAKEFILE | sed -e 's%/Makefile%/bsp/.git%g')

if [ "$BOARD_LOCAL" = "local" ]; then
  if [ -d "$BOARD_GIT" ]; then
    echo [ $BOARD_MAKEFILE ]:
    cat -n $BOARD_MAKEFILE
  fi
  exit 0
fi

if [ "$BOARD_LOCAL" = "remote" ]; then
  if [ ! -d "$BOARD_GIT" ]; then
    echo [ $BOARD_MAKEFILE ]:
    cat -n $BOARD_MAKEFILE
  fi
  exit 0
fi

echo [ $BOARD_MAKEFILE ]:
cat -n $BOARD_MAKEFILE
