---
layout: post
author: 'Wu Zhangjin'
title: "嵌入式 Linux 产品技术评估之系统裁剪与启动速度"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /linux-product-evaluate-size-and-boot/
description: "本文通过实例介绍了嵌入式 Linux 产品系统裁剪与启动速度的技术评估方法。"
category:
  - 产品评估
tags:
  - 系统裁剪
  - 启动优化
  - 时间换空间
  - 功耗换时间
---

> By Falcon of [TinyLab.org][1]
> Dec 09, 2019

## 背景简介

前段有同学抛出来这么一个问题：

> 如何实现内核和文件系统做到 2M 以内，启动速度控制在 5s 内

这实际上是要对某款嵌入式 Linux 产品进行技术评估。这类需求其实蛮常见的，正好借此机会展示一款嵌入式 Linux 产品的技术评估过程。

## 基本思路

极端的嵌入式系统通常只有很小的 Flash，这个时候就要考虑把内核和文件系统以及相应的应用都做得很小。

通常的思路：

* 一个是裁剪功能，删除不需要的库、库函数、普通函数
* 一个是用时间换空间，先压缩，运行时解压。

## 压缩算法评估

要做到 2M 以内，那需要看看，用最厉害的压缩算法，压缩比可以到多少？

这篇文章列出了各类压缩算法的比较：[Quick Benchmark: Gzip vs Bzip2 vs LZMA vs XZ vs LZ...](https://catchchallenger.first-world.info/wiki/Quick_Benchmark:_Gzip_vs_Bzip2_vs_LZMA_vs_XZ_vs_LZ4_vs_LZO)

找到上述文章的 Compression ratio 部分，发现最高的在 14% 左右，这里以 15% 为例，这个反过来可以算出来，允许的最大实际 size 是：2M / 15%，也就是 13M。

但是，压缩比比较高的，解压速度一般会更慢一些，所以折衷来看，这个 size 能控制到一半，也就是 6M 左右就比较理想。至于启动速度，可以看一下 Decompression time，看上去同等压缩比，lz4 比 lzop 要优秀一些。而 gzip 在压缩率和解压时间上的 balance 很好。所以最后还是要根据实际情况去挑选。

还有一个需要考虑的是内存，在解压的时候，看看内存这块的消耗，即 Memory requirements on decompression，gzip 和 lzop 需求都比较小，lz4 需要最大，要 10M 以上。

## 系统裁剪方法

接下来就是裁剪，裁剪不外乎：

1. 明确功能需求，做一个需求 list

2. 根据需求细致地配置内核

    记得打开诸如 `-Os` 的选项（可以实测看看，有时候 `-O2` 也不一定大），去掉一些不是很必要的 debug 特性，调试符号什么的都可以去掉，用小尺寸的 features，这里有一个例子，压缩完 300多K，[GitHub - tinyclub/linux-loongson-community at tiny...](https://github.com/tinyclub/linux-loongson-community/tree/tiny36)

    内核模块如果不是特别多，直接编译到内核里头，把内核模块 loading 功能也可以关掉，如果比较多的话，担心启动时间，就可以把内核模块 delay 加载。

3. 根据需求细致地配置文件系统

    比如可以用 busybox，也可以直接用 buildroot 选配，可以选用比较小得文件系统，比如 musl。这里有一份不同库得比较：[Comparison of C/POSIX standard library implementat...](http://www.etalabs.net/compare_libcs.html) ，另外，这里还有一份更详细的比较：<http://tinylab.org/linux-lab-full-rootfs>。

    编译的时候尽量用静态编译取代动态编译。记得开启必要的 strip 选项，如果没有配置，编译完可以手动 strip。

    如果要用到图形系统，可以选小尺寸的，比如国产 minigui，[Home · VincentWei/minigui Wiki · GitHub](https://github.com/VincentWei/minigui/wiki)

4. 文件系统选择

    文件系统可以选独立的只读压缩文件系统，比如说 Cramfs 和 Squashfs，也可以用 cpio，直接把文件系统作为内置 initramfs 编译到内核中。可以在内核中用 `CONFIG_INITRAMFS_SOURCE` 指定。如果是要支持写的，可以考虑搞一小块分区出来做可写的分区，用其他文件系统，比如说 f2fs, ext4。

## 关于启动速度

这个是另外一个课题，有一部分方法是跟裁剪类似的，那就是去掉不需要的功能。还有一些方法是尽量提前让“看得到”的东西先初始化，“看不到的”放在后台线程里头，或者 delay 到后面，这些可以通过调整 initcall 的顺序达到，但是需要注意依赖关系。

还有一些方法：

* 启动的时候可以让启动频率快一些。
* 板子固定的一些数据，如果不是经常变动的，那么可以提前算好，通过参数传递或者写死，牺牲一些灵活性，这里有个比较自动化的方法是 kexec。
* 还有一个不是很常注意的，就是需要关掉串口打印，这个通常会拖慢。
* 再有一个办法是，用功耗换性能，那就是用休眠唤醒取代真正的开机，平时在那里睡着。

曾经的项目里头，关机充电时跑的一个 Recovery 小系统，从开机到显示充电界面，可以跑到 5s 左右。如果用休眠唤醒做模拟开机，就跟平时用手机一样，唤醒一下，做到 2s 内应该问题不大。

## 参考资料

更多的资料欢迎参考泰晓科技为大家收集的一些资源。

1. 系统裁剪优化

    [TinyLinux](http://tinylab.org/tinylinux) 是笔者早期维护过的一段嵌入式 Linux 基金会赞助的项目，里头有收集大量相关成果和资料。

2. 系统启动优化

    下述内容涵盖测量、分析和优化方法与工具。

    * [嵌入式 Linux 启动时间优化](http://tinylab.org/elinux-org-boot-time-optimization/)
    * [Linux 系统启动速度优化概述](http://tinylab.org/linux-system-boot-speedup-overview/)
    * [用 Kexec 快速切换当前 Linux 内核](http://tinylab.org/directly-switch-to-another-kernel-with-kexec/)
    * [测量和分析 Linux 内核启动时间](http://tinylab.org/measure-and-draw-the-boot-up-time-of-linux-kernel/)

[1]: http://tinylab.org
