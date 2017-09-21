---
layout: post
author: 'Wu Zhangjin'
title: "第3期直播：用 Linux 0.11 Lab 学古董 Linux"
tagline: 用泰晓实验云台+微信语音做 IT 技术直播
album: Linux 直播
permalink: /tech-live-learning-linux-0.11/
description: "本文介绍如何用 Linux 0.11 Lab 快速高效地学习 Linux 0.11 操作系统，可配合用于学习《Linux内核完全注释》"
category:
  - 视频直播
  - Linux 0.11 Lab
tags:
  - Linux
  - Cloud Lab
  - Linux 0.11
  - oldlinux.org
  - 实验云台
---

> By Falcon of [TinyLab.org][1]
> 2017-09-20 21:27:07

## 回顾/简介

最近一个月，我们陆续组织了两场技术直播，这两场都是介绍 Linux Lab —— 一个高效的 Linux 内核和嵌入式 Linux 实验环境：

* [用 Linux Lab 做《奔跑吧 Linux 内核》实验](http://tinylab.org/tech-live-with-obs-huya-openshot/)
* [用 Linux Lab 做 Uboot 实验](http://tinylab.org/tech-live-learning-uboot-in-linux-lab/)

本期我们继续介绍实验环境，不过这次是 Linux 0.11 Lab：一个高效的 Linux 0.11 内核实验环境，专门为赵博士的《Linux内核完全注释》打造，可用来配合做书中的实验，也可以用来学习大学的操作系统课程。

十年前，笔者要花几个礼拜才能搭建这样一个实验环境，如今基于 Linux 0.11 Lab，我们几分钟就可以搭建，省时又不费力。学习操作系统之路的拦路虎就此摆平，从此就可以迈入曾经高深莫测的 OS 学习大门，走上人生巅峰。。。

## 报名/预约

### 直播纲要

> 直播地址：[泰晓科技 Linux 直播频道](https://3qk.easyvaas.com/show/homepage/index?id=423)
> 内容大纲：[Learning Linux 0.11 in Linux 0.11 Lab](https://github.com/tinyclub/linux-0.11-lab/blob/master/doc/live/linux-0.11-lab.md)
> 直播时间：本周六(2017/9/23) 下午 2:00～3:00
> 直播口号：摆平操作系统学习之路上的拦路虎，从此。。。

### 报名方式

可任选一种方式报名：

* 直接通过 [直播频道](https://3qk.easyvaas.com/show/homepage/index?id=423) 预约报名
* 从 [开源小店][3] 购买一个月的 Linux 0.11 Lab 体验帐号
* 扫描文末的二维码赞助我们

报名后请添加笔者微信号 lzufalcon 申请加入直播专用微信群，申请时记得提供报名凭证。

**注**：本次直播仅象征性地收取一些费用，用于支付相关服务器的运营，感谢支持！

![Learning Linux 0.11 in Linux 0.11 Lab](/wp-content/uploads/2017/09/linux-0.11-lab.jpg)

## 阅读材料

为达到更好的收看效果，请提前了解一下 Linux 0.11 和 Linux 0.11 Lab：

### Linux 0.11

Linux 0.11 是一份早期版本的 Linux 内核，虽然功能不如现代版本的 Linux 内核强大，但是由于代码量相对小很多（Linux 0.11 不超过 2 万行，而 Linux 2.6.0 已经有 592 万行），而且它具备操作系统的所有核心功能，麻雀虽小，五脏俱全，因此非常适合初学操作系统的学生，也特别适合很多打算了解底层软件工作原理的工程师。

赵博士专门建立了一个网站，用于收藏古董 Linux，这个网站是：<http://oldlinux.org>，他还专门为 Linux 0.11 写了一本书，叫《Linux 内核完全注释》，更为重要的是，这本书是开放的，可以在他的网站上下载到：[clk011c-3.0.pdf](http://www.oldlinux.org/download/clk011c-3.0.pdf)。很多学生因此受益，我也是一个其中一位，在此深表感谢！

### Linux 0.11 Lab

[Linux 0.11 Lab][2] 用于快速构建一个基于 Docker 和 Qemu/Bochs 的 Linux 0.11 实验环境，最快可以在 5 分钟内搭建。它可用于学习 C、汇编以及操作系统。最初由笔者于 10 年前搭建，主要基于赵老师网站和书中的例子。后面陆陆续续有其他同学做了一些修订，大约在 2 年前，为了让更多的同学受益，笔者抽空把早期的工作做了重新梳理，制作了一份较为完备的实验环境并开放到了 [Github](https://github.com/tinyclub/linux-0.11-lab) 上。

Linux 0.11 Lab 的主要特性如下：

* 包含所有可用的映像文件: ramfs/floppy/hard disk image。
* 轻松支持 Qemu 和 Bochs，可通过 `make switch` 切换。
* 可以生成任何函数的调用关系，方便代码分析：`make cg f=func d=file|dir`
* 支持 Ubuntu 和 Mac OS X，在 VirtualBox 的支持下也可以在 Windows 上工作。
* 支持最新的编译器和调试器，可直接用 Qemu/Bochs + gdb 调试
* 在解压之前整个大小只有 30M
* 支持 Docker 一键构建
* 可通过 Web 直接访问

另外，本次直播内容实操性非常强，建议提前 [参考文档][2] 搭建好 Linux 0.11 Lab，或者直接从 [泰晓开源小店][3] 提前获取一个在线 Linux 0.11 Lab 帐号。

## 致谢

本次直播在原 [泰晓科技 Linux 直播频道](https://3qk.easyvaas.com/show/homepage/index?id=423) 的基础上，增加另外一种直播方式，那就是直接采用 [泰晓实验云台/Cloud Lab][4] + 微信语音，该实验云台由 [青云QingCloud][5] 赞助服务器。


[1]: http://tinylab.org
[2]: http://tinylab.org/linux-0.11-lab
[3]: https://weidian.com/i/1487448443
[4]: http://tinylab.cloud:6080
[5]: https://www.qingcloud.com/
