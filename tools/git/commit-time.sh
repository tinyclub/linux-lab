#!/bin/bash

commit=$1

[ -z "$commit" ] && echo "Usage: $0 commit|tag|branch" && exit 1

date -d @`git log -1 --format=%ct $commit` +%Y%m%d-%H%M%S
