---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 新增中天微处理器 Linux 开发插件"
tagline: "零距离接触国产处理器芯片 Linux 开发环境"
group: original
permalink: /linux-lab-add-csky-dev-plugin/
description: "Linux Lab 开源项目新增国产中天微处理器 Linux 开发插件，助力国产处理器提升系统软件开发效率。"
category:
  - Linux Lab
tags:
  - 中天微
  - csky
  - qemu
  - buildroot
---

> By Falcon of [TinyLab.org][1]
> Nov 25, 2017

## 简介

C-SKY CPU 体系结构由 [杭州中天微系统有限公司](http://www.c-sky.com/) 开发，主要面向 IoT 市场。

为了方便大家体验 [C-SKY Linux](https://c-sky.github.io)，杭州中天微准备了 [buildroot](https://buildroot.org)。Buildroot 使用方便，功能强大，可用于快速构建嵌入式 Linux 系统开发环境。在 [github.com/c-sky/buildroot](https://github.com/c-sky/buildroot) 可下载最新的 C-SKY buildroot 代码。

笔者在 C-SKY Linux 维护人员 Guo Ren 的指导下亲自体验了 C-SKY Buildroot 的强大，该 Buildroot 完美集成了 C-SKY 版本的 Qemu, Linux 和 uClibc-ng 等软件包，确实非常简易方便，参考这篇 [readme.txt](https://github.com/c-sky/buildroot/tree/master/board/qemu/csky)，在网速较好的环境下可以快速体验 C-SKY 的开发。

不过基于 Buildroot 的方式还是有一些不足，例如：需要临时下载 1.2G 左右的软件包，临时编译 Qemu、交叉工具链、内核和文件系统，这一路下来需要等待和耗费非常多的时间。

[Linux Lab](http://tinylab.org/linux-lab) 正好能够很好地解决这些问题，它允许提前编译好上述工具因此只需要下载最关键的软件包，对于在线版的 Linux Lab，还会预先下载部分软件包。这些功能允许开发者极速体验一款新的处理器或者开发板，并根据需要仅仅重新编译需要开发的那部分软件，因此会节约大量的时间，也会相应地降低开发门槛。

日前，基于 [C-SKY Linux](https://github.com/c-sky) 的开源成果，与 Guo Ren 同学通过 [Cloud Lab](http://tinylab.cloud:6080/) 在线协作，经过大约一周多的努力，终于以插件的方式在 Linux Lab 中添加了对 C-SKY ck810 处理器 Linux 开发环境的支持：

- [Linux Lab C-SKY Plugin](https://gitee.com/tinylab/csky)

## 用法

该插件使用起来非常简单，先介绍在线使用。

### 在线使用

为了让国人能够快速体验国产处理器，我们在开发完 Linux Lab 的 csky 插件后，已经第一时间上线 [泰晓实验云台](http://tinylab.cloud:6080/labs/)。

因此，进入该云台的 Linux Lab，登陆后点击桌面的终端快捷方式，输入以下命令即可极速体验：

    $ make boot BOARD=csky/virt

上述命令快速启动预先编译好的内核和文件系统，[这里](http://showterm.io/40f54d3209b4651307273) 可以查看通过 Showterm 录制的效果。

而通过 NFS 挂载根文件系统，可以简单执行：

    $ make boot ROOTDEV=/dev/nfs

录制好的效果可通过 [这里](http://showterm.io/2800f4fb79e8830774b7c) 查看。

### 本地使用

如果想在本地使用，也很方便，参考 [Linux Lab](http://tinylab.org/linux-lab) 先下载和安装好 [Cloud Lab](http://tinylab.org/cloud-lab) 和 Linux Lab，然后参考 [csky 插件](https://gitee.com/tinylab/csky) 的文档完成下述过程。

    $ cd boards/
    $ git clone https://gitee.com/tinylab/csky.git
    $ cd ../
    $ make list
    $ make BOARD=csky/virt
    $ make boot

上述命令下载 csky 插件，选择 `csky/virt` 虚拟开发板然后在该板子上启动好预先编译好的内核和文件系统。

下面介绍一条更为复杂和完整的命令：

    $ make test BOARD=csky/virt TEST=root-full,kernel-full

它完成如下动作：

1. 设置板子为 `csky/virt`
2. 下载、配置、打补丁并编译根文件系统
3. 下载、配置、打补丁并编译内核
4. 在 qemu-system-cskyv2 上运行新编译的内核并通过 nfs 挂载根文件系统
5. 关闭系统退出 qemu

上述动作也通过 Showterm 进行了录制，可通过 [这里](http://showterm.io/90d11debc3e51bb56d274) 查看。

实际上，该插件也已经支持 qemu 编译。

### 详细用法

由于该插件新增的 `csky/virt` 虚拟开发板完美支持 Linux Lab 的绝大部分功能（目前暂时不支持Uboot），所以用法跟其他已有的虚拟开发板类似。

更多具体的用法请直接参考 [Linux Lab](http://tinylab.org/linux-lab) 以及 Linux Lab 源码中的 [README.md](https://gitee.com/tinylab/linux-lab/blob/master/README.md)。

## 后记

Linux Lab 一开始就加入了 4 大处理器架构和 6 款虚拟开发板，一直希望能够加入一款国产处理器和国产开发板，从而可以让国人极速体验国产芯片以及相关系统软件的研发成果。

前不久，恰好有一天，[C-SKY Linux](https://c-sky.github.io) 的维护人员 Guo Ren 同学联系到我，希望能够在 Linux Lab 中加入 C-SKY 支持，两个人一拍即合。

上上周，笔者通过 Cloud Lab 搭建了一套用于协作的在线 Linux Lab，与 Guo Ren 同学通过大约一周多的协力，终于为 Linux Lab 添加了 [C-SKY](https://gitee.com/tinylab/csky) 插件。

在这一周多的时间内，通过深入研究 [C-SKY Buildroot](https://github.com/c-sky/buildroot)，发现该项目架构清晰、文档健全、更新活跃，深切感受到中天微在 Linux 开源方面的工作成果非常突出，令人为之赞叹。

希望这份努力能够为国产芯片的发展作出一些微薄的贡献，也期待国产芯片能够取得更多的成就。

目前正计划为 Linux Lab 添加龙芯处理器的 Linux 开发插件，敬请期待。

[1]: http://tinylab.org
