---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 真盘开发日志（4）：在台式机、笔记本和 macBook 上即插即用"
draft: true
tagline: "在 X86_64 主机关机状态下，开机上电引导后免安装使用 Linux Lab"
album: "Linux Lab"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-disk-raw-boot/
description: "本文记录了如何在 X86_64 主机上即插即用使用 Linux Lab Disk 启动 Linux Lab"
category:
  - Linux Lab
tags:
  - 真盘
  - 启动盘
  - 安装盘
  - Ubuntu
  - U盘
  - Linux Lab to go
  - Linux Lab Disk
  - Linux
  - F12
  - Option
  - macbook
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

前面三篇介绍了如何在 Windows、macOS 和 Linux 系统下利用 VirtualBox 或 Qemu 来直接启动 Linux Lab Disk，当双系统使用。本文介绍如何在 “裸机” 上直接引导启动 Linux Lab Disk。

* [在 Windows 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-windows-boot/)
* [在 macOS 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-macos-boot/)
* [在 Linux 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-linux-boot/)

更多用法可以查看 [Linux Lab Disk 的项目开发记录](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)。

## 主机支持情况

不是很老很老的机器一般都能很顺畅的引导 Linux Lab Disk，目前拿到 Linux Lab Disk 的同学们都没反馈过引导失败的问题。

仅有少数机器配置的显卡或者无线网卡驱动可能不是特别常见，所以驱动方面会有一些影响，安装上即可，如果恰好配置的设备无法驱动，欢迎加 tinylab 进开发这群讨论。

这里简单列一下基本要求：

* 主机处理器为 X86_64，所以大部分市面上的主流台式机、笔记本甚至 M1 之前的 macBook 一般都支持
* BIOS 支持 UEFI 引导
* USB 接口为 Type-A USB 3.0, 3.1
* 内存在 4G 或以上
* 对存储无要求，主机可以没有存储

## 在裸机下引导 Linux Lab Disk 的简单过程

### 选择引导设备

首先让主机进入到关机状态，接着就是按下 F12 + 电源按键开机进入到引导设备选择界面。

测试过的几个主机都能通过 F12 进入到引导设备选择界面，而 macBook 需要按 Option 按键。

接着就是选择引导界面显示的 Linux Lab Disk 对应的产品型号。

目前制作的 Linux Lab Disk 会显示 U 盘制造商的产品信息，比如 LanKxin 字样，大家注意通过类似信息选择上 Linux Lab Disk，未来我们会统一标识为 Linux Lab Disk，增强辨识性。

选择完以后，按下 Enter 即可进入 Grub 引导菜单。

### 修改默认引导顺序

测试过的几个主机都能通过 `F2 + DEL` 进入到 BIOS 设定界面。

进入该 BIOS 设定界面后，通常会有类似 `Boot Option Priorities` 类似的选项，根据 BIOS 的快捷键设定引导顺序即可，比如说 USB 引导优先。

不过目前固态版的 Linux Lab Disk 可能会被直接识别为 HDD，部分 BIOS 也许不一定能在 HDD 设备中再做顺序设定。

### 在 Grub 菜单中引导 Linux Lab Disk

Grub 菜单中提供了多个选项，默认的就是第一个，会看到 Linux Lab Disk 字样，正常情况下请不要刻意去选择。

如果错误移动了上下方向键，大家移动回第一个选项即可，之后按下 Enter。

在这个界面，如果没有移动方向键，会只停留 2s 钟。

按下方向键或者停留超过 2s 后会一路引导进入到 Linux Lab Disk 桌面系统。

## 直接使用 Linux Lab 真盘中的 Linux Lab

Linux Lab 真盘内已经安装好了 Linux Lab 以及所需的一切，直接点击虚拟机内桌面的 Linux Lab 图标即可启动。

由于使用是类似的，所以直接复用之前的截图：

![Linux Lab boots on qemu](/wp-content/uploads/2021/03/29/linux-lab-disk-booted.png)

启动效果如下：

![Linux Lab booted on qemu](/wp-content/uploads/2021/03/29/linux-lab-booted.png)

至此，在 “裸机” 下终于成功启动 Linux Lab 真盘里面的 Linux Lab 系统了。

## 裸机下直接使用 Linux Lab Disk 的优劣

“裸机” 下直接上电使用 Linux Lab Disk 的好处多多：

1. CPU、内存资源独占，配合固态版的 Linux Lab Disk，体验会比较爽快。
2. 没有其他系统和事情干扰，可以更专心的做实验和开发。
3. 只要有一台 X86_64 的主机，随时随地，没有特别的依赖，不需要提前在主机系统装虚拟机。

当然，这个时候要说有 “劣势”，那就是需要先把机器关了，其他手头的工作需要停一停。

如果实在是不想停，那就参考前三篇文章当双系统使用吧，按需随便选择用法，提前装一次 Virtualbox 或 Qemu 就好。

## 抢先体验 Linux Lab Disk

>
> 首批已经制作完，会打 Logo 哦，继企鹅水杯之后，又一款生动的社区纪念品～
>
>
> 大家可以进某宝检索 “Linux Lab 真盘”，有多个不同外观、速度和容量的款色可以选择。
>
> 也可以直接进 [泰晓科技自营店](https://shop155917374.taobao.com/) 直接选购。

## 小结

体验完以后最大的感觉就是便利性，有了一块 Linux Lab 真盘，随时随地随系统都能使用：

* 在主机关机状态下，插入 Linux Lab Disk，按下 F12 （macBook 按 Option）上电选择新识别的盘，上电开机就能用
* 在三大主流操作系统中（Windows、Linux 和 macOS），均可通过 Virtualbox 等虚拟机直接启动 Linux Lab Disk，无需安装新系统就能直接用

不仅无需安装 Linux Lab，连 Linux 系统也不用安装了，因为 Linux Lab Disk 自带了一套最新的 Ubuntu 20.04.2，所以可以直接当 Linux 开发系统使用。

如果实在想画蛇添足，再安装一个系统，Linux Lab Disk 还可以当安装盘使用，当然，也可以当急救盘。另外，因为有预留了 10G 的 NTFS，还可以用来作数据备份、甚至用来当车载音乐盘。

由于 Linux Lab 的主系统目前只支持 X86_64，所以 macBook M1 暂时并不支持。

## 参考资料

1. [Linux Lab 正在新增对 Linux Lab Disk 的支持](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)
2. [How to boot from USB in VirtualBox - AIO Boot](https://www.aioboot.com/en/boot-from-usb-in-virtualbox/)

[1]: http://tinylab.org
