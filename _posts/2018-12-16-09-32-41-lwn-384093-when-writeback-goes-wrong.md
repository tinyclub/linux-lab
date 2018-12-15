---
layout: post
author: 'Wang Chen'
title: "LWN 384093: 有关 “回写”（writeback）的问题讨论"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-384093/
description: "LWN 文章翻译，有关 “回写”（writeback）的问题讨论"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[When writeback goes wrong](https://lwn.net/Articles/384093/)
> 原创：By corbet @ Apr. 20, 2010
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Shaolin Deng](https://github.com/ShaolinDeng)

> Like any other performance-conscious kernel, Linux does not immediately flush data written to files back to the underlying storage. Caching that data in memory can help optimize filesystem layout and seek times; it also eliminates duplicate writes should the same blocks be written multiple times in succession. Sooner or later (preferably sooner), that data must find its way to persistent storage; the process of getting it there is called "writeback." Unfortunately, as some recent discussions demonstrate, all is not well in the Linux writeback code at the moment.

和所有注重性能的内核一样，Linux 并不会立即将写入文件的数据刷新（flush）回底层的存储设备（而是缓存在内存中）。在内存中缓存数据有助于优化文件系统数据在磁盘上的分布并提高搜索数据的效率; 此外还可以避免由于连续多次对相同的块执行写操作而造成的重复写入。迟早（当然越早越好），缓存在内存中的数据总会找到自己的路径被同步到磁盘设备中；这个过程称之为 “回写”（writeback，译者注，下文直接使用，不再翻译）。不幸的是，最近的一些讨论表明，目前 Linux 中的 writeback 相关代码运行的效果并不是很理想。

> There are two distinct ways in which writeback is done in contemporary kernels. A series of kernel threads handles writeback to specific block devices, attempting to keep each device busy as much of the time as possible. But writeback also happens in the form of "direct reclaim," and that, it seems, is where much of the trouble is. Direct reclaim happens when the core memory allocator is short of memory; rather than cause memory allocations to fail, the memory management subsystem will go casting around for pages to free. Once a sufficient amount of memory is freed, the allocator will look again, hoping that nobody else has swiped the pages it worked so hard to free in the meantime.

当前内核中存在两种不同的触发执行 writeback 的方式。一种是采用一组内核线程对各自负责的磁盘执行 writeback，并尽可能地确保每个设备处于忙状态（译者注，这么做的好处是不会相互之间妨碍导致 I/O 阻塞，具体可以参考[另一篇 LWN 文章](/lwn-326552)）。另一种 writeback 以 “直接回收” （"direct reclaim"，译者注，下文直接使用，不再翻译）的形式执行，而正是这种方式导致了很多问题（译者注，严格地说 “direct reclaim” 中会触发 writeback，writeback 只是内核在执行 “direct reclaim” 中的步骤之一”。）。当核心内存分配器（core memory allocator）发现内存不足分配时，会尝试 direct reclaim；具体来说，所谓 direct reclaim 就是为了确保内存分配成功，内存管理子系统在空闲内存不足时并不会直接返回失败，而是转而试图释放占用的页框。一旦释放了足够数量的内存，分配器将再次尝试寻找空闲内存进行分配，当然前提是它刚刚释放的页框没有被其他人又占用。

> Dave Chinner recently [encountered a problem](https://lwn.net/Articles/384110/) involving direct reclaim which manifested itself as a kernel stack overflow. Direct reclaim can happen as a result of almost any memory allocation call, meaning that it can be tacked onto the end of a call chain of nearly arbitrary length. So, by the time that direct reclaim is entered, a large amount of kernel stack space may have already been used. Kernel stacks are small - usually no larger than 8KB and often only 4KB - so there is not a lot of space to spare in the best of conditions. Direct reclaim, being invoked from random places in the kernel, cannot count on finding the best of conditions.

Dave Chinner 最近[遇到了一个 涉及 direct reclaim 的问题](https://lwn.net/Articles/384110/)，其表现为内核栈溢出。几乎任何涉及内存分配的函数调用都可能会触发 direct reclaim，这意味着对 direct reclaim 的执行会被添加到任意长度的函数调用路径的末尾。因此，当执行路径走到 direct reclaim 时，内核栈空间可能已经被使用了很多。内核栈很小，一般不大于 8KB，通常只有 4KB，所以这要求我们必须节省着用。由于 direct reclaim 在内核中被调用的地方很多，所以很难估计栈的使用长度最大是多少。

> The problem is that direct reclaim, itself, can invoke code paths of great complexity. At best, reclaim of dirty pages involves a call into filesystem code, which is complex enough in its own right. But if that filesystem is part of a union mount which sits on top of a RAID device which, in turn, is made up of iSCSI drives distributed over the network, the resulting call chain may be deep indeed. This is not a task that one wants to undertake with stack space already depleted.

问题是 direct reclaim 本身的代码执行路径也非常复杂。最简单的情况下，回收 “脏” 页的逻辑会调用文件系统代码，这本身就足够复杂。如果该文件系统还是建立在使用 iSCSI 服务部署的网络 RAID 之上，那么最终的调用栈会非常的深。在栈空间已经将要耗尽的情况下想要再执行 direct reclaim 几乎是不可能的事情。

> Dave ran into stack overflows - with an 8K stack - while working with XFS. The XFS filesystem is not known for its minimalist approach to stack use, but that hardly matters; in the case he describes, over 3K of stack space was already used before XFS got a chance to take its share. This is clearly a situation where things can go easily wrong. Dave's answer was [a patch](https://lwn.net/Articles/384112/) which disables the use of writeback in direct reclaim. Instead, the direct reclaim path must content itself with kicking off the flusher threads and grabbing any clean pages which it may find.

Dave 是在使用 XFS 时遇到了栈溢出，当时他设置的栈大小为 8K。XFS 文件系统在栈的使用上优化程度一般，这在平时并不会引起什么大的问题；但在 Dave 所描述的场景下，在 XFS 的处理开始运行之前，内核栈空间的使用已经超过 3K 。显而易见，这才是导致异常的原因。Dave 的解决方法是提供了一个 [补丁](https://lwn.net/Articles/384112/)，采用的方法很简单，就是在 direct reclaim 中去除了 writeback 操作。取而代之的是，在 direct reclaim 处理中通过唤醒 flusher 线程来释放内存，从而满足自己的需要。

> There is another advantage to avoiding writeback in direct reclaim. The per-device flusher threads can accumulate adjacent disk blocks and attempt to write data in a way which minimizes seeks, thus maximizing I/O throughput. Direct reclaim, instead, takes pages from the least-recently-used (LRU) list with an eye toward freeing pages in a specific zone. As a result, pages flushed by direct reclaim tend to be scattered more widely across the storage devices, causing higher seek rates and worse performance. So disabling writeback in direct reclaim looks like a winning strategy.

在 direct reclaim 中避免 writeback 还有另一个好处。每个设备专有的 flusher 线程会把相邻的磁盘块聚拢在一起，这样可以尽量减少在向磁盘写入数据时执行搜索所花费的时间，从而最大化 I/O 的吞吐量。而原先在 direct reclaim 中，为了释放特定域（zone）中的页框，会基于最近最少使用（least-recently-used，简称 LRU）列表获取需要释放（并执行 writeback）的页框。这么做的结果会造成数据在存储设备中的分布更分散，导致搜索频率增高和性能变坏（译者注，LRU 队列是按照使用频度对页框排序的，最近最少被使用的页框会被优先选中释放，但这并不能保证优先释放的页框是相邻的）。因此，在 direct reclaim 中禁用 writeback 看起来像是一种不错的选择。

> Except, of course, we're talking about virtual memory management code, and nothing is quite that simple. As Mel Gorman [pointed out](https://lwn.net/Articles/384113/), no longer waiting for writeback in direct reclaim may well increase the frequency with which direct reclaim fails. That, in turn, can throw the system into the out-of-memory state, which is rarely a fun experience for anybody involved. This is not just a theoretical concern; it [has been observed](https://lwn.net/Articles/384116/) at Google and elsewhere.

当然，讨论代码逻辑是一回事，而对于实际运行来说，事情可没有那么简单。正如 Mel Gorman [所指出的](https://lwn.net/Articles/384113/)，不在 direct reclaim 中执行 writeback 可能会增加 direct reclaim 失败的概率。反过来，这可能会使系统进入内存不足（out-of-memory）的状态，这对需要内存的人来说可不是什么好消息。这已经不仅仅是一个理论上的推测；谷歌（Google）和其他人[已经实际观察到有类似的情况出现](https://lwn.net/Articles/384116/)。

> Direct reclaim is also where [lumpy reclaim](http://lwn.net/Articles/211505/) is done. The lumpy reclaim algorithm attempts to free pages in physically-contiguous (in RAM) chunks, minimizing memory fragmentation and increasing the reliability of larger allocations. There is, unfortunately, a tradeoff to be made here: the nature of virtual memory is such that pages which are physically contiguous in RAM are likely to be widely dispersed on the backing storage device. So lumpy reclaim, by its nature, is likely to create seeky I/O patterns, but skipping lumpy reclaim increases the likelihood of higher-order allocation failures.

Direct reclaim 处理中也会涉及 [lumpy reclaim](lwn-211505/)。lumpy reclaim 算法尝试尽可能地确保释放的页框在物理上保持连续，从而最大限度地减少内存碎片并提高成功分配大内存的可靠性。遗憾的是，这里存在一种处理上的矛盾：虚拟内存机制天生会造成一种现象，就是对于某些数据，当缓存在内存页框中时在物理上是连续的，但对应到磁盘上却是分散的。这会造成 lumpy reclaim 在处理中频繁地搜索磁盘空间，但如果我们不执行 lumpy reclaim 又会增加 “高阶” （higher-order，指连续大块内存）分配失败的可能性。

> So various other solutions have been contemplated. One of those is simply putting the kernel on a new stack-usage diet in the hope of avoiding stack overflows in the future. Dave's stack trace, for example, shows that the `select()` system call grabs 1600 bytes of stack before actually doing any work. Once again, though, there is a tradeoff here: `select()` behaves that way in order to reduce allocations (and improve performance) for the common case where the number of file descriptors is relatively small. Constraining its stack use would make an often performance-critical system call slower.

于是社区考虑了各种其他解决方案。其中之一就是简单地限制内核代码中对栈的使用，以避免将来出现栈溢出。例如，Dave 对栈的使用进行跟踪后发现 `select()` 这个系统调用在执行实际工作之前先从栈中预先分配了 1600 个字节。但是，这里也存在一种权衡： `select()` 之所以这么做也是针对通常情况下当文件描述符数量相对较少时的一种优化，可以避免过多的内存分配操作（从而提高性能）。限制其对栈的使用常常会使一些性能敏感的系统调用变慢。

> Beyond that, reducing stack usage - while being a worthy activity in its own right - is seen as a temporary fix at best. Stack fixes can make a specific call chain work, but, as long as arbitrarily-complex writeback paths can be invoked with an arbitrary amount of stack space already used, problems will pop up in places. So a more definitive kind of fix is required; stack diets may buy time but will not really solve the problem.

此外，减少栈使用这种做法，虽然本身具备一定的价值，但也只能说是一种暂时的解决方案。针对栈的修改可以使得一些特定的调用路径工作，但是，存在那么多复杂的 writeback 执行路径，各有各的不同的对栈的使用情况，说不定哪天又在别的地方出现问题。因此需要一种更明确的修复方式；采用限制栈的使用这种方式只是临时的，不可能真正解决问题。

> One common suggestion is to move direct reclaim into a separate kernel thread. That would put reclaim (and writeback) onto its own stack where there will be no contention with system calls or other kernel code. The memory allocation paths could poke this thread when its services are needed and, if necessary, block until the reclaim thread has made some pages available. Eventually, the lumpy reclaim code could perhaps be made smarter so that it produces less seeky I/O patterns.

大部分人的建议是将 direct reclaim 移到单独的内核线程中实现。这样 reclaim（包括 writeback）就可以使用它们自己的栈，也就不会与系统调用或其他内核代码竞争栈空间。内存分配路径可以在必要时激活这个线程，并且如果需要，可以阻塞自己直到回收线程释放了一些页框。此外，还可以对 lumpy reclaim 做进一步的改进，尽量在处理中避免对磁盘进行搜索。

> Another possibility is simply to increase the size of the kernel stack. But, given that overflows are being seen with 8K stacks, an expansion to 16K would be required. The increase in memory use would not be welcome, and the increase in larger allocations required to provide those stacks would put more pressure on the lumpy reclaim code. Still, such an expansion may well be in the cards at some point.

另一种可能性是简单地增加内核栈的大小。但是，考虑到栈溢出发生在 8K 大小情况下，所以至少需要扩展到 16K。更多地使用内存显然是不受欢迎的，而且为了提供这样的栈要分配的是连续的大块内存，这将增加对 lumpy reclaim 处理的压力。当然增加栈大小在未来可能是一种趋势。

> [According to Andrew Morton](https://lwn.net/Articles/384119/), though, the real problem is to be found elsewhere:

>     The poor IO patterns thing is a regression. Some time several years ago (around 2.6.16, perhaps), page reclaim started to do a LOT more dirty-page writeback than it used to. AFAIK nobody attempted to work out why, nor attempted to try to fix it.

然而，根据 Andrew Morton 的说法，以上都算不上是最终真正的解决之道：

    糟糕的 I/O 问题又再一次回来了。几年前的某个时候（也许是大约在 2.6.16），我们发现页回收处理中对 “脏” 页的 writeback 操作变得异常地多起来。据我所知（As Far As I Know，简称 AFAIK）当时并没有人试图找出原因，也没有试图解决它。

> In other words, the problem is not how direct reclaim is behaving. It is, instead, the fact that direct reclaim is happening as often as it is in the first place. If there were less need to invoke direct reclaim in the first place, the problems it causes would be less pressing.

换句话说，问题并不在于当前 direct reclaim 的处理方式。相反，事实上是由于 direct reclaim 的发生频率高（所以我们觉得问题出在这里）。如果 direct reclaim 没有被那么多人调用的话，我们也就不太会觉得是它引起的问题了。

> So, if Andrew gets his way, the focus of this work will shift to figuring out why the memory management code's behavior changed and fixing it. To that end, Dave has posted [a set of tracepoints](https://lwn.net/Articles/384120/) which should give some visibility into how the writeback code is making its decisions. Those tracepoints have already revealed some bugs, which have been duly fixed. The main issue remains unresolved, though. It has already been named as a discussion topic for the upcoming filesystems, storage, and memory management workshop (happening with LinuxCon in August), but many of the people involved are hoping that this particular issue will be long-solved by then.

因此，如果 Andrew 没说错的话，这项工作的重心将转移到弄清楚究竟是什么导致内存管理代码的行为发生了变化，然后才好去修复它。为此，Dave 为内核增加了[一组 tracepoints](https://lwn.net/Articles/384120/)，可以让您了解 writeback 代码的处理细节。这些 tracepoints 已经揭示了一些错误并被及时修复了。但主要问题仍未得到解决。该问题已经被列到即将到来的文件系统，存储和内存管理研讨会的讨论主题中（会议即将在 8 月份于 Linux 大会（LinuxCon）上召开），大部分相关人员都认为这个问题短期内还看不到解决的希望。

  [1]: http://tinylab.org
