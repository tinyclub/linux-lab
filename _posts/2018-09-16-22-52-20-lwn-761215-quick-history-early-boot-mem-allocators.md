---
layout: post
author: 'Wang Chen'
title: "LWN 761215: 关于内核初始化早期阶段内存分配管理机制的发展回顾"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-761215/
description: "LWN 文章翻译，关于内核初始化早期阶段内存分配管理机制的发展回顾"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[A quick history of early-boot memory allocators](https://lwn.net/Articles/761215/)
> 原创：By Mike Rapoport @ July 30, 2018
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> One might think that memory allocation during system startup should not be difficult: almost all of memory is free, there is no concurrency, and there are no background tasks that will compete for memory. Even so, boot-time memory management is a tricky task. Physical memory is not necessarily contiguous, its extents change from system to system, and the detection of those extents may be not trivial. With NUMA things are even more complex because, in order to satisfy allocation locality, the exact memory topology must be determined. To cope with this, sophisticated mechanisms for memory management are required even during the earliest stages of the boot process.

大家可能会认为在系统初始化期间，内存的分配管理应该并不复杂：因为那时几乎所有的内存都是空闲的，初始化的动作都是串行发生的，不存在并发性的问题，更没有后台任务会对内存的使用产生竞争。但即便如此，该阶段中对内存进行管理也是一项棘手的任务。首先，物理内存并不一定是连续的，其范围值随着系统的不同而发生变化，因此需要花费点精力对这些范围进行检测。如果是 NUMA 的系统，则情况愈加复杂，为了确保支持局部性分配，还必须提前确定存储器的拓扑结构。可见，为了解决这些问题，即使在内核初始化过程的最早阶段，也需要引入复杂的内存管理机制。

> One could ask: "so why not use the same allocator that Linux uses normally from the very beginning?" The problem is that the primary Linux page allocator is a complex beast and it, too, needs to allocate memory to initialize itself. Moreover, the page-allocator data structures should be allocated in a NUMA-aware way. So another solution is required to get to the point where the memory-management subsystem can become fully operational.

有人可能会问：“为什么不对所有阶段都使用相同的内存分配机制，而要区分什么初始化阶段和正常运行阶段呢？” 要回答这个问题首先要知道内核正常运行期间所使用的物理页分配管理器（译者注：包括了 buddy 子系统和基于其之上的 slab 分配器）是一个多么复杂的 “巨兽”，包括它自己本身的初始化也需要分配大量的内存。此外，为了支持 NUMA，页分配器（buddy）的数据结构也是针对 NUMA 的特点专门设计的。所以，在内核引初始化的早期阶段，我们需要另一种相对简单的解决方案（译者注，指本文所要重点介绍的 early-boot memory allocator），直到正式的内存管理子系统可以完全接替它的工作为止。

> In the early days, Linux didn't have an early memory allocator; in the 1.0 kernel, memory initialization was not as robust and versatile as it is today. Every subsystem initialization call, or simply any function called from `start_kernel()`, had access to the starting address of the single block of free memory via the global `memory_start` variable. If a function needed to allocate memory it just increased `memory_start` by the desired amount. By the time v2.0 was released, Linux was already ported to five more architectures, but boot-time memory management remained as simple as in v1.0, with the only difference being that the extents of the physical memory were detected by the architecture-specific code. It should be noted, though, that hardware in those days was much simpler and memory configurations could be detected more easily.

在 Linux 发展的初期，并没有所谓早期内存分配器（early memory allocator）的概念（译者注，为方便大家理解， early memory allocator 后面不再翻译）; 在 1.0 版本的内核中，内存的初始化功能可没有现在这样强大和通用。内核初始化的主函数 `start_kernel()` 在调用每个子系统初始化函数时，由各个子系统自己负责读写一个全局变量 `memory_start` 来访问内核预留的一块空闲的内存空间。每次申请一定大小的内存时，通过简单地增加 `memory_start` 的大小来标识内存的使用量（译者注，即通过该全局变量标识可用内存的起始地址）。到内核进入 v2.0 后，Linux 已经被移植到另外五个体系架构上，但初始化期间的内存管理方式仍然像 v1.0 一样简单，唯一的区别是具体检测物理内存范围的工作由特定的体系架构相关代码完成。需要指出的是，当时的硬件要简单得多，检测内存的配置状况也简单的多。

> Up until version 2.3.23pre3, all early memory allocations used global variables indicating the beginning and end of free memory and adjusted them accordingly. Luckily, the page and slab allocators were available early, so heavy memory users, such as `buffers_init()` and `page_cache_init()`, could use them. Still, as hardware evolved and became more sophisticated, the architecture-specific code dealing with memory had grown quite a bit of complex cruft.

直到版本 2.3.23pre3 之前，系统初始化早期的内存分配还都是使用如上所述的方式，即使用全局变量来标识可用内存区的开始和结束地址，并在初始化过程中相应地对其进行调整。所幸的是，页分配器（译者注，指 buddy 系统）和 slab 分配器很快就会完成初始化，因此需要申请大量内存的子系统的初始化过程（例如 `buffers_init()` and `page_cache_init()` 等）将基于页分配器进行。尽管如此，随着硬件的发展，硬件变得越来越复杂，体系结构中处理内存的特定代码部分也相应变得复杂起来。

> The 2.3.23pre3 patch set included the first bootmem allocator implementation, which used a bitmap to represent the status of each physical memory page. Cleared bits identified available pages, while set bits meant that the corresponding memory pages were busy or absent. All the generic functions that tweaked memory_start and the i386 initialization code were converted to use bootmem, but other architectures were left behind. They were converted by the time version 2.3.48 was ready. Meanwhile, Linux was ported to Itanium (ia64), which was the first architecture to start off using bootmem.

2.3.23pre3 版本的补丁集中引入了第一个版本的 bootmem 分配器的实现，它使用一个位图来表示每个物理内存页的使用状态。清零标志位表示该物理页可用，而设置该位则意味着相应的物理页已被占用或者不存在。所有原先使用 `memory_start` 的通用部分代码，以及 i386 架构下的初始化代码在该版本中都转换为使用 bootmem。其他架构暂时没有跟上，直到版本 2.3.48 时才全部完成了转换。与此同时，Linux 被移植到 Itanium（ia64）上，这是第一个从一开始就使用 bootmem 的架构。

> Over time, memory detection has evolved from simply asking the BIOS for the size of the extended memory block to dealing with complex tables, pieces, banks, and clusters. In particular, the Power64 architecture came prepared, bringing with it the [Logical Memory Block allocator](https://lwn.net/Articles/387083/) (or LMB). With LMB, memory is represented as two arrays of regions. The first array describes the physically contiguous memory areas available in the system, while the second array tracks allocated regions. The LMB allocator made its way into 32-bit PowerPC when the 32-bit and 64-bit architectures were merged. Later on it was adopted by SPARC. Eventually LMB made its way to other architectures and became what is now known as memblock.

随着时间的推移，对内存的检测已经从简单地询问 BIOS 有关扩展内存块的大小发展为处理更复杂的拓扑关系，譬如 tables，pieces ，banks 和 clusters 等。特别地，内核对 Power64 架构的支持也已经准备就绪，同时还引入了[逻辑内存块分配器（Logical Memory Block allocator，下文简称 LMB）](/lwn-387083) 的概念。对于 LMB，其管理的内存区域通过两个数组来标识，第一个数组描述系统中可用的连续的物理存储区域，而第二个数组用于跟踪这些区域的分配情况。在内核整合 PowerPC 的 32 位和 64 位代码过程中，LMB 分配器被 32 位 的 PowerPC 架构所采纳。后来它又被 SPARC 架构使用。最终，所有的体系架构都开始使用 LMB，现在它被叫做 memblock。

> The memblock allocator provides two basic primitives that are used as the base for more complex allocation APIs: [`memblock_add()`](https://elixir.bootlin.com/linux/latest/source/mm/memblock.c#L596) for registering a physical memory range, and [`memblock_reserve()`](https://elixir.bootlin.com/linux/latest/source/mm/memblock.c#L714) to mark a range as busy. Both of these are based, in the end, on [`memblock_add_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memblock.c#L489), which adds a range to either of the two arrays.

memblock 分配器提供了两个最基本原语，其他更复杂的 API 内部都会调用它们： 一个是 [`memblock_add()`](https://elixir.bootlin.com/linux/latest/source/mm/memblock.c#L596)，用于发现并注册一个可用的物理内存范围，还有一个是 [`memblock_reserve()`](https://elixir.bootlin.com/linux/latest/source/mm/memblock.c#L714) 用于申请某段内存范围并将其标记为已使用。这两个 API 内部都会调用同一个函数 [`memblock_add_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memblock.c#L489)，由该函数将相关内存区域分别添加到前面介绍的两个数组中的一个，从而参与管理。

> The major drawback of bootmem is the bitmap initialization. To create this bitmap, it is necessary to know the physical memory configuration. What is the correct size of the bitmap? Which memory bank has enough contiguous physical memory to store the bitmap? And, of course, as memory sizes increase so does the bootmem bitmap. For a system with 32GB of RAM, the bitmap will require 1MB of that memory. Memblock, on the other hand, can be used immediately as it is based on static arrays large enough to accommodate, at least, the very first memory registrations and allocations. If a request to add or reserve more memory would overflow a memblock array, the array is doubled in size. There is an underlying assumption that, by the time that may happen, enough memory will be added to memblock to sustain the allocation of the new arrays.

bootmem 的主要缺点在于如何初始化位图。要创建此位图，必须基于实际的物理内存配置。位图的大小取决于实际物理内存的大小。并且内核需要确保能够找到一个合适的内存 bank，其必须要拥有足够大的、连续的物理内存来存储该位图。系统的内存越多，bootmem 所使用的位图所占用的内存也越大。对于一个具有 32 GB 内存的系统，位图需要占用 1 MB 的内存。而对于 Memblock 来说则没有类似的问题，它采用静态数组的方式，数组的大小确保至少可以支持系统最开始运行时的内存需要（包括执行基本的对内存区域的注册和分配动作）。如果运行过程中出现数组大小不够用的情况，则 memblock 处理的方法很简单，就是直接将数组的大小增加一倍。当然这么做有一个潜在的假设，就是，在扩大数组时，总有足够的内存存在。

> The design of memblock relies on the assumption that there will be relatively few allocation and deallocation requests before the primary page allocator is up and running. It does not need to be especially smart, since its lifetime is limited before it hands off all the memory to the buddy page allocator.

memblock 这么设计的原因是基于这样的假设：在内核的页分配器启动和运行之前，系统中只会有相对较少的分配和释放内存的请求操作。它的实现不需要特别复杂，因为一旦页分配器（buddy）开始工作，它那短暂的历史使命也就结束了。

> To ease the pain of transition from bootmem to memblock, a compatibility layer called [nobootmem](https://elixir.bootlin.com/linux/latest/source/mm/nobootmem.c) was introduced. Nobootmem provides (most of) the same interfaces as bootmem, but instead of using the bitmap to mark busy pages it relies on memblock reservations. As of v4.17, only five out of 24 architectures are still using bootmem as the only early memory allocator; 14 use memblock with nobootmem. The remaining five use memblock and bootmem at the same time.

为了减轻从 bootmem 迁移到 memblock 的痛苦，内核引入了一个名为 [nobootmem](https://elixir.bootlin.com/linux/latest/source/mm/nobootmem.c) 的适配层。Nobootmem 提供了（大部分）与 bootmem 相同的接口，但在接口的内部没有使用位图，而是封装了 memblock 的调用接口。截至 v4.17，内核所支持的 24 个架构中只有 5 个仍然在使用 bootmem 作为唯一的内核初始化早期内存分配器; 14 个使用 memblock （以 nobootmem 封装的方式）；其余五个同时支持 memblock 和 bootmem。

> Currently there is ongoing work on enabling the use of memblock with nobootmem on all architectures. Several architectures that use device trees have been converted as a consequence of recent changes in early memory management in the device-tree drivers. There are patches for alpha, c6x, m68k, and nios2 that are already published. Some of them are already merged by the arch maintainers while some are still under review.

目前，正在进行的工作是在所有架构上使用由 nobootmem 封装的 memblock。由于最近设备树驱动中对早期内存管理机制的改变，使用设备树的几种体系结构也已经完成了转换。针对 alpha，c6x，m68k 和 nios2 体系架构的补丁业已发布。其中一些已经由各自体系架构的维护人员完成合并，而另一些体系架构的代码还在审查中。

> Hopefully, by the 4.20 merge window all architectures will cease using bootmem; after that it will be possible to start a major cleanup of the early memory management code. That work would include removing the bootmem allocator and several kernel configurations associated with it. That, in turn, should make it possible to start moving more early-boot functionality from the architecture-specific subtrees into common code. There is never a lack of problems to solve in the memory-management subsystem.

希望在 4.20 版本的集成窗口期间，所有架构都将停止使用 bootmem；这样，内核可以开始对早期内存管理代码进行深入的清理。清理工作将包括删除 bootmem 分配器和与之关联的几个内核配置。同时，我们也可以逐渐将内核初始化阶段中的一些功能实现从特定于体系架构的代码中转移到公共代码中。总而言之，对于内存管理子系统的优化工作是永无止境的。

[1]: http://tinylab.org
