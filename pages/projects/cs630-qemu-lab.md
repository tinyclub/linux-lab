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

这里为在线演示地址：<http://showterm.io/547ccaae139df14c3deec>。

## 代码仓库

  * 仓库地址

    [https://github.com/tinyclub/cs630-qemu-lab.git][3]

  * 下载源码

        $ git clone https://github.com/tinyclub/cs630-qemu-lab.git

  * 安装 qemu 和编译环境

        $ sudo apt-get install qemu gcc gdb binutils

  * 下载汇编语言源码
    
        $ cd cs630-qemu-lab
        $ make update
    
    上述命令将从 CS630 课程网站 [CS 630: Advanced Microcomputer Programming (Fall 2006)][1] 下载最新的源码到 `res/`。

## 通过 Qemu 学 CS630

现在开学了，写了两个简单的文档: README.md 和 NOTE.md, 请参考它们做实验。

下面以 helloworld 和 rtc 为例展开：

### Real Mode

  * helloworld
    
        $ ./configure src/helloworld.s
        $ make boot
        

  * rtc
    
        $ ./configure src/rtc.s
        $ make boot
        

### Protected Mode

  * helloworld
    
        $ ./configure res/pmhello.s
        $ make pmboot
        

  * rtc
    
        $ ./configure res/rtcdemo.s
        $ make pmboot
        

## 演示图

下面是 rtcdemo 在 Qemu 上运行时的截图:

![image][4]




 [1]: http://www.cs.usfca.edu/~cruse/cs630f06/
 [2]: http://wiki.qemu.org/Main_Page
 [3]: https://github.com/tinyclub/cs630-qemu-lab
 [4]: /wp-content/uploads/2014/03/cs630-qemu-pmrtc.png
