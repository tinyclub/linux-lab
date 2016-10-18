#!/bin/bash
#
# os-detection.sh -- detect the type of OS that lab is running on
#

uname_s=$(uname -s)

if [ "$uname_s" = "Darwin" ]; then
    OS_TYPE="macOS"
elif [ "$uname_s" = "Linux" ]; then
    OS_TYPE="Linux"
elif [ "$(expr substr $uname_s 1 10)" = "MINGW64_NT" ]; then
    OS_TYPE="Windows"
else
    echo "You may be using some unsupport platform"
    exit 0
fi