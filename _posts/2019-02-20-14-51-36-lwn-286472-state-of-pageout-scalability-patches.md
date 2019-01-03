---
layout: post
author: 'Wang Chen'
title: "LWN 286472: 页框回收处理中着眼于可扩展性能（scalability）改进的最新介绍"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-286472/
description: "LWN 页框回收处理中着眼于可扩展性能改进的最新介绍"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[The state of the pageout scalability patches](https://lwn.net/Articles/286472/)
> 原创：By corbet @ Jun. 17, 2008
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Fan Xin](https://github.com/fan-xin)

> The virtual memory scalability improvement patch set overseen by Rik van Riel has been under construction for well over a year; LWN [last looked at it](http://lwn.net/Articles/257541/) in November, 2007. Since then, a number of new features have been added and the patch set, as a whole, has gotten closer to the point where it can be considered for mainline inclusion. So another look would appear to be in order.

由 Rik van Riel 负责的有关虚拟内存可扩展性（scalability）改进补丁集（译者注，下文简称为 VM scalability 补丁集）已经开发了有一年多了；LWN 曾经在 2007 年 11 月给大家做过 [介绍](/lwn-257541)。从那以后，补丁集中又添加了许多新的功能，整个补丁集已经接近完成，可以考虑合入主线。所以在此有必要再给大家更新一下其最新状态。（译者注，该补丁集最终随 2.6.28 合入内核主线。更详细的补丁提交信息可以参考 [这里](https://kernelnewbies.org/Linux_2_6_28#Memory_management_Scalability_improvements)。）

> One of the core changes in this patch set remains the same: it still separates the least-recently-used (LRU) lists for pages backed up by files and those backed up by swap. When memory gets tight, it is generally preferable to evict page cache pages (those backed up by files) rather than anonymous memory. File-backed pages are less likely to need to be written back to disk and they are more likely to be well laid-out on disk, making it quicker to read them back in if necessary. Current Linux kernels keep both types of pages on the same LRU list, though, forcing the pageout code to scan over (potentially large numbers of) pages which it is not interested in evicting. Rik's patch improves this situation by splitting the LRU list in two, allowing the pageout code to only look at pages which might actually be candidates for eviction.

该补丁集的核心改动依然保持不变：原本的 “最近最少使用（least-recently-used，简称 LRU）” 链表根据处理的页框类型的不同，拆分为两组链表，一组链表上的页框是用于缓存文件内容，回收前（如果被修改）会换出（写回）文件，另一组链表上的页框存放进程数据，回收前换出到 swap 区（译者注，严格地说，原本每个 zone 中只有 active 和 inactive 两个链表，每个链表上存放的页框不区分类型，拆分后，页框根据存放数据类型不同分为 `LRU_ANON` 和 `LRU_FILE`，每种类型的页框再根据其是否 active 分别存放在 `LRU_INACTIVE_ANON`、`LRU_ACTIVE_ANON`、`LRU_INACTIVE_FILE` 和 `LRU_ACTIVE_FILE` 四个 LRU 链表上。具体代码参考 2.6.28 版本 `mmzone.h` 文件中的 [`lru_list` 枚举定义](https://elixir.bootlin.com/linux/v2.6.28/source/include/linux/mmzone.h#L133) 和 [`struct zone` 中的 `lru` 成员](https://elixir.bootlin.com/linux/v2.6.28/source/include/linux/mmzone.h#L313)）。当内存变得紧张时，通常优先换出 “页缓存中的页框”（那些备份了文件内容的页框，译者注，本文简称之为 cache page，不再翻译）而不是 “匿名内存中的页框”（译者注，本文简称之为 anonymous page，不再翻译。之所以不倾向于换出 anonymous page，是因为对于 anonymous page，总是需要先被写入 swap 分区才能被换出）。cache page 所缓存的文件内容不太可能需要写回磁盘，并且由于文件内容在磁盘上布局良好，必要时将其恢复回内存的速度也很快。然而，当前的 Linux 内核将这两种类型的页框维护在同一条 LRU 链表中，这导致页框回收算法不得不扫描那些我们并不倾向于换出的页框（而且这样的页框数量有可能还非常多）。Rik 的补丁通过将原本的 LRU 链表分成两条链表来改善这种情况，允许页框回收算法仅查看那些实际有可能被换出的候选页框。

> There comes a point, though, where anonymous pages need to be reclaimed as well. The kernel will make an effort to pick the best pages to evict by going for those which have not been recently referenced. Doing that, however, requires going through the entire list of anonymous pages, clearing the "referenced" bit on each. A large system can have many millions of anonymous pages; iterating over the entire set can take a long time. And, as it turns out, it's not really necessary.

需要指出的是，有时候也会需要回收 anonymous page。内核将尽可能地选择那些最近未被引用的页来换出。但是，这样做需要遍历链表中所有的 anonymous page，并清除每个页上的 “引用”（“referenced”） 标记位。一个大型的系统中可能存在有数百万个 anonymous page；遍历整个集合可能需要很长时间。但我们发现，并不是非这样做不可。

> The VM scalability patch set now changes that behavior by simply keeping a certain percentage of the system's anonymous pages on the inactive list - the first place the system looks for pages to evict. Those pages will drift toward the front of the list over time, but will be returned to the active list if they are used. Essentially, this patch is applying a form of the "referenced" test to a portion of anonymous memory - whether or not anonymous pages are being evicted at the time - rather than trying to check the referenced state of all anonymous pages when the kernel decides it needs to reclaim some of them.

VM scalability 补丁集采取的处理方式很简单，考虑到回收处理中内核优先搜索 inactive list 并从中挑选换出页，所以要做的就是确保 anonymous page 的 inactive list 上页框的数量不要太多，并为具体的数量设定了一个标准，规定不得超过 anonymous page 总量的一个百分比值。这些页框随着时间的推移会逐渐向链表头部移动（译者注，FIFO 形式），一旦被访问，则又被添加回 active list。本质上来说，补丁采用的方法是：只对匿名内存的一部分检测其 “是否被引用”（无论这些 anonymous page 是否正在被换出），而不是在内核发现需要回收时对所有的 anonymous page 的引用状态进行检查。（译者注，具体修改可以参考 [commit: vmscan: second chance replacement for anonymous pages](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=556adecba110bf5f1db6c6b56416cfab5bcab698)。）

> Another set of patches addresses a different situation: pages which cannot be evicted at all. These pages might have been locked into memory with a system call like `mlock()`, be part of a locked SYSV shared memory region, or be part of a RAM disk, for example. They can be either page cache or anonymous pages. Either way, there is little point in having the reclaim code scan them, since it will not be possible to evict them. But, of course, the current reclaim code does have to scan over these pages.

补丁集中的另一组改动针对的是另一个场景：即对那些不能被换出的页框的处理。某些页框可能被诸如 `mlock()` 这样的系统调用锁定，或者是作为 SYSV 共享内存区的一部分而被锁定，亦或者是作为 RAM 磁盘的一部分而无法被换出。它们可以是 cache page 或者是 anonymous page。无论哪种方式，在回收代码中扫描它们都没什么意义，因为它们不可能被换出。但是，当前的回收代码却并不对该场景进行区分。

> This unneeded scanning, as it turns out, can be a problem. The extensive [unevictable LRU document](https://lwn.net/Articles/286485/) included with the patch claims:

>     For example, a non-numal x86_64 platform with 128GB of main memory will have over 32 million 4k pages in a single zone. When a large fraction of these pages are not evictable for any reason [see below], vmscan will spend a lot of time scanning the LRU lists looking for the small fraction of pages that are evictable. This can result in a situation where all cpus are spending 100% of their time in vmscan for hours or days on end, with the system completely unresponsive.

显而易见，这种不必要的扫描是一个问题。补丁中所包含的 [关于不可换出（unevictable） LRU 的说明文档](https://lwn.net/Articles/286485/) 解释得非常详细，摘录一段如下：：

    举例来说，一个拥有 128GB 主存的 non-numal x86_64 系统将在单个域（zone）中拥有超过 3 千 2 百万个 4K 大小的页框。如果这些页框中的很大一部分由于某种原因无法被换出，vmscan 将不得不为寻找那一小部分可以换出的页框而花费大量的时间扫描整个 LRU。这可能导致所有的处理器在 vmscan 中花费 100% 的时间并长达数小时乃至数天，结果就是整个系统看上去就像完全没有反应的样子。

> Most of us are not currently working with systems of this size; one must spend a fair amount of money to gain the benefits of this sort of pathological behavior. Still, it seems like something which is worth fixing.

虽然我们中的大多数人目前还暂时不太可能接触到这种规模的系统；要知道为了装备这样的机器我们需要花费相当多的钱，但结果却可能碰上这种令人沮丧的现象。但无论如何，这看上去是一个值得修复的问题。

> The solution, of course, is yet another list. When a page is determined to be unevictable, that page will go onto the special, per-zone unevictable list, after which the pageout code will simply not see it anymore. As a result of the variety of ways in which a page can become unevictable, the kernel will not always know at mapping time whether a specific page can go onto the unevictable list or not. So the pageout code must keep an eye out for those pages as it scans for reclaim candidates and shunt them over to the unevictable list as they are found. In relatively short order, the locked-down pages will accumulate in this list, freeing the pageout code to concentrate on pages it can actually do something about.

解决的方法仍然是新增加了一个链表。当一个页框被确定为不可换出时，会被加入一个特殊的 “不可换出链表（unevictable list，译者注，下文直接使用不再翻译）”，这个链表每个域（zone）一个，执行换页扫描时将忽略该链表。由于导致页框变得不可换出的途径很多，内核并不总是能在映射（mapping，译者注，这里的映射应该指的是为进程创建页表的操作）的时候判断出是否可以将一个页框移入 unevictable list。因此，kswapd 任务（pageout code）必须密切关注这些页框，并在扫描回收候选项时将它们挑选出来移到 unevictable list 中。锁定的页框很快就会被收纳在此链表中，这样页框回收逻辑就可以专注于那些可换出的页框了。

> Many of the concerns which have been raised about this patch set over the last year have been addressed. A few remain, though. Some of the new features require new page flags; these flags are in extremely short supply, so there is always pressure to find ways of implementing things which do not allocate more of them. There are a few too many configuration options and associated `#ifdef` blocks. And so on. Addressing these may take a while, but convincing everybody that these (rather fundamental) memory management changes are beneficial under all circumstances may take rather longer. So, while this patch set is making progress, a 2.6.27 merge is probably not in the cards.

自去年以来，社区针对这个补丁提出了许多建议，大部分都已经解决。但还剩一些需要继续改进。譬如，部分新功能的实现需要增加一些新的页标记（page flags）；考虑到标记位数目实在有限，因此设计上总是需要不停地寻找优化的方法以尽量避免使用过多的标记位。另外配置选项有点多，导致代码中存在不少用条件编译 `#ifdef` 括起来的代码块。解决以上这些问题还需要一点时间，更何况要让所有人都相信这些（相当基本的）内存管理修改在所有运行条件下都能表现良好，所需要的时间恐怕会更长。因此，虽然这个补丁集正在取得进展，但要想在 2.6.27 版本中被合入估计还不太可能（译者注，该补丁集最终随 2.6.28 合入内核主线）。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: http://tinylab.org
