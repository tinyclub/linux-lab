---
title: 'LEP 开发环境'
tagline: 'Linux Easy Profiling 项目开发环境'
author: Wu Zhangjin
layout: page
permalink: /lep-lab/
description: 基于 Cloud Lab 构建的一套 LEP 快捷开发环境。
update: 2017-11-13
categories:
  - Cloud Lab
  - 内核调试与跟踪
tags:
  - LEP
---

## 简介

LEP 是一个开源工具箱，可用于 Linux/Android 可视化分析。

* [首页](http://www.linuxep.com/)
* [Github](https://github.com/linuxep/)

为了降低 LEP 的学习和开发门槛，我们为 LEP 开发了这套 LEP Lab，它可以作为 [Cloud Lab](http://tinylab.org/cloud-lab) 的插件使用。

下面简单介绍一下如何通过 Cloud Lab 使用 LEP Lab。

## 安装 Docker

使用 LEP Lab 之前，需要安装 Docker：

* Linux, Mac OSX, Windows 10: [Docker CE](https://store.docker.com/search?type=edition&offering=community)
* Old Windows: [Docker Toolbox](https://www.docker.com/docker-toolbox)

注意事项：

如果想免密使用，可以把用户加入 docker 用户组：

    $ sudo usermod -aG docker $USER

如果想更快下载 Docker 镜像，换个国内的源吧：

  * [阿里云 Docker 镜像使用文档](https://help.aliyun.com/document_detail/60750.html)
  * [USTC Docker 镜像使用文档](https://lug.ustc.edu.cn/wiki/mirrors/help/docker)

如果 Docker 默认网络跟局域网地址冲突，可进行修改：

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

如果上述修改不生效，可以做如下修改：

    $ grep dockerd /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16 --registry-mirror=https://docker.mirrors.ustc.edu.cn
    $ service docker restart

对于 12.04，更新内核后才能使用 Docker。

    $ sudo apt-get install linux-generic-lts-trusty

## 选择一个工作目录

如果通过 Docker Toolbox 安装的 Docker，请使用 Virtualbox 上的 default 系统中的 `/mnt/sda1` 作为工作目录，否则，掉电后数据会丢失，因为其他目录是只读的 iso 文件，挂载在内存中，关机后无法回写。

    $ cd /mnt/sda1

对于 Linux 或者 Mac OSX，可以使用 `~/Downloads` 或者 `~/Documents`。

    $ cd ~/Documents

## 下载 LEP Lab

以 Ubuntu 为例，首先下载 Cloud Lab 管理框架，之后，下载相关环境的镜像和源代码：

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose lep-lab

## 运行并登陆

直接运行并自动登陆：

    $ tools/docker/run lep-lab

退出以后下次可直接登陆：

    $ tools/docker/vnc lep-lab

## 使用 LEP Lab

登陆以后，点击桌面的 'LEP Lab' 快捷键，可进入该开发环境的主目录。

### 下载源码

    $ make init

### 编译和运行 lepd

    $ cd lepd
    $ make ARCH=x86      // ARCH 现在只支持 x86 和 arm
    $ ./lepd

### 运行 lepv 后端

    $ cd lepv/app
    $ python3 ./run.py & // 请务必使用 python3，python2 会有编码问题

### 打开 lepv 前端

    $ chromium-browser http://localhost:8889

### 更多用法

获取帮助：

    $ make help
    Usage:

    init  -- download or update lepd and lepv (1)
    _lepd -- compile and restart lepd (2)
    _lepv -- restart the lepv backend (3)
    view  -- start the lepv frontend (4)
    all   -- do (1) (2) (3) one by one

重新编译并启动 ARM 版本的 lepd（通过 `qemu-arm` 直接在 X86 上运行）：

    $ make _lepd ARCH=arm

默认接入的 lepd 服务地址是 `www.rmlink.cn`，可通过如下方式自动切换为本地 lepd 服务：

    $ make view SERVER=localhost
