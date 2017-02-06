#!/bin/bash
#
# update-lab-uid.sh
#

TOP_DIR=$(cd $(dirname $0) && pwd)

id -u $USER > $TOP_DIR/.lab_unix_uid
