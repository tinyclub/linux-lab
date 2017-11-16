---
title: 'CS630 Qemu 汇编实验环境'
tagline: '通过 Qemu 学习旧金山大学的 CS630 汇编语言课程'
author: Wu Zhangjin
layout: page
permalink: /cs630-qemu-lab/
description: 通过 Qemu 学习旧金山大学的汇编语言课程 CS630。
update: 2015-10-1
categories:
  - 开源项目
  - 汇编
  - Qemu
tags:
  - CS630
---

## 简介

该项目致力于通过 Qemu 学习旧金山大学的汇编语言课程 [CS630][1]。

与此相关的是作者在大学二年级整理的[《汇编语言 王爽著》](/assembly/)，是一门基于 Windows 平台的汇编课程，而 CS630 是基于 Linux 平台的汇编课程。

[CS 630: Advanced Microcomputer Programming (Fall 2008)][1] 是我学过的最好的汇编语言课程，该课程针对 x86 架构, 为了更方便实验，我写了一系列脚本以便这些代码可以跑在 [Qemu][2] 上。

有了这些脚本，学生就可以很方便地在当前开发主机上实验，从而免去了不必要的重启，也避免了烧坏自己主机的风险。

## 在线演示

* [命令行视频](http://showterm.io/547ccaae139df14c3deec)
* [桌面演示视频](http://showdesk.io/1f06d49dfff081e9b54792436590d9f9/)

## 在线实验

* [泰晓实验云台](http://tinylab.cloud:6080/labs/)

## 实验代码

  * 仓库地址

    [https://github.com/tinyclub/cs630-qemu-lab.git][3]

  * 下载源码

        $ git clone https://github.com/tinyclub/cs630-qemu-lab.git

  * 安装 qemu 和编译环境（本地使用才需要，通过 Docker 使用不需要）

        $ sudo apt-get install qemu gcc gdb binutils

  * 下载汇编语言源码
    
        $ cd cs630-qemu-lab
        $ make update
    
    上述命令将从 CS630 课程网站 [CS 630: Advanced Microcomputer Programming (Fall 2006)][1] 下载最新的源码到 `res/`。

## 实验环境

[Cloud Lab](http://tinylab.org/how-to-deploy-cloud-labs/) 是泰晓科技开发的一套独立的虚拟实验环境，可快速构建和远程访问，方便企业和学校教学。

下面以 Ubuntu 为例。其他 Linux 和 Mac OSX 系统请先安装 [Docker CE](https://store.docker.com/search?type=edition&offering=community)。Windows 系统，请先下载并安装 [Docker Toolbox](https://www.docker.com/docker-toolbox)。

安装完 docker 后如果想免 `sudo` 使用 linux lab，请务必把用户加入到 docker 用户组并重启系统。

    $ sudo usermod -aG docker $USER

由于 docker 镜像文件比较大，有 1G 左右，下载时请耐心等待。另外，为了提高下载速度，建议通过配置 docker 更换镜像库为本地区的，更换完记得重启 docker 服务。

    $ grep registry-mirror /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --registry-mirror=https://docker.mirrors.ustc.edu.cn"
    $ service docker restart

如果 docker 默认的网络环境跟本地的局域网环境地址冲突，请通过如下方式更新 docker 网络环境，并重启 docker 服务。

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

请务必注意，通过 Docker Toolbox 安装的 `default` 系统中默认的 `/root` 目录仅仅挂载在内存中，关闭系统后数据会丢失，请千万不要用它来保存实验数据。可以使用另外的目录来存放，比如 `/mnt/sda1`，它是在 Virtualbox 上外挂的一个虚拟磁盘镜像文件，默认有 17.9 G，足够存放常见的实验环境。

### 工作目录

再次提醒，在 Linux 或者 Mac 系统，可以随便在 `~/Downloads` 或者 `~/Documents` 下找一处工作目录，然后进入，比如：

   $ cd ~/Documents

但是如果使用的是 Docker Toolbox 安装的 `default` 系统，该系统默认的工作目录为 `/root`，它仅仅挂载在内存中，因此在关闭系统后所有数据会丢失，所以需要换一处上面提到的 `/mnt/sda1`，它是外挂的一个磁盘镜像，关闭系统后数据会持续保存。

   $ cd /mnt/sda1

### 下载

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab && tools/docker/choose cs630-qemu-lab

### 安装

    $ tools/docker/run            # 加载镜像，拉起一个 CS630 Qemu Lab 容器

### 实验

执行 `tools/docker/vnc` 后会打开一个 VNC 网页，根据 console 提示输入密码登陆即可，之后打开桌面的 `CS630 Qemu Lab` 控制台并执行：

    $ make help
    $ make boot SRC=src/rtc.s

## 通过 Qemu 学 CS630

现在开学了，写了两个简单的文档: README.md 和 NOTE.md, 请参考它们做实验。

下面以 helloworld 和 rtc 为例展开：

### Real Mode

  * helloworld
    
        $ make boot SRC=src/helloworld.s
        

  * rtc
    
        $ make boot SRC=src/rtc.s
        

### Protected Mode

  * helloworld
    
        $ make boot SRC=res/pmhello.s
        

  * rtc
    
        $ make boot SRC=res/rtcdemo.s
        

## 演示图

下面是 rtcdemo 在 Qemu 上运行时的截图:

![image][4]

## 演示视频

<iframe src="http://showdesk.io/1f06d49dfff081e9b54792436590d9f9/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>


 [1]: http://www.cs.usfca.edu/~cruse/cs630f06/
 [2]: http://wiki.qemu.org/Main_Page
 [3]: https://github.com/tinyclub/cs630-qemu-lab
 [4]: /wp-content/uploads/2014/03/cs630-qemu-pmrtc.png
