#!/bin/bash

commit=$1

date -d @`git log -1 --format=%ct $commit` +%Y%m%d-%H%M%S
