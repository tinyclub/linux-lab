#!/bin/bash
#
# mirror.sh -- mirror qemu submodule from urls in qemu/.gitmodules to gitee.com/tinylab/qemu-xxx
#

TOP_DIR=$(cd $(dirname $0)/ && pwd)

# /path/to/mainline-qemu/.gitmodules
GITMODULES=$1

GITMODULES_URL=$TOP_DIR/gitmodules.url.txt

if [ -n "$GITMODULES" -a -f "$GITMODULES" ]; then
  grep url $GITMODULES | awk '{printf("%s\n",$3);}' | sort -u > $GITMODULES_URL
fi

exec 3<$GITMODULES_URL

while read -u 3 url
do
  url=$(echo $url | sed -e "s%/$%%g;s%.git$%%g")
  repo=$(basename $url)

  echo "URL: $url"
  echo "REPO: $repo"

  if [ ! -d $repo ]; then
    mkdir $repo
    pushd $repo
    git init
    git remote add origin $url
  else
    pushd $repo
  fi

  pwd

  #git fetch --all

  git checkout master
  if [ $? -ne 0 ]; then
    branch=$(git branch -a | grep remotes | xargs -i basename {})
    git checkout $branch
  fi

  git pull

  x=$(echo $repo| sed -e "s/qemu-//g")
  echo $x

  git push --mirror gitee:tinylab/qemu-$x.git

  popd
done
