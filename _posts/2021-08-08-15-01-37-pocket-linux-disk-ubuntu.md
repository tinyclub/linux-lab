---
layout: post
author: 'Wu Zhangjin'
title: "社区发布随身 Pocket Linux 系统盘，首批支持 Ubuntu 18.04.5, 20.04.2, 21.04"
draft: false
top: true
tagline: "免安装的 Linux 系统盘来了，支持智能启动+透明倍容+时区兼容"
license: "cc-by-nc-nd-4.0"
permalink: /pocket-linux-disk-ubuntu/
description: "继 Linux Lab Disk 之后，泰晓科技技术社区本次发布随身 Pocket Linux Disk，预装多种交流影音办公与开发软件，免安装，并且支持智能启动+透明倍容+时区兼容。"
category:
  - Linux 系统
  - Ubuntu
tags:
  - Pocket Linux
  - 随身 Linux
  - 系统盘
  - Ubuntu 18.04
  - Ubuntu 20.04
  - Ubuntu 21.04
---

> By Falcon of [TinyLab.org][1]
> Aug 08, 2021

## Pocket Linux 简介

大概一周前，在 [Linux Lab 开源项目](https://gitee.com/tinylab/linux-lab) 突破 1000 Stars 之际，泰晓科技技术社区发布了随身原生 Pocket Linux 系统盘，旨在把 Linux Lab Disk 的基础特性（免安装+智能启动+透明倍容+时区兼容等）也带给更多的 Linux 用户，方便其他计算机技术的开发者开展学习、实验与开发。

上周仅制作了 10 枚 16G 版本的 Pocket Linux Disk（随身 Linux 系统盘），已经支持 Ubuntu 18.04.5，20.04.2，21.04。

发布之后，部分同学希望有更大容量的版本，所以社区今次补充了 32G/64G/128G MLC颗粒+高速主控版本（读写150MB/80MB）以及 128G MLC颗粒+固态主控版本（读写500MB/400MB），采用 MLC 颗粒的版本持续读写不掉速。

## 如何收藏与选购

为了照顾更多同学的需要，除了推出更大容量和更高速度的版本，我们还有如下两项举措：

1. 上周发布的 16G 版本在未来一周降低至 49￥，方便大家体验，其他容量和速度的版本也在未来一周有相应的活动。

2. 除了 Ubuntu 18.04.5/20.04.2/21.04，社区也在继续研发基于其他发行版的 Pocket Linux Disk，计划新增 Deepin, Fedora 等社区常规发行版，欢迎回复讨论。

感兴趣的同学可以直接在某宝检索 “Pocket Linux 系统” 或者直接进入泰晓科技技术社区的开源小店：<https://shop155917374.taobao.com>

如需用来做 Linux 内核开发，建议直接选用 “Linux Lab Disk”（也可以直接当 Linux 系统盘使用，只是目前 Linux Lab Disk 没有安装 Pocket Linux Disk 预装的那些交流娱乐办公类软件），在某宝检索 “Linux Lab真盘” 即可。

如果现在还没有自己需要的发行版，建议先收藏起来，方便关注后续更新。

## Pocket Linux 特性

下面简单介绍一下相关特性：

1. 全部预装了常用交流娱乐办公与开发软件。

    ![Pocket Linux - pre-installed softwares](/wp-content/uploads/2021/08/pocket-linux/pocket-linux-intro.jpg)

2. 支持透明倍容。

    目前版本预装了上述软件后系统共12G以上，但是实际只占用了5-6G左右存储，预计还能写入10G-16数据。可用容量翻倍，16G差不多能当32G用，类似地，128G 预期能得到 256G 左右可用容量。透明倍容对于可压缩度较高的代码、文本类文件预期会有更好的效果，对于iso、zip等本来已经压缩的文件，预期收益效果会小一些。

3. 自动兼容其他系统的时区设定。

    切换启动系统后不会导致时区紊乱，无需额外设定时区。

4. 支持智能启动。

    不仅可以在关机情况下直接按F12或Option按键开机上电即插即用（多次启动后能自动记住并优先启动），也可以在运行的 Windows和Linux系统下插入后即时启动（仅需提前安装Virtualbox）。

    以下图片为在 Windows 下同时插入并智能启动一支 Linux Lab Disk 和一支 Pocket Linux Disk 的情况。

    ![Pocket linux disk 智能启动效果](/wp-content/uploads/2021/08/pocket-linux/pocket-linux-vmboot-demo.jpg)

## 加入讨论群组

收藏或选购以后联系微信 tinylab，可以申请加入相应讨论群组。

[1]: http://tinylab.org
