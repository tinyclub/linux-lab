---
title: 'Linux 内核实验环境'
tagline: '可快速构建，支持 Docker, Qemu, Ubuntu, Mac OSX, Windows, Web'
author: Wu Zhangjin
layout: page
permalink: /linux-lab/
description: 基于 Qemu 的 Linux 内核开发环境，支持 Docker, 支持 Ubuntu / Windows / Mac OS X，也内置支持 Qemu，支持通过 Web 远程访问。
update: 2016-06-19
categories:
  - 开源项目
  - Linux Lab
tags:
  - 实验环境
  - Lab
  - Qemu
  - Docker
  - Uboot
  - 内核
  - 嵌入式
---

## 项目描述

该项目致力于快速构建一个基于 Qemu 的 Linux 内核开发环境。

  * 使用文档：[README.md][2]

  * 在线实验
      * [泰晓实验云台](http://tinylab.cloud:6080/labs/)

  * 在线演示
      * 命令行
          * [Linux 快速上手](http://showterm.io/6fb264246580281d372c6)
          * [Uboot 快速上手](http://showterm.io/11f5ae44b211b56a5d267)
          * [AT&T 汇编上手](http://showterm.io/0f0c2a6e754702a429269)
          * [C 语言上手](http://showterm.io/a98435fb1b79b83954775)
          * [C 语言编译过程](http://showterm.io/887b5ee77e3f377035d01)
          * [Shell语言上手](http://showterm.io/445cbf5541c926b19d4af)
      * 视频
          * [Linux 基本用法](http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8)
          * [Linux 进阶用法](https://v.qq.com/x/page/y0543o6zlh5.html)
          * [Uboot 基本用法](https://v.qq.com/x/page/l0549rgi54e.html)

  * 代码仓库
      * [https://github.com/tinyclub/linux-lab.git][3]

  * 基本特性：
      * 跨平台，支持 Linux, Windows 和 Mac OSX。
      * Qemu 支持的大量虚拟开发板，统统免费，免费，免费。
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 直接通过 Web 访问，非常便捷，便捷，便捷。
      * 已内置支持 4 大架构：ARM, MIPS, PowerPC 和 X86。
      * 已内置支持 6 款开发板：X86+X86_64/PC, PowerPC/G3beige, MIPS/Malta, ARM/versatilepb, ARM/vexpress-a9, ARM64/Virt, 全部升级到了最新的 v5.1。
      * 已内置支持从 Ramfs, Harddisk, NFS rootfs 启动。
      * 一键即可启动，支持 串口 和 图形 启动。
      * 已内建网络支持，可以直接 ping 到外网。
      * 已内建 Uboot 支持，可以直接启动 Uboot，并加载内核和文件系统。
      * 预编译有 内核镜像、Rootfs、Qemu、Toolchain，可以快速体验实验效果。
      * 可灵活配置和扩展支持更多架构、虚拟开发板和内核版本。
      * 支持在线调试和自动化测试框架。
      * 正在添加 树莓派raspi3 和 risc-v 支持。

  * 插件
      * [RLK4.0](https://github.com/tinyclub/rlk4.0)：《奔跑吧Linux内核 4.0》一书课程实验
      * [CSKY](https://github.com/tinyclub/csky)：中天微国产处理器 [C-SKY Linux](https://c-sky.github.io) 开发插件

## 相关文章

  * [利用 Linux Lab 完成嵌入式系统开发全过程][7]
  * [基于 Docker/Qemu 快速构建 Linux 内核实验环境][6]
  * [五分钟内搭建 Linux 0.11 的实验环境][4]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 五分钟教程

### 准备

以 Ubuntu 和 Qemu 为例。其他 Linux 和 Mac OSX 系统请先安装 [Docker CE](https://store.docker.com/search?type=edition&offering=community)。Windows 系统，请先下载并安装 [Docker Toolbox](https://www.docker.com/docker-toolbox)。

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

如果上述改法不生效，请在类似 `/lib/systemd/system/docker.service` 这样的文件中修改后再重启 docker 服务。

    $ grep dockerd /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16 --registry-mirror=https://docker.mirrors.ustc.edu.cn
    $ service docker restart

如果使用 Docker Toolbox，由于安装的默认 `default` 系统未提供桌面，所以需要先获取该系统的外网地址，即 eth1 网口的 IP 地址，然后在外部系统访问。

    $ ifconfig eth1 | grep 'inet addr' | tr -s ' ' | tr ':' ' ' | cut -d' ' -f4
    192.168.99.100

如果是自己通过 Virtualbox 安装的 Linux 系统，即使有桌面，也想在外部系统访问时，则可以通过设置 'Network -> Adapter2 -> Host-only Adapter' 来添加一个 eth1 网口设备。

请务必注意，通过 Docker Toolbox 安装的 `default` 系统中默认的 `/root` 目录仅仅挂载在内存中，关闭系统后数据会丢失，请千万不要用它来保存实验数据。可以使用另外的目录来存放，比如 `/mnt/sda1`，它是在 Virtualbox 上外挂的一个虚拟磁盘镜像文件，默认有 17.9 G，足够存放常见的实验环境。

### 工作目录

再次提醒，在 Linux 或者 Mac 系统，可以随便在 `~/Downloads` 或者 `~/Documents` 下找一处工作目录，然后进入，比如：

    $ cd ~/Documents

但是如果使用的是 Docker Toolbox 安装的 `default` 系统，该系统默认的工作目录为 `/root`，它仅仅挂载在内存中，因此在关闭系统后所有数据会丢失，所以需要换一处上面提到的 `/mnt/sda1`，它是外挂的一个磁盘镜像，关闭系统后数据会持续保存。

    $ cd /mnt/sda1

### 下载

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab && tools/docker/choose linux-lab

### 安装

    $ tools/docker/run            # 加载镜像，拉起一个 Linux Lab 容器

### 快速尝鲜

执行 `tools/docker/vnc` 后会打开一个 VNC 网页，根据 console 提示输入密码登陆即可，之后打开桌面的 `Linux Lab` 控制台并执行：

    $ make boot

默认会启动一个 `versatilepb` 的 ARM 板子，要指定一块开发板，可以用：

    $ make list                   # 查看支持的列表
    $ make BOARD=malta             # 这里选择一块 MIPS 板子：malta
    $ make boot

### 下载更多源码

    $ make core-source -j3             # 同时下载 linux-stable, qemu 和 buildroot

### 配置

    $ make root-defconfig         # 配置根文件系统
    $ make kernel-checkout        # 检出某个特定的分支（请确保做该操作前本地改动有备份）
    $ make kernel-defconfig       # 配置内核

    $ make root-menuconfig         # 手动配置根文件系统
    $ make kernel-menuconfig       # 手动配置内核

### 编译

    $ make root         # 编译根文件系统，稍微有点慢，需要下载带 sysroot 的编译器
    $ make kernel       # 编译内核，采用 Ubuntu 和 emdebian.org 提供的交叉编译器

### 保存所有改动

    $ make save         # 保存新的配置和新产生的镜像

    $ make kconfig-save # 保存到 boards/BOARD/
    $ make rconfig-save

    $ make root-save    # 保存到 prebuilt/
    $ make kernel-save

### 启动新的根文件系统和内核

需要打开 `boards/BOARD/Makefile` 屏蔽已经编译的 `KIMAG` 和 `ROOTFS`，此时会启动 `output/` 目录下刚编译的 rootfs 和内核：

    $ vim boards/versatilepb/Makefile
    #KIMAGE=$(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/zImage
    #ROOTFS=$(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/rootfs.cpio.gz
    $ make boot

### 启动串口

    $ make boot G=0	# 使用组合按键：`CTL+a x` 退出，或者另开控制台执行：`pkill qemu`

### 选择 Rootfs 设备

    $ make boot ROOTDEV=/dev/nfs
    $ make boot ROOTDEV=/dev/ram

### 扩展

通过添加或者修改 `boards/BOARD/Makefile`，可以灵活配置开发板、内核版本以及 BuildRoot 等信息。通过它可以灵活打造自己特定的 Linux 实验环境。

    $ cat boards/versatilepb/Makefile
    ARCH=arm
    XARCH=$(ARCH)
    CPU=arm926t
    MEM=128M
    LINUX=2.6.35
    NETDEV=smc91c111
    SERIAL=ttyAMA0
    ROOTDEV=/dev/nfs
    ORIIMG=arch/$(ARCH)/boot/zImage
    CCPRE=arm-linux-gnueabi-
    KIMAGE=$(PREBUILT_KERNEL)/$(XARCH)/$(BOARD)/$(LINUX)/zImage
    ROOTFS=$(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/rootfs.cpio.gz

默认的内核与 Buildroot 信息对应为 `boards/BOARD/linux_${LINUX}_defconfig` 和 `boards/BOARD/buildroot_${CPU}_defconfig`，如果要添加自己的配置，请注意跟 `boards/BOARD/Makefile` 里头的 CPU 和 Linux 配置一致。

### 更多用法

详细的用法这里就不罗嗦了，大家自行查看帮助。

    $ make help

### 实验效果图

![Linux Lab Demo](/wp-content/uploads/2016/06/docker-qemu-linux-lab.jpg)

## 演示视频

<iframe src="http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>

 [2]: https://github.com/tinyclub/linux-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/linux-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
 [6]: http://tinylab.org/docker-qemu-linux-lab/
 [7]: http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/
