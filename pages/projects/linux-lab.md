---
title: 'Linux 实验环境'
tagline: '可快速构建，支持Docker/Qemu/Ubuntu/OS X/Windows/Web'
author: Wu Zhangjin
layout: page
permalink: /linux-lab/
description: 基于 Qemu 的 Linux 内核开发环境，支持 Docker, 支持 Ubuntu / Windows / Mac OS X，也内置支持 Qemu，支持通过 Web 远程访问。
update: 2016-06-19
categories:
  - 开源项目
  - Linux
tags:
  - 实验环境
---

## 项目描述

该项目致力于快速构建一个基于 Qemu 的 Linux 内核开发环境。

  * 使用文档： [README.md][2]
  * 代码仓库：[https://github.com/tinyclub/linux-lab.git][3]
  * 基本特性：
      * Qemu 支持的大量虚拟开发板，统统免费，免费，免费。 
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 直接通过 Web 访问，非常便捷，便捷，便捷。
      * 已内置支持 4 大架构：ARM, MIPS, PowerPC 和 X86。
      * 已内置支持从 Ramfs 或者 NFS rootfs 启动。
      * 一键即可启动，支持串口和图形启动。
      * 预编译有 initrd 和内核镜像文件，可以快速体验实验效果。
      * 可灵活配置和扩展支持更多架构、虚拟开发板和内核版本。
      * 未来计划支持 Uboot，支持 Android emulator，支持在线调试。。。

## 相关文章

  * [五分钟内搭建 Linux 0.11 的实验环境][4]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 五分钟教程

### 准备

以 Ubuntu 和 Qemu 为例：

### 下载

    git clone https://github.com/tinyclub/linux-lab.git
    

### 安装

    $ sudo tools/install-docker-lab.sh
    $ tools/run-docker-lab-daemon.sh
    $ tools/open-docker-lab.sh
    

### 快速尝鲜

打开 `http://localhost:6080/vnc.html` 并输入 `ubuntu` 密码登陆，之后打开一个控制台：

    $ sudo -s
    $ cd /linux-lab
    $ make boot

默认会启动一个 `versatilepb` 的 ARM 板子。

### 更多用法

详细的用法这里就不罗嗦了，大家自行查看帮助。

    $ make help

### 实验效果图

![Linux Lab Demo](/wp-content/uploads/2016/06/docker-qemu-linux-lab.jpg)


 [2]: https://github.com/tinyclub/linux-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/linux-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
