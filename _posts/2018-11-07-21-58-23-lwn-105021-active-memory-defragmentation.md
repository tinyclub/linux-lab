---
layout: post
author: 'Zhao Yimin'
title: "LWN 105021: 主动内存碎片整理"
album: 'LWN 中文翻译'
group: 'translation'
license: "cc-by-sa-4.0"
permalink: /lwn-105021/
description: "LWN 文章翻译: 主动内存碎片整理 "
plugin: mermaid
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Active memory defragmentation](https://lwn.net/Articles/105021/)
> 原创：By corbet @ Oct. 5, 2004
> 翻译：By [Tacinight](https://github.com/tacinight)
> 校对：By [Bennnyzhao](https://github.com/Bennnyzhao) & [unicornx](https://github.com/unicornx)

> "High order" allocations, in the kernel, are attempts to obtain multiple, contiguous pages for an application which needs more than one page in a single, physically-contiguous block. These allocations have always been a problem for the kernel to satisfy; once the system has been running for a while, physical memory is usually fragmented to the point that very few groups of adjacent, free pages exist. Last month, this page looked at [Nick Piggin's kswapd changes](https://lwn.net/Articles/101230/) which attempt to mitigate this problem somewhat. There are other people working in this area, however.

在内核中，“高阶” 内存分配指的是，指的是当一个应用需要大于一个页框的连续物理内存块时内核能够为其提供多个连续的页框的功能。但是内核往往难以满足这样的分配请求；系统在运行了一段时间之后，物理内存往往散乱到很少存在连续空闲的页框。上个月，本文的作者还给大家介绍了 [Nick Piggin 的 kswapd 补丁][2]，该补丁也试图缓解内存的碎片问题。当然也还有很多人专注于这一领域尝试着解决问题。

> One of those is Marcelo Tosatti, who posted [a patch](https://lwn.net/Articles/104843/) which adds active memory defragmentation to the kernel. At a high level, the algorithm used is relatively simple: to obtain free blocks of order N, start with the largest, smaller blocks you can find, and try to relocate the contents of the pages immediately before and after the block. If enough pages can be moved, a larger block of free pages will have been created.

其中一个就是 Marcelo Tosatti，他向内核中提交了一个动态内存碎片整理的[补丁][3]。在抽象层面上，他所给的算法也相当直接易懂：为了获得阶数为 N 的连续内存块，先从你能找到的小于 N 的最大阶数的内存块开始，试图去为该内存块前后非空的页框重定位，如果移走了足够数量的页框，那么一个更大的连续内存块就创建完成了。

> Naturally, this process seems rather more complicated when looked at closely. Not all pages can be relocated; those which are locked or reserved, for example, are not touchable. The patch also declines to work with pages which are currently under writeback; until the writeback I/O completes, those pages must not move. A number of more complicated cases, such as moving pages which are part of a nonlinear mapping, are not handled with the current patch.

可是，一旦仔细研究起来会发现这比初看上去要复杂得多。首先，并不是所有的页都可以重定位，比如那些被锁定或者预留的页就不能被移动。其次，这个补丁也不能很好的和页框的写回机制共处，因为这些页必须等到 I/O 回写操作完成才能被移动。还有一系列更复杂的情况，这个补丁也无法去处理，例如移动被非线性映射的页框。

> If a page does appear to be relocatable, it must first be locked and have its contents copied to the new page. Then all page tables which reference the old page must be re-pointed to the new page. Reverse mapping information, if any, must be set correctly. If there is a copy of the page in swap, that copy must be connected with the new page. And so on. Marcelo's patch responds to many of the more complicated cases by simply refusing to move the page. Even so, Marcelo reports good results in creating large, contiguous blocks of free memory.

如果一个页框满足了重定位的条件，他还必须先锁定，等待他将内容拷贝到新的页框中。然后页表中所有指向旧页框的要重新指向新的页框。如果有反向映射信息的也要一一设置正确。在 swap 分区中的副本也要正确关联到新的页框。等等。对很多复杂情形在 Marcelo 的补丁中只是简单的不去处理。即使如此，Marcelo 的报告中给出，这个补丁在创建大的连续页内存块方面取得了不错的效果。

> Of course, there are a few glitches, including problems on SMP systems. But, says Marcelo, never fear:

当然也还有一些小毛病，包括在 SMP 系统上的一些不足，但是 Marcelo 的回应显得毫无畏惧：

>     But it works fine on UP (for a few minutes :)), and easily creates large physically contiguous areas of memory.

    “他在单核机器上正常的运转了（尽管只是几分钟 ：）），并且可以轻易的创建出大范围物理连续的内存空间”

> It was pointed out that this patch has some common features with a different effort: the drive to support hotpluggable memory. When memory is to be removed from the system, all pages currently stored in that memory must be relocated. In essence, the hotplug memory patches seek to create a large block of free memory which happens to cover a specific set of physical addresses.

他的补丁也被指出和一些其他的工作有所相似，例如用于来支持热拔插内存。当内存要被移除系统时，相应内存区域上的页框必须要被移动到其他地方。本质上说，热拔插内存补丁试图创建一块大的内存区域，而这区域刚好包括了实体内存相应的物理地址。

> Dave Hansen [described](https://lwn.net/Articles/105023/) two patches adding hotplug memory support - one done at IBM, and one from Fujitsu. Each apparently has its strong and weak points.

Dave Hansen [介绍了][4] 两个用于添加内存热拔插支持的补丁，一个来自于 IBM，另一个则是 Fujitsu 提供的。两个补丁各有优缺点。

> Between Marcelo's work and the hotplug patches, there is a significant amount of experience in moving pages aside to free blocks of memory. An effort to bring together those patches into a single one containing the best of each will probably be necessary before any can be merged. But the end result of that work could be an end to problems with high-order allocations.

在 Marcelo 的工作以及热拔插补丁中，都有大量关于移动页框用以释放成块内存的经验总结。在合并任一补丁前，有必要做些工作将这些补丁中最好的部分提取成一个最佳的方案。这些成果最终可能将为高阶内存分配问题画上一个完美的句号。

[1]: http://tinylab.org
[2]: /lwn-101230
[3]: https://lwn.net/Articles/104843/
[4]: https://lwn.net/Articles/105023/
