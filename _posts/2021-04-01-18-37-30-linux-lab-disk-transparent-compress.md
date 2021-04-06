---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 真盘开发日志（5）：体验透明压缩带来的可用容量翻倍效果"
draft: true
tagline: "Linux Lab Disk 主系统采用支持透明压缩的文件系统"
album: "Linux Lab"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-disk-transparent-compress/
description: "本文演示了 Linux Lab Disk 的透明压缩功能带来的容量翻倍的实实在在的好处"
category:
  - Linux Lab
tags:
  - 真盘
  - 启动盘
  - 安装盘
  - U盘
  - Linux Lab to go
  - Linux Lab Disk
  - Linux
  - 透明压缩
  - 磁盘寿命
  - 可用容量
  - Ubuntu
---

> By Wu Zhangjin of [TinyLab.org][1]
> April 01, 2021

## Linux Lab 真盘介绍

牛年到来之前，Linux Lab 又有了新的目标：**只需要一个随身携带的 U 盘，就能实现 Linux Lab 系统的随时启动**。

>
> Linux Lab Disk 的开发工作目标是制作一个 “开箱即用” 的 Linux Lab，降低对网络的依赖。
>
> 本次 Linux Lab Disk 作为 Linux Lab v0.7 的主要开发内容，跟 Linux Lab 本身一样，该盘基础系统初步选定为 Ubuntu 20.04，方便内外保持使用一致性。
>
>
> Linux Lab Disk 中文名被命名为 “Linux Lab真盘”，一方面是用以区别于不能启动系统只能存储文件的普通数据 U 盘或者硬盘，另外一方面是延续 “Linux Lab 真板” 的命名方式。
>
> 目前 Linux Lab Disk 主要以 U 盘的形态出现，并打上了 Linux Lab 的 Logo，可识别度很高，未来不排除有其他形态的方式出现。
>

Linux Lab Disk 插入到主机（支持 X86_64 的 PC、笔记本、MacBook 等）上以后，可以在关机状态下上电直接启动，也可以在 Windows、Linux 和 MacOS 系统中直接启动当双系统使用，这两种方式都免安装，启动就能用。

前面 4 篇介绍了 Linux Lab Disk 在裸机上直接上电启动以及在现有系统下当双系统启动，本篇进一步介绍其透明压缩功能。

