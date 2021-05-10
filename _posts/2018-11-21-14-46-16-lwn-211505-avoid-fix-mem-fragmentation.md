---
layout: post
author: 'Wang Chen'
title: "LWN 211505: 避免和解决内存碎片化"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-211505/
description: "LWN 文章翻译，避免和解决内存碎片化"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Avoiding - and fixing - memory fragmentation](https://lwn.net/Articles/211505/)
> 原创：By corbet @ Nov. 28, 2006
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Li lingjie](https://github.com/lljgithub)

> Memory fragmentation is a kernel programming issue with a long history. As a system runs, pages are allocated for a variety of tasks with the result that memory fragments over time. A busy system with a long uptime may have very few blocks of pages which are physically-contiguous. Since Linux is a virtual memory system, fragmentation normally is not a problem; physically scattered memory can be made virtually contiguous by way of the page tables.

内存碎片（memory fragmentation）是内核编程中一个历史悠久的问题。系统运行过程中，各种任务都会请求分配内存页框，导致随着时间的推移，内存的碎片化现象会愈发严重。对一个繁忙的系统来说，长时间运行一段时间后，只有很少的空闲页框还能在物理上保持连续。当然，由于 Linux 支持虚拟内存管理，所以物理内存碎片通常不是问题；在页表的帮助下，物理上分散的内存在虚拟地址上呈现出来仍然是连续的。

> But there are a few situations where physically-contiguous memory is absolutely required. These include large kernel data structures (except those created with `vmalloc()`) and any memory which must appear contiguous to peripheral devices. DMA buffers for low-end devices (those which cannot do scatter/gather I/O) are a classic example. If a large ("high order") block of memory is not available when needed, something will fail and yet another user will start to consider switching to BSD.

但仍有一些情况下必须要求使用物理上保持连续的内存块。这样的例子包括用于存放内核创建的一些大型的数据结构（使用 `vmalloc()` 函数创建的除外）以及为了满足外设要求必须保证某些内存块的物理内存地址连续。第二个例子常见于在操作某些低端外设（不支持 [scatter/gather 模式][2]）的 DMA 缓冲区时。如果在需要时无法分配 “高阶”（high-order，指物理上由多个连续的页框组成）内存块，将影响一些应用实现，说得严重点可能会导致一些 Linux 用户转而投奔 BSD。

> Over the years, a number of approaches to the memory fragmentation problem have been considered, but none have been merged. Adding any sort of overhead to the core memory management code tends to be a hard sell. But this resistance does not mean that people stop trying. One of the most persistent in this area has been Mel Gorman, who has been working on an anti-fragmentation patch set for some years. Mel is back with [version 27 of his patch](http://lwn.net/Articles/211194/), now rebranded "page clustering." This version appears to have attracted some interest, and may yet get into the mainline.

多年来，为了解决内存碎片的问题，社区已经考虑了许多方法，但还没有一个被内核主线所接受。任何试图对内存管理核心代码进行修改的尝试都需要慎之又慎。但这并没有阻止人们努力尝试的决心。要问在这个领域，哪些人最有毅力，恐怕就不得不提起 Mel Gorman，他多年来一直在研究反碎片（anti-fragmentation）问题。最近针对该问题他又向内核提交了[他的补丁的第 27 个版本][3]，并给它起了一个新的名字叫做 "page clustering"（译者注，clustering 有聚合，一簇的意思，即下文所解释的算法中对页框进行分类的概念）。这个版本似乎引起了大家的一些兴趣，很有可能会进入内核主线。

> The core observation in Mel's patch set remains that some types of memory are more easily reclaimed than others. A page which is backed up on a filesystem somewhere can be readily discarded and reused, for example, while a page holding a process's task structure is pretty well nailed down. One stubborn page is all it takes to keep an entire large block of memory from being consolidated and reused as a physically-contiguous whole. But if all of the easily-reclaimable pages could be kept together, with the non-reclaimable pages grouped into a separate region of memory, it should be much easier to create larger blocks of free memory.

Mel 补丁的新版本并没有改变其核心思想（译者注，这个补丁已经延续了很久，较早的介绍请参考 [首次介绍 Mel 的补丁（更新到 V6）][4]；[第二次介绍 Mel 的补丁（更新到 V19）][5]），仍然是基于他对内存的观察，并根据其在运行过程中是否易于回收（reclaim）对页框进行了分类。例如，用于缓存文件的内存页应该是容易被回收和重用的，而一个包含了进程任务结构体的内存页则不能随意回收。这种不能回收的页框一旦夹杂在其他可回收的页框中会导致内核无法将他们整合为一个连续的内存块。但是，如果通过将不可回收的页框和可回收页框分隔开，也就是说如果将所有易于回收的页框保持在一起的话，那么创建更大的空闲内存块会变得容易得多。

> So Mel's patch divides each memory zone into three types of blocks: non-reclaimable, easily reclaimable, and movable. The "movable" type is a new feature in this patch set; it is used for pages which can be easily shifted elsewhere using the kernel's [page migration](http://lwn.net/Articles/160201/) mechanism. In many cases, moving a page might be easier than reclaiming it, since there is no need to involve a backing store device. Grouping pages in this way should also make the creation of larger blocks "just happen" when a process is migrated from one NUMA node to another.

Mel 的补丁正是根据以上思想将每个存储区域（zone）的页框划分为三种类型：不可回收的（“non-reclaimable”），易于回收的（“easily reclaimable”）和可移动的（“movable”）。“可移动” 类型是此次补丁版本中新增加的类型；所谓的“可移动”是指利用内核的[页面迁移机制（page migration）][6] 可以方便地将页框上的内容转移到其他页框上去。在许多情况下，“移动”（move）页面会比回收（reclaim）页面更容易，因为不需要涉及向磁盘设备进行写操作。采用这种方式对页框进行分类后（指引入“移动”方式后）会带来一个好处，就是当我们将一个进程从一个 NUMA 节点迁移到另一个 NUMA 节点时，大块的连续内存会很自然地呈现出来。

> So, in this patch, movable pages (those marked with `__GFP_MOVABLE`) are generally those belonging to user-space processes. Moving a user-space page is just a matter of copying the data and changing the page table entry, so it is a relatively easy thing to do. Reclaimable pages (`__GFP_RECLAIMABLE`), instead, usually belong to the kernel. They are either allocations which are expected to be short-lived (some kinds of DMA buffers, for example, which only exist for the duration of an I/O operation) or can be discarded if needed (various types of caches). Everything else is expected to be hard to reclaim.

在此补丁中，可移动页（即当我们使用 `__GFP_MOVABLE` 选项申请分配的页框）通常属于用户空间的进程。移动属于用户空间的页框只需要复制数据以及更改页表条目，是一件相对容易的事情。相反，可回收页面（即使用 `__GFP_RECLAIMABLE` 选项申请分配的页框）通常由内核使用。它们或者是预期使用后会被快速释放的内存（例如，某些类型的 DMA 缓冲区，仅在输入或者输出操作期间存在），或者是一些如果有必要可以立即回收的内存（譬如各种类型的缓存）。除了这两种类型以外的页框都归类于不可回收的内存。

> By simply grouping different types of allocation in this way, Mel was able to get some pretty good results:

通过简单地以这种方式对分配的内存进行分类归组后，Mel 宣称（针对避免内存碎片化）能够获得一些非常好的效果：

>     In benchmarks and stress tests, we are finding that 80% of memory is available as contiguous blocks at the end of the test. To compare, a standard kernel was getting < 1% of memory as large pages on a desktop and about 8-12% of memory as large pages at the end of stress tests.

    在基准测试和压力测试中，我们发现（采用补丁后） 80% 内存在测试结束后仍然是连续的。作为对比，我们发现采用标准内核（未加入补丁情况下）的台式机上通常的运行结果是连续的大内存小于 1%，如果是运行压力测试后则连续的大内存占比在大约 8-12%。

> Linus has, in the past, been generally opposed to efforts to reduce memory fragmentation. His [comments](https://lwn.net/Articles/211515/) this time around have been much more detail-oriented, however: should allocations be considered movable or non-movable by default? The answer would appear to be "non-movable," since somebody always has to make some effort to ensure that a specific allocation can be moved. Since the discussion is now happening at this level, some sort of fragmentation avoidance might just find its way into the kernel.

Linus 过去一直对减少内存碎片的的补丁修改持反对意见。但这次，他的[回应][7] 看上去却似乎更加注重细节：Linus 在回复中提到，当我们调用分配页框的接口（`alloc_page()`）时，如果不特殊指明，缺省的请求类型应该是被视为可移动（movable）还是不可移动（non-movable）？他倾向于采用缺省为 “不可移动”，因为相对于 “不可移动”，内核针对 “可移动” 类型的页框会执行额外的操作（译者注，所谓额外操作即前文所述利用页迁移机制移动页框，需要补充说明的是，Linus 之所以提出这种想法的目的无非是从使用的角度出发，即如果能够让调用者在请求分配时对需要移动的场景明确提出其请求，会促使调用者更明确其意图并意识到这么做的后果会增加内核额外的动作）。值得注意的是，这次针对这个补丁的讨论已经详细到这个地步，看来有关避免内存碎片的改动有希望在不久将会进入内核主线。

> A related approach to fragmentation is the [lumpy reclaim mechanism](http://lwn.net/Articles/211199/) posted by Andy Whitcroft but originally by Peter Zijlstra. Memory reclaim in Linux is normally done by way of a least-recently-used (LRU) list; the hope is that, if a page must be discarded, going after the least recently used page will minimize the chances of throwing out a page which will be needed soon. This mechanism will tend to free pages which are scattered randomly in the physical address space, however, making it hard to create larger blocks of free memory.

另一个和碎片化有关的补丁是 Andy Whitcroft 提交的 [lumpy reclaim 机制][8] 改进，这个方法最初由 Peter Zijlstra 提出。Linux 中的内存回收通常利用 LRU 链表来完成（译者注， LRU 是 least-recently-used 的缩写）；其原理是，如果必须释放页框，则内核会从 LRU 链表中选择最近最少被使用的页框进行释放，避免换出那些经常被访问的页框。但基于这种机制会倾向于造成内存的碎片化，妨碍内核分配更大的连续的空闲内存块。（译者注，具体原因是释放的过程是按照 LRU 链表中的顺序进行的，并没有考虑释放的页框之间物理地址是否连续）

> The lumpy reclaim patch tries to address this problem by modifying the LRU algorithm slightly. When memory is needed, the next victim is chosen from the LRU list as before. The reclaim code then looks at the surrounding pages (enough of them to form a higher-order block) and tries to free them as well. If it succeeds, lumpy reclaim will quickly create a larger free block while reclaiming a minimal number of pages.

lumpy reclaim 补丁尝试通过对 LRU 算法进行轻微的调整来解决这个问题。当需要分配内存时，首先基于 LRU 链表按照上节描述的方法选择可以释放的页框。区别是，在此原有基础上，修改后的回收代码会查看该被释放的页框的周围是否有连续的页框可以和刚刚释放的页框一起形成更大的内存块，如果有则尝试释放它们。一旦成功，该补丁可以在回收少量页框的同时快速地创建更大的连续空闲内存块。

> Clearly, this approach will work better if the surrounding pages can be freed. As a result, it combines well with a clustering mechanism like Mel Gorman's. The distortion of the LRU approach could have performance implications, since the neighboring pages may be under heavy use when the lumpy reclaim code goes after them. In an attempt to minimize this effect, lumpy reclaim only happens when the kernel is having trouble satisfying a request for a larger block of memory.

显然，如果一个可以回收的页框的周围的页框也是很易于释放的，那么这种方法（指 lumpy reclaim 补丁）工作起来的效果将更好。因此，它非常适合与像 Mel Gorman 提交的那个补丁结合起来一起工作。对 LRU 方法的修改可能会影响性能，因为当 lumpy reclaim 补丁的逻辑在处理那些周围相邻的页框时，这些页框可能正在被频繁地使用。为了尽量减少这种影响，lumpy reclaim 补丁采用的策略是只有在内核无法分配更大内存块时，才会执行以上操作。

> If - and when - these patches may be merged is yet to be seen. Core memory management patches tend to inspire a high level of caution; they can easily create chaos when exposed to real-world workloads. The problem doesn't go away by itself, however, so something is likely to happen, sooner or later.

这些补丁是否会被合入内核以及何时会被合入还有待观察。针对内存管理核心子系统的修改往往会受到社区的严格审查；特别地真实环境下的压力测试才是对它们真正的考验。总而言之，这个话题还远未结束，让我们看看最终会是什么样的结果吧。（译者注，最终的结果是，lumpy reclaim 补丁随 2.6.23 版本合入主线，而 Mel 的补丁经过修改后随 2.6.24 版本合入主线）

[1]: http://tinylab.org
[2]: https://en.wikipedia.org/wiki/Vectored_I/O
[3]: http://lwn.net/Articles/211194/
[4]: /lwn-121618
[5]: /lwn-158211
[6]: http://lwn.net/Articles/160201/
[7]: https://lwn.net/Articles/211515/
[8]: http://lwn.net/Articles/211199/
