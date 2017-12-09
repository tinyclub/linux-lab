#!/bin/bash
#
# test_host_after.sh -- test the kernel feature in host side.
#
# Prepare some data (before) or Analyze the data(after) genearted by testing.
#

TOP_DIR=$(cd $(dirname $0) && pwd)/

# The data is saved in $ROOTDIR of `make env`
DATA_DIR=$1

head -50 $DATA_DIR/trace.log

echo
echo
echo
