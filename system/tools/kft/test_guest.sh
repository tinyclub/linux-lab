#!/bin/sh
#
# test.sh -- test kft, see doc/kft/kft_kickstart.txt
#

echo
echo "KFT: Getting kft tracing progress from /proc/kft"
echo

cat /proc/kft

echo
echo "KFT: Waiting for tracing for a while ..."
echo
sleep 5

echo
echo "KFT: Dummping 500 lines of kft tracing data from /proc/kft_data to kft_data.sym"
echo

head -500 /proc/kft_data | tee kft_data.sym
