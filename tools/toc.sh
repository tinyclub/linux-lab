#!/bin/bash

cat README.md | grep ^# | sed "s%^#####%        -%g" | sed "s%^####%      -%g" | sed -e "s%^###%   -%g" | sed -e "s%^## %- %g" | grep -v ^# \
	| sed -e "s%\(.*\)- \(.*\)%echo -n \"\1- [\2]\";echo \"(#\L\2)\" | tr ' ' '-' | tr -d '/' | tr -d ':'%g" | bash
