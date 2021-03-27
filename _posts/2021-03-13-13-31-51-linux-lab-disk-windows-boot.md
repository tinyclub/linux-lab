---
layout: post
author: 'Jia Xianhua'
title: "Linux Lab 真盘开发日志（1）：在 Windows 下直接启动 Linux Lab Disk，当双系统使用"
draft: true
tagline: "在 Windows 系统中通过 VirtualBox 直接启动 Linux Lab Disk 中的 Linux Lab"
album: "Linux Lab"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-disk-windows-boot/
description: "本文记录了如何在 Windows 下使用 VirtualBox 从 U 盘版 Linux Lab Disk 启动 Linux Lab"
category:
  - Linux Lab
tags:
  - 真盘
  - 启动盘
  - U盘
  - Linux Lab to go
---

> By 贾献华 of [TinyLab.org][1]
> Mar 13, 2021

## Linux Lab 真盘介绍

牛年到来之前，Linux Lab 又有了新的目标：**只需要一个随身携带的 U 盘，就能实现 Linux Lab 系统的随时启动**。

>
> Linux Lab Disk 的开发工作目标是制作一个 “开箱即用” 的 Linux Lab，降低对网络的依赖。
>
> 本次 Linux Lab Disk 作为 Linux Lab v0.7 的主要开发内容，跟 Linux Lab 本身一样，该盘基础系统初步选定为 Ubuntu 20.04，方便内外保持使用一致性。
>

真是辛苦 Linux Lab 的团队了，为了在春节前让小伙伴能尽早体验，不停的测试 U 盘，改进体验。

近水楼台先得月，我在春节前，也就是 2021 年 2 月 4 日就收到 128G 高速固态版 Linux Lab Disk，抢先体验了一把。

另外，需要补充的是：

>
> Linux Lab Disk 中文名被命名为 “Linux Lab真盘”，一方面是用以区别于不能启动系统只能存储文件的普通数据 U 盘或者硬盘，另外一方面是延续 “Linux Lab 真板” 的命名方式。
>
> 目前 Linux Lab Disk 主要以 U 盘的形态出现，并打上了 Linux Lab 的 Logo，可识别度很高，未来不排除有其他形态的方式出现。
>

Linux Lab Disk 插入到主机（支持 X86_64 的 PC、笔记本、MacBook 等）上以后，可以在关机状态下上电直接启动，也可以在 Windows、Linux 和 MacOS 系统中直接启动当双系统使用，这两种方式都免安装，启动就能用。

下面简单介绍如何在 Windows 系统下利用 VirtualBox 来直接启动 Linux Lab Disk，本文会介绍两种使用方式。

更多用法可以查看 [Linux Lab Disk 的项目开发记录](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)，里面登记了 PC，MacBook 上启动 Linux Lab Disk 的方法。

## 创建映射到 Linux Lab Disk 的 Virtualbox 虚拟硬盘

### 查看 Linux Lab Disk 的磁盘编号

首先通过 `Windows + R` 打开 **运行** 程序：

```
diskmgmt.msc
```

![diskmgmt](/wp-content/uploads/2021/03/13/diskmgmt.png)

识别到 128G Linux Lab Disk 为 `磁盘1`，即 `PhysicalDrive1`，后面会用到。

![disk1](/wp-content/uploads/2021/03/13/disk1.png)

也可以直接通过该命令查看：

```
wmic diskdrive list brief
```

### 启动 Cmd 程序，通过 VBoxManage 创建虚拟硬盘

在搜索框输入 Cmd，并选择 **以管理员身份打开** Cmd：

![cmd](/wp-content/uploads/2021/03/13/cmd.png)

接下来，进入到 VirtualBox 的安装目录位置：

```
cd D:\Program Files\Oracle\VirtualBox
```

然后，通过 VBoxManage 创建映射到 Linux Lab Disk 的虚拟硬盘：

```
VBoxManage internalcommands createrawvmdk -filename F:\VBOX\LinuxLab.vmdk -rawdisk \\.\PhysicalDrive1
```

![createrawvmdk](/wp-content/uploads/2021/03/13/createrawvmdk.png)

上面的命令会在目标目录下生成 LinuxLab.vmdk。

![vmdk](/wp-content/uploads/2021/03/13/vmdk.png)

## 创建 Virtualbox 虚拟机用于启动 Linux Lab Disk 对应的虚拟硬盘

首先启动 Virtualbox，并创建一个新的虚拟机：

![vbox](/wp-content/uploads/2021/03/13/vbox.png)

然后，虚拟硬盘选择之前生成的 LinuxLab.vmdk 即可：

![vdisk](/wp-content/uploads/2021/03/13/vdisk.png)

## 在 Virtualbox 中启动 Linux Lab Disk

接下来，通过前述创建的虚拟机来启动 Linux Lab Disk。

### 进入启动界面

![boot](/wp-content/uploads/2021/03/13/boot.png)

### 报错信息

直接启动后出现如下错误：

![error](/wp-content/uploads/2021/03/13/error.png)

### 启用 EFI

换用 EFI 启动后完美起来：

![efi](/wp-content/uploads/2021/03/13/efi.png)

## 通过 VMUB 更自动化的实现 Linux Lab Disk 启动

前述过程比较繁琐，所以社区开发有 VMUB，这款软件能够自动完成上述虚拟硬盘的创建和相关设定。

下面简单介绍其用法。

### 下载与安装

首先在下面的链接下载最新的版本并安装：

* [Releases · DavidBrenner3/VMUB](https://github.com/DavidBrenner3/VMUB/releases)

### 新建启动项

启动上述软件并作相关设定如下：

- VM Name 选刚才创建的虚拟机
- Drive to add and boot: 选择 U盘

![vmub](/wp-content/uploads/2021/03/13/vmub.png)

### 移除之前创建的 LinuxLab.vmdk

为了避免重复，这里可以先移除掉之前创建的虚拟硬盘。

![remove](/wp-content/uploads/2021/03/13/remove.png)

### 点击 Start 启动虚拟机

如果提示错误，不用理会，并不影响实际使用：

![start](/wp-content/uploads/2021/03/13/start.png)

如果虚拟机没有启动，在 VirtualBox 里面启动一下就可以了：

![ubuntu](/wp-content/uploads/2021/03/13/ubuntu.png)

## 直接使用 Linux Lab 真盘中的 Linux Lab

Linux Lab 真盘内已经安装好了 Linux Lab 以及所需的一切，直接点击虚拟机内桌面的 Linux Lab 图标即可启动，启动效果如下：

![linuxlab](/wp-content/uploads/2021/03/13/linuxlab.png)

至此，在 Windows 下终于成功启动 Linux Lab 真盘里面的 Linux Lab 系统了。

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
