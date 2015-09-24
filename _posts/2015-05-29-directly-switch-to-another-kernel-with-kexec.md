---
title: 用 Kexec 快速切换当前 Linux 内核
author: Wu Zhangjin
layout: post
permalink: /directly-switch-to-another-kernel-with-kexec/
views:
  - 38
tags:
  - bootloader
  - Kexec
  - Linux
categories:
  - Linux
---

> By Falcon of [TinyLab.org][1]
> 2008/11/02


## 什么是 kexec

今天在 linuxsir.org 上转悠，突然看到这个东西，感觉很有意思，就找了一些资料（实际上我应该早点看内核源代码里头的.txt文档，不过至今没有这个习惯）。

> kexec is a set of systems call that allows you to load another kernel from the currently executing Linux kernel.

这个东西对普通用户来说就对应到内核（2.6.13 或以上）中的一个 kexec 工具，比如在 Debian 下只要把 kexec-tools 安装上 ok 了。我们可以用这个工具来启动一个新内核，那它跟普通的 bootloader 有什么区别呢？

> kexec performs the function of the boot loader from within the kernel. The primary difference between a standard system boot and a kexec boot is that the hardware initialization normally performed by the BIOS or firmware (depending on architecture) is not performed during a kexec boot. This has the effect of reducing the time required for a reboot.

看到好处了吧，kexec is a timesaver~ 有兴趣马上试试了，那就看看前两个参考资料先。

## Kexec 有哪些用处

莫止于此，我还有几个想法：

1. 基于 kexec 来实现 Linux 休眠。

    休眠是一种电源管理的方式，它基本的内容就是把设备和 CPU 的状态保存到内存里面去，然后再把内核里面内存的内容存到磁盘里，然后就关机，或者是待机的状态，这样来达到省电的目的。等到重启之后再把相应的内容恢复回来。

    Linux 电源管理一直是个大家关注的话题，特别是在笔记本方面，所以 Intel, Loongson（有学弟在那边做这个工作）等都有在做这一块。Kexec 的工作原理跟休眠似乎有一定的契合，正是这样，来自英特尔科研技术中心上海的黄瀛（老师）才有[资料][2]一文，至于具体怎么用 Kexec 来实现休眠，有时间看看该文的细节去吧。

2. 基于 Kexec 进行远程系统维护。

    如果要维护远程服务器，冷启动（直接启动硬件）是很麻烦的，如果能够直接利用 Kexec 在当前状态下快速地把老内核替换成加入安全补丁的新编译对服务器维护人员来说应该是一个非常大的帮助。不过，如果在新内核启动过程中就崩溃掉，Kexec 似乎是没有办法的，它还能够回退到老内核去吗？（可以研究一下）。如果在内核中加入一个选项，指定系统启动过程中崩溃以后能够自动切换到一个正常的内核就好了，也就是在 panic 的时候，自动重启并加载另外一个正常的内核，或者是通过它下一层的 boot loader来实现。关于这部分，你可以参考一下[资料][3]，当然，也建议你看看我之前写的一篇[文档][4]。

3. Kexec会不会成为内核开发人员的一个强大工具呢？

    对于内核开发人员来说，要不停地修改源代码，并进行测试，这样就不可避免地要测试加入新代码的内核，要不停地重启内核。最早的时候，大家可能都必须不停地重启硬件（冷启动），等待硬件初始化，浪费很多时间；现在大家可以用各种各样的虚拟机（比如 Qemu, UML, KVM 等）来做测试，不过使用虚拟机也会有很多问题，比如内核加载速度较慢、虚拟机支持的硬件有限等。是不是可以考虑在辅助内核开发方面增强 Kexec 的功能呢？让它加速内核开发人员的开发进程。

    当然，这个也可能成为嵌入式工程师的强大工具，嵌入式开发人员可以方便地调整内核配置，添加补丁等来适应嵌入式系统开发的需要，而无须频繁重启开发板。

4. 增强 Linux 在 Safety 领域的应用

    Safety 是软件安全、工业控制等领域的一个相当热门的话题。在一些重要的领域，如何保障系统的安全而不至于产生较大的经济、环境、人员等灾难性的后果，是大家一直在探讨和研究的问题。系统的容错性跟系统安全非常相关，如果系统容错性好，系统就可能不至于因为内核或者是其他某一部分“出错”而导致整个系统“崩溃”（这里的崩溃可能是系统停止工作也可能是系统工作异常），而且避免由此带来的灾难性后果。

    Kexec 提供的 `-p` 选项能够在系统崩溃时自动切换到一个正常的系统，这为 Linux 提供了一种在最坏情况下（崩溃）的自我“纠错”机制，而且这种切换比普通的重启要节省很多时间，如果这个时间能够有效限制在对系统正常工作基本不产生影响的时间内，那么将能够作为 Linux 容错技术的一个重要手段，而且这个手段是操作系统层面的，对 Safety 领域来说可能是一个非常大的贡献，除此之外，其他的 RT OS 也甚至可以借鉴 Kexec 的思想，实现某种程度上的系统自我恢复功能，以便提供更好的容错性，不过那些基于 Linux 的 RT OS 在这方面应该会有先天性的优势，因为它们应该更易于移植 Kexec。

还有其他想法么？总之 Kexec 还是有必要去了解一下的。

## 参考资料

  * [用 kexec 迅速切换内核][5]
  * [Reboot Linux faster using kexec][6]
  * [利用 Linux 提升休眠复活技术][2]
  * [内核文档翻译-Linux内核崩溃转储机制][3]
  * [如何更新远程主机上的linux内核][4]





 [1]: http://tinylab.org
 [2]: http://soft.chinabyte.com/30/7818030.shtml
 [3]: http://blog.chinaunix.net/uid-20228521-id-1971053.html
 [4]: /how-to-update-the-linux-kernel-of-a-remote-machine
 [5]: http://www.linuxsir.org/bbs/thread335331.html
 [6]: http://www.ibm.com/developerworks/cn/linux/l-kexec/
