---
layout: post
author: 'Jia Xianhua'
title: "Linux Lab 真盘开发日志（2）：在 macOS 下直接启动 Linux Lab Disk，当双系统使用"
draft: true
tagline: "在 macOS 系统中通过 VirtualBox 直接启动 Linux Lab Disk 中的 Linux Lab"
album: "Linux Lab"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-disk-macos-boot/
description: "本文记录了如何在 macOS 下使用 VirtualBox 从 U 盘版 Linux Lab Disk 启动 Linux Lab"
category:
  - Linux Lab
tags:
  - 真盘
  - 启动盘
  - U盘
  - Linux Lab to go
  - macOS
  - Virtualbox
  - EFI
---

> By 贾献华 of [TinyLab.org][1]
> Mar 20, 2021

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

[上一篇](http://tinylab.org/linux-lab-disk-windows-boot/) 介绍了如何在 Windows 系统下利用 VirtualBox 来直接启动 Linux Lab Disk，本文介绍如何在 macOS 下完成相关功能。

更多用法可以查看 [Linux Lab Disk 的项目开发记录](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)。

## 安装 Virtualbox

Virtualbox 支持所有主流的桌面操作系统，请先按需下载并安装 macOS 上的版本，下载地址如下：

* [Virtualbox 下载](https://www.virtualbox.org/wiki/Downloads)

## 创建映射到 Linux Lab Disk 的 Virtualbox 虚拟硬盘

### 卸载掉自动挂载的 NTFS 分区

在 macOS 中插入 Linux Lab Disk 后，会自动挂载分区，为了创建虚拟硬盘，需要先卸载掉：

```
$ df -h | grep usbdata
/dev/disk2s1   10Gi  67Mi   10Gi  1% 38 10533327 0%  /Volumes/usbdata
$ sudo umount /Volumes/usbdata
```

否则会提示如下错误：

```
VBoxManage: error: Cannot open the raw disk '/dev/disk2s1': VERR_RESOURCE_BUSY
VBoxManage: error: The raw disk vmdk file was not created
```

### 查看 Linux Lab Disk 对应的设备

上述 `df -h` 结果也告诉我们 Linux Lab Disk 对应的设备为 `/dev/disk2`，`/dev/disk2s1` 为其第一个分区。

### 通过 VBoxManage 创建虚拟硬盘

```
$ VBoxManage internalcommands createrawvmdk -filename  "/tmp/LinuxLabDisk.vmdk" -rawdisk /dev/disk2
RAW host disk access VMDK file /tmp/LinuxLabDisk.vmdk created successfully.
```

**注意**：具体使用时，建议使用一个永久的地址来存放 LinuxLabDisk.vmdk 文件，因为上述 `/tmp` 目录下的内容在关机以后会丢失。

## 创建 Virtualbox 虚拟机用于启动 Linux Lab Disk 对应的虚拟硬盘

类似于 Windows，首先启动 Virtualbox，并创建一个新的虚拟机：

<!-- TODO：补充一张截图 -->

然后，虚拟硬盘选择之前生成的 LinuxLab.vmdk 即可。

## 在 Virtualbox 中启动 Linux Lab Disk

接下来，通过前述创建的虚拟机来启动 Linux Lab Disk。

使用过程中踩了几个坑，需要提醒大家注意一下：

### 启用 EFI

Linux Lab Disk 采用 EFI 引导协议，所以在 Virtualbox 系统配置的 “扩展部分”，请在 “启用 EFI （只针对某些操作系统）” 前打钩：

<!-- TODO：补充一张截图 -->

### 加大内存到 4G 左右

同样是 Virtualbox 系统配置，请把 “内存大小” 调整为 4096M 或以上：

<!-- TODO：补充一张截图，得空可以验证下最低需要的内存大小，比如说 2G 是否够用？ -->

否则屏幕会一直黑屏，无法正常启动：

### 使用桥接网络

而 “网络” 的连接方式请调整为 “桥接网卡”：

<!-- TODO：补充一张截图 -->

否则会出现如下错误：

<!-- TODO：补充一张错误截图 -->

做完上述调整后，就能正常使用了。

## 直接使用 Linux Lab 真盘中的 Linux Lab

Linux Lab 真盘内已经安装好了 Linux Lab 以及所需的一切，直接点击虚拟机内桌面的 Linux Lab 图标即可启动，启动效果如下：

<!-- TODO：补充相关截图 -->

至此，在 macOS 下终于成功启动 Linux Lab 真盘里面的 Linux Lab 系统了。

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
