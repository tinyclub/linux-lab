#!/bin/bash
#
# clone.sh -- clone a remote repo via git init + git fetch, update it if exist
#
# Copyright (C) 2016-2021 Wu Zhangjin <falcon@ruma.tech>
#

git_repo_url=$1
git_repo_dir=$2
git_repo_branch=$3

[ -z "$git_repo_url" ] && echo "Usage: $0 git_repo_url [git_repo_dir] [git_repo_branch]" && exit 1

if [ -z "$git_repo_dir" ]; then
  git_repo_dir=$(basename $git_repo_url | sed -e "s%.git$%%g")
fi
if [ -z "$git_repo_branch" ]; then
  git_repo_branch=master
fi

if [ -e $git_repo_dir ]; then
  if [ -e $git_repo_dir/.git ]; then
    echo
    echo "LOG: $git_repo_dir is there, update it with: git fetch"
    echo

    cd $git_repo_dir
    git fetch --tags --all

    exit 0
  else
    _git_repo_dir=$git_repo_dir
    git_repo_dir=${git_repo_dir}-${RANDOM}
    echo
    echo "NOTE: $_git_repo_dir is there, but not a git repo, use $git_repo_dir instead."
    echo
  fi
fi

echo
echo "LOG:  Cloning a new repository with: git init + git fetch."
echo "FROM: $git_repo_url"
echo "TO:   $git_repo_dir"
echo

mkdir -p $git_repo_dir
cd $git_repo_dir
git init
git remote add origin $git_repo_url
git fetch --tags --all
git checkout -f $git_repo_branch
