#!/bin/bash
#
# tags.sh -- list tags of all specified docker image
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

image=$1

[ -z "$image" ] && echo "Usage: $0 image_name" && exit 1

echo $image | grep -q '/' || image=library/$image

curl -s "https://registry.hub.docker.com/v2/repositories/$image/tags/" | jq '."results"[]["name"]'
