---
title: 'Linux 内核实验环境'
tagline: '可快速构建，支持Docker/Qemu/Ubuntu/OS X/Windows/Web'
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
  * 代码仓库：[https://github.com/tinyclub/linux-lab.git][3]
  * 基本特性：
      * Qemu 支持的大量虚拟开发板，统统免费，免费，免费。
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 直接通过 Web 访问，非常便捷，便捷，便捷。
      * 已内置支持 4 大架构：ARM, MIPS, PowerPC 和 X86。
      * 已内置支持从 Ramfs, Harddisk, NFS rootfs 启动。
      * 一键即可启动，支持串口和图形启动。
      * 已内建网络支持，可以直接 ping 到外网。
      * 已内建 Uboot 支持，可以直接启动 Uboot，并加载内核和文件系统。
      * 预编译有 initrd 和内核镜像文件，可以快速体验实验效果。
      * 可灵活配置和扩展支持更多架构、虚拟开发板和内核版本。
      * 未来计划支持 Android emulator，支持在线调试。。。

## 相关文章

  * [利用 Linux Lab 完成嵌入式系统开发全过程][7]
  * [基于 Docker/Qemu 快速构建 Linux 内核实验环境][6]
  * [五分钟内搭建 Linux 0.11 的实验环境][4]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 五分钟教程

### 准备

以 Ubuntu 和 Qemu 为例。其他 Linux 和 Mac OSX 系统请先安装 [Docker CE](https://store.docker.com/search?type=edition&offering=community)。Windows 系统，请先下载并安装 [Docker Toolbox](https://www.docker.com/docker-toolbox)。

### 下载

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab && tools/docker/choose linux-lab

注意：安装完 docker 后如果想免 `sudo` 使用 linux lab，请务必把用户加入到 docker 用户组并重启系统。

    $ sudo usermod -aG docker $USER

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
