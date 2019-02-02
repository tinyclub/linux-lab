---
layout: post
author: 'Wang Chen'
title: "LWN 257541: 大容量内存系统的页框回收处理"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-257541/
description: "LWN 大容量内存系统的页框回收处理"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Page replacement for huge memory systems](https://lwn.net/Articles/257541/)
> 原创：By Jake Edge @ Nov. 7, 2007
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Shaowei Wang](https://github.com/shaoweiaaron)

> As the amount of RAM installed in systems grows, it would seem that memory pressure should reduce, but, much like salaries or hard disk space, usage grows to fill (or overflow) the available capacity. Operating systems have dealt with this problem for decades by using virtual memory and swapping, but techniques that work well with 4 gigabyte address spaces may not scale well to systems with 1 terabyte. That scalability problem is at the root of several different ideas for changing the kernel, from supporting [larger page sizes](http://lwn.net/Articles/250335/) to [avoiding memory fragmentation](https://lwn.net/Articles/224829/).

随着系统中内存（RAM）容量的增加，内存压力似乎应该会降低，但是，就像大家手里的薪水或者硬盘空间一样，可用量总是跟不上需求的增加。几十年来，操作系统通过使用虚拟内存和交换（swapping）技术来解决这个问题，但是同样的某些方法，当内存容量为 4GB 时运行良好，一旦系统扩展到 1TB 则又会显得捉襟见肘。从深层次上推动内核发生改变的几个问题中，对可扩展性（scalability）的支持一直位列其中，譬如 [支持更大的页](http://lwn.net/Articles/250335/) 和 [避免内存碎片](https://lwn.net/Articles/224829/)。

> Another approach to scaling up the memory management subsystem was recently posted to linux-kernel by Rik van Riel. His [patch](http://lwn.net/Articles/257223/) is meant to reduce the amount of time the kernel spends looking for a memory page to evict when it needs to load a new page. He lists two main deficiencies of the current page replacement algorithm. The first is that it sometimes evicts the wrong page; this cannot be eliminated, but its frequency might be reduced. The second is the heart of what he is trying to accomplish:

>     The kernel scans over pages that should not be evicted. On systems with a few GB of RAM, this can result in the VM using an annoying amount of CPU. On systems with >128GB of RAM, this can knock the system out for hours since excess CPU use is compounded with lock contention and other issues.

最近 Rik van Riel 针对内核内存管理子系统的扩展性问题提出了另一种改进的方法。他提交的 [补丁](http://lwn.net/Articles/257223/) 可用于在执行页框回收处理中减少搜索换出页的时间。他列出了当前页框回收（本文称之为 page replacement，译者注，在 Linux 中还有类似的另一种说法称之为 “页框回收”（Page Frame Reclaiming），本文翻译时采用后一种说法）算法的两个主要缺陷。首先，它有时会换出错误的页；很可惜这是不可避免的（译者注，换出页的选择基于预期，而预期总是不确定的），但可能性或许还可以降低。第二个缺陷则正是他所想要改进的问题，他在补丁中的描述如下：

    内核会扫描那些不会被换出的内存页。在具有几 GB 内存的系统上，这可能导致虚拟内存子系统产生额外的计算开销。在一个具有大于 128GB 内存的系统上，由于锁的竞争以及综合了其他问题所导致的过多处理器开销，甚至可能会使系统停顿达数小时之久。

> A system with 1TB of 4K pages has 256 million pages to deal with. Searching through the pages stored on lists in the kernel can take an enormous amount of time. According to van Riel, most of that time is spent searching pages that won't be evicted anyway, so in order to deal with systems of that size, the search needs to focus in on likely candidates.

一个装机容量为 1TB 内存的系统（按每个页框 4KB 大小）计算，需要涉及高达 2 亿 5 千 6 百万个页框。对管理这些页框的内核链表进行搜索会花费大量时间。根据 van Riel 的说法，大部分时间浪费在遍历无论如何都不会被换出的页框上，因此为了处理像这样的大规模系统，搜索算法需要改进为只关注那些会被换出的页框。

> Linux tries to optimize its use of physical memory, by keeping it full, using any memory not needed by processes for caching file data in the page cache. Determining which pages are not being used by processes and striking a balance between the page cache and process memory is the job of the page replacement algorithm. It is that algorithm that van Riel would eventually like to see replaced.

Linux 尽其所能优化其对物理内存的使用，采用的方法是尽可能地将进程不使用的内存用于缓存文件的数据。页框回收算法的主要工作就是确定哪些页框未被进程所使用并确保页缓存和进程所使用的内存数量之间的平衡。而 van Riel 最终希望改进的就是这个算法。

> The current set of patches, though, take a smaller step. In today's kernel, there are two lists of pages, active and inactive, for each memory zone. Pages move between them based on how recently they were used. When it is time to find a page to evict, the kernel searches the inactive list for candidates. In many cases, it is looking for page cache pages, particularly those that are unmodified and can simply be dropped, but has to wade through an enormous number of process-memory pages to find them.

目前的补丁改动还是相对保守的。当前内核为每个内存域（zone）维护了两个页框链表，一个是 “活动”（“active”）链表，另一个是 “不活动”（“inactive”）链表。所有的页框根据它们最近一段时间内使用的频度在这两个链表之间切换。当需要寻找被换出的页框时，内核会在 inactive list 中搜索。大部分情况，搜索的目标是那些用于页缓存（page cache）的页框，特别是那些页框上数据还未经修改从而可以被简单地回收的页框，但在搜索过程中不可避免地会遍历到大量的进程内存页。

> The solution proposed is to break both lists apart, based on the type of page. Page cache pages (aka file pages) and process-memory pages (aka anonymous pages) will each live on their own active and inactive lists. When the kernel is looking for a specific type, it can choose the proper list to reduce the amount of time spent searching considerably.

建议的解决方案是根据页框上保存数据的类型对两个链表进行分拆。页缓存中的页框（也称为 file page，译者注，即缓存了文件内容的页框，下文直接采用 cache page 表示，不再翻译）和进程内存页（也称为匿名页，即 anonymous page，译者注，下文直接使用不再翻译）将分别拥有自己的 active  list 和 inactive list。当内核在寻找特定类型的页框时，它可以选择正确的链表从而可以大量减少搜索所花费的时间。

> This patch is an update to an earlier proposal by van Riel, [covered here last March](http://lwn.net/Articles/226756/). The patch is now broken into ten parts, allowing for easier reviewing. It has also been updated to the latest kernel, modified to work with various features (like [lumpy reclaim](http://lwn.net/Articles/211505/)) that have been added in the interim.

当前补丁是 van Riel 先前提案的更新，先前的提案已于 [同年三月报道过](/lwn-226756)。该补丁现在分为十个部分，便于查看。它也已经同步到最新的内核，并针对各种新特性（如 [lumpy reclaim](/lwn-211505/)）做了相应的适配修改。

> Additional features are planned to be added down the road, as outlined on van Riel's [page replacement design web page](http://linux-mm.org/PageReplacementDesign). Adding a non-reclaimable list for pages that are locked to physical memory with `mlock()`, or are part of a RAM filesystem and cannot be evicted, is one of the first changes listed. It makes little sense to scan past these pages.

正如 van Riel 在 [页框回收设计网页](http://linux-mm.org/PageReplacementDesign) 上所描述的那样，他计划在未来添加如下其他功能。首批计划中的一个是：增加一个 “不可回收”（“non-reclaimable”）链表管理那些因为调用 `mlock()` 而被锁定的物理内存页框，以及那些存放了内存文件系统的内容而不可以被换出的页框。对这些页框进行扫描是毫无意义的。

> Another feature that van Riel lists is to track recently evicted pages so that, if they get loaded again, the system can reduce the likelihood of another eviction. This should help keep pages in the page cache that get accessed somewhat infrequently, but are not completely unused. There are also various ideas about limiting the sizes of the active and inactive lists to put a bound on worst-case scenarios. van Riel's plans also include making better decisions about when to run the out-of-memory (OOM) killer as well as making it faster to choose its victim.

van Riel 所列出的另一个功能是增加对最近被换出的页框的跟踪，这样，如果它们被再次换入，系统可以选择减少将其再次换出的可能性。这么做的好处是有助于将那些不经常被访问，但也不是完全无用的页框尽量保持在页缓存中。另外他对在最恶劣条件下限制 active list 和 inactive list 的方案也有所考虑。van Riel 的计划中甚至还包括如何决策何时运行内存不足清理（out-of-memory (简称 OOM) killer）以及如何以更快的速度选择被清理（杀死）的进程。

> Overall, it is a big change to how the page replacement code works today, which is why it will be broken up into smaller chunks. By making changes that add incremental improvements, and getting them into the hands of developers and testers, the hope is that the bugs can be shaken out more easily. Before that can happen, though, this set of patches must pass muster with the kernel hackers and be merged. The external user-visible impacts of these particular patches should be small, but they are fairly intrusive, touching a fair amount of code. In addition, memory management patches tend to have a tough path into the kernel.

总的来说，这次改动对于目前的页框回收逻辑影响很大，这也是为什么要将整个修改分解成更小的补丁进行提交的原因。通过这种增量的改进方式将修改提交给开发人员（试用）和测试人员（测试），其目的是希望可以更容易地发现并消除其中的隐患。然而，在此之前（指前述提交给开发和测试人员之前），这套补丁必须通过内核专家的审核才可以被合入。这个补丁修改虽然在使用上对外部用户的影响应该很小，但在内部涉及的地方很多，导致修改的代码数量也很多。此外，对内存管理方面进行修改的补丁要想被合入主线一直也不是一件容易的事情。

[1]: http://tinylab.org
