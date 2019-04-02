---
layout: post
author: 'Wang Chen'
title: "LWN 359158: 透明巨页（Transparent Hugepages）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-359158/
description: "LWN 中文翻译，透明巨页"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Transparent hugepages](https://lwn.net/Articles/359158/)
> 原创：By Jonathan Corbet @ Oct. 28, 2009
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Shaowei Wang](https://github.com/shaoweiaaron)

Most Linux systems divide memory into 4096-byte pages; for the bulk of the memory management code, that is the smallest unit of memory which can be manipulated. 4KB is an increase over what early virtual memory systems used; 512 bytes was once common. But it is still small relative to the both the amount of physical memory available on contemporary systems and the working set size of applications running on those systems. That means that the operating system has more pages to manage than it did some years back.

大多数的 Linux 系统将内存以 4096 字节大小的页为单位进行划分；对于大部分内存管理代码来说，这是可以操作的最小内存单元。早期虚拟内存系统上最常见的页大小是 512 个字节，与这个比起来，4KB 这个数字已经大了不少。但它相对于现代系统上可用的物理内存容量和在这些系统上运行的应用程序所占用的内存（working set）大小而言仍然很小。这意味着和以前相比，现代操作系统所要管理的内存页的数量还是多了很多。

Most current processors can work with pages larger than 4KB. There are advantages to using larger pages: the size of page tables decreases, as does the number of page faults required to get an application into RAM. There is also a significant performance advantage that derives from the fact that large pages require fewer translation lookaside buffer (TLB) slots. These slots are a highly contended resource on most systems; reducing TLB misses can improve performance considerably for a number of large-memory workloads.

大多数当前的处理器可以支持大于 4KB 的内存页。使用较大页（译者注，即本文所提到的 large page，又称为 huge page，译为 “巨页” 或者 “大页”，下文一般直接使用 “huge page”， 不再翻译）有一些优点：页表的大小减少了，为了将应用程序读入内存所需的 “缺页异常（page fault）” 的触发次数也会相应减少。由于较大的页导致所需的 “转换后援缓存（Translation Lookaside Buffer，简称 TLB）” 的 “表项（slot）” 较少，因此还会给性能带来显著的提高。在大多数系统中，TLB 表项是高度稀缺的资源；对于许多内存消耗较大的应用来说，减少 TLB 的 “未命中（miss）” 可以大大提高其运行的性能。（译者注，举个例子来理解一下：假设应用程序需要 2MB 的内存，如果操作系统以 4KB 作为分页的单位，则需要 512 个页面，进而在 TLB 中需要 512 个表项，同时也需要 512 个页表项，操作系统需要经历至少 512 次 TLB Miss 和 512 次缺页异常才能将 2MB 应用程序空间全部映射到物理内存；然而，当操作系统采用 2MB 作为分页的基本单位时，只需要一次 TLB Miss 和一次缺页异常，就可以为 2MB 的应用程序空间建立虚地址到物理地址之间的映射。另外如果假设不发生 TLB 项替换和 Swap 的话，程序在运行过程中也无需再经历 TLB Miss 和缺页异常。）

There are also disadvantages to using larger pages. The amount of wasted memory will increase as a result of internal fragmentation; extra data dragged around with sparsely-accessed memory can also be costly. Larger pages take longer to transfer from secondary storage, increasing page fault latency (while decreasing page fault counts). The time required to simply clear very large pages can create significant kernel latencies. For all of these reasons, operating systems have generally stuck to smaller pages. Besides, having a single, small page size simply works and has the benefit of many years of experience.

使用较大的页也有其缺点。由于 “内碎片（internal fragmentation）” 的产生，浪费的内存数量将会增加；同时由于数据在内存上的分布比较稀疏也会导致一些额外的开销用于移动数据。将较大页上的数据从二级存储读入到主存需要更长的时间，这会降低缺页异常处理的速度（虽然缺页异常发生的次数减少了）。对于非常大的内存页，即便是执行简单的数据清除，所需的时间也可能会导致显著的内核延迟。鉴于所有的这些原因，操作系统一般会倾向于使用较小的页。此外，使用单个的小页已经可以基本上满足我们的需求，使用上也具备多年的成熟经验。

There are exceptions, though. The mapping of kernel virtual memory is done with huge pages. And, for user space, there is "hugetlbfs," which can be used to create and use large pages for anonymous data. Hugetlbfs was added to satisfy an immediate need felt by large database management systems, which use large memory arrays. It is narrowly aimed at a small number of use cases, and comes with significant limitations: huge pages must be reserved ahead of time, cannot transparently fall back to smaller pages, are locked into memory, and must be set up via a special API. That worked well as long as the only user was a certain proprietary database manager. But there is increasing interest in using large pages elsewhere; virtualization, in particular, seems to be creating a new set of demands for this feature.

但也有例外（译者注，指本文发表时，内核中也有一些地方特别启用了 huge page 的功能）。内核态虚拟内存的映射是通过 huge page 完成的。而且，对于用户空间，则可以利用 “hugetlbfs” 创建和使用 huge page 作为匿名（anonymous）页（译者注，hugetlbfs 特性于 2002 年随 v2.5.36 进入内核主线，相关文档可以参考较新内核版本（v4.18 及以上）的 `Documentation/vm/hugetlbfs_reserv.rst`）。实现 hugetlbfs 是为了满足大型数据库管理系统内存消耗量巨大的迫切需求。它仅针对少数特殊用例，具有很大的局限性：譬如：huge pages 必须提前预留，无法自动地返回到小页状态，预留的 huge pages 在内存中也处于锁定状态，如果需要使用 huge page 还必须调用特殊的 API（译者注，指应用使用 Hugetlb FileSystem 的方式，具体参考网上的一篇文章 [“Linux 大页面使用与实现简介”][1]）。所有的这些功能专为数据库管理应用所设计。但是随着其他应用对 huge page 的兴趣逐渐增大；譬如，虚拟化应用等，正在对该特性提出一系列新的需求。

A host setting up memory ranges for virtualized guests would like to be able to use large pages for that purpose. But if large pages are not available, the system should simply fall back to using lots of smaller pages. It should be possible to swap large pages when needed. And the virtualized guest should not need to know anything about the use of large pages by the host. In other words, it would be nice if the Linux memory management code handled large pages just like normal pages. But that is not how things happen now; hugetlbfs is, for all practical purposes, a separate, parallel memory management subsystem.

当一台主机为虚拟客户机设置内存范围时更愿意使用大页。如果大页不可用，系统就会简单地退而求其次，使用大量较小的页来代替。如果可能的话，系统直接采用大页来实现交换就更好了（译者注，显然写作本文的当时直接基于大页进行页交换还没有实现。）。而虚拟客户机并不需要知道主机对大页的使用情况。换句话说，如果 Linux 的内存管理子系统能够像处理普通页一样处理大页，那就太好了。但现在的情况并非如此；就 hugetlbfs 来说，从各种方面来看（包括了实现和使用），和内核自身的内存管理子系统完全是独立和并行运行的。

Andrea Arcangeli has posted [a transparent hugepage patch](https://lwn.net/Articles/358904/) which attempts to remedy this situation by removing the disconnect between large pages and the regular Linux virtual memory subsystem. His goals are fairly ambitious: he would like an application to be able to request large pages with a simple madvise() system call. If large pages are available, the system will provide them to the application in response to page faults; if not, smaller pages will be used.

Andrea Arcangeli 发布了一个称之为 [“透明巨页（transparent hugepage）” 的补丁][2]，试图解决大页和常规 Linux 虚拟内存子系统之间的割裂问题。他的目标相当宏伟：他希望应用程序能够通过简单的 `madvise()` 系统调用来请求大页。如果有大页可用，系统会在执行缺页异常时将它们提供给应用程序；否则仍旧使用较小的页。

Beyond that, the patch makes large pages swappable. That is not as easy as it sounds; the swap subsystem is not currently able to deal with memory in anything other than PAGE_SIZE units. So swapping out a large page requires splitting it into its component parts first. This feature works, but not everybody agrees that it's worthwhile. Christoph Lameter [commented](https://lwn.net/Articles/359183/) that workloads which are performance-sensitive go out of their way to avoid swapping anyway, but that may become less true on a host filling up with virtualized guests.

除此之外，补丁将允许大页也支持交换（译者注，原先的 hugetlbfs 中的 huge pages  在物理内存中处于锁定（locked）状态无法被换出）。这并不像听起来那么容易；交换子系统当前只能以 `PAGE_SIZE` 大小为单位进行交换。因此，如果要换出（swap out）大页需要先将其按照基本单元（`PAGE_SIZE`）进行拆分。该补丁已经可以工作，但不是每个人都认同这项改进的价值。Christoph Lameter 就 [认为][3] 那些性能敏感（performance-sensitive）的应用总是会尽力避免交换（译者注，言下之意就是既然交换不会发生所以我们也就没有必要为大页支持交换），但他的观点却未必正确，因为在一个具备很多虚拟客户机的主机上交换可能是无法避免的。

A future feature is transparent reassembly of large pages. If such a page has been split (or simply could not be allocated in the first place), the application will have a number of smaller pages scattered in memory. Should a large page become available, it would be nice if the memory management code would notice and migrate those small pages into one large page. This could, potentially, even happen for applications which have never requested large pages at all; the kernel would just provide them by default whenever it seemed to make sense. That would make large pages truly transparent and, perhaps, decrease system memory fragmentation at the same time.

未来可以进一步实现对大页的 “透明（transparent）” 重组。（“透明” 的含义是指）如果一个大页已被拆分（或者一开始就无法分配大页），则应用程序将在内存中拥有许多分散的较小的页。一旦内存中出现一个（空闲的）满足大页的空间，内存管理子系统就会主动将那些小页迁移（migrate）到该大页中。只要看起来有意义，内核就会默认为应用提供大页，即使应用自身并没有主动请求使用大页。这将使得大页的使用变得真正 “透​​明”，并且可能同时减少了系统的内存碎片。

This is an ambitious patch to the core of the Linux kernel, so it is perhaps amusing that the chief complaint seems to be that it does not go far enough. Modern x86 processors can support a number of page sizes, up to a massive 1GB. Andrea's patch is currently aiming for the use of 2MB pages, though - quite a bit smaller. The reasoning is simple: 1GB pages are an unwieldy unit of memory to work with. No Linux system that has been running for any period of time will have that much contiguous memory lying around, and the latency involved with operations like clearing pages would be severe. But Andi Kleen [thinks this approach is short-sighted](https://lwn.net/Articles/359184/); today's massive chunk of memory is tomorrow's brief email. Andi would rather that the system not be designed around today's limitations; for the moment, no agreement has been reached on that point.

对于 Linux 内核的核心部分代码来说这个补丁修改的抱负不可谓不小，但有趣的是，社区对它的主要意见竟然是还觉得它步子迈得还不够。现代 x86 处理器可以支持多种页大小，最大可达 1GB。Andrea 的补丁目前的目标是使用 2MB 的页，属于比较小的那个档次。Andrea 给出的原因很简单：1GB 页对于我们来说太难以操作了。实际运行中的 Linux 系统不可能长时间地维持这么大的一段连续内存，而且对于执行清除页等操作所涉及的延迟也将非常严重。但 Andi Kleen [却认为 Andrea 的考虑是短视的][4]；今天我们所认为的巨量内存在未来看起来可能只是很小的一点容量。Andi 更倾向于系统设计要着眼于未来；目前，在这一点上尚未达成任何一致的意见。

In any case, this patch is an early RFC; it's not headed toward the mainline in the near future. It's clearly something that Linux needs, though; making full use of the processor's capabilities requires treating large pages as first-class memory-management objects. Eventually we should all be using large pages - though we may not know it.

总之，该补丁仍处于征求意见稿（Request For Comments，简称 RFC）草案阶段；谈论合入主线还为时尚早。但这的确是 Linux 所需要的一个功能；为了充分利用处理器的功能，有必要将大页优先作为内存管理的对象。最终我们都将使用大页，而这对于上层应用来说可能是无感（透明）的。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://www.ibm.com/developerworks/cn/linux/l-cn-hugetlb/
[2]: https://lwn.net/Articles/358904/
[3]: https://lwn.net/Articles/359183/
[4]: https://lwn.net/Articles/359184/
