---
title: Linux 系统启动速度优化概述
author: Wu Zhangjin
layout: post
permalink: /linux-system-boot-speedup-overview/
views:
  - 39
tags:
  - Linux
  - 启动速度
  - 优化
categories:
  - Linux
---

> By Falcon of [TinyLab.org][1]
> 2009/02/17


## 背景

Linux 世界精彩纷呈，因为它自由、开放，是众多牛人智慧碰撞的结晶。

虽然硬件在不断地更新换代，但是这本身并没有给系统的启动速度带来太大的变化，反而是这之外的创新带来了革命性的变化。就加速 Linux 启动这一块而言，就是日新月异，创新辈出，下面简要回顾一下人们的探索和创新过程，以及我们未来可以做的一些工作。

## 如何优化 Linux 启动速度

首先来看看 Linux 系统的大概启动过程，可以通过 `man boot` 查看到。

    $ man boot


大概列出来这么几部分：

  * Hardware-boot(BIOS)
  * OS Loader
  * Kernel Startup
  * init and inittab
  * Boot Scripts
  * Sequencing Directories
  * &#8230;

### 常规做法

为了能够加速 Linux 系统的启动，通常的做法是对这些步骤本身进行优化，比如：

  * 减少或者合并某些步骤
  * 对某些步骤内部进行优化

针对第一个，有人已经把 Linux 系统内置到了主板上（如 splashtop），这可以说是对前面三步的合并。而对于第二个办法，则有大量的例子，比如：

  1. 采用经过优化的专有（相对通用而言，比如Lilo, Grub)的 BIOS 和 BootLoader，比如 Lemote.com 公司采用的 [PMON 2000][2]。

  2. 至于内核启动过程的优化，则有大量的分析工具来跟踪内核的启动过程的函数调用图，找出可以优化的 hotspot，然后同样可以采用减少或者合并某些步骤以及对子步骤进行优化的措施来加速内核本身的启动。这类分析工具有 [KFT][3]（注：最新 mainline Linux 已经采用 Ftrace） 和 kgcov[5][4]。

  3. 在传统的 Linux 发行版上采用的是 init 这个进程管理工具，而在 Ubuntu 6.10 以后则采用了基于事件的 [upstart][5] 来加速进程启动过程，当然这也可以说是策略上的创新。类似地，Fedora 则采用了另外一套 systemd。

  4. 在启动 init 以后实际上就已经到了进程世界了，之后可能就需要通过脚本启动一序列的进程，这里可以做的优化包括把一些脚本替换为二进程程序（重写部分代码），然后通过诸如 bootchart 这样的工具来分析进程启动过程，然后对进程启动过程进行优化，同样可以采用上面提到的通常的做法。

  5. 对某些重要的进程运行进行优化，这种优化包括两个层面：第一个优化进程的内部启动过程，比如去掉某些不必要的初始化，另外一个是以进程使用过的内核系统调用作为入口，对内核进行优化，大概的做法是通过 [strace][6] 跟踪到进程运行过程中调用的系统调用，然后通过 KFT/Ftrace 与 Kgcov 对内核进行优化，类似的工具可能还有 gcov, gprof, [oprofile][7] 和 [LTT][8] 等。对于系统启动而言，这类初始化比较重要的程序当然是 X 系统和你所采用的桌面管理程序。

### 非常规化方法

这些通常的做法确实也有效地提高了内核的启动速度，但是并没有带来质的变化。根本原因在于这种优化的策略是面向过程的，面向某一个具体的对象的，一种更为革命的做法是采用系统化的抽象化方法，不直接面向过程，也不直接面向某个具体对象。而是统观全局，下面我们来介绍这样一种策略。

1. Kexec：复用初始化过程

    BIOS 与 Bootloader 也好，内核也好，启动的时候都需要对硬件进行扫描和初始化，但是对于某台组装好的机器来说，这些硬件是固定的，硬件信息也是固定，如果内核在第一次启动的时候就获取到了这些信息，并设法保存起来，这样下次启动时就可以忽略这样一个过程，从而加速以后的过程，采用这种方法的有 [kboot(kexec-bootloader)][6]。

2. STR：能耗换时间

    另外一种更极端的做法是，既然可以保存硬件的初始化信息，为什么不可以保存某次常用进程都运行的内存状态，在下次开机时直接进入该状态，而越过大量的进程启动过程呢？而这一类实现就是通过休眠/唤醒到内存（STR）来模拟关机/开机，某些 Android 手机厂商就是这么做。

    可以预想，如果能够有效结合这些策略，并通过不断创新，挖掘新的想法，系统的启动速度到时候将让我们无法预料。

更多的一些思路有在嵌入式 Linux 基金会的 Wiki 上做了详细介绍：[Boot Time][9] 和 [Boot up Time Reduction Howto][10]。

## 相关资料

  * [upstart][5]
  * [PMON 2000][2]
  * [KFT][3]
  * [Kgcov][4]
  * [bootchart][11]
  * [strace][6]
  * [kboot][12]
  * [LTT][8]
  * [Oprofile][7]
  * [Boot Time][9]
  * [Boot-up Time Reduction Howto][10]





 [1]: http://tinylab.org
 [2]: http://www.linux-mips.org/wiki/PMON_2000
 [3]: http://elinux.org/Kernel_Function_Trace
 [4]: http://ltp.sourceforge.net/coverage/gcov.php
 [5]: http://upstart.ubuntu.com/
 [6]: http://sourceforge.net/projects/strace/
 [7]: http://oprofile.sourceforge.net/about/
 [8]: http://en.wikipedia.org/wiki/Linux_Trace_Toolkit
 [9]: http://elinux.org/Boot_Time
 [10]: http://elinux.org/Boot-up_Time_Reduction_Howto
 [11]: http://www.bootchart.org/
 [12]: http://kboot.sourceforge.net/
