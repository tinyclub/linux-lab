---
layout: post
author: 'Wu Zhangjin'
title: "为已安装好的 Linux 系统新增一个内核模块"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /add-kernel-modules/
description: "本文介绍如何为已经安装好的 Linux 系统新增一个内核模块"
category:
  - Linux 内核
tags:
  - 内核模块
---

> By Falcon of [TinyLab.org][1]
> Dec 10, 2019

## 背景简介

有一个具体的需求：

> 那就是 docker for mac 的内核没有编译进 minix 内核模块，导致 [Linux 0.11 Lab](http://tinylab.org/linux-0.11-lab) 在这种情况下无法挂载 minix 的文件系统。所以，得根据用户内核的情况，单独去编译这个内核模块。

这里简单介绍一下，如何快速下载相应的模块源码，并在 host 下编译。

## 安装 linux headers

首先安装 linux-headers：

    $ sudo apt-get -y update
    $ sudo apt-get install -y linux-headers-`uname -r`

接着下载相应模块的代码（一定要是同一个版本的内核），比如说用 `uname -r` 命令看到的是：4.4.0-165-generic，那么下载 v4.4 的内核，可以到国内镜像站下载。

## 下载内核模块的源代码

考虑到只能在内核源码中找到 minix 模块，这里直接下载整个内核源码。

打开如下链接，在右侧“克隆/下载”那点击“下载ZIP”，ZIP 包只有 159M，下载还是很快的。

* [Linux Stable: 官方 Linux Stable 镜像站 —— 加速 Linux Stab...](https://gitee.com/tinylab/linux-stable/tree/v4.4)

也可以用 wget 直接下载：

    $ wget -c https://gitee.com/tinylab/linux-stable/repository/archive/v4.4.zip

## 基于 `/lib/modules/` 来编译

以 minix fs 为例，

    $ cd /path/to/linux-stable
    $ cd fs/minix/
    $ make -C /lib/modules/`uname -r`/build M=$PWD modules CONFIG_MINIX_FS=m LOCALVERSION=
    make: Entering directory '/usr/src/linux-headers-4.4.0-165-generic'
      CC [M]  /labs/linux-lab/minix/module/bitmap.o
      CC [M]  /labs/linux-lab/minix/module/itree_v1.o
      CC [M]  /labs/linux-lab/minix/module/itree_v2.o
      CC [M]  /labs/linux-lab/minix/module/namei.o
      CC [M]  /labs/linux-lab/minix/module/inode.o
      CC [M]  /labs/linux-lab/minix/module/file.o
      CC [M]  /labs/linux-lab/minix/module/dir.o
      LD [M]  /labs/linux-lab/minix/module/minix.o
      Building modules, stage 2.
      MODPOST 1 modules
      CC      /labs/linux-lab/minix/module/minix.mod.o
      LD [M]  /labs/linux-lab/minix/module/minix.ko
    make: Leaving directory '/usr/src/linux-headers-4.4.0-165-generic'

## 直接在内核源码中编译

如果是类似上面有完整的内核源代码，那么可以直接在 Linux 源码根目录下配置编译。

不过，需要先拿到配置文件，通常可以在 `/proc/config.gz` 中拿到：

    $ cd /path/to/linux
    $ zcat /proc/config.gz > .config

通常也可以从 `/boot` 下面拿到：

    $ cp /boot/config-`uname -r` .config

然后用老的配置文件配置一遍：

    $ make olddefconfig

之后准备以下内核模块需要编译的环境：

    $ make modules_prepare

接着直接编译 minix fs 模块：

    $ make fs/minix/minix.ko CONFIG_MINIX_FS=m LOCALVERSION=

## 补充

如果内核源码目录有内容没有被提交，或者不干净，那么会在内核版本后面加上 + 和 dirty，如果不想关注它们，直接把 LOCALVERSION 设置为空。也可以用 `git clean -fdX` 和 `git reset --hard` 清理一下。


[1]: http://tinylab.org
