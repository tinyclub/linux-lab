---
layout: post
author: 'Wang Chen'
title: "LWN 320556: 为页框分配器（page allocator）加速"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-320556/
description: "LWN 文章翻译，为页框分配器加速"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Speeding up the page allocator](https://lwn.net/Articles/320556/)
> 原创：By corbet @ Feb. 25, 2009
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Zhang Songfeng](https://github.com/lyzhsf)

> It is a rare kernel operation that does not involve the allocation and freeing of memory. Beyond all of the memory-management requirements that would normally come with a complex system, kernel code must be written with extremely tight stack limits in mind. As a result, variables which would be declared as automatic (stack) variables in user-space code require dynamic allocation in the kernel. So the efficiency of the memory management subsystem has a pronounced effect on the performance of the system as a whole. That is why the kernel currently has three slab-level allocators (the original slab allocator, SLOB, and [SLUB](http://lwn.net/Articles/229984/)), with another one ([SLQB](http://lwn.net/Articles/311502/)) waiting for the 2.6.30 merge window to open. Thus far, nobody has been able to create a single slab allocator which provides the best performance in all situations, and the stakes are high enough to make it worthwhile to keep trying.

内核操作中很少有不涉及内存分配和释放的。作为一个复杂的系统，在内存管理上除了具备通常的要求之外，内核编程中对栈（stack）的使用也有很大的限制。因此，对那些用户态编程中通常会声明为自动类型（automatic，即存放在栈中）的变量，换成了内核态编程则会优先采用动态分配的方式。由此可见，内存管理子系统的效率对整个系统的性能有着多么显著的影响。这也是为何当前内核中光 slab 分配器（slab allocator）就有三个选择（最早的 slab 分配器，SLOB 和[SLUB](http://lwn.net/Articles/229984/)，译者注，本文用 slab allocator 表示三种内存分配器的通称，而非专指某种具体的内存分配器，下文直接使用 slab allocator，不再翻译为中文），还有一个新提交的（[SLQB](http://lwn.net/Articles/311502/)）正在等待被下一个版本（2.6.30）合入。到目前为止，还没有人能够创建一个统一的 slab 分配器可以适用于所有情况并提供最佳性能，这也是一个巨大的挑战，吸引着众多的内核极客去勇敢尝试。

> While many kernel memory allocations are done at the slab level (using `kmem_cache_alloc()` or `kmalloc()`), there is another layer of memory management below the slab allocators. In the end, all dynamic memory management comes down to the page allocator, which hands out memory in units of full pages. The page allocator must manage memory without allowing it to become overly fragmented; it also must deal with details like CPU and NUMA node affinity, DMA accessibility, and high memory. It also clearly needs to be fast; if it is slowing things down, there is little that the higher levels can do to make things better. So one might do well to be concerned when memory management hacker Mel Gorman [writes](http://lwn.net/Articles/320279/):

> 	The complexity of the page allocator has been increasing for some time and it has now reached the point where the SLUB allocator is doing strange tricks to avoid the page allocator. This is obviously bad as it may encourage other subsystems to try avoiding the page allocator as well.

虽然许多内核内存分配的工作是在 slab 层次完成的（通过调用 `kmem_cache_alloc()` 或者 `kmalloc()`），但在 slab allocator 下面还有另一层内存管理。所有的动态内存管理最终归结为使用页面分配器（page allocator，译者注，下文直接使用英文不再翻译），它以完整的物理页框为单位分配内存。page allocator 在内存管理中必须尽量避免碎片化（fragmented）问题； 它还必须处理诸多细节，包括处理 CPU 和 NUMA 节点的关联性，DMA 的可访问性，以及高端内存（high memory）等。显然地，page allocator 的处理速度也需要足够地快；如果它变慢了，那么在它之上的内存管理子系统（译者注，指 slab allocator）自然也快不到哪里去。所以当内存管理子系统的主要开发人员 Mel Gorman 对 page allocator 的性能问题[发表了](http://lwn.net/Articles/320279/)如下言论时，立即受到了大家的广泛关注：

    page allocator 的复杂性一直以来在不断增加（译者注，暗示的意思就是这导致 page allocator 的处理效率也在逐渐降低），以至于 SLUB allocator 甚至试图使用一些特殊的技巧来尽量避免使用 page allocator。这可不是一个好兆头，因为这只会鼓励越来越多的其他子系统尝试绕开 page allocator。

> As might be expected, Mel has come up with a set of patches designed to speed up the page allocator and do away the the temptation to try to work around it. The result appears to be a significant cleaning-up of the code and a real improvement in performance; it also shows the kind of work which is necessary to keep this sort of vital subsystem in top shape.

不负众望，Mel 已经提交了一系列补丁，旨在加速 page allocator 以此来打消那些试图避免使用它的念头。他的补丁对代码进行了重大的清理，给性能带来了真正的改进；它还揭示了如何将内存管理这种重要的子系统保持在最佳状态所必须注意的操作。

> Mel's 20-part patch (linked with the quote, above) attacks the problem in a number of ways. Many of them are small tweaks; for example, the core page allocation function (`alloc_pages_node()`) includes the following test:

Mel 的补丁集由 20 个小补丁组成（参考上文提供的原文链接），从多个方面对 page allocator 进行了改进。其中不少是小调整；譬如，核心的页分配函数（`alloc_pages_node()`）中含有以下测试：

	if (unlikely(order >= MAX_ORDER))
		return NULL;

> But, as Mel puts it, no proper user of the page allocator should be allocating something larger than `MAX_ORDER` in any case. So his patch set removes this test from the fast path of the allocator, replacing it with a rather more attention-getting test (`VM_BUG_ON`) in the slow path. The fast allocation path gets a little faster, and misuse of the interface should eventually be caught (and complained about) anyway.

但是，正如 Mel 所说，作为一个正常的 page allocator 的用户，无论如何都不会试图将该参数（order）指定为一个大于 `MAX_ORDER` 的值。因此，他从该函数的快速路径（fast path，译者注，所谓 fast path 指的是内存分配函数中大概率会分配成功的执行路径，反之称之为 slow path）中删除了此条件测试，而在慢速路径（slow path）中使用了相当多的检查（采用 `VM_BUG_ON` 宏）。这样使得快速路径下函数会执行得快那么一点，同时也确保了对该函数的错误使用会被捕获（通过断言并输出调试信息的方式 ）。

> Then, there is the little function `gfp_zone()`, which takes the flags passed to the allocation request and decides which memory zone to try to allocate from. Different requests must be satisfied from different regions of memory, depending on factors like whether the memory will be used for DMA, whether high memory is acceptable, or whether the memory can be relocated if needed for defragmentation purposes. The current code accomplishes this test with a series of four `if` tests, but lots of jumps can be expensive in fast-path code. So Mel's patch replaces the tests with a table lookup.

另一个优化的例子是针对一个小函数 `gfp_zone()`，它的入参是请求分配内存时给定的 GFP flags，并根据该 flags 来决定从哪个内存区域（zone）中分配内存。具体选择时需要根据不同的使用要求做出不同的选择，譬如内存是否将用于 DMA，是否可接受使用高端内存，或者是否需要重新定位内存以支持碎片整理。当前代码通过串行的四个 `if` 条件测试来完成这些判断，但是在快速路径代码中执行大量的判断代价过高。因此 Mel 的补丁中采用查表的方式替换了条件测试。

> There are a number of other changes along these lines - seeming micro-optimizations that one would not normally bother with. But, in fast-path code deep within the system, this level of optimization can be worth doing. The patch set also reorganizes things to make the fast path more explicit and contiguous; that, too, can speed things up, but it also helps ensure that developers know when they are working with performance-critical code.

类似的改动还有一些，都是一些不太引人注意的小优化。但是，在系统内部代码处理的快速路径上，这种优化还是值得的。补丁集还对代码做了重新的组织，使得快速路径看上去更加明确，并且尽量组织在一起不分散；这么做不仅可以加快速度，更有助于确保开发人员理解这些影响性能的关键代码。

> The change which provoked the most discussion, though, was the removal of the distinction between hot and cold pages. This feature, [merged for 2.5.45](http://lwn.net/Articles/14768/), attempts to track which pages are most likely to be present in the processor's caches. If the memory allocator can give cache-warm pages to requesters, memory performance should improve. But, notes Mel, it turns out that very few pages are being freed as "cold," and that, in general, the decisions on whether to tag specific pages as being hot or cold are questionable. This feature adds some complexity to the page allocator and doesn't seem to improve performance, so Mel decided to take it out. After [running some benchmarks](https://lwn.net/Articles/320568/), though, he concluded that, in fact, he has no idea whether the feature helps or not. So the second version of the patch has left out the hot/cold removal, but this topic will be revisited in the future.

修改中引起最多讨论的是该补丁删除了对所谓热页（hot pages）和冷页（cold pages）的区别。该特性[于 2.5.45 合入内核主线](http://lwn.net/Articles/14768/)，试图跟踪那些最有可能出现在处理器缓存（cache）中的物理页。如果内存分配器可以将处于缓存中的物理页提供给请求者，则处理性能势必会有所提高。但是，Mel 指出，事实证明很少有物理页会被释放而成为所谓的“冷”页，因此，是否有必要为页框标识“热”或“冷”值得讨论。为了支持该特性只会使得 page allocator 变得更复杂，但似乎并没有对提高性能带来什么好处，因此 Mel 决定移除该功能。但[运行了一些基准测试](https://lwn.net/Articles/320568/)后，他又无法断定该特征是否真的没有帮助。所以补丁的第二个版本保留了该特性，留待未来重新审视。

> Mel claims some good results:

> 	Running all of these through a profiler shows me the cost of page allocation and freeing is reduced by a nice amount without drastically altering how the allocator actually works. Excluding the cost of zeroing pages, the cost of allocation is reduced by 25% and the cost of freeing by 12%. Again excluding zeroing a page, much of the remaining cost is due to counters, debugging checks and interrupt disabling. Of course when a page has to be zeroed, the dominant cost of a page allocation is zeroing it.

Mel 声称该补丁带来了如下一些好的结果：

    通过对测试结果的分析表明，引入该补丁后，在没有大幅改变分配器实际工作方式的前提下，页框的分配和释放的效率提高了很多。不考虑清空页框引入的折损，整个内存分配成本降低了 25%，释放成本降低了 12%。同样不考虑清空页框的操作，内存分配的大部分成本来自计数器操作，调试检查和中断禁用带来的延迟。当然，当页框必须被清零时，分配页框的主要成本还是来自清零操作。

> A number of standard user-space benchmarks also show improvements with this patch set. The reviews are generally good, so the chances are that these changes could avoid the lengthy delays that characterize memory management patches and head for the mainline in the relatively near future. Then there should be no excuse for trying to avoid the page allocator.

许多标准的用户态基准测试程序的运行结果也表明，该补丁改进了内存分配的效率。审阅的反响都不错，看来这个补丁应该会很快进入主线，而不会像其他内存管理相关的补丁那样在进入内核主线的道路上费尽周折（译者注，该补丁随内核版本 2.6.31 合入主线）。更重要的是，以后再也不会有试图绕过 page allocator 的理由了。

[1]: http://tinylab.org
