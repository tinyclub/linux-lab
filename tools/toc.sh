#!/bin/bash
#
# toc.sh -- generate toc for READMEs
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

TOP_DIR=$(cd $(dirname $0)/../ && pwd)

[ -n "$1" ] && README=$1
[ -z "$README" ] && README=$TOP_DIR/README.md

echo -e "<!-- toc start -->\n" > ${README}.toc

echo $README | grep -q _zh
if [ $? -eq 0 ]; then
  echo -e "\n# 目录\n" >> ${README}.toc
else
  echo -e "\n# Table of Content\n" >> ${README}.toc
fi

cat $README | grep -v "^# Table of Content" | grep -v "^# 目录" | grep ^# | sed "s%^##### %            - %g" | sed "s%^#### %          - %g" | sed -e "s%^### %       - %g" | sed -e "s%^## %    - %g" | sed -e "s%^# %- %g"\
	| sed -e "s%\(.*\)- \(.*\)%echo -n \"\1- [\2]\";echo \"(#\L\2)\" | tr ' ' '-' | tr -d '/' | tr -d '.' | tr -d ':'%g" | bash -v >>${README}.toc 2>/dev/null

echo -e "\n<!-- toc end -->" >> ${README}.toc

echo "${README}.toc generated."

sed -i -e '/<!-- toc start -->/{:a; N; /\n<!-- toc end -->$/!ba; r '${README}'.toc' -e 'd;}' ${README}

echo "${README} updated with new toc."
