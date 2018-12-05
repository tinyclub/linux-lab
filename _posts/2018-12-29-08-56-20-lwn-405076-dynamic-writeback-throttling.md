---
layout: post
author: 'Wang Chen'
title: "LWN 405076: 动态回写抑制（Dynamic writeback throttling）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-405076/
description: "LWN 文章翻译，动态回写抑制"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Dynamic writeback throttling](https://lwn.net/Articles/405076/)
> 原创：By corbet @ Sep. 15, 2010
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Songfeng Zhang](https://github.com/lyzhsf)

> Writeback is the process of writing dirty memory pages (i.e. those which have been modified by applications) back to persistent storage, saving the data and potentially freeing the pages for other use. System performance is heavily dependent on getting writeback right; poorly-done writeback can lead to poor I/O rates and extreme memory pressure. Over the last year, it has become increasingly clear that the Linux kernel is not doing writeback as well as it should; several developers have been putting time into improving the situation. The [dynamic dirty throttling limits patch](http://lwn.net/Articles/404612/) from Wu Fengguang demonstrates a new, relatively complex approach to making writeback better.

“回写” （writeback，译者注，下文直接使用不再翻译）的作用是将 “脏” 页（即那些已被应用程序修改过的缓存页）上的数据内容写回持久存储（译者注，可以理解为磁盘）保存起来，从而使得那些缓存页可以被用于其他用途。系统性能在很大程度上取决于 writeback 是否能够正常地工作；当 writeback 工作得不好时会降低磁盘的读写吞吐率并给内存分配带来极大的压力。过去一年以来，社区逐渐发现 Linux 内核在 writeback 上表现不佳；一些开发人员已经花费了不少时间试图改善这种情况。Wu Fengguang 提交的 [动态抑制缓存写入（dynamic dirty throttling limits）补丁](http://lwn.net/Articles/404612/) 给大家展示了一种新的，相对复杂的方法，可以用于改进 writeback 的效能。（译者注，从补丁的名字和后面的介绍来看，本文的标题严格说是有问题的，因为该补丁所抑制的是对缓存的写入（dirtying），而非 writeback。）

> One of the key concepts behind writeback handling is that processes which are contributing the most to the problem should be the ones to suffer the most for it. In the kernel, this suffering is managed through a call to `balance_dirty_pages()`, which is meant to throttle a process's memory-dirtying behavior until the situation improves. That throttling is done in a straightforward way: the process is given a shovel and told to start digging. In other words, a process which has been tossed into `balance_dirty_pages()` is put to work finding dirty pages and arranging to have them written to disk. Once a certain number of pages have been cleaned, the process is allowed to get back to the vital task of creating more dirty pages.

一个对缓存写入贡献最多的任务理应受到最大的抑制，这是引入 writeback 处理的主要原因之一。在当前内核中，这种抑制是通过调用 `balance_dirty_pages()` 来实现的，该调用旨在抑制（throttle）任务对缓存的写入行为直到情况有所改善。具体的抑制是通过一种直接的（straightforward）方式完成：一旦 `balance_dirty_pages()` 被任务调用，该函数就会查找 “脏” 页并将它们 writeback 入磁盘。打个比方来说，调用这个函数就好比给了任务一把 “铲子” 并让它立即开始挖掘（digging，译者注，这里的 “挖掘” 比喻的是执行 writeback，而非继续执行写入）。当一定数量的 “脏” 页被清理之后，才允许该任务继续执行写入操作，而这又会产生更多的 “脏” 页。

> There are some problems with cleaning pages in this way, many of which have been covered elsewhere. But one of the key ones is that it tends to produce seeky I/O traffic. When writeback is handled normally in the background, the kernel does its best to clean substantial numbers of pages of the same file at the same time. Since filesystems work hard to lay out file blocks contiguously whenever possible, writing all of a file's pages together should cause a relatively small number of head seeks, improving I/O bandwidth. As soon as `balance_dirty_pages()` gets into the act, though, the block layer is suddenly confronted with writeback from multiple sources; that can only lead to a seekier I/O pattern and reduced bandwidth. So, when the system is under memory pressure and very much needs optimal performance from its block devices, it goes into a mode which makes that performance worse.

以这种方式清理 “脏” 页存在一些问题，这些问题中的大部分已在其他地方给大家做过介绍。而在这些问题之中有一个值得引起我们的关注，就是直接执行 writeback 往往会引发磁盘搜索而影响对磁盘的读写。当 writeback 由后台任务正常处理时，内核会尽力在同一时刻清理同一个文件相关的缓存页。由于在文件系统的帮助下，同一个文件的数据块总是尽可能地被连续存放，所以对同一个文件的缓存页执行回写时磁头的搜索操作也会较少，从而提高了数据的读写速度。而当 `balance_dirty_pages()` 也参与 writeback 时，block 层（指磁盘）会突然面临来自多个任务发起的 writeback（译者注，多个任务是指后台回写任务和调用 `balance_dirty_pages()` 的任务）；这会使得磁盘来回移动磁头导致整体读写效率下降。因此，在系统本身内存压力已经很大的情况下，正确的做法本应该是让块设备以最佳的效率执行读写（指通过 writeback 以减缓缓存压力），但采用直接 writeback 的方式反而使得磁盘的性能变得更差。

> Fengguang's 17-part patch makes a number of changes, starting with removing any direct writeback work from `balance_dirty_pages()`. Instead, the offending process simply goes to sleep for a while, secure in the knowledge that writeback is being handled by other parts of the system. That should lead to better I/O performance, but also to more predictable and controllable pauses for memory-intensive applications.

Fengguang 提交的补丁集（由 17 个子补丁构成）做了以下改进，首先从 `balance_dirty_pages()` 中删除了所有会导致直接 writeback 的工作。这样，执行写入操作的任务只会暂时休眠一段时间，等待系统的后台任务来负责执行真正的 writeback。这应该可以带来更好的磁盘读写性能，同时对于那些内存密集型的应用程序来说，任务的休眠（pause）时长也更加可以被预期和可控。（译者注，由于本文的作者在写作时参考的是当时还未合入主线的代码补丁，包含了以上修改。但在真正合入主线时，并不包含这部分改动，有关在 `balance_dirty_pages()` 中删除直接 writeback 的修改是在另一个也是由 Fengguang 完成的补丁中实现，具体参考[另外一篇介绍](/lwn-456904/)。）

> Much of the rest of the patch series is aimed at improving that pause calculation. It adds a new mechanism for estimating the actual bandwidth of each backing device - something the kernel does not have a good handle on, currently. Using that information, combined with the number of pages that the kernel would like to see written out before allowing a dirtying process to continue, a reasonable pause duration can be calculated. That pause is not allowed to exceed 200ms.

补丁集的其余部分大部分旨在改善对任务休眠时长（pause，译者注，或者译为 “暂停”）的计算。它增加了一种新机制来估计每个磁盘设备的实际读写带宽，在这一点上当前的内核做的还不够。使用该信息，结合内核希望在继续缓存写入之前 writeback 的缓存页的数目值，可以计算出合理的暂停持续时间。该暂停时长最大不允许超过 200 毫秒。（这部分改动参考正式合入主线的 [“commit: writeback: bdi write bandwidth estimation”](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=e98be2d599207c6b31e9bb340d52a231b2f3662d)。）

> The patch set tries to be smarter than that, though. 200ms is a long time to pause a process which is trying to get some work done. On the other hand, without a bit of care, it is also possible to pause processes for a very short period of time, which is bad for throughput. For this patch set, it was decided that optimal pauses would be between 10ms and 100ms. This range is achieved by maintaining a separate "`nr_dirtied_pause`" limit for every process; if the number of dirtied pages for that process is below the limit, it is not forced to pause. Any time that `balance_dirty_pages()` calculates a pause time of less than 10ms, the limit is raised; if the pause turns out to be over 100ms, instead, the limit is cut in half. The desired result is a pause within the selected range which tends quickly toward the 10ms end when memory pressure drops.

补丁中对休眠时长的优化还不止这些，毕竟对于一个运行中的任务来说，强制休眠 200ms 也是一个很长的时间了。更何况，如果不巧的话，甚至可能会在一个很短的时间段内导致多个任务被暂停，这对系统吞吐效率的影响也是不利的。该补丁集设计为将最佳的休眠时间控制在 10 毫秒到 100 毫秒之间。具体的方法是通过为每个任务维护一个自己的 “nr_dirtied_pa​​use” 来对休眠时间进行限制；如果某个任务的 “脏” 页数低于该值（指 “nr_dirtied_pa​​use”），则不会对其执行强制休眠。如果通过 `balance_dirty_pages()` 函数计算得到的暂停时间小于 10 毫秒，则增加该值；如果计算的暂停值超过 100 毫秒，则将该限制值减半。总之期望达到的结果是，首先确保任务休眠的时长被限制在规定的范围内，同时当内存压力下降时，还要使得计算得到的休眠时长值快速收敛到 10 毫秒。（译者注，休眠得越短对于任务来说总是较好的。注意在最终合入内核主线时，这部分改动似乎没有出现。）

> Another change made by this patch series is to try to come up with a global estimate of the memory pressure on the system. When normal memory scanning encounters dirty pages, the pressure estimate is increased. If, instead, the `kswapd` process on the most memory-stressed node in the system goes idle, then the estimate is decreased. This estimate is then used to adjust the throttling limits applied to processes; when the system is under heavy memory pressure, memory-dirtying processes will be put on hold sooner than they otherwise would be.

该补丁另一个修改是尝试对系统的整体内存压力进行估计。当正常的内存扫描遇到 “脏” 页时，则增加该压力估计值。相反，如果对于系统中大多数内存使用密集的节点（node），运行在其上的 `kswapd` 任务进入空闲，则降低该估计值。然后使用该估计值来调整对任务的写入抑制（throttling）；这样达到的效果是，当系统整体上出现严重的内存压力时，写入缓存的任务将会被尽快地抑制。

> There is one other important change made in this patch set. Filesystem developers have been complaining for a while that the core memory management code tells them to write back too little memory at a time. On a fast device, overly small writeback requests will fail to keep the device busy, resulting in suboptimal performance. So some filesystems (xfs and ext4) actually ignore the amount of requested writeback; they will write back many more pages than they were asked to do. That can improve performance, but it is not without its problems; in particular, sending massive write operations to slow devices can stall the system for unacceptably long times.

该补丁集中还有另外一项重要的更改。文件系统的开发人员一直在抱怨核心内存管理子系统每次执行 writeback 时回写涉及的内存量偏少。对于一个快速存储设备来说，writeback 请求量过小无法充分利用设备的高吞吐能力，导致性能欠佳。为此一些文件系统（xfs 和 ext4）会忽略实际的 writeback 请求数量；而是在他们接收到 writeback 请求时回写更多的缓存页。这当然可以提高性能，但并非没有问题；特别是在向慢速设备执行大量写入操作时会导致系统卡顿，产生不可接受的延迟。

> Once this patch set is in place, there's a better way to calculate the best writeback size. The system now knows what kind of bandwidth it can expect from each device; using that information, it can size its requests to keep the device busy for one second at a time. Throttling limits are also based on this one-second number; if there are not enough dirty pages in the system for one second of I/O activity, the backing device is probably not being used to its full capacity and the number of dirty pages should be allowed to increase. In summary: the bandwidth estimation allows the kernel to scale dirty limits and I/O sizes to make the best use of all of the devices in the system, regardless of any specific device's performance characteristics.

而一旦这个补丁集被加入内核后，我们就会有更好的方法来计算最佳的 writeback 大小。系统现在知道了每个设备可以承受的 writeback 带宽；基于该信息，它可以调整 writeback 请求以保证设备一次可以忙碌一秒钟。抑制（Throttling）操作也可以基于这个一秒钟的写入数据量进行判断；如果系统中的 “脏” 页量太少，不足以支持一秒钟的 writeback，则说明磁盘设备不能被充分使用，此时可以允许任务写入更多的 “脏” 页。总之：基于对磁盘读写带宽的估计，允许内核调节（提高）写入 “脏” 页的限制和 writeback 的数据量，从而可以充分利用系统中的所有设备，同时不用单独考虑特定设备的读写特性。（这部分改动参考正式合入主线的 [“commit: writeback: scale IO chunk size up to half device bandwidth”](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=1a12d8bd7b2998be01ee55edb64e7473728abb9c)。）

> Getting this code into the mainline could take a while, though. It is a complicated set of changes to core code which is already complex; as such, it will be hard for others to review. There have been some concerns raised about the specifics of some of the heuristics. A large amount of performance testing will also be required to get this kind of change merged. So we may have to wait for a while yet, but better writeback should be coming eventually.

但是，将此补丁代码合入主线还需要一段时间。内核内存子系统的代码本身已经十分复杂，而该补丁的修改也不简单；这给其他人的审查工作带来了困难。也有些人对补丁中采用的估算方式的细节提出了一些担忧。除此之外，我们还需要经过大量的性能测试验证才能将这个更改最终合入主线。总之我们还要再等待一段时间，但相信该补丁合入后对 writeback 的性能提升应该会有更大的帮助。（译者注，该补丁最终随 3.1 版本合入主线。）

[1]: http://tinylab.org
