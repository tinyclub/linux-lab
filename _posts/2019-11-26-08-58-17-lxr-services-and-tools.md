---
layout: post
author: 'Wu Zhangjin'
title: "LXR 在线服务和搭建工具"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /lxr-services-and-tools/
description: "本文收集了几个可用的 Linux 在线交叉检索服务和搭建工具"
category:
  - 效率工具
  - 开放服务
tags:
  - LXR
  - Elixir
  - Opengrok
  - Livegrep
  - ctags
  - cscope
---

> By Falcon of [TinyLab.org][1]
> Aug 01, 2019

LXR 服务对于检索某些有特定意义的信息，往往比简单的 grep 更高效，比如说查找某个变量的定义，因为 grep 要理解某个变量的定义是很难的，正则表达式也不是那么好记的。

所以，ctags, cscope 之类就显得很必要，但是这两个是命令行的，交互上不是那么友好，而且每次都得配置一些路径什么的，没那么方便。

基于 Web 的 LXR 服务就显得很有必要，最早是 [LXR / The Linux Cross Reference](http://lxr.linux.no/)，后来有 [LXR linux/](https://lxr.missinglinkelectronics.com/linux)，前者基本失效了，后者最新的才到 v4.20，能用的现在看上去只有：

* [Linux/](http://tomoyo.osdn.jp/cgi-bin/lxr/source/)

* [Linux source code:  (v5.2.2) - Bootlin](https://elixir.bootlin.com/linux/latest/source)

后面这个采用的技术稍微新一些，也有提供 Dockerfile 方便构建本地服务，还能定制只索引某个内核版本，源码在：

* [GitHub - bootlin/elixir: The Elixir Cross Referenc...](https://github.com/bootlin/elixir)

Docker 版本记得稍微修改一下，建议在 Dockerfile 里头增加代码改一下 `projects/linux.sh`，限制下需要建立索引的内核版本，不然每个版本都索引一遍，得跑好多天，举个例子：

    diff --git a/projects/linux.sh b/projects/linux.sh
    index 63b9657..c83c88c 100644
    --- a/projects/linux.sh
    +++ b/projects/linux.sh
    @@ -6,3 +6,9 @@ list_tags_h()
         tac |
         sed -r 's/^(((v2.6)\.([0-9]*)(.*))|(v[0-9]*)\.([0-9]*)(.*))$/\3\6 \3\6.\4\7 \3\6.\4\7\5\8/'
     }
    +
    +list_tags()
    +{
    +    echo "$tags" |
    +    grep "^v5.2.1"
    +}
    $

这里的 `list_tags()` 用 base64 编码后放到 Dockerfile 里头，过程如下：

    $ cat list_tags.txt

    list_tags()
    {
        echo "$tags" |
        grep "^v5.2.1"
    }
    $ base64 < list_tags.txt
    Cmxpc3RfdGFncygpCnsKICAgIGVjaG8gIiR0YWdzIiB8CiAgICBncmVwICJedjUuMi4xIgp9Cg==

    $ git diff
    diff --git a/docker/debian/Dockerfile b/docker/debian/Dockerfile
    index aa2cb79..124411e 100644
    --- a/docker/debian/Dockerfile
    +++ b/docker/debian/Dockerfile
    @@ -35,6 +35,7 @@ ENV LXR_DATA_DIR /srv/elixir-data/linux/data

     RUN \
       cd /usr/local/elixir/ && \
    +  echo Cmxpc3RfdGFncygpCnsKICAgIGVjaG8gIiR0YWdzIiB8CiAgICBncmVwICJedjUuMi4xIgp9Cg== | base64 -d >> projects/linux.sh && \
       ./script.sh list-tags && \
       ./update.py

构建的代码，建议把 Linux 仓库换成国内的源或者本地的源，例如：

    $ docker build -t elixir --build-arg GIT_REPO_URL=https://mirrors.tuna.tsinghua.edu.cn/git/linux-stable.git

关于 LXR 构建，也有同学推荐了 Opengrok，这里顺带推荐两个相关工具：

* [Livegrep：在线 Linux 源码 Grep 服务](https://livegrep.com/)
* [Bootlin.vim: Elixir vim 插件](https://github.com/fcangialosi/bootlin.vim)

[1]: http://tinylab.org
