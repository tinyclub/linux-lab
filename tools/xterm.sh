#!/bin/sh
#
# xterm.sh -- get current terminal
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

# Default setting
TERM_MATCH='term|onsole'
THIS_SCRIPT=`basename $0`
DEPTH=${2:-5}

# Functions
ppid () { ps -p ${1:-$$} -o ppid= 2>/dev/null; }
pcmd () { ps -p ${1:-$$} -o command= 2>/dev/null; }

# Find the terminal
found=0
pid=`ppid`
for i in `seq 1 $DEPTH`
do
    _XTERM=`pcmd $pid`
    echo $_XTERM | grep -v grep | grep -v $THIS_SCRIPT | egrep -q $TERM_MATCH
    [ $? -eq 0 ] && found=1 && break
    pid=`ppid $pid`
    depth=$i
done

# Get the command name
[ $found -eq 1 ] && XTERM=$(basename `echo $_XTERM | tr ' ' '\n' | egrep $TERM_MATCH`)

XTERM=${XTERM:-$1}

# reserve gnome-terminal for gnome-terminal-server
if [ "$XTERM" = "gnome-terminal-server" ]; then
  XTERM=${XTERM%-*}
fi

if [ -n "$XTERM" ]; then
  which "$XTERM" > /dev/null
  [ $? -eq 0 ] && echo "$XTERM" && exit 0
  XTERM=""
fi

for t in gnome-terminal deepin-terminal terminator konsole qterminal lxterminal
do
  which $t > /dev/null 2>&1
  [ $? -eq 0 ] && XTERM=$t && break
done

echo $XTERM
