---
layout: post
author: 'Wu Zhangjin'
title: "国产操作系统 HotPot 快速上手"
group: original
permalink: /hot-pot-os-quickstart/
description: "HotPot 是一款有国内黑客主导开发的操作系统，主要供爱好者学习。"
category:
  - HotPot
tags:
  - 国产
  - 操作系统
---

> By Falcon of TinyLab.org
> 2016-03-20 01:26:15

## 简介

近日，来自中兴的 [kernel-hacker](http://weibo.com/u/2472448382) 在其微博宣布，一款名为 HotPot 的操作系统诞生了。作为业界知名的 Kernel Hacker，他曾经主导开源书籍 [Perf Book](https://www.kernel.org/pub/linux/kernel/people/paulmck/perfbook/perfbook.html) 的中文翻译。

作者很谦虚地宣称该操作系统是由一群自嘲为“傻瓜”的程序员开发的“玩具”操作系统，主要供爱好者学习。

## HotPot 详情

它到底是一款怎么样的操作系统呢？

* 项目首页：<http://115.28.165.172>
* 源码仓库：
    * HotPot官方仓库：https://code.csdn.net/xiebaoyou/hot-pot.git
    * 泰晓科技克隆版（含Docker实验环境）：<https://github.com/tinyclub/hot-pot-lab.git>
* 遵循协议：GPL
* 支持平台：CPU：ARM，Board：Beagle
* 当前特性：
    * ARM 单板小系统，含内存、时钟初始化。
    * 全局优化级调度模块，调度算法类似于 Linux 实时调度。
    * 最简单的内存管理模块，没有伙伴系统、也没有 SLAB 管理。但是调用接口与 kmalloc、kfree 兼容。
    * 一个存在 BUG 的 FAT 文件系统和块设备层实现。
    * 集成了 LWIP 协议栈。
    * 移植了常用的 C 库 API
* 未来计划：
    * 一个能在 Virtualbox 上运行起来的 x86 小系统，能提供定时器中断。
    * IDE 磁盘驱动。
    * USB 驱动（优先级略低，有熟悉的同学可以考虑做这个模块）。
    * 支持用户态任务。
    * 常用用户态 C 库 API 移植，可参考开源实现。
    * 文件系统框架。
    * 现有模块的优化。
    * 各个模块的文档
    * 实验环境的安装，整理成文档。
    * 出书

另外，HotPot 的作者呼吁任何建设性的建议和优雅的代码。

HotPot 的名字很奇怪，但是从作者的工作地点（成都）不难看出一些端倪。

## HotPot 上手

### 开发 Docker 实验环境

本文并不尝试马上阅读和分析相关代码，先把环境快速搭建起来。

HotPot 当前已经支持 ARM 架构的 Beagle Board，只不过实际开发用的是 Qemu 虚拟机。而官方 Qemu 目前还不支持 Beagle，只有 Linaro 社区的代码才支持，所以得自己编译。我们克隆了一份 HotPot 代码并加入了 Dockerfile 以便支持环境的快速搭建。

除了添加 Docker 支持外，还做了其他内容的部分调整，这些调整包括配置，编译，Clean，.gitignore 等方面，甚至也大大减少了 beagle.img 的大小（从 3G 到 8M），不仅节省了存储开销，并节约了实验时解压它的时间。

相关的改进放置在 Github 上，代码地址如下：<https://github.com/tinyclub/hot-pot-lab.git>，后续会尝试 Upstream 到原作者的仓库。

### 快速上手 HotPot

有了 Docker 支持，我们就可以跟随 [README.md](https://github.com/tinyclub/hot-pot-lab/blob/master/README.md)，几步就搞定实验环境并把 HotPot 跑起来。

* 克隆 HotPot Lab

      $ git clone https://github.com/tinyclub/hot-pot-lab.git

* 搭建环境

      $ cd hot-pot-lab/lab

  对于 Ubuntu 14.04：

      $ sudo ./lab-env

  或自行安装 [docker-engine](https://docs.docker.com/engine/installation/linux/)，然后自助构建 docker 镜像：

      $ docker build -t tinylab/hot-pot-lab .

* 启动环境

      $ ./lab-build
      root@687031bd8f37:/hot-pot-lab# exit
      $ ./lab-start
      root@687031bd8f37:/hot-pot-lab#

* 配置，编译和引导

      root@687031bd8f37:/hot-pot-lab# ./arm.config
      root@687031bd8f37:/hot-pot-lab# ./arm.compile
      root@687031bd8f37:/hot-pot-lab# ./arm.run
      Texas Instruments X-Loader 1.5.1 (Jul 26 2011 - 00:39:12)
      Beagle xM
      Reading boot sector
      Loading u-boot.bin from mmc


      U-Boot 2011.06 (Aug 19 2011 - 17:43:34)

      OMAP36XX/37XX-GP ES2.0, CPU-OPP2, L3-165MHz, Max CPU Clock 1 Ghz
      OMAP3 Beagle board + LPDDR/NAND
      I2C:   ready
      DRAM:  512 MiB
      NAND:  256 MiB
      MMC:   OMAP SD/MMC: 0
      *** Warning - bad CRC, using default environment

      ERROR : Unsupport USB mode
      Check that mini-B USB cable is attached to the device
      In:    serial
      Out:   serial
      Err:   serial
      Beagle xM Rev A
      No EEPROM on expansion board
      Die ID #51454d5551454d555400000051454d55
      Hit any key to stop autoboot:  0
      SD/MMC found on device 0
      reading boot.scr

      508 bytes read
      Running bootscript from mmc ...
      ## Executing script at 82000000
      reading uImage

      207208 bytes read
      reading uInitrd

      1856548 bytes read
      reading board.dtb

      316 bytes read
      ## Booting kernel from Legacy Image at 80000000 ...
         Image Name:   Linux-2.6.36.1xby.0217001-g4f759
         Image Type:   ARM Linux Kernel Image (uncompressed)
         Data Size:    207144 Bytes = 202.3 KiB
         Load Address: 80008000
         Entry Point:  80008000
         Verifying Checksum ... OK
      ## Loading init Ramdisk from Legacy Image at 81600000 ...
         Image Name:   initramfs
         Image Type:   ARM Linux RAMDisk Image (uncompressed)
         Data Size:    1856484 Bytes = 1.8 MiB
         Load Address: 00000000
         Entry Point:  00000000
         Verifying Checksum ... OK
      ## Flattened Device Tree blob at 815f0000
         Booting using the fdt blob at 0x815f0000
         Loading Kernel Image ... OK
      OK
         Using Device Tree in place at 815f0000, end 815f313b

      Starting kernel ...

      Uncompressing Linux... done, booting the kernel.
      Serial driver version 4.11 with no serial options enabled
      tty00 at 0xf9e09000 (irq = 4) is a 8250
      omap_serial_init
      RAMDISK: 4194304 bytes, starting at 0xc0902820

      VFS: Insert ramdisk floppy and press ENTER
      VFS: Mounted root (msdos filesystem) readonly.

          ##############################################
          #                                            #
          #  *   *   ***   *****  ****    ***   *****  #
          #  *   *  *   *    *    *   *  *   *    *    #
          #  *   *  *   *    *    *   *  *   *    *    #
          #  *****  *   *    *    ****   *   *    *    #
          #  *   *  *   *    *    *      *   *    *    #
          #  *   *  *   *    *    *      *   *    *    #
          #  *   *   ***     *    *       ***     *    #
          #                                            #
          ##############################################

      [dim-sum@hot pot]#

  如果想退出 HotPot 命令行，按下 `CTRL+C` 即可。

  环境搭建好以后，大家就可以自行阅读、分析和修改代码了，有好的建议和修改别忘记 Upstream 回 HotPot 仓库或者发 PR 给 [HotPot Lab](https://github.com/tinyclub/hot-pot-lab.git) 哈。
