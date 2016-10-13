#!/bin/bash
#
# rm-docker-lab.sh -- rm a docker lab
#

TOP_DIR=$(cd $(dirname $0) && pwd)

CONTAINER_ID=$1
if [ -z "$CONTAINER_ID" ]; then
    LAB_CONTAINER_ID=$TOP_DIR/.lab_container_id
    if [ -f $LAB_CONTAINER_ID ]; then
        CONTAINER_ID=$(< $LAB_CONTAINER_ID)
    else
        echo "LOG: Container id or name required" && exit 1
    fi
fi

docker stats $CONTAINER_ID 2>&1
