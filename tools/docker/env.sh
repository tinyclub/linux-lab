#!/bin/bash
#
# env.sh -- list current system information
#

# System
echo -n "System: "
lsb_release -d | cut -d':' -f2 | tr -d '\t'

# Kernel
echo -n "Linux: "
uname -r

# Docker
echo -n "Docker: "
docker --version
