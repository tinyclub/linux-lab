#!/bin/bash
#
# valsval.sh -- Get the value of a variable which reference another variable
#
# ref: https://unix.stackexchange.com/questions/41406/use-a-variable-reference-inside-another-variable
#
# eval: Combine args to a string and use the result as input to the shell ... it is powerful. 
#

# Init manually and list them and the values
a_val=1
b_val=2
c_val=3
d_val=4

# list values
echo -e "\nREAD: list initialized values\n"

for x in a b c d
do
	# Note: can not use something like: v=`eval "echo \$${x}_val"`
	v=$(eval "echo \$${x}_val")
	echo -e "x=$x	${x}_val=$v"
done

# update values
echo -e "\nWRITE: update to random values\n"
for x in a b c d
do
	# Note: can not use something like: v=`eval "echo \$${x}_val"`
	eval "${x}_val=$RANDOM"

	v=$(eval "echo \$${x}_val")
	echo -e "x=$x	${x}_val=$v"
done
