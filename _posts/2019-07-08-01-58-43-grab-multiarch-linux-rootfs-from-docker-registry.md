---
layout: post
author: 'Wu Zhangjin'
title: "从 Docker 镜像中随时抓取想要的 Linux Rootfs"
draft: false
permalink: /grab-multiarch-linux-rootfs-from-docker-registry/
description: "Rootfs 是学习嵌入式 Linux 不可或缺的，对于一个全新处理器架构而言，快速获得一个可用的 Rootfs 非常关键，本文介绍如何从 Docker 镜像库中获取这样的资源。"
category:
  - 根文件系统
tags:
  - Docker
  - Debian
  - Ubuntu
  - rootfs
  - Linux Lab
---

> By Falcon of [TinyLab.org][1]
> Jul 04, 2019

[Linux Lab 新增全功能 Rootfs 支持](http://tinylab.org/linux-lab-full-rootfs/) 一文不仅介绍了 7 种 Linux 文件系统的制作方法，也介绍了如何把文件系统制作成 Docker 镜像并发布到 Docker 官方镜像库中。

实际上，也有其他人在 Docker 镜像库中发布了很多的文件系统，而其中比较正式的当属 Ubuntu 和 Debian 的 Rootfs，以 arm64v8 举个例子：

    $ docker search --no-trunc arm64 | egrep "ubuntu|debian"
    arm64v8/ubuntu Ubuntu is a Debian-based Linux operating system based on free software.                   25
    arm64v8/debian Debian is a Linux distribution that's composed entirely of free and open-source software. 20

进一步调查，发现 Docker 官方提供多种处理器架构和各种版本的 Ubuntu 和 Debian 文件系统，这些文件系统虽然不是 Full Rootfs，但是因为有包管理工具，很容易扩展功能，所以很适合嵌入式系统开发。

  * [arm64v8/debian docker image](https://hub.docker.com/r/arm64v8/debian)
  * [arm64v8/ubuntu docker image](https://hub.docker.com/r/arm64v8/ubuntu)

除了 arm64v8，两种发行版当前支持的架构列表如下：

  * Ubuntu: amd64, arm32v7, arm64v8, i386, ppc64le, s390x
  * Debian: amd64, arm32v5, arm32v7, arm64v8, i386, ppc64le, s390x

通过 [Linux Lab](/linux-lab) 的工具，可以直接从这些镜像中抽取出文件系统（请确保已经安装了 `qemu-user-static`）：

    $ cd linux-lab
    $ tools/rootfs/docker/extract.sh arm64v8/debian aarch64
    $ ls prebuilt/fullroot/tmp/arm64v8-debian/

这个脚本做了几个事情：

**拉取镜像**

    $ docker pull arm64v8/debian

**启动镜像**

    $ cid=$(docker run -d -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static arm64v8/debian)

**拷贝出文件系统**

    $ rootdir=prebuilt/fullroot/tmp/arm64v8-debian/
    $ mkdir -p $rootdir
    $ sudo docker cp $cid:/ $rootdir
    $ sudo chown $USER:$USER -R $rootdir

**删除容器**

    $ sudo docker rm -f $cid

拉取下来的文件系统带有 `apt-get`，可以用 chroot 或者 docker 运行起来，安装更多需要的工具：

    $ tools/rootfs/docker/run.sh arm64v8/debian aarch64
    LOG: Running arm64v8/debian
    root@57471f588826:/#
    root@57471f588826:/#

    $ tools/rootfs/docker/chroot.sh arm64v8/debian
    LOG: Chroot into ./prebuilt/fullroot/tmp/arm64v8-debian
    [sudo] password for falcon:
    root@ubuntu:/#

由于文件系统比较简陋，不带编辑器，建议在本地修改好文件系统中的 apt 源，改成国内比较快的[镜像站](http://tinylab.org/mirror-sites-in-great-china/)：

    $ cd $rootdir
    $ vim etc/apt/sources.list

之后就可以用到目标环境中，比如在 Linux Lab 下，可以用 `ROOTFS` 直接指定作为文件系统启动：

    $ make b=aarch64/virt boot ROOTFS=$PWD/prebuilt/fullroot/tmp/arm64v8-debian/

更进一步的调查发现，Ubuntu 和 Debian 镜像用到的 rootfs 源自这里：

  * Ubuntu: <https://partner-images.canonical.com/core/>
  * Debian: <https://github.com/debuerreotype/docker-debian-artifacts/tree/dist-arm64v8>
    (Debian 需要通过切换不同分支获取不同架构）

所以，如果没有安装 docker，也可以从上述路径直接下载目标架构最新的 rootfs。

[1]: http://tinylab.org
