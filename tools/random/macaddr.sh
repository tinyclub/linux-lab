#!/bin/bash

dd bs=1 count=6 if=/dev/random 2>/dev/null | od -h | head -1 | cut -d' ' -f2,3,4 | sed -e "s/\(..\)\(..\) \(..\)\(..\) \(..\)\(..\)/\1:\2:\3:\4:\5:\6/g" | tr -d '\n'
