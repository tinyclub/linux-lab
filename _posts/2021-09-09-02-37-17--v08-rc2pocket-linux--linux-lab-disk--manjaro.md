---
layout: post
author: 'Wu Zhangjin'
title: "社区发布 Linux Lab v0.8-rc2，Pocket Linux 与 Linux Lab Disk 同时支持 Manjaro"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /manjaro2go/
description: "Manjaro 继承 ArchLinux 诸多优点，比如软件丰富，滚动更新，针对 X86_64 特定优化，Manjaro 在使用上做了一些改进，界面清爽、更易用、更健壮。"
category:
  - Linux Lab
  - 开源项目
tags:
  - ArchLinux
  - pacman
  - Manjaro
  - Pocket Linux
---

> By Falcon of [TinyLab.org][1]
> Sep 09, 2021


## 概述

最近主要在为 Linux Lab Disk 和 Pocket Linux Disk 适配更多的 Linux 发行版，以便覆盖更多的用户群体。所以，Linux Lab 本身的开发推进较为缓慢，但是跟 Cloud Lab 一起，也有 20 笔变更，并且修复了多处重要 Bug。

## v0.8-rc2

本次主要变更如下：

1. 早期文档中描述的更新步骤较重，替换为更为轻量级的更新步骤。
2. 在 MacOS 系统上，由于无法正常创建 console, null 等设备文件，导致无法正常启动系统，对于用户提报的 i386/pc，把默认文件系统格式改为 cpio，临时 workaround 该问题。
3. 修复 make clean 错误，先执行 kernel clean，再做 git reset，避免清理掉 kernel clean 必须的 patch。
4. 进一步清理 rootfs 各种格式的依赖关系。
5. 进一步优化 make debug，确保 debug 基于最新的改动。
6. 清理不必要的 1234 端口映射，该部分可以让用户按需开启。

如果遇到相关问题，建议更新。

## Manjaro 支持

ArchLinux 作为一个特殊的存在，其带来的专属优化、滚动更新、软件丰富等特性都非常吸引人，所以很多同学希望能为 Linux Lab Disk 和 Pocket Linux Disk 适配它或相关变体 Manjaro，经过慎重考虑，我们最终选择了发布节奏更为平缓一些的 Manjaro。

Manjaro 相比 ArchLinux 虽然更为稳健，但是适配过程中我们依然遇到了诸多问题，不过，经过艰难的调试，我们逐一攻克了。

有了 Manjaro，我们可以更快地体验最新的内核与软件，我们可以直接安装最新的 Linux v5.14 内核：

    $ sudo pacman -S linux514

也可以直接滚动到最新的系统：

    $ sudo pacman -Syu

国内的镜像都非常健全，我们已经做好了配置。

其他的功能基本跟采用 Ubuntu、Deepin 系统的版本对齐，包括智能启动、透明倍容、时区兼容等。

下面展示几张图：

![Linux Lab Disk 透明倍容效果图](/wp-content/uploads/2021/09/manjaro-linux-lab-disk-system-size.jpg)

![Pocket Linux Disk 预装软件列表](/wp-content/uploads/2021/09/manjaro-pocket-linux-apps.jpg)

## 快速体验

16G-512G 的 Linux Lab Disk 和 Pocket Linux Disk 均已经支持 Manjaro Linux：

Pocket Linux Disk 首批实物图：

![image](/wp-content/uploads/2021/08/deepin-support/pocket-linux-disks.jpg)

Linux Lab Disk 实物图：

![image](/wp-content/uploads/2021/08/deepin-support/linux-lab-disk-256.jpg)
![image](/wp-content/uploads/2021/08/deepin-support/linux-lab-disk-128.jpg)

在某宝检索 “Linux Lab真盘” 或 “Pocket Linux系统” 即可选购。

[1]: http://tinylab.org
