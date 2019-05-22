#!/bin/bash
#
# reader -- read fifo in backround
#

pipe_file=$1
log_file=$2
pipe_reader_pid=$3

[ -z "$pipe_file" ] && pipe_file=tmp.fifo
[ -z "$log_file" ] && pipe_file=tmp.log
[ -z "$pipe_reader_pid" ] && pipe_reader_pid=fifo.reader.pid

[ ! -p "$pipe_file" ] && mkfifo $pipe_file

(while :;
do
	sleep 1
	[ -p "$pipe_file" ] && cat $pipe_file | tee -a $log_file
done)&

reader=$!
[ -f "$pipe_reader_pid" ] && echo $reader > $pipe_reader_pid

echo "pipe reader pid:" $reader
