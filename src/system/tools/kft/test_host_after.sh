#!/bin/bash
#
# test_host_after.sh -- test the kernel feature in host side.
#
# Prepare some data (before) or Analyze the data(after) genearted by testing.
#

TOP_DIR=$(cd $(dirname $0) && pwd)/

# The data is saved in $ROOTDIR of `make env`
DATA_DIR=$1

KFT_KD=${TOP_DIR}/kd

echo
echo "KFT: handling the kft data $DATA_DIR/kft_data.sym ..."
echo

$KFT_KD -c -l -i $DATA_DIR/kft_data.sym

echo
echo
echo
