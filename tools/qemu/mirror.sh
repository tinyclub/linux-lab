#!/bin/bash
#
# mirror.sh -- mirror qemu submodule from urls in qemu/.gitmodules to gitee.com/tinylab/qemu-xxx
#

TOP_DIR=$(cd $(dirname $0)/ && pwd)

# Silence error: server certificate verification failed
export GIT_SSL_NO_VERIFY=1

# /path/to/mainline-qemu/.gitmodules
GITMODULES=$1

# Allow restart
[ -z "$RESTART" ] && RESTART=0

# Must update the repo at first
if [ -z "$GITMODULES" ]; then
  QEMU_SRC=$TOP_DIR/../../src/qemu
  pushd $QEMU_SRC
  git fetch --tags https://gitlab.com/qemu-project/qemu.git
  git checkout $(git tag | tail -1)
  popd
  GITMODULES=$QEMU_SRC/.gitmodules
fi

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

  [ $RESTART -eq 1 ] && rm -rf $repo

  [ ! -d $repo ] && mkdir -p $repo

  pushd $repo >/dev/null

  # Init it if no .git there
  if [ ! -d .git ]; then
    git init
    git remote add origin $url

    MIRROR_TAG=tinylab
    gitee_url=$(echo $url | sed -e "s%https://git.qemu.org/git/qemu-%https://gitee.com/$MIRROR_TAG/qemu-%g;s%https://git.qemu.org/git/%https://gitee.com/$MIRROR_TAG/qemu-%g;s%https://gitlab.com/qemu-project/qemu-%https://gitee.com/$MIRROR_TAG/qemu-%g;s%https://gitlab.com/qemu-project/%https://gitee.com/$MIRROR_TAG/qemu-%g;s%https://gitlab.com/libvirt/%https://gitee.com/$MIRROR_TAG/qemu-%g")
    git remote add gitee $gitee_url
  fi

  # Show current directory
  pwd

  # Fetch all
  git fetch gitee
  # Remove gitee itself
  git remote remove gitee

  git fetch --all

  # Checkout master branch by default
  branches=$(git branch -a | grep remotes | xargs -i basename {} | grep -E "master|main")
  for branch in $branches
  do
    git checkout $branch
  done

  if [ -z "$branches" ]; then
    branch=$(git branch -a | grep remotes | xargs -i basename {} | head -1)
    git checkout $branch
  fi

  # Pull current branch
  git pull

  x=$(echo $repo| sed -e "s/qemu-//g")
  echo $x

  # Push all to mirror sites
  git push --mirror gitee:tinylab/qemu-$x.git

  popd >/dev/null
done
