---
layout: post
author: 'Wu Zhangjin'
title: "利用 Linux Lab 完成嵌入式系统开发全过程"
permalink: /using-linux-lab-to-do-embedded-linux-development/
description: "本文详细介绍了如何利用 Linux Lab 来搭建一个基于 ARM 的嵌入式 Linux 系统，并详细介绍了 U-boot, Linux Kernel, 根文件系统的相关操作，比如配置、编译、制作与引导。"
category:
  - Linux Lab
  - Qemu
tags:
  - 嵌入式
  - Docker
  - Buildroot
  - Uboot
  - Linux
  - 内核
---

> By Falcon of [TinyLab.org](http://tinylab.org)
> 2016-10-03 20:37:27

## 简介

早在 2013 年，本站发表过一篇文章：[利用 qemu 模拟嵌入式系统制作全过程][1]，该文详细介绍了如何利用 Qemu 来搭建一个基于 ARM 的嵌入式 Linux 系统，内容涵盖：

* 配置/编译 Linux Kernel
* 配置/编译 Busybox 并制作成 initramfs
* 配置物理文件系统，切换根文件系统类型
* 配置/编译 Uboot，加载 Linux Kernel

今年年中，本站又推出了一款 [Linux Lab][2]，它不仅适合做 Linux 内核开发，也提供了完整的嵌入式 Linux 系统开发环境；不仅涵盖上述过程，而且更加自动化和便捷。最核心的好处有：

* 基于 Qemu，提供了大量免费的虚拟开发板
* 开发环境可快速构建，基于 Docker 一键构建，避免执行一堆命令
* Repeatable，在不同机器上有同样表现
* 聚焦开发本身，避免浪费精力在环境搭建上

下面以类似的章节来对照介绍。

## 环境搭建

首先把 Linux Lab 下载下来：

    $ git clone https://github.com/tinyclub/linux-lab.git

由于 Linux Lab 把所有的环境 docker 容器化了，只需要一条命令即可构建，以 Ubuntu 为例：

    $ cd linux-lab
    $ sudo tools/install-docker-lab.sh
    $ tools/update-lab-uid.sh   # 同步本地和容器内的用户 id，确保文件属主一致
    $ tools/update-lab-identify.sh  # 禁用登录密码，避免每次输入密码麻烦

接着就可以启动该环境：

    $ tools/run-docker-lab.sh

上述命令启动容器并运行浏览器，浏览器打开后可点击页面右上角的 Connect 即可进入开发环境，退出浏览器后可用如下命令再次登录：

    $ tools/open-docker-lab.sh

关机后可以通如下命令快速恢复：

    $ tools/start-docker-lab.sh

也可先调用 `tools/kill-docker-lab.sh` 删除该容器后再通过 `tools/run-docker-lab.sh` 重构。

登进 Linux Lab 后，可在桌面看到三个快捷图标：

* Demo Page：基于 showterm.io 录制的命令行操作：<http://showterm.io/6fb264246580281d372c6>
* Help Page：直接链接到 Linux Lab 项目首页：<http://tinylab.org/linux-lab>
* Linux Lab：点击后可快速启动控制台并进入到开发环境所在的目录。

在进行下述完整过程之前，可以利用预编译的镜像快速上手体验：

    $ make boot

上述命令会在 Qemu 虚拟的 `versatilepb` 板子上启动存放在 `prebuilt/` 目录下的预编译好的内核镜像、DTB 和根文件系统。

## 下载 Uboot, Linux, Buildroot 源码

直接一键拉取所需的源码：

    $ make core-source

也可单独下载：

    $ make uboot-source
    $ make kernel-source
    $ make root-source

源码从如下镜像站获取：

* u-boot: https://github.com/u-boot/u-boot.git
* linux-stable: https://github.com/tinyclub/linux-stable.git
* buildroot: https://github.com/buildroot/buildroot.git

说明：

* buildroot 内含 Busybox 等大量嵌入式系统所需的软件包，用它可以大大简化根文件系统的制作。
* 也可从其他源自行拉取所需源码，可使用默认目录：u-boot, linux-stable 和 buildroot，也可更新 Makefile 中对应的配置：`BOOTLOADER_SRC`, `KERNEL_SRC` 和 `BUILDROOT_SRC`。

## 选择或者添加一款虚拟开发板

### 选择已有的板子

Linux Lab 理论上支持所有 Qemu 内置的十几款处理器架构和几十款开发板，目前已实际加入了 4 个架构（ARM、MIPS、PPC、X86），5 个开发板（versatilepb, vexpress-a9, malta, g3beige, pc）：

    $ make list-short
    [ pc ]:
          ARCH     = x86
          CPU     ?= i686
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0
    [ g3beige ]:
          ARCH     = powerpc
          CPU     ?= generic
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0
    [ vexpress-a9 ]:
          ARCH     = arm
          CPU     ?= cortex-a9
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/mmcblk0
    [ malta ]:
          ARCH     = mips
          CPU     ?= mips32r2
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0
    [ versatilepb ]:
          ARCH     = arm
          CPU     ?= arm926t
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0

可以这样选择一款已经添加的板子，类似那篇 [利用 qemu 模拟嵌入式系统制作全过程][1]，本文也以 versatilepb 为例：

    $ make MACH=versatilepb

### 添加一款新板子

如果要添加一款板子，可对照现有板子中的一个，复制一份 `machine/BOARD/` 并做相应配置即可。

先来看看现在的板子，以 versatilepb 为例：

    $ ls machine/versatilepb/

* 板子配置：Makefile（TODO：部分变量名有待优化）
    * ARCH：处理器架构
    * XARCH: 包含大小端、指令长度等信息，为兼容 `qemu-system-XARCH` 而设置
    * CPU：指令集
    * MEM: 内存大小
    * UBOOT: Uboot 版本号
    * LINUX: Linux 版本号
    * KRN_ADDR: Uboot 加载内核镜像的地址
    * RDK_ADDR: Uboot 加载 Ramdisk 的地址
    * DTB_ADDR: Uboot 加载 DTB 的地址
    * UCONFIG: Uboot 板级配置文件，配置工具：tools/uboot/config.sh
    * NETDEV：网卡设备
    * SERIAL：串口设备
    * ROOTDEV：根文件系统类型，支持 /dev/ram, /dev/nfs, /dev/sda, /dev/mmcblk0
    * FSTYPE：根文件系统格式，默认为 ext2
    * ORIIMG：内核镜像原生路径，例如：arch/$(ARCH)/boot/zImage
    * UORIIMG：可用于 Uboot 加载的内核镜像文件路径，例如：arch/$(ARCH)/boot/uImage
    * ORIDTB：DTB 文件原生路径，例如：arch/$(ARCH)/boot/dts/versatile-pb.dtb
    * CCPRE：交叉编译工具前缀，例如：arm-linux-gnueabi-
    * BIMAGE：预先构建的 Bootloader 镜像文件路径
    * KIMAGE：预先构建的内核镜像文件路径
    * DTB   ：预先构建的 DTB 文件路径
    * UKIMAGE：预先构建的 Uboot 可加载内核镜像文件
    * ROOTFS ：预先构建的 Ramdisk
    * UROOTFS：预先构建的 Uboot 可加载的 Ramdisk
    * HROOTFS：预先构建的根文件系统，虚拟硬盘版
* Buildroot 配置文件：buildroot_arm926t_defconfig
* Linux 配置文件：linux_2.6.35_defconfig, linux_2.6.36_defconfig, linux_4.6_defconfig
* Uboot 配置文件：uboot_v2015.07_defconfig

配置板子时，可以参考 `qemu-system-ARCH -M ?`, `doc/qemu-doc.html`, `buildroot/board/qemu/`, `linux-stable/arch/ARCH/configs/`, `buildroot/configs/`, `u-boot/configs/`。详细的添加过程我们将用另外一篇文章进行深入介绍。

## 配置/编译 Linux Kernel

检出所需的内核版本（注：会 Reset 掉历史修改，请注意备份变更）

    $ make kernel-checkout

使能默认配置文件：

    $ make kernel-defconfig

添加/修改所需配置选项：

    $ make kernel-menuconfig

交叉编译内核，如果配置了 `UBOOT`，会自动编译 `uImage`：

    $ make kernel

如果支持 DTB，也会自动生成 DTB 文件。

如果要保存内核配置文件（存回 `machine/versatilepb/`），可执行：

    $ make kconfig-save

而要保存内核镜像文件、DTB 等（存到 `prebuilt/kernel/`），可执行：

    $ make kernel-save

## 配置/编译 Buildroot 并制作成 Ramdisk

用法跟上面几乎一致，使能默认配置文件：

    $ make root-defconfig

添加/修改所需配置选项：

    $ make root-menuconfig

交叉编译根文件系统，可在上面配置根文件系统类型，比如 Ramdisk 或者是磁盘镜像：

    $ make root

Linux Lab 也提供了一个脚本：`tools/rootfs/mkfs.sh` 用于自动从 Ramdisk 生成所需格式的磁盘镜像文件，Linux Lab 会依据 `ROOTDEV` 自动搞定所有根文件系统的转换。

如果要保存 Buildroot 配置文件（存回 `machine/versatilepb/`），可执行：

    $ make rconfig-save

而要保存文件系统镜像（存到 `prebuilt/root/`），可执行：

    $ make root-save

## 加载 Linux Kernel 和根文件系统

有了 Linux 内核镜像、DTB 和根文件系统，Linux Lab 就可以自动引导了。

    $ make boot

引入时可切换根文件系统类型，默认类型是 Ramdisk，例如换成磁盘镜像：

    $ make boot ROOTDEV=/dev/sda

也可切换 Qemu 为串口输出模式，默认为 Framebuffer 输出：

    $ make boot G=0   # G 为 Graphic 缩写，G=0 会设置 -nographic

## 配置/编译 Uboot，加载 Linux Kernel

同样地，可配置和编译 Uboot：

检出所需的 Uboot 版本（注：会 Reset 掉历史修改，请注意备份变更）

    $ make uboot-checkout

使能默认配置文件（会自动调用 `tools/uboot/config.sh` 配置 `CONFIG_BOOTCOMMAND` 等参数）：

    $ make uboot-defconfig

添加/修改所需配置选项：

    $ make uboot-menuconfig

交叉编译 Uboot，

    $ make uboot

通过 Uboot 引导内核：

    $ make boot U=1

需要注意的是，如果这里引导时也要切换根文件系统类型，在配置时也需要相应传递 `ROOTDEV` 参数，并重新编译 Uboot。

如果要保存 Uboot 配置文件（存回 `machine/versatilepb/`），可执行：

    $ make uconfig-save

而要保存 Uboot 镜像（存到 `prebuilt/uboot/`），可执行：

    $ make uboot-save

## 结语

到这里，基于 Linux Lab，我们轻松地完成了嵌入式 Linux 系统的一般开发过程。

对于初学者而言，环境搭建的繁杂细节和不一致性往往会成为拦路虎，而 Linux Lab 恰恰很好地隐藏了那些细节，降低准入的门槛。

对于有经验的开发者而言，环境搭建往往变成一个重复而令人讨厌的工作，Linux Lab 彻底消除了这部分烦恼，允许大家更加聚焦于开发本身。

对于社区开发者而言，可以很好地利用 Linux Lab 来进行 Uboot、Linux、Buildroot 等项目的新特性开发，很方便利用 `prebuilt/` 的镜像来做快速验证和测试。

对于学生而言，Linux Lab 借助 Qemu 提供的大量免费开发板可以大大节省学习开支。

[1]: http://tinylab.org/using-qemu-simulation-inserts-the-type-system-to-produce-the-whole-process/
[2]: http://tinylab.org/linux-lab/
