---
layout: post
author: 'Wu Zhangjin'
title: "基于 Docker/Qemu 快速构建 Linux 实验环境"
group: original
permalink: /docker-qemu-linux-lab/
description: "继 Linux 0.11 Lab 之后，本站放出 Linux Lab，另外一个可快速构建的 Linux 内核实验环境。"
category:
  - Linux 内核
  - Linux Lab
tags:
  - Docker
  - Qemu
  - 实验环境
  - versatile
  - g3beige
  - pc
  - malta
---

> By Falcon of TinyLab.org
> 2016-07-20 01:46:26

## 缘起

早在大学的时候，就尝试过，在学校报废的古老 i386 的机器上跑 User Mode Linux，为 [兰大开源社区][1] 的用户提供过在线 [Linux][9] 虚拟实验环境，目的就是希望为大家降低 Linux 学习准入的门槛。

而比较近的尝试是 [Linux 0.11 Lab][2]，一个基于 [Docker][8]/[Qemu][7]，可以在 5 分钟内构建的 [Linux 0.11][10] 实验环境。

这些动作的背后是意识到，很多时候，工程类的学习之所以不能深入或者久久无法入门，很大程度是卡在实践必须的实验环境的构建上。

要知道，我上大研究生那伙，一个月 400 块的补助，除了吃喝，根本就没钱买开发板，幸好实验室有大量板子可以玩。但是，作为学生，大多没有经济收入来源，不一定那么容易取得所需的开发板。

而另外一个方面是，即使是有钱买板子，如果只是想研究某个内核特性，那些折腾板子的挫折也可能彻底堵住 Linux 求学之路。

所以，有幸有这么多前辈们铺路，先有了比 User Mode Linux 更强大的虚拟机 Qemu/KVM，后有了容器 Docker，整个的开发环境搭建过程变得非常地便捷。

从最初玩 Linux 0.11，花了不下 2 个多礼拜才把环境搭建起来，把环境分享出去后，也前前后后还有几十号人跟我咨询讨论，在实验环境一项上就来来回回折腾浪费了很多精力。而到现在，Linux 0.11 Lab 只要 5 分钟就可以搭建，华科的两个大一女生前不久来邮件讨论说添加 System Call 遇到了问题，原来她们很轻松就用 Linux 0.11 Lab 把环境搭建并做起实验来了。这不单单是节约生命，而且大大疏通了 Linux 求学的路途。

Linux 0.11 很适合操作系统基本原理的学习，但是要搞嵌入式开发，搞 Android 智能手机，还得研究最新的主线 Linux。所以一个更便捷的 Linux 实验环境也来得非常迫切。

大约在 2011 年左右，当时有利用业余时间提案并申请 CELF （消费电子 Linux 基金会）的项目，主要是做 [Linux 裁剪][3]，其中重中之重，就是 [gc-section][11]。

当时做 gc-section 的初衷就是要往社区提的，在提交之前，必须有足够充足的测试和验证。当时都已经毕业了，也搞不到那么多开发板做测试，于是用 Qemu 针对 4 个架构都编译了 Linux 内核，创建了 initrd，并写了脚本来做自动化测试、验证和调试。但是这些脚本不够完善，不同架构的支持也是比较零散，所以那时很迫切的一个目标就是整理出一个完整的脚本环境。

可惜地是，之后很长一段时间，工作忙碌起来，那个裁剪项目最终也未能顺利完成，相关项目也还只是停留在自己的代码仓库中（中途有过华为的同学来电咨询过 Patch 移植）。随着 Linux 0.11 Lab 的成功，迫切觉得有必要把之前那些工作成果捡起来，通过 Docker 整合一下，分享给行业，造福更多的同学，也方便大家更容易从事 Linux 方面的学习、工作和研究。

## 目标和现状

目标是非常清晰，那就是这个环境：

* 得基于 [Qemu][7]，天生要支持一大堆的免费开发板和处理器架构，使得自然而然地获得一个完整的 Linux 开发板仓库，可以方便各种开发、调试与测试。
* 另外一个是，基于 [Docker][8]，可以快速构建和复制这个实验环境，避免一条一条命令反反复复地敲，节约生命。
* 再一个是选择一个居中规模的 rootfs 构建工具：[Buildroot][6]，可以用它灵活构建具有各种工具的小型文件系统，这样就很方便整合自己需要的工具。

有了这几个目标以后，最近两周终于下定决心把之前的脚本环境和进行 gc-section 开发时保留的内核配置文件等充分利用起来，然后快速构建了一个 Linux Lab 框架：

* [Linux Lab 代码仓库][4]
* [Linux Lab 项目首页][5]

通过两周的迭代，已经完成了 4 个常见架构（ARM、 X86、PowerPC、MIPS），支持从 `/dev/ram` 和 `/dev/nfs` 加载 rootfs，支持串口和图形，内建网络支持…… 接下来，在线调试支持和 Android emulator 的支持很快就会到位了。

当然，也热烈欢迎大家提交PR，提交各种新的架构和内核版本等配置。

## 尝鲜

未来的迭代还会继续，但是已经不妨碍我们尝鲜了，以 Ubuntu 和 Qemu 为例：

### 下载

    git clone https://github.com/tinyclub/linux-lab.git
    

### 安装

    $ sudo tools/install-docker-lab.sh
    $ tools/run-docker-lab-daemon.sh
    $ tools/open-docker-lab.sh
    

### 启动

打开 `http://localhost:6080/vnc.html` 并输入 `ubuntu` 密码登陆，之后打开一个控制台：

    $ sudo -s
    $ cd /linux-lab
    $ make boot

默认会启动一个 `versatilepb` 的 ARM 板子。

### 更多用法

详细的用法这里就不罗嗦了，大家自行查看帮助。

    $ make help

因为还在火热迭代中，所以部分用法可能会变更，请随时注意 `README.md` 的变化 ;-)

### 实验效果图

![Linux Lab Demo](/wp-content/uploads/2016/06/docker-qemu-linux-lab.jpg)

[1]: http://oss.lzu.edu.cn
[2]: http://tinylab.org/linux-0.11-lab
[3]: http://elinux.org/Work_on_Tiny_Linux_Kernel
[4]: https://github.com/tinyclub/linux-lab.git
[5]: http://tinylab.org/linux-lab
[6]: https://buildroot.org/
[7]: http://wiki.qemu.org/Main_Page
[8]: http://www.docker.com/
[9]: http://www.kernel.org
[10]: http://www.oldlinux.org
[11]: http://tinylab.org/tinylinux/
