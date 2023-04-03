#!/bin/bash

ps -ef | grep -E "qemu|gdb" | tr -s ' ' | cut -d ' ' -f2 | xargs -i sudo kill -9 {}
