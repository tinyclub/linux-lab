#!/bin/sh
#
# xterm.sh -- get current terminal
#

# Default setting
TERM_MATCH='term'
THIS_SCRIPT=`basename $0`
DEPTH=${2:-5}

# Functions
ppid () { ps -p ${1:-$$} -o ppid=; }
pcmd () { ps -p ${1:-$$} -o command=; }

# Find the terminal
found=0
pid=`ppid`
for i in `seq 1 $DEPTH`
do
    _XTERM=`pcmd $pid`
    echo $_XTERM | grep -v grep | grep -v $THIS_SCRIPT | grep -q $TERM_MATCH
    [ $? -eq 0 ] && found=1 && break
    pid=`ppid $pid`
    depth=$i
done

# Get the command name
[ $found -eq 1 ] && XTERM=$(basename `echo $_XTERM | tr ' ' '\n' | grep $TERM_MATCH`)

XTERM=${XTERM:-$1}

echo $XTERM
