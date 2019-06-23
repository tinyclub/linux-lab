#!/bin/bash

ps -ef | egrep "qemu|gdb" | tr -s ' ' | cut -d ' ' -f2 | xargs -i sudo kill -9 {}
