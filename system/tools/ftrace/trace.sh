#!/bin/sh
#
# trace.sh -- test ftrace
#

tracer=$1
cmd=$2
result=$3
debug=/sys/kernel/debug/

[ -z "$tracer" ] && tracer=function
[ -z "$cmd" ] && cmd=ls
[ -z "$result" ] && result=trace

if [ -d $debug ]; then
  tracing=$debug/tracing/
  [ ! -d $tracing ] && mount -t debugfs none $debug
else
  tracing=/sys/kernel/tracing
  [ ! -f $tracing/trace ] && mount -t tracefs none $tracing
fi

echo "[Available Tracers]"
echo
cat $tracing/available_tracers
echo

echo "[Using tracer: $tracer]"
echo $tracer > $tracing/current_tracer

echo "[Enabling tracing]"
[ -f $tracing/tracing_enabled ] && echo 1 > $tracing/tracing_enabled
[ -f $tracing/tracing_on ] && echo 1 > $tracing/tracing_on

echo "[Running command: $cmd]"
echo
$cmd

echo
echo "[Disabling tracing]"
[ -f $tracing/tracing_on ] && echo 0 > $tracing/tracing_on
[ -f $tracing/tracing_enabled ] && echo 0 > $tracing/tracing_enabled

echo "[Recording tracing result from $tracing/$result]"
echo
cat $tracing/$result | head -500 > $PWD/trace.log

echo "Tracing [$cmd] log with [$tracer] saved in $PWD/trace.log"
echo
