---
layout: post
author: 'Wu Zhangjin'
title: "Linux 0.11 Lab 和 CS630 Qemu Lab 同时发布 v0.1 rc1"
draft: true
license: "cc-by-sa-4.0"
permalink: /linux-0.11-lab-cs630-qemu-lab-release-v0.1-rc1/
description: "Linux 0.11 Lab 是 Linux 0.11 操作系统的实验环境，CS630 Qemu Lab 是 X86 Linux 汇编语言实验环境，两个环境于 2019年7月3日 同时发布 v0.1 rc1"
category:
  - Linux 0.11 Lab
  - 汇编
tags:
  - Linux 0.11
  - CS630
  - Qemu
  - Bochs
  - Cloud Lab
---

> By Falcon of [TinyLab.org][1]
> Jul 03, 2019

## Linux 0.11 Lab

[Linux 0.11 Lab](/linux-0.11-lab) 是 Linux 0.11 的极速实验环境，可配合《Linux 0.11 内核完全注释》使用。

它源自作者于 2008 年左右学习赵博士《Linux 0.11 内核完全注释》一书时的读书笔记和代码实践。

2008 年的代码实践有回馈给赵老师的论坛，之后有很多同学复用相关的代码。

2015 年在 Docker 兴起之后，作者重构了历史代码，发布到 Github 上，并取名为 Linux 0.11 Lab。

经过数年的开发和迭代，目前已经收获了 355 Stars，172 份 Forks，最近一段时间，修复了部分 Bugs，基本功能已经足够完善，所以计划发布一个正式的版本 v0.1，这里先发布 [v0.1 rc1](https://gitee.com/tinylab/linux-0.11-lab/tree/v0.1-rc1/)。

Linux 0.11 Lab v0.1 rc1 已经具备如下功能：

1. 基于 Docker，支持在 Windows, Linux 和 Mac OSX 下做实验。
2. 同时支持 Qemu 和 Bochs 模拟器，预编译了支持 Linux 0.11 Floppy 的 Qemu 0.10。
3. 预制了三种类型的根文件系统：Ram, Floppy, Harddisk。
4. 预装了编译器，添加了 make 目标：boot, boot-fd, boot-hd，支持一键编译和启动
5. 添加了在线调试 make 目标：debug, debug-fd, debug-hd，同时支持 Qemu 和 Bochs
6. 内建了 Syscall, Linux 0.00, Linux 0.11 内部编译 Linux 0.11 等例子
7. boot/{bootsect.s, setup.s}：用 AT&T 汇编重写
8. tools/build.c：用 shell 重写
9. tools/callgraph: 可生成函数调用关系

**极速体验**（在非 Ubuntu 平台，请提前自行安装好 docker）：

    $ git clone https://gitee.com/tinylab/cloud-lab.git
    $ cd cloud-lab
    $ tools/docker/run linux-0.11-lab

进去以后，打开控制台，敲入如下命令即可启动一个板子：

    $ make boot

## CS630 Qemu Lab

[CS630 Qemu Lab](/cs630-qemu-lab) 是 X86 Linux AT&T 汇编语言的极速实验环境，可配合旧金山大学的高级微机编程课程 [CS630](http://www.cs.usfca.edu/~cruse/cs630f06/) 使用。

它源自作者早年自学 [CS630](http://www.cs.usfca.edu/~cruse/cs630f06/) 课程时的实践成果，该实践成果有回馈给 CS630 课程的老师并且得到了老师的积极反馈：

> Hello, Falcon

> I’m amazed to receive your cs630-experiment-on-VM. I think, as an online “student”, you have earned an ‘A’ for this course! I will let some Ubuntu-savvy students here know about what you’ve created, and we’ll see if they find it to be a timesaver, as it ought to be. Thanks for contributing these efforts to the class.

这门课程非常精彩，推荐给所有高校计算机专业的老师和学生。

经过了数年的开发和迭代，这个 Lab 也已经非常完善，是时候发布 v0.1 了，先发布 v0.1 rc1，方便接收更多测试和验证：

1. 基于 Docker，支持在 Windows, Linux 和 Mac OSX 下做实验。
2. 预安装了编译器和 Qemu，支持直接编译和启动：make boot
3. 支持实模式和保护模式
4. 支持在线调试：make debug
5. 有接近 100 个例子，涵盖 rtc, irq controller, multi-tasks, keyboard, monitor, timer, SMP, perf monitor 等

**极速体验**（在非 Ubuntu 平台，请提前自行安装好 docker）：

    $ git clone https://gitee.com/tinylab/cloud-lab.git
    $ cd cloud-lab
    $ tools/docker/run cs630-qemu-lab

进去以后，打开控制台，敲入如下命令即可启动一个板子：

    $ make boot

<hr>

**联系我们**：

![tinylab wechat](/images/wechat/tinylab.jpg)

[1]: http://tinylab.org
