#!/bin/bash
#
# trace.sh -- Trace a function automatically
#
# Author: falcon <wuzhangjin@gmail.com>
# Update: 2009-08-06, 2016-10-07
# Usage:
#
#      $ ./trace.sh [function_name] [script_path] [1|0]
#
# E.x. $ ./trace.sh sys_write ./ 1

function error_report
{
	echo "Usage: "
	echo "    $ ./trace.sh [function_name] [script_path] [1|0]"
	echo ""
	echo "    Note: Copy `kd` to the same and then try this"
	echo ""
	echo "    $ ./trace.sh sys_write ./    # Trigger it ourselves"
	echo "    or"
	echo "    $ ./trace.sh sys_write ./ 1  # Trigger by external actions"
	exit
}

# Get the function need to tace from user
[ -z "$1" ] && echo "Please input the function need to be traced" && error_report

trac_func=$1

# Get the path of the path of the tool: `kd`
script_path=  # /path/to/kernel/usr/src/scripts/

[ -n "$2" ] && script_path=$2

if [ -z "$script_path" ]; then
	echo "Please configure the path of `kd`" && error_report
fi

# Start it manually or automatically
auto=0		# If want to trace it by external trigger, change it to 1

[ -n "$3" ] && auto=$3

# Generate a default configuration file for KFT
cat <<EOF > config.sym
new
begin
	trigger start entry $trac_func
	trigger stop exit $trac_func
end
EOF

# config KFT
cat config.sym > /proc/kft

# Prime it
echo prime > /proc/kft

sleep 1 

# Start it

if [ "$auto" -eq 1 ];then
	grep -q "not complete" /proc/kft
	while [ $? -eq 0 ]
	do
		echo "please do something in the other console or terminal to trigger me"
		sleep 1
	done
else
	echo start > /proc/kft
fi
sleep 1

# Get the data
cat /proc/kft_data > log.sym

# Generate a readable log
$script_path/kd -c -l -i log.sym
