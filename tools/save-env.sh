#!/bin/bash
#
# save-env.sh -- Save the variable set in command line
#

ENV_FILE=$1
ENV_VARS="$2"

env_list=`env`

for var in $ENV_VARS
do
	echo $env_list | tr ' ' '\n' | grep "^${var}="
	if [ $? -eq 0 ]; then
		value=`eval echo \\$${var}`
		sed -i -e "s/^${var}.*/${var} ?= ${value}/g" ${ENV_FILE}
	fi
done
