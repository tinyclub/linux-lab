---
layout: post
author: 'Wu Zhangjin'
title: "允许在 Docker 中生成 core 文件"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /coredump-in-docker/
description: "本文介绍在 Docker 容器中，如何确保程序崩溃时可以正常生成 core 文件。"
category:
  - Docker
tags:
  - core
  - core_pattern
  - ulimit
---

> By Falcon of [TinyLab.org][1]
> Dec 10, 2019

## 背景简介

[《360° 剖析 Linux ELF》](https://w.url.cn/s/AMcKZ3a) 课程使用 [Linux Lab](http://tinylab.org/linux-lab) 来做实验环境，刚开始有学员报告说，当程序出现段错误时，即使用 ulimit 做了配置，也无法正常生成 core 文件。

后面分析并解决了这一问题，本文记录一下解决方法。

## 允许本地程序崩溃时生成 core 文件

当程序崩溃时，在本地可以用 `ulimit -c unlimited` 让应用正常生成 core 文件，方便调试。

## 允许在 Docker 容器中生成 core 文件

在 docker 中，当程序崩溃时，即使放开 core 文件的大小限制，也生成不了 core 文件。

经查，需要做两个改动：

* 在 docker 启动的时候，配置一下 ulimit，不限制 coredump 大小
* 然后配置一下 `core_pattern`，确保 core 生成在当前目录，跟本地默认一致。

具体可以这么做：

* 在使用 docker run 时加这个参数：`--ulimit core=-1`
* 另外，在启动容器后配置 core_pattern：

        sudo sh -c 'echo core > /proc/sys/kernel/core_pattern'

这个 core_pattern 还可以这样配：

    sudo sh -c 'echo "/tmp/cores/core.%e.%p" > /proc/sys/kernel/core_pattern'

以上用于配置 core 文件的名称和存放路径。

如果要能在本地访问 core 文件，还可以把本地存放 core 的路径通过 `docker -v` 挂载过去，例如：

    $ mkdir /path/to/cores
    $ docker -v /path/to/cores:/tmp/cores

## 小结

core 文件是很重要的调试手段，所以确保 Docker 容器也能正常生成 core 文件是非常重要。解决完该问题以后，让 Linux Lab 工作得更完美了。

[1]: http://tinylab.org