* [在 Windows 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-windows-boot/)
* [在 macOS 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-macos-boot/)
* [在 Linux 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-linux-boot/)
* [在台式机、笔记本和 macBook 上即插即用](http://tinylab.org/linux-lab-disk-raw-boot/)

更多用法可以查看 [Linux Lab Disk 的项目开发记录](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)。

## 透明压缩简介

透明压缩不同于普通压缩，无需用户手动去压缩某个文件，用户所有操作跟平时一样就好，文件的压缩和解压过程完全在背后自动完成。

透明压缩带来的最大好处是：相同容量的磁盘可以存储更多的内容，具体效果如何呢？接下来一起看看。

透明压缩由于会做额外的压缩、解压动作，当然会需要消耗一部分的 CPU、内存资源，对前台操作可能会有一定的影响，但是在 1.9G 主频, 8 核，8G 内存的机器上的实际体验来看，基本是无感的。

## 查看 Linux Lab Disk 裸盘容量

首先来看看刚制作好还没开始使用的 Linux Lab Disk 的 “裸盘” 情况，注意，不同版本因功能升级会略有差异。

以 128G 的某品牌盘为例，来查看一下整个磁盘的大小。

```
$ lsblk -Po size -dn /dev/sdc
SIZE="116.5G"
```

实际可用的容量，按 1024 为单位阶梯来算，实际只有 116.5GiB。

再来看看使用情况：

```
$ df -h | grep sdc
/dev/sdc4       2.6G  2.6G     0 100% /media/ubuntu/lld-cd-v0.1
/dev/sdc6        58G  3.8M   56G   1% /media/ubuntu/misc
/dev/sdc1        11G   53M   10G   1% /media/ubuntu/linux-lab-disk
/dev/sdc5        47G  8.1G   38G  18% /media/ubuntu/writable1
```

可用容量和已用容量很快可以算出来：

```
$ echo "56+10+38" | bc -l
104
$ echo "116.5-104" | bc -l
12.5
```

那实际写入了多少数据呢？重点看 `/media/ubuntu/writable1` 和 `/media/ubuntu/lld-cd-v0.1`。

```
$ sudo du -sh /media/ubuntu/writable1/
11G	/media/ubuntu/writable1/
$ sudo du -sh /media/ubuntu/lld-cd-v0.1/
2.6G	/media/ubuntu/lld-cd-v0.1/
$ sudo du -sh /rofs
4.9G	/rofs/
$ lsblk -Po size /dev/sdc3
SIZE="220M"
```

几个数据加起来会超过 18.72G，这么多数据实际上只占用了 12.5G，差不多节省了 6G 左右，节省幅度是 30% 左右。

而单纯来看主分区，写入了 11G 以上，只占用了 8.1G，省了将近 3G，也有 26%，这里有个需要注意的是，由于多个 lab 仓库的 git pack 本身是压缩的，所以收益看上去不是很明显，如果是纯粹的代码，这个受益会很可观。

按保守估计 30% 计算，预计余下的 104G 可以写入 135.2G，如果数据内容不一样，压缩比会大大提升，下一节我们会看到更可观的效果。

再来看看另外一个 64G Linux Lab Disk 的情况。

```
$ lsblk -Po size -dn /dev/sdc
SIZE="59G"
$ df -h | grep sdc
/dev/sdc4       2.6G  2.6G     0 100% /media/ubuntu/lld-cd-v0.1
/dev/sdc1        11G   53M   10G   1% /media/ubuntu/linux-lab-disk
/dev/sdc5        47G  8.2G   38G  18% /media/ubuntu/writable1
```

剩余容量在 48G，按 30% 的比例保守估计，预计还可以写入 62.4G。

## 使用一段时间后再查看容量

再来看看另外一个 128G Linux Lab Disk，这个已经用了较长的时间，写入的数据更多，安装的软件包也更多，数据类型也更丰富。

我们重点来看看主分区：

```
$ df -h | grep sdb5
/dev/sdb5       106G   42G   64G  40% /media/ubuntu/writable
$ sudo du -sh /media/ubuntu/writable
89G	/media/ubuntu/writable
```

这里看到 42G 物理容量写入了 89G 数据，达到惊人的 2.11 倍，省了 53%，也就是实际占用不到一半，可用容量翻了一倍。

再来看看另外一款 64G Linux Lab Disk，这个用的次数少一些，安装的软件包也少比较多。

```
$ df -h | grep sdc5
/dev/sdc5        47G   30G   17G  65% /media/ubuntu/writable1
$ sudo du -sh /media/ubuntu/writable1/
80G	/media/ubuntu/writable1/
```

写入了 80G，只用了 30G，差不多省了 63%，可用容量翻了一倍还多。30G 物理容量存下了 80G 数据，达到惊人的 2.67 倍。

## 透明压缩收益小结

综合上述两组数字来看，如果存储的是文本、代码、程序等可压缩性比较高的数据，那么可用容量有可能达到甚至超过翻倍的效果。

## 抢先体验 Linux Lab Disk

>
> 首批已经制作完，会打 Logo 哦，继企鹅水杯之后，又一款生动的社区纪念品～
>
>
> 大家可以进某宝检索 “Linux Lab 真盘”，有多个不同外观、速度和容量的款色可以选择。
>
> 也可以直接进 [泰晓科技自营店](https://shop155917374.taobao.com/) 直接选购。

## 小结

从透明压缩的收益来看，Linux Lab Disk 不仅可以做到免安装即插即用使用 Linux Lab，还能带来额外的可用容量，理想的情况下，可用容量能翻倍。

## 参考资料

* [Linux Lab 正在新增对 Linux Lab Disk 的支持](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)

[1]: http://tinylab.org
