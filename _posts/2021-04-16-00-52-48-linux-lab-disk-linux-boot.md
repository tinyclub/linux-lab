---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 真盘开发日志（3）：在 Linux 下直接启动 Linux Lab Disk，当双系统使用"
draft: false
tagline: "在 Linux 系统中通过 VirtualBox, Qemu, kvm 等直接启动 Linux Lab Disk 中的 Linux Lab"
album: "Linux Lab"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-disk-linux-boot/
description: "本文记录了如何在 Linux 下使用 VirtualBox, Qemu, KVM 从 U 盘版 Linux Lab Disk 启动 Linux Lab"
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
  - Virtualbox
  - Qemu
  - EFI
---

> By Wu Zhangjin of [TinyLab.org][1]
> Mar 29, 2021

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

前面两篇介绍了如何在 Windows 和 macOS 系统下利用 VirtualBox 来直接启动 Linux Lab Disk，本文介绍如何在 Linux 下完成相关功能。

* [在 Windows 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-windows-boot/)
* [在 macOS 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-macos-boot/)

更多用法可以查看 [Linux Lab Disk 的项目开发记录](https://gitee.com/tinylab/linux-lab/issues/I31ZTK)。

## 通过 Virtualbox 直接引导

### 安装 Virtualbox

Virtualbox 支持所有主流的桌面操作系统，各大 Linux 发行版都提供了非常完善的支持，一般都可以直接通过包管理工具安装，例如，Ubuntu 下可以这么安装：

```
$ sudo apt-get install -y virtualbox
```

### 创建虚拟磁盘

在 Linux 下的 Virtualbox 用法跟 macOS 和 Windows 几乎一致，唯一区别是，Linux 下的设备名称会有差异，这里简单提一下。

首先插入设别并识别设备名：

```
$ df -h | grep linux-lab-disk
/dev/sdc1        11G   53M   10G   1% /media/ubuntu/linux-lab-disk
```

`linux-lab-disk` 为我们预留给 Windows 和 macOS 共享文件的 10G 空间，是整个磁盘的第一个分区，磁盘完整设备为 `/dev/sdc`。

之后是创建映射到 Linux Lab Disk 的虚拟磁盘：

```
$ VBoxManage internalcommands createrawvmdk -filename "/path/to/LinuxLab.vmdk" -rawdisk /dev/sdc
```

### 通过 Virtualbox 引导 Linux Lab Disk

后续用法跟在 Windows 和 macOS 下完全一致，包括创建名为 “Linux Lab Disk” 的虚拟机、添加虚拟磁盘、使能 EFI、增加内存到 4G，增加 CPU 个数等等。

创建过程比较简单，这里不再重复，请大家参考前述两篇文章之一：

* [在 Windows 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-windows-boot/)
* [在 macOS 系统中直接引导 Linux Lab Disk](http://tinylab.org/linux-lab-disk-macos-boot/)

创建完以后可以直接通过命令行引导：

```
$ virtualboxvm --startvm "Linux Lab Disk"
```

## 通过 Qemu 或 kvm 直接引导

本文主要介绍如何通过 Qemu 或 kvm 来引导，实际上 Windows 和 macOS 下也可以使用 Qemu，只是下载和安装可能没有 Linux 这么方便。

Qemu 或 kvm 最终用到的都是 Qemu System 模拟，只是 kvm 会使能硬件加速。

**注意**：部分早期制作的 Linux Lab Disk 并未开放对 Qemu 的支持，建议优先使用 Virtualbox。

### 安装 Qemu 和 kvm

以 Ubuntu 为例，安装如下：

```
$ sudo apt-get install -y qemu-kvm qemu-system-x86
```

### 通过 Qemu 或 kvm 引导 Linux Lab Disk

同样，先找到 Linux Lab Disk 对应的整个设备：

```
$ df -h | grep linux-lab-disk
/dev/sdc1        11G   53M   10G   1% /media/ubuntu/linux-lab-disk
```

同上，`linux-lab-disk` 为第一个分区，完整设备为 `/dev/sdc`。

Qemu 或 kvm 比 Virtualbox 更为简单，无需额外创建虚拟磁盘，可以直接把查找到的设备号传递给 Qemu 或 kvm，最简单的参数如下：

```
$ sudo kvm -hdb /dev/sdc
```

不过，上述参数还需要略微完善以下，明确指定一下设备的 `Image format` 为 raw 可以消除警告，另外，增加内存可以解决 “error: Out of Memory” 的引导错误。

```
$ sudo kvm -drive file=/dev/sdc,format=raw,index=0,media=disk -m 4G
```

上述 `-drive` 选项指定了磁盘的完整描述，`-m 4G` 给 qemu 留了 4G 内存。这么简单设定以后就能启动，比 Virtualbox 来得简单得多。

当然，还可以增加 cpu 个数：

```
$ sudo kvm -drive file=/dev/sdc,format=raw,index=0,media=disk -m 4G \
    -cpu host -smp 4
```

启动过程如下：

![Linux Lab Disk boots on qemu](/wp-content/uploads/2021/03/29/linux-lab-disk-boot.png)

更多详细用法这里不做展开。

## 直接使用 Linux Lab 真盘中的 Linux Lab

Linux Lab 真盘内已经安装好了 Linux Lab 以及所需的一切，直接点击虚拟机内桌面的 Linux Lab 图标即可启动：

![Linux Lab boots on qemu](/wp-content/uploads/2021/03/29/linux-lab-disk-booted.png)

启动效果如下：

![Linux Lab booted on qemu](/wp-content/uploads/2021/03/29/linux-lab-booted.png)

至此，在 macOS 下终于成功启动 Linux Lab 真盘里面的 Linux Lab 系统了。

## 在三大主流桌面系统中实现即插即用

到目前为止，我们详细介绍了如何在三大主流桌面系统（Windows、macOS 和 Linux）下通过 Virtualbox，Qemu 或 kvm 来直接引导 Linux Lab Disk 并立即使用 Linux Lab。

已经非常方便了吧？

不过，这并不能满足我们，因为创建和配置虚拟机的过程还是略微繁琐，完全可以是用户透明的 —— 未来我们的预期是：在三大主流桌面系统中实现 “即插即用”，跟开机上电的 “即插即用” 一样方便。

我们已经在做这方面的开发，并且已经在 Linux 系统下实现了相应的原型实现，体验非常棒，当然，还需要有更多的开发和验证，尤其是 Windows 平台，奇葩的批处理脚本不会那么好学习和应付，有这块基础的同学快来加入项目吧。

另外，有同学关注到能否通过 Vmware 直接引导，答案是 Yes，上周有几位开发者完成了初期验证，不过还需要更多的验证和评估，我们更希望支持更为开放的 Virtualbox，所以暂时请普通用户不要尝试通过 Vmware 来引导 Linux Lab Disk，Linux Lab Disk 暂时也未开放对 Vmware 的支持，在完成充分的验证之后，我们会再考虑开放相应支持。

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
