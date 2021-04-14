---
layout: post
author: 'Wang Chen'
title: "LWN 101230: Kswapd 和 “高阶”（high-order）内存申请"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-101230/
description: "LWN 文章翻译，Kswapd 和 “高阶”（high-order）内存申请"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Kswapd and high-order allocations](https://lwn.net/Articles/101230/)
> 原创：By Jonathan Corbet @ Sept. 8, 2004
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Evan Zhao](https://github.com/Tacinight)

> The core memory allocation mechanism inside the kernel is page-based; it will attempt to find a certain number of contiguous pages in response to a request (where "a certain number" is always a power of two). After the system has been running for a while, however, "higher-order" allocations requiring multiple contiguous pages become hard to satisfy. The virtual memory subsystem fragments physical memory to the point that the free pages tend to be separated from each other.

Linux 的内存分配以页框为基本单位，每次根据申请者的请求试图返回一组连续的物理页（准确地说，该组物理页的个数是 2 的整次幂）。试想随着系统的运行，再想申请 “高阶” （higher-order）内存变得愈来愈困难。这是因为由于虚拟内存子系统的存在，其运行机制会导致物理内存碎片化（fragmentation），即剩余的空闲物理页往往是彼此分离而不连续。（译者注，内核伙伴系统（buddy system）把所有空闲的页框分组为 11 个档次，每档分别管理包含大小为 1（2 的 0 次方）， 2（2 的 1 次方）， 4（2 的 2 次方）， ... 1024 （2 的 10 次方） 个连续页框的内存块，higher-order 内存指的是除了第一档（即 2 的 0 次方）以外的那些大小超过一个页框的连续页内存块，下文直接使用 higher-order 指代，不再翻译为中文。）

> Curious readers can query `/proc/buddyinfo` to see how fragmented the currently free pages are. On a 1GB system, your editor currently sees the following:

读者可以通过读取文件 `/proc/buddyinfo` 查看当前系统中物理页的碎片化状态。譬如在我的一台电脑上（内存容量为 1 GB），读取该文件可以看到如下内容:

```
Node 0, zone   Normal 258 9 5 0 1 2 0 1 1 0 0
```

> On this system, 258 single pages could be allocated immediately, but only nine contiguous pairs exist, and only five groups of four pages can be found. If something comes along which needs a lot of higher-order allocations, the available memory will be exhausted quickly, and those allocations may start to fail.

在这个系统上（译者注，严格地说是该系统上 0 号节点（Node）的 Normal 域（zone）），当前可用的单个页框（2 的 0 次幂）有 258 个，包含连续两页（2 的 1 次幂）的内存块只有 9 个，包含连续四页（2 的 2 次幂）的内存块只有 5 个。如果出现需要很多 higher-order 分配请求的情况则可用内存将很快被耗尽，导致再有这样的内存请求会失败。

> Nick Piggin has recently [looked at this issue](https://lwn.net/Articles/100877/) and found one area where improvements can be made. The problem is with the `kswapd` process, which is charged with running in the background and making free pages available to the memory allocator (by evicting user pages). The current `kswapd` code only looks at the number of free pages available; if that number is high enough, `kswapd` takes a rest regardless of whether any of those pages are contiguous with others or not. That can lead to a situation where high-order allocations fail, but the system is not making any particular effort to free more contiguous pages.

Nick Piggin 最近 [研究了一下这个问题][2] 并提出了一个改进建议。他的关注点在 `kswapd` 这个后台进程，该进程通过交换（swap）的方式释放被占用的物理页。但问题是基于当前 `kswapd` 的处理逻辑，它并不会考虑释放后的物理页是否连续，只要感觉当前空闲页数量足够多，就会暂停 swap 工作。所以看上去 high-order 内存的分配之所以会失败，原因是在于 swap 的处理还不到位。

> Nick's patch is fairly straightforward; it simply keeps `kswapd` from resting until a sufficient number of higher-order allocations are possible.

Nick 的补丁相当有针对性；它修改了 `kswapd` 的行为，即只有当系统存在足够数量的 higher-order 内存时才让该进程睡眠。

> It has been pointed out, however, that the approach used by `kswapd` has not really changed: it chooses pages to free without regard to whether those pages can be coalesced into larger groups or not. As a result, it may have to free a great many pages before it, by chance, creates some higher-order groupings of pages. In prior kernels, no better approach was possible, but 2.6 includes the reverse-mapping code. With reverse mapping, it should be possible to target contiguous pages for freeing and vastly improve the system's performance in that area.

需要指出的是，Nick 的补丁并没有对 kswapd 的核心逻辑做修改：它在选择可以交换并释放的物理页时并不检查这些页框是否可以合并。因此，整个选择页框进行释放的行为是随机而没有目的性的。这导致该进程往往显得过于忙碌，花费了大量的时间，释放了很多的内存，但都不能满足 high-order 的要求，换句话说，要想获得 higher-order 的内存块往往要靠碰运气。在过去，似乎没有什么更好的解决办法，但（译者注，[根据 Arjan van de Ven 的建议][3]） 2.6 版本的内核引入了反向映射功能（reverse-mapping）。利用反向映射功能，我们或许可以更有目的地选择并释放连续的内存页，从而大大提高系统在这方面的的性能。

> Linus's [objection](https://lwn.net/Articles/101238/) to this idea is that it overrides the current page replacement policy, which does its best to evict pages which, with luck, will not be needed in the near future. Changing the policy to target contiguous blocks would make higher-order allocations easier, but it could also penalize system performance as a whole by throwing out useful pages. So, says Linus, if a "defragmentation" mode is to be implemented at all, it should be run rarely and as a separate process.

但是 Linus 先生对此（指 Nick 的补丁）表示 [反对][3]，他认为这么做违反了设计 swap 机制的初衷，swap 的目的仅仅是尽可能地将 “可能” 暂时不用的内存页换出。如果我们改变这一策略，附加上额外的目标（指有目的地选择页框使其连续）当然会有助于 higher-order 内存分配问题的解决，但反过来却会对系统的整体性能造成损害，因为在挑选过程中会导致一些有用（不该被换出）的页被换出。总而言之，Linus 认为，如果真的要以后台任务的方式实现 “碎片整理” 的话，最好作为单独的一个进程实现并且它不应该被频繁地运行。

> The other approach to this problem is to simply avoid higher-order allocations in the first place. The switch to 4K kernel stacks was a step in this direction; it eliminated a two-page allocation for every process created. In current kernels, one of the biggest users of high-order allocations would appear to be high-performance network adapter drivers. These adapters can handle large packets which do not fit in a single page, so the kernel must perform multi-page allocations to hold those packets.

解决该问题的另一种思路就是直接在申请内存时就尽量避免使用 higher-order 的内存块。内核采用 4K 大小的内核栈将有助于减轻对 higher-order 内存分配的压力；因为从此创建内核进程时将无需为其申请分配连续两页的内存块。当前内核中，higher-order 内存的最大的一个用户似乎是那些高性能网络适配器驱动程序。这些适配器会处理较大的数据包，而这些数据包的长度往往超过单个页的大小，所以内核必须分配与之大小相匹配的的连续的页框。

> Actually, those allocations are only required when the driver (and its hardware) cannot handle "nonlinear" packets which are spread out in memory. Most modern hardware can do scatter/gather DMA operations, and thus does not care whether the packet is stored in a single, contiguous area of memory. Using the hardware's scatter/gather capabilities requires additional work when writing the driver, however, and, for a number of drivers, that work has not yet been done. Addressing the high-order allocation problem from the demand side may prove to be far more effective than adding another objective to the page reclaim code, however.

实际上，higher-order 内存分配的问题仅当驱动程序（包括其驱动的设备）无法处理物理地址不连续的 “非线性”（"nonlinear"）数据包时才需要。大多数现代硬件支持 [scatter/gather 方式的 DMA 操作][4]，因此并不会太在意数据包是否存放在一个单一且物理地址连续的内存区域上。利用硬件的这一特性在编写驱动程序时需要额外的工作，所以目前一些驱动程序还不支持该特性。看起来，相比给回收算法增加新的处理逻辑（指 Nick 的补丁），直接从控制申请的内存大小入手来解决 high-order 内存分配问题或许更有效些。

[1]: http://tinylab.org
[2]: https://lwn.net/Articles/100877/
[3]: https://lwn.net/Articles/101238/
[4]: https://en.wikipedia.org/wiki/Vectored_I/O