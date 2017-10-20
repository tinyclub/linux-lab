#!/bin/sh

ppid () { ps -p ${1:-$$} -o ppid=; }
pcmd () { ps -p ${1:-$$} -o command=; }
pppid () { ppid `ppid ${1:-$$}`; }
ppcmd () { pcmd `pppid ${1:-$$}`; }
ppppid () { pppid `ppid ${1:-$$}`; }
pppcmd () { pcmd `ppppid ${1:-$$}`; }
pppppid () { ppppid `ppid ${1:-$$}`; }
ppppcmd () { pcmd `pppppid ${1:-$$}`; }

# Override XTERM
_XTERM=`ppppcmd`
echo $_XTERM | grep -q 'term'
[ $? -eq 0 ] && XTERM=$(basename `echo $_XTERM | tr ' ' '\n' | grep 'term'`)

XTERM=${XTERM:-$1}

echo $XTERM
