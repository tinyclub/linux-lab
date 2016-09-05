#!/bin/bash
#
# debug-docker-lab.sh -- Start shell in a container with root for debugging
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

docker exec -t -i $CONTAINER_ID /bin/bash
