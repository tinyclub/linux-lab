#!/bin/bash


TOP_DIR=$(cd $(dirname $0)/../ && pwd)

[ -n "$1" ] && README=$1
[ -z "$README" ] && README=$TOP_DIR/README.md

cat $README | grep -v "^## Contents" | grep ^# | sed "s%^#####%        -%g" | sed "s%^####%      -%g" | sed -e "s%^###%   -%g" | sed -e "s%^## %- %g" | grep -v ^# \
	| sed -e "s%\(.*\)- \(.*\)%echo -n \"\1- [\2]\";echo \"(#\L\2)\" | tr ' ' '-' | tr -d '/' | tr -d '.' | tr -d ':'%g" | bash
