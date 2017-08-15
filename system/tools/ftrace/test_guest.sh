#!/bin/sh
#
# test.sh -- test ftrace, see doc/ftrace/ftrace.md
#

TOP_DIR=$(cd $(dirname $0) && pwd)

echo
echo "Ftrace: "
echo

${TOP_DIR}/trace.sh
