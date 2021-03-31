---
title: 'RT-Thread 开发环境'
tagline: '国产 IoT 操作系统 RT-Thread 开发环境'
author: Wu Zhangjin
layout: page
permalink: /rtthread-lab/
description: 基于 Cloud Lab 构建的一套 RT-Thread 开发环境。
update: 2017-11-13
categories:
  - Cloud Lab
tags:
  - RT-Thread
  - IoT
---

**注意：该项目已经过期，不再提供维护与支持**

## 简介

RT-Thread 是一套国产 IoT 操作系统。

* [RT-Thread 首页](http://www.rt-thread.org/)
* [RT-Thread Git 仓库](https://github.com/rt-thread/)

为了降低 RT-Thread 的学习和开发门槛，我们为它开发了这套 RT-Thread Lab，它可以作为 [Cloud Lab](http://tinylab.org/cloud-lab) 的插件使用。

下面简单介绍一下如何通过 Cloud Lab 使用 RT-Thread Lab。

在正式使用之前，可以先看一下提前录制好的演示视频：

* [RT-Thread Lab 演示视频](http://showterm.io/942d1782b37d737b04856)

另外，这套 Lab 不一定有时间及时更新，后续 RT-Thread 的版本更新请参考它的持续构建配置文件：[.travis.yml](https://github.com/RT-Thread/rt-thread/blob/master/.travis.yml)。

## 安装 Docker

使用 RT-Thread Lab 之前，需要安装 Docker：

* Linux, Mac OSX, Windows 10: [Docker CE](https://store.docker.com/search?type=edition&offering=community)
* Old Windows: [Docker Toolbox](https://www.docker.com/docker-toolbox)

注意事项：

如果想免密使用，可以把用户加入 docker 用户组：

    $ sudo usermod -aG docker $USER

如果想更快下载 Docker 镜像，换个国内的源吧：

  * [阿里云 Docker 镜像使用文档](https://help.aliyun.com/document_detail/60750.html)
  * [USTC Docker 镜像使用文档](https://lug.ustc.edu.cn/wiki/mirrors/help/docker)

对于 12.04，更新内核后才能使用 Docker。

    $ sudo apt-get install linux-generic-lts-trusty

## 选择一个工作目录

如果通过 Docker Toolbox 安装的 Docker，请使用 Virtualbox 上的 default 系统中的 `/mnt/sda1` 作为工作目录，否则，掉电后数据会丢失，因为其他目录是只读的 iso 文件，挂载在内存中，关机后无法回写。

    $ cd /mnt/sda1

对于 Linux 或者 Mac OSX，可以使用 `~/Downloads` 或者 `~/Documents`。

    $ cd ~/Documents

## 下载 RT-Thread Lab

以 Ubuntu 为例，首先下载 Cloud Lab 管理框架，之后，下载相关环境的镜像和源代码：

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose rtthread-lab

## 运行并登陆

直接运行并自动登陆：

    $ tools/docker/run rtthread-lab

退出以后下次可直接登陆：

    $ tools/docker/vnc

## 使用 RT-Thread Lab

登陆以后，点击桌面的 'RT-Thread Lab' 快捷键，可进入该开发环境的主目录。

### 下载或更新 RT-Thread 源码

    $ make init

### Checkout 验证过的版本

  说明：新的版本可能要更新编译器或者调整 Makefile，具体请参考 README_zh.md 和 [RT-Thread ENV工具](https://www.rt-thread.org/page/download.html)。

    $ pushd rt-thread
    $ git checkout d629a3c87f
    $ git clean -fdx
    $ popd

### 配置 RT-Thread

    $ make config

### 编译 RT-Thread for qemu-vexpress-a9

    $ make build

### 通过 Qemu 运行（串口方式）

    $ make boot

### 通过 Qemu 运行（图形化方式）

目前实际的图形效果还没来得及添加，启动后请通过 `CTRL+ALT+4` 切到第 4 个控制台的 Shell 环境下：

    $ make boot G=1

### 配置网络

先获得主机 br0 设备的 IP：

    $ ifconfig br0 | grep inet
          inet addr:172.17.217.83  Bcast:172.17.255.255  Mask:255.255.0.0

然后随机选择该网段的一个 IP 作为 Guest 系统的 IP，并以 br0 IP 为网关：

    msh /> ifconfig e0 172.17.217.168 172.17.217.83 255.255.255.0
    config : e0
    IP addr: 172.17.217.168
    Gateway: 172.17.217.83
    netmask: 255.255.255.0

从主机 ping 往 Guest 进行测试：

    $ ping 172.17.217.168
    PING 172.17.217.168 (172.17.217.168) 56(84) bytes of data.
    64 bytes from 172.17.217.168: icmp_seq=1 ttl=255 time=1.96 ms

### 清理编译结果

    $ make clean

### 更多用法

    $ make help
