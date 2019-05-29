#!/bin/bash
#
# bisect.sh -- find out the first bad change quickly
#
# Usage:
#
#       $ cd linux-lab
#       $ cp tools/git/bisect.sh .
#	$ ./bisect.sh bad good cmd args
#
# Example:
#
# 1. find out the first commit who remove the specified code line
#
#	$ ./bisect.sh efa5cf b6fcf0 "grep -q UCONFIG Makefile"
#	bdbf2122dba19298b56a3e934e49b1052fdfac4c is the first bad commit
#
# 2. find out who have broken uboot booting, not the same cause, this wrongly changed if .. fi statements
#
#       $ cp tools/uboot/boot-fails.sh .
#	$ ./bisect.sh efa5cf a61e84 ./boot-fails.sh versatilepb
#	d1fccb583bc60c504d7531ffe6c6934ddf960cb4 is the first bad commit

bad=$1
good=$2
cmd="$3"
args="$4"

[ -z "$bad" -o -z "$good" -o -z "$cmd" ] && \
	echo "ERR: $0 bad_commit good_commit run_cmd cmd_args" && exit 1

git bisect start $bad $good
git bisect run $cmd $args
git bisect reset
