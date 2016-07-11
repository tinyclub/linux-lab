#!/bin/bash
#
# kill-docker-lab.sh -- rm a docker lab
#

TOP_DIR=$(dirname `readlink -f $0`)

CONTAINER_ID=$1
if [ -z "$CONTAINER_ID" ]; then
    LAB_CONTAINER_ID=$TOP_DIR/.lab_container_id
    if [ -f $LAB_CONTAINER_ID ]; then
        CONTAINER_ID=$(< $LAB_CONTAINER_ID)
    else
        echo "LOG: Container id or name required" && exit 1
    fi
fi

docker rm -f $CONTAINER_ID 2>&1
