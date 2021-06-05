---
layout: post
author: 'Wang Chen'
title: "LWN 591998: 内存规整（memory compaction）所存在的问题"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-591998/
description: "LWN 文章翻译，内存规整（memory compaction）所存在的问题"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Memory compaction issues](https://lwn.net/Articles/591998/)
> 原创：By corbet @ Mar. 26, 2014
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Anle Huang](https://github.com/hal0936)

> Memory compaction is the process of relocating active pages in memory in order to create larger, physically contiguous regions — memory defragmentation, in other words. It is useful in a number of ways, not the least of which is making huge pages available. But compaction apparently has some problems of its own; Vlastimil Babka led a brief session in the 2014 Linux Storage, Filesystem, and Memory Management Summit to explore the issue.

内存规整（Memory compaction）通过将已分配的内存页框上的内容重新移动到别的地方来创建更大的在物理上连续的内存区域，换句话说，就是实现类似内存碎片整理的功能。它在很多方面都非常有用，其中最重要的还是用于支持实现分配 “巨页”（huge pages）。但内存规整功能还存在一些问题；Vlastimil Babka 在 2014 年度的 Linux 存储，文件系统和内存管理峰会（Linux Storage, Filesystem, and Memory Management Summit，简称 LSFMM）上主持了一个简短的会议，以探讨该问题。

> After Vlastimil gave a quick overview of how compaction works (also described in [this article](https://lwn.net/Articles/368869/)) and described problems related to compaction overhead, Rik van Riel made the claim that there are two core issues to be looked at in this area: (1) can the compaction code be made to be faster, and (2) when compaction appears to be too expensive, should it just be skipped?

会议中，首先由 Vlastimil 快速概述了内存规整的实现原理（也可参考[这篇文章介绍][2]）并描述了内存规整算法的开销问题，然后 Rik van Riel 做了一个总结，他认为在这个议题上存在两个核心的问题有待解决：（1）是否可以改进规整算法，使其更快，（2）当预期规整处理过于费时的时候，是否可以简单地跳过（忽略）规整处理？

> It seems that a number of compaction bugs have been fixed over the years, but some clearly remain. How, it was asked, can they be made easier to find? Writing test programs that reveal compaction problems tends to be hard; these problems arise out of specific workloads that exercise the system in certain ways. There does not appear to be any easy way to abstract the problematic access patterns out of the workloads into separate test programs.

多年来（译者注，自内存规整算法合入内核主线（2.6.35）到本文发表已经有三年多的时间了）内核已经针对内存规整修复了不少故障，但有些问题依然存在。会上有人询问，是否有更方便的方法定位这些故障？这些问题依赖于特定系统，特定操作环境和负载下才会出现，所以要想编写一些能够帮助发现问题的测试程序往往很困难。暂时还没有找到简单的方法可以从各种问题中总结出一定的规律来编写有针对性的测试程序。

> What that means is that the memory management developers don't really have a good understanding of why compaction problems are happening. Some workloads obviously create situations where compaction gets expensive, but how that happens is obscure. So there is clearly a need to gain a better understanding of how the problems come about. One step in that direction might be to add a new counter that is incremented anytime the kernel detects that it has spent a significant amount of time in the compaction code. If that counter starts to increase, that will be a signal that bugs in the compaction code are being tickled. Then, perhaps, it will be possible to try to figure out where those bugs are.

这意味着内存管理子系统的开发人员还没有真正理解为什么这些问题会发生。在有些工作负载下非常明显地会看到规整的计算开销特别地高，但具体的原因还不清楚。所以，很显然我们还需要更深入地理解问题究竟是如何产生的。为了这个目的，初步的建议是添加一个新的计数器，一旦内核检测到它在规整代码中花费了大量时间，则对该计数器的值加一。如果我们发现该计数器的值开始增加，则表明规整代码中有潜在的错误正在被触发。这样也许有助于我们找出那些错误的位置。

[1]: http://tinylab.org
[2]: /lwn-368869

