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

  * 使用文档：[README_zh.md][2]

  * 视频教程
      * [Linux Lab 公开课](https://www.cctalk.com/m/group/88948325)
          * Linux Lab 简介
          * 龙芯 Linux 内核开发
      * [《360° 剖析 Linux ELF》](https://www.cctalk.com/m/group/88089283)
          * 该课程全程采用 Linux Lab 开展实验，提供了上百个实验案例

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
      * 其他
          * [Linux Lab v0.1-rc1 的所有板子启动测试结果](http://showterm.io/8cd2babf19e0e4f90897e)
          * [在 arm/vexpress-a9 上运行 Ubuntu 18.04 LTS](http://showterm.io/c351abb6b1967859b7061)
          * [使用 riscv32/virt 和 riscv64/virt 开发板](http://showterm.io/37ce75e5f067be2cc017f)
          * [一条命令测试和体验某个内核特性](http://showterm.io/7edd2e51e291eeca59018)
          * [一条命令配置、编译和测试内核模块](http://showterm.io/26b78172aa926a316668d)

  * 代码仓库
      * [https://gitee.com/tinylab/linux-lab.git][10]
      * [https://github.com/tinyclub/linux-lab.git][3]

  * 基本特性：
      * 跨平台，支持 Linux, Windows 和 Mac OSX。
      * Qemu 支持的大量虚拟开发板，统统免费，免费，免费。
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 直接通过 Web 访问，非常便捷，便捷，便捷。
      * 已内置支持 7 大架构：ARM, MIPS, PowerPC, X86, Risc-V, Loongson, Csky。
      * 已内置支持 18 款开发板：i386+X86_64/PC, PowerPC/G3beige, MIPS/Malta, ARM/versatilepb, ARM/vexpress-a9, ARM/mcimx6ul-evk, ARM/ebf-imx6ull, ARM64/Virt, ARM64/Raspi3, Riscv32+64/Virt, Loongson/{ls1b, ls232, ls2k, ls3a7a}, Csky/ck810 全部升级到了最新的 v5.1（其中 Riscv32/Virt 仅支持 V5.0）。
      * 已内置支持从 Ramfs, Harddisk, NFS rootfs 启动。
      * 一键即可启动，支持 串口 和 图形 启动。
      * 已内建网络支持，可以直接 ping 到外网。
      * 已内建 Uboot 支持，可以直接启动 Uboot，并加载内核和文件系统。
      * 预编译有 内核镜像、Rootfs、Qemu、Toolchain，可以快速体验实验效果。
      * 可灵活配置和扩展支持更多架构、虚拟开发板和内核版本。
      * 支持在线调试和自动化测试框架。
      * 正在添加 树莓派raspi3 和 risc-v 支持。

## Linux Lab 真盘

  Linux Lab v0.7 版支持 “Linux Lab 真盘”，实现 Linux Lab 的即插即用，完全免安装，进一步提升 Linux Lab 使用体验，快速高效地开展 Linux 相关实验与开发。

![Linux Lab 真盘](/wp-content/uploads/2021/03/linux-lab-disk.png)

  使用文档：

  * [Linux Lab 真盘开发日志（1）：在 Windows 下直接启动 Linux Lab Disk，当双系统使用](/linux-lab-disk-windows-boot)
  * [Linux Lab 真盘开发日志（2）：在 macOS 下直接启动 Linux Lab Disk，当双系统使用](/linux-lab-disk-macos-boot)
  * [Linux Lab 真盘开发日志（3）：在 Linux 下直接启动 Linux Lab Disk，当双系统使用](/linux-lab-disk-linux-boot)

  购买地址：

  * [在某宝搜索 “Linux Lab 真板” 即可选购](https://shop155917374.taobao.com/)

## Linux Lab 真板

  Linux Lab v0.6 版支持 “Linux Lab 真板”，实现了对真实嵌入式开发板的完美支持，从此，不仅可以使用 Linux Lab 学习 Linux 内核，还可以用它来做 Linux 驱动开发。

![Linux Lab 真板](/wp-content/uploads/2021/01/linux-lab/ebf-imx6ull.png)

  使用文档：

  * [Linux Lab 真板开发日志（1）：50 天开发纪要与上手初体验](/linux-lab-imx6ull-part1)
  * [Linux Lab 真板开发日志（2）：macOS 和 Windows 环境之无串口开发](/linux-lab-imx6ull-part2)
  * [Linux Lab 真板开发日志（3）：macOS 环境之 SD 卡、无线网卡、虚拟串口](/linux-lab-imx6ull-part3)
  * [Linux Lab 真板开发日志（4）：上手全平台 GUI 库 GuiLite](/linux-lab-imx6ull-part4)

  购买地址：

  * [在某宝搜索 “Linux Lab 真板” 即可选购](https://shop155917374.taobao.com/)

## 更多用法

* [Linux Lab：难以抗拒的十大理由 V1.0](http://tinylab.org/why-linux-lab)
* [Linux Lab：难以抗拒的十大理由 V2.0](http://tinylab.org/why-linux-lab-v2)
* [Linux Lab 龙芯实验手册 V0.2](http://tinylab.org/pdfs/linux-lab-loongson-manual-v0.2.pdf)
* Linux Lab 视频公开课
    * [CCTALK](https://www.cctalk.com/m/group/88948325)
    * [B 站](https://space.bilibili.com/687228362/channel/detail?cid=152574)
    * [知乎](https://www.zhihu.com/people/wuzhangjin)
* 采用 Linux Lab 作为实验环境的视频课程
    * [《360° 剖析 Linux ELF》](https://www.cctalk.com/m/group/88089283)

## 五分钟教程

以 Ubuntu 为例，请先参考其他资料安装好 Docker。

### 下载

    $ git clone https://gitee.com/tinylab/cloud-lab.git
    $ cd cloud-lab && tools/docker/choose linux-lab

### 安装

    $ tools/docker/run            # 加载镜像，拉起一个 Linux Lab 容器

### 快速尝鲜

执行 `tools/docker/webvnc` 后会打开一个 VNC 网页，根据 console 提示输入密码登陆即可，之后打开桌面的 `Linux Lab` 控制台并执行：

    $ make boot

启动后，会打印如下登陆提示符，输入 root，无需密码直接按下 Enter 键即可。

    Welcome to Linux Lab

    linux-lab login: root

    # uname -a
    Linux linux-lab 5.1.0 #3 SMP Thu May 30 08:44:37 UTC 2019 armv7l GNU/Linux

默认会启动一个 `versatilepb` 的 ARM 板子，要指定一块开发板，可以用：

    $ make list                   # 查看支持的列表
    $ make BOARD=malta            # 这里选择一块 MIPS 板子：malta
    $ make boot

### 配置

    $ make kernel-checkout        # 检出某个特定的分支（请确保做该操作前本地改动有备份）
    $ make kernel-defconfig       # 配置内核
    $ make kernel-menuconfig      # 手动配置内核

### 编译

    $ make kernel       # 编译内核，采用 Ubuntu 和 emdebian.org 提供的交叉编译器

### 保存所有改动

    $ make save         # 保存新的配置和新产生的镜像

    $ make kconfig-save # 保存到 boards/BOARD/

    $ make kernel-save

### 启动新的内核

只要有新编译的内核，就会自动启动：

    $ make boot

### 启动串口

    $ make boot G=0	# 使用组合按键：`CTL+a x` 退出，或者另开控制台执行：`pkill qemu`

### 选择 Rootfs 设备

    $ make boot ROOTDEV=/dev/nfs
    $ make boot ROOTDEV=/dev/ram

### 扩展

通过添加或者修改 `boards/BOARD/Makefile`，可以灵活配置开发板、内核版本以及 BuildRoot 等信息。通过它可以灵活打造自己特定的 Linux 实验环境。

    $ cat boards/arm/versatilepb/Makefile
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

 [2]: https://gitee.com/tinylab/linux-lab/blob/master/README_zh.md
 [3]: https://github.com/tinyclub/linux-lab
[10]: https://gitee.com/tinylab/linux-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
 [6]: http://tinylab.org/docker-qemu-linux-lab/
 [7]: http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/
