---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 新增国产 openEuler Kernel 开发支持，从下载编译到启动仅需一条命令"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /openeuler-kernel-4-linux-lab/
description: "Linux Lab 在国产操作系统开发支持上又进一步，本次合并了 openEuler Kernel 开发支持，体验一条命令快捷开发。"
category:
  - Linux Lab
  - 开源项目
tags:
  - openEuler
  - 开源之夏
---

> By Falcon of [TinyLab.org][1]
> Sep 27, 2021

## 开源之夏

今年的开源之夏活动马上接近尾声，开源之夏是由中科院软件所组织的暑期开源活动，主要面向高校学生和开源社区，由开源社区出项目和 Mentor，面向高校召集学生报名开展 3 个月的开源项目开发活动。

泰晓科技技术社区每年都参与了该项活动，今年更是提报了 5 个左右的项目，相关信息见：<http://tinylab.org/summer2021>

目前活动即将结束，提报的几个项目也陆续进入到紧张的代码集成和总结阶段，相关项目的开发过程见：<https://gitee.com/tinylab/cloud-lab/issues>

由于部分学生在开展项目的过程中，有的在企业实习，有的在撰写论文，所以开发时间其实是非常紧张的，而参与指导的 Mentor 们自己本身有繁重的企业项目工作，所以能取得目前的进展还是非常不容易的。

感谢所有实实在在投入精力参与指导的 Mentor 们，也祝贺花费时间思考和动手并获得一定提升的同学们。

欢迎同学们关注并报名明年社区即将提报的项目 ;-)

## openEuler Kernel 开发支持

今年提报的项目之一是：Linux Lab openEuler 集成开发支持。

作为一款国产开源项目，Linux Lab 已经并且在继续为国产芯片、开发板和系统提供大力支持。

* 2019 年，Linux Lab 为平头哥前身中天微CSKY添加了集成开发支持
* 2019-2020 年，Linux Lab 已经为龙芯 MIPS 架构的 3 大芯片系列的 4 款开发板提供了即时开发支持
* 2020-2021 年，Linux Lab 集成了国产真实嵌入式硬件开发板

这些工作让开发者“零门槛”真切快速地用上国产芯片和开发板，也让国产芯片和开发板有更多的开发者生态。

本次项目有两个子项目，旨在 Linux Lab 现有 `x86_64/pc` 和 `aarch64/virt` 虚拟开发板的基础上，增加对知名开源国产操作系统 openEuler 的集成开发支持，旨在降低 openEuler 内核与系统的学习、实验与开发门槛，同时为 openEuler 开源项目吸引更多的爱好者与开发者。

本次开源之夏活动重点是集成对 openEuler Kernel 的开发支持。

## 在 Linux Lab 中极速体验用 openEuler Kernel 开发

openEuler Kernel 有独立的代码仓库，无法简单跟 Linux Lab 的 linux-stable 主仓库直接复用；另外，由于 openEuler 独立维护的 kernel patch 较多，更新频繁，所以也不方便类似诸如 rust 这样的 kernel feature 用独立的 patchset 来管理。

经过与参与学生的多轮讨论和实验，本次开发我们在早期 i386 v2.6.10 内核支持采用独立内核代码仓库（tglx-linux-history）的基础上，做了进一步抽象，把所有类似龙芯内核、openEuler 内核以及未来我们准备新增的阿里系龙晰 Linux 内核等抽象为 Linux 的内核 Fork，即 `KERNEL_FORK`，这个 fork 可以配置为 loongson, openeuler, openanolis 等，这些 fork 下面可以有自己的 linux versions，多个 versions 可以共享一个 kernel fork 仓库，这样就可以减少很多冗余设定。

目前默认使用了当前最新的 openEuler-21.09 对应的 tag：5.10.0-5.10.0（感觉这个 tag 比较晦涩）。

考虑到需要保留一些时间作更充分的测试，目前 Linux Lab 新建了一个名叫 “openeuler” 的分支来管理 openeuler kernel 开发支持，在 openeuler 分支下面，用这三条命令就可以快速体验（以 `x86_64/pc` 为例，`aarch64/virt` 用法完全类似）：

```
// 用 x86_64/pc 这块板子
$ make BOARD=x86_64/pc
// 配置 kernel fork 为 openeuler，相当于指定了独立的 Linux 内核仓库
$ make local-config KERNEL_FORK=openeuler
// 自动下载、编译并启动，如果不传递 BUILD 参数，会自动下载并启动已经编译好的内核
$ make boot BUILD=kernel
...
```

如果大家想用其他 tag 或者版本，用 kernel-clone 接口就好。

关注 openEuler Kernel 新特性的同学，可以看看这个链接：<https://gitee.com/openeuler/kernel/wikis/kernel>

手头有 Linux Lab Disk 的同学可以直接体验了，在 labs/linux-lab 目录下更新仓库并 checkout openeuler 分支即可，之后的用法同上：

```
$ git fetch --all
$ git checkout -b openeuler origin/openeuler
```

手头没有 Linux Lab Disk 的同学可以去某宝检索集成了 Linux Lab 的 “Linux Lab真盘”。

![image](/wp-content/uploads/2021/08/deepin-support/linux-lab-disk-256.jpg)

动手能力较强，喜欢折腾的同学也可以自行摸索并安装 Linux Lab，安装完记得顺手给个 Star 哈：

* <https://gitee.com/tinylab/linux-lab>

## 后续计划

预计在 2 周左右，会把该功能合并到 Linux Lab 的 next 分支，随后再发布到 v0.8-rc3，敬请期待，v0.8 正式版预计也会在一个月左右发布。

[1]: http://tinylab.org
