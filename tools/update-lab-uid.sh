#!/bin/bash
#
# update-lab-uid.sh
#

TOP_DIR=$(dirname `readlink -f $0`)

id -u $USER > $TOP_DIR/.lab_unix_uid
