---
layout: post
author: 'Wu Zhangjin'
title: "在 498 行极小系统跑标准 ELF 程序"
draft: false
top: false
license: "cc-by-nc-nd-4.0"
permalink: /running-elf/
description: "CS630 是旧金山大学的一个高级微机编程课程，它提供了很多非常好的实验案例，本文介绍如何极速使用其中的 ELF 装载和运行案例。"
category:
  - 程序执行
tags:
  - ELF
  - CS630
---

> By Falcon of [TinyLab.org][1]
> Aug 18, 2019

## 简介

ELF 在 Linux 系统中作为标准可执行文件格式已经存在了 ~25 年。

如果要在 Linux 下直接研究 ELF，通常很难绕过 Linux 本身的复杂度。

为了降低学习 ELF 的门槛，今天特地引荐一个极小的系统，这个小系统不仅有 “Bootloader”，有 “OS”，还能加载和运行标准的可以打印 Hello 的 ELF 程序。

所有这些都由 [CS630-Qemu-Lab](http://tinylab.org/cs630-qemu-lab) 提供。它是一套用于学习旧金山大学课程 [CS 630: Advanced Microcomputer Programming](https://www.cs.usfca.edu/~cruse/cs630f06/) 的极简实验环境，是一个由[泰晓科技](http://tinylab.org)主导的开源项目。

它可以独立使用，也可以在 [Linux Lab](http://tinylab.org/linux-lab) 下使用。下面介绍如何在 Linux Lab 下使用它。

## 准备环境

先准备 Linux Lab（非 Ubuntu 系统请提前安装好 Docker）：

    $ git clone https://gitee.com/tinylab/cloud-lab
    $ cd cloud-lab
    $ tools/docker/run linux-lab

执行完正常会看到一个启动了 LXDE 桌面的浏览器，进去以后，点击桌面的控制台，启动后下载 CS630-Qemu-Lab 到 `/labs` 目录下：

    $ cd /labs
    $ git clone https://gitee.com/tinylab/cs630-qemu-lab
    $ cd cs630-qemu-lab

## 一键运行 ELF

接下来，通过 CS630 Qemu Lab 提供的极速体验方式，一键编译 Bootloader, OS 和 Hello 汇编程序，并自动依次运行：

    $ make boot SRC=res/elfexec.s APP=res/hello.s

运行完以后，会弹出一个 Qemu 界面，并在屏幕打印一个 Hello 字符串。

![CS630 ELF 汇编案例](http://tinylab.org/wp-content/uploads/2019/08/cs630-elf.png)

默认是从软盘加载程序，如果要改为硬盘，可以用：

    $ make boot-hd SRC=res/elfexec.s APP=res/hello.s

## 初步解读

这个实验主要包含如下三部分：

* “Bootloader”
  * `src/quikload_floppy.s`：实际代码只有 68 行
  * `src/quikload_hd.s`：实际代码只有 44 行

* “OS”
  * `res/elfexec.s`：实际代码只有 430 行，有提供 write, exit 等几个小的系统调用，还能加载标准 ELF

* “APP”
  * `res/hello.s`：实际代码仅 19 行，可以打印 Hello 字符串，编译生成标准的 ELF 程序

以 Floppy 版本为例，上述 bootloader 和 os 加起来仅有 498 行代码，含注释和空行也才 644 行，相比庞大的 Linux 来讲，可谓极其微小，因此特别适合核心 ELF 原理分析。

## 题外话

CS630 Qemu Lab 的汇编语言实验案例非常丰富，全部以 X86 为平台，以 Linux AT&T 汇编语法撰写，代码简洁清晰，非常适合学习。例如，跑一个 rtc 程序：

    $ make boot SRC=src/rtc.s

下面是演示视频：

![CS630 RTC 汇编案例](http://tinylab.org/wp-content/uploads/2019/08/cs630-rtc.gif)

## 小结

Jonathan Blow 在莫斯科 DevGAMM 上，做了一个题为[《阻止文明倒塌》](https://mp.weixin.qq.com/s/WbTXKzbbnMpllqtazDrmRg)的演讲。

这个演讲反应了一个普遍的情况，某个项目，随着功能的迭代和技术的发展，其功能不断丰富，复杂度却在不断增加。对于后来者，学习难度和门槛就变得越来越高。很多内容，由于逐步远离了当初设计者和开发者的环境，新来的维护人员极易出现理解偏差，随着老一辈 Maintainers 逐渐地离开，系统可能会变得越来越难以维护。

Linux 有点类似这样，它正在变得越来越复杂，我们学习一个可执行文件格式，得抱着几本大砖头 Linux 图书，并从数万行代码中找出那些关联的片段，看上去就是一个令人畏惧的工程。

泰晓科技致力于降低 Linux 技术的学习和研究门槛，我们正在做很多努力，去简化问题的复杂度，一方面构建了多套极简又容易快速上手的实验环境，另外一方面，从产品实战的细微处追本溯源，分享了大量的技术原创文章，争取见微知著。

后续将进一步深度解读这个 498 行的极小系统。

[1]: http://tinylab.org
