#!/bin/bash
#
# reader -- read fifo in backround
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

pipe_file=$1
log_file=$2
pipe_reader_pid=$3

[ -z "$pipe_file" ] && pipe_file=tmp.fifo
[ -z "$log_file" ] && pipe_file=tmp.log
[ -z "$pipe_reader_pid" ] && pipe_reader_pid=fifo.reader.pid

[ ! -p "${pipe_file}.out" ] && mkfifo ${pipe_file}.out
[ ! -p "${pipe_file}.in" ] && mkfifo ${pipe_file}.in

(while :;
do
	sleep 1
	[ -p "${pipe_file}.out" ] && cat ${pipe_file}.out | tee -a $log_file
done)&

reader=$!
[ -f "$pipe_reader_pid" ] && echo $reader > $pipe_reader_pid

echo "pipe reader pid:" $reader
