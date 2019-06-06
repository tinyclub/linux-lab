---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 433904: 一个 “组调度（group scheduling）” 的运行实例"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-433904/
description: "LWN 文章翻译，一个 “组调度” 的运行实例"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - schedule
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[A group scheduling demonstration](https://lwn.net/Articles/433904/)
> 原创：By Jonathan Corbet @ Mar. 16, 2011
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Xiaojie Yuan](https://github.com/llseek)

> There has been much talk of the per-session group scheduling patch which is part of the 2.6.38 kernel, but it can be hard to see that code in action if one isn't doing a 20-process kernel build at the time. Recently, your editor inadvertently got a demonstration of group scheduling thanks to some unexpected results from a Rawhide system upgrade. The way the scheduler works was clearly shown in a way that could be captured at the time.

“基于会话（session）的组调度“ 这个补丁自从随 2.6.38 版本被合入内核后已经引发了不少的讨论，但如果你还没有真正尝试过诸如同时运行二十个进程来编译内核这样的工作，那么你是很难体会到这个补丁所带来的实际效果的。最近，在执行 Rawhide 系统升级的过程中（Rawhide 是 Fedora 的一个开发版本的代号。具体参考 [Rawhide 的 wiki 介绍][1]），我无意中见识到了组调度所展现的魅力。调度器触发了该项功能并且其现场也被我清晰地记录了下来。

> Rawhide users know that surprises often lurk behind the harmless-looking `yum upgrade` command. In this particular case, something in the upgrade (related to fonts, possibly) caused every graphical process in the system to decide that it was time to do some heavy processing. The result can be seen in this output from the `top` command:

只要你是 Rawhide 的用户，应该了解那个看似简单的 `yum upgrade` 命令执行后可能会给我们带来的 “惊喜”。在我碰到的这次升级事件中，某些升级的内容（可能与字体有关）导致系统中的每个和图形显示有关的进程都开始变得忙碌起来。通过运行 `top` 命令看到了如下的输出结果：

![](https://static.lwn.net/images/2011/group-sched-top.png)

> The per-session heuristic had put most of the offending processes into a single control group, with the effect that they were mostly competing against each other for CPU time. These processes are, in the capture above, each currently getting 5.3% of the available CPU time. Two processes which were not in that control group were left essentially competing for the second core in the system; they each got 46%. The system had a load average of almost 22, and the desktop was entirely unresponsive. But it was possible to log into the system over the net and investigate the situation without really even noticing the load.

基于会话对任务尝试进行分组的方法将大多数受到升级影响的进程都加入到同一个控制组（control group）中（译者注，因为这些和图形终端有关的进程都属于当前登录会话），使得它们在一个组内相互竞争处理器时间。在上面的截屏快照中，我们可以看到这些进程各分得了可用处理器时间的 5.3%（译者注，看上去 cobert 的这台机器上有两个处理器 core，和登录会话相关的进程所在的组使用了其中的一个 core）。不在该控制组中的两个进程被分配到系统中的另个一 core 上并竞争该处理器；每个得到该处理器时间的 46%。系统的平均负载接近 22（译者注，指长时间运行下系统总进程数的平均值），此时桌面几乎完全没有响应。但是我们仍然可以通过网络方式登录系统并查看系统的运行状态，而不会受到其他繁忙运行的任务的影响。

> This isolation is one of the nicest features of group scheduling; even when a large number of processes go totally insane, their ability to ruin life for other tasks on the machine is limited. That, alone, justifies the cost of this feature.

这种对任务的隔离功能是 “组调度” 所能够提供的最好特性之一；即使系统中存在大量疯狂运行的进程，它们也不会过多地干扰机器上其他任务的正常运行。仅此一点就证明了 “组调度” 这个特性自身的价值。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://fedoraproject.org/wiki/Releases/Rawhide/zh-cn
