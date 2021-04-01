---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 真盘开发日志（6）：体验内存编译的用法和好处"
draft: true
tagline: "Linux Lab Disk 支持内存编译，零磁盘损耗做内核开发"
album: "Linux Lab"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-disk-raw-boot/
description: "本文展示了 Linux Lab Disk 内存编译的易用性和好处，内存编译能大幅提升磁盘寿命并提升可用容量"
category:
  - Linux Lab
tags:
  - 真盘
  - 启动盘
  - U盘
  - Linux Lab to go
  - Linux
  - 内存编译
  - 编译速度
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

前面 5 篇介绍了基本用法和透明压缩，本片继续介绍内存编译。

* [在 Windows 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-windows-boot/)
* [在 macOS 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-macos-boot/)
* [在 Linux 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-linux-boot/)
* [在台式机、笔记本和 macBook 上即插即用](http://tinylab.org/linux-lab-disk-raw-boot/)
* [体验透明压缩带来的可用容量翻倍效果](/linux-lab-disk-transparent-compress/)

更多用法可以查看 [Linux Lab Disk 的项目开发记录](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)。

## 内存编译简介

Linux 开发免不了大量的代码编译动作，编译动作则会涉及频繁的磁盘写操作，这个会影响磁盘的寿命。所以作为一款开发用的磁盘，需要设法减少磁盘写操作。

透明压缩在提升可用容量的同时，实际也会提升磁盘寿命，因为翻倍的可用容量提升也意味着磁盘写入的次数减少了一半。

但是，Linux Lab Disk 在这个基础上再进一步，让编译动作直接写到内存不就可以基本消除磁盘写操作了吗？

## 内存编译的用法

Linux Lab 的所有编译输出都统一在 `build/` 目录，如果要实现内存编译，直接把 `build/` 放到内存即可。

### 启用内存编译

启动非常简单，在编译之前只要执行如下命令：

```
$ sudo tools/docker/cache
```

### 跟平时一样编译内核

之后的内存编译动作就完全是透明的，而且编译结果还会进行透明压缩，直接跟平时一样编译就可以，例如：

```
$ time make kernel
  ...
  OBJCOPY arch/arm/boot/zImage
  Kernel: arch/arm/boot/zImage is ready
  UIMAGE  arch/arm/boot/uImage
Image Name:   Linux-5.1.0
Created:      Thu Apr  1 21:44:08 2021
Image Type:   ARM Linux Kernel Image (uncompressed)
Data Size:    4519304 Bytes = 4413.38 KiB = 4.31 MiB
Load Address: 60003000
Entry Point:  60003000
  Kernel: arch/arm/boot/uImage is ready
make[2]: Leaving directory '/labs/linux-lab/build/arm/linux-v5.1-vexpress-a9'
make[1]: Leaving directory '/labs/linux-lab/src/linux-stable'

real	3m39.082s
user	21m19.521s
sys	1m51.298s
```

一次编译下来只用了 3 分多钟，而且这个速度基本不受磁盘写速度的影响，编译时间会很稳定可预期，体验会大大提升。

从这个编译速度来看，即使是关机以后下次想重新编译，也不需要等太久，如果平时直接做休眠唤醒不关机的话，这个数据其实也是 “persistent” 的，当然，千万要插着充电器确保一直有电。

### 查看内存占用情况

如果要查看内存的使用情况，可以用：

```
$ sudo tools/docker/free
Filesystem Size  Used Avail Use% Mounted on
/dev/zram0 5.2G  108M  5.1G   3% /labs/linux-lab/build
```

考虑到内存有限，对于内存编译，我们同样引入了透明压缩。

目前是取了 2/3 的 Free Memory 来做 build，实际测试的情况是，8G 内存大概有 5.2G 来做 build。

```
$ sudo du -sh build
197M	build/
```

而从上述数据来看，默认的 `vexpress-a9` 编译完有 200M 左右，实际只用了大约 100M，那意味着，5.2G 实际可以用来存储 10G，相当于 “平白无故” 多了 10G 容量可以用。

即使是磁盘容量快用完了，有这个 10G 也完全不用担心无法编译，甚至还可以用来临时存放一些其他不重要的数据，千万不要放重要数据，一掉电就完了。

### 备份本次编译的数据

如果关机或者突然掉电，内存中的数据会丢失，如果介意编译的结果，那么可以主动备份起来。

```
$ sudo tools/build/backup
```

注意，目前的实现方案是，这个备份结果会存到一个文件中，并不会回写到原来的 build 目录下。

可以用如下命令恢复使用上次备份的缓存作为 build 目录：

```
$ sudo mount /path/to/backup-file /labs/linux-lab/build/
```

未来可以考虑实现透明备份，也就是直接同步到原有的 `build/` 目录下。

### 恢复到磁盘编译

如果想切换回原有的磁盘编译方式，可以这么取消内存编译：

```
$ sudo tools/build/uncache
```

## 内存编译的好处

综上所述，内存编译的好处其实比较多：

* 基本消除磁盘写操作，大大提升磁盘寿命
* 提供较快的编译速度和较稳定的编译时间预期，基本不受磁盘写速度影响
* 变相提升了 “磁盘” 容量，配合透明压缩，预计从 8G 内存中可拿来 10G 可用容量
    * 这意味着，即使是磁盘快满了，也可以继续做开发和编译

## 抢先体验 Linux Lab Disk

>
> 首批已经制作完，会打 Logo 哦，继企鹅水杯之后，又一款生动的社区纪念品～
>
>
> 大家可以进某宝检索 “Linux Lab 真盘”，有多个不同外观、速度和容量的款色可以选择。
>
> 也可以直接进 [泰晓科技自营店](https://shop155917374.taobao.com/) 直接选购。

## 小结

由于内存编译存在掉电丢失数据的风险，所以请确保仅用来存放编译结果，不要放置其他数据，并自行按需做好备份，确保数据安全。

除了上述风险，内存编译的好处是显而易见的，所以平时可按需开启。

## 参考资料

* [Linux Lab 正在新增对 Linux Lab Disk 的支持](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)

[1]: http://tinylab.org
