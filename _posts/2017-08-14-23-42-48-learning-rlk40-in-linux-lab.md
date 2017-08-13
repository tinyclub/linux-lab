---
layout: post
author: 'Wu Zhangjin'
title: "通过 Linux Lab 践行《奔跑吧 Linux 内核》"
permalink: /learning-rlk4.0-in-linux-lab/
description: "《奔跑吧 Linux 内核》是全球首本Linux 4.x内核分析书籍，本文介绍如何通过Linux Lab来做书中的实验。"
category:
  - Linux 内核
  - Linux Lab
tags:
  - 奔跑吧Linux内核
---

> By Falcon of [TinyLab.org][1]
> 2017-08-14 23:42:48

盼望着，盼望着，《奔跑吧 Linux 内核》终于如期付梓，几大知名图书站点都可以预订了。

## Figo

首先，恭喜 Figo.Zhang，这样一本几百页的IT巨著着实是非常考验体力、智力和能力的。

笔者自己曾经编写过一本[几十页的小册子](http://www.packtpub.com/optimizing-embedded-systems-using-busybox/book)，都累到满脸痘痘，心力憔悴。这样一本几百页的图书更是如此。IT 图书有个区别于其他图书的地方是，里头涉及到大量的实操性内容，必须是可重复的，就单纯这一项的反复校订就是巨大的工程。

另外，关于 Linux 内核的书在市面上其实有不少，如果要撰写一本全新的书，如何编排、如何挑选内容、甚至如何推广都是非常考研智力的。

而在做好初步准备以后，如果落地，如何运筹帷幄，如果掷地有声都是非常考验经验和技能的，需要对知识了如指掌，又或者信手拈来。

就是这样一个聪慧、敏捷、经验老到的实力派 Linux 玩家，他却谦称 “笨叔叔”。

## 奔跑吧 Linux 内核

接下来，我们来看看这本书的编排：

* 处理器体系结构
* 内存管理
* 进程管理
* 并发与同步
* 中断管理
* 内核调试

相比于传统的内核书籍，该书做了很好的内容挑选，这些内容的实用性很高，很贴合工作实战，也是 Figo 十多年的内核与驱动工作经验的心得和分享。

另外，本书显著的特点还有：

* 基于 ARM32/ARM64 体系架构
* 基于 Linux 4.x 内核和 Android 7.x
* 以实际问题为导向的内核分析书籍，给读者提供一个以解决实际问题为引导的阅读方式
* 内容详实，讲解深入透彻，反映内核社区技术发展，比如 EAS调度器、MCS锁、QSpinlock、DirtyCOW

### 实操性

本书花了整整一章来介绍内核调试，不仅介绍了诸如 printk、RAM Console、Oops分析，还用大量篇幅介绍了 Ftrace、Systemtap、内存检测、死锁检测等当前很流行也很贴切实际开发需要的内容。更重要地是，这些内容都可以通过软件模拟器 Qemu 来做实验，所有实验代码也已经开放到了 Github 上：<https://github.com/figozhang/runninglinuxkernel_4.0>。

在 Figo 撰写本书的过程中，笔者刚好在开发一个 Linux 内核学习和实验环境：[Linux Lab](http://tinylab.org/linux-lab)，这个环境通过 Docker 容器化技术大大地简化了实验环境的构建过程，并结合笔者早年的社区工作经验设计了一个 Qemu 虚拟化实验框架，可以大大简化内核编译、文件系统制作、内核测试和调试等。Figo 很果断地在书中给读者们做了推荐。

为了更加地便利各位读者，笔者通过两天的努力，为本书的实验环境制作了一套独立的 Linux Lab 插件：<https://github.com/tinyclub/rlk4.0>，这个插件可以直接放置到 Linux Lab 的 `boards/` 目录下使用。

完整的使用和实验演示请看下文：

* [Linux Lab 用法](http://tinylab.org/linux-lab)
* [RLK4.0 插件 for Linux Lab](https://github.com/tinyclub/rlk4.0)
    * [用 Showterm 录制的命令行操作视频](http://showterm.io/e786d08e0ea0964f3efb1)
    * [用 Showdesk 录制的桌面操作视频]()

![RLK4.0 Book](/wp-content/uploads/2017/08/rlk4.0.jpg)

[1]: http://tinylab.org
