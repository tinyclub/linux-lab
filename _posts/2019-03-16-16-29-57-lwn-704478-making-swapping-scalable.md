---
layout: post
author: 'Wang Chen'
title: "LWN 704478: 让页交换（swapping）更具扩展性（scalable）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-704478/
description: "LWN 文章翻译，让页交换更具扩展性"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Making swapping scalable](https://lwn.net/Articles/704478/)
> 原创：By Jonathan Corbet @ Oct. 26, 2016
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Yang Wen](https://github.com/w-simon)

> The swap subsystem is where anonymous pages (those containing program data not backed by files in the filesystem) go when memory pressure forces them out of RAM. A widely held view says that swapping is almost always bad news; by the time a Linux system gets to the point where it is swapping out anonymous pages, the performance battle has already been lost. So it is not at all uncommon to see Linux systems configured with no swap space at all. Whether the relatively poor performance of swapping is a cause or an effect of that attitude is a matter for debate. What is becoming clearer, though, is that the case for using swapping [is getting stronger](https://lwn.net/Articles/690079/), so there is value in making swapping faster.

交换（swap，译者注，下文直接使用 swap 或者 swapping，不再翻译）子系统负责在内存紧张时将匿名页（anonymous page，即那些存放了程序数据而不是文件系统中的文件数据的页框）上的内容写出到用于备份的存储设备（譬如磁盘）上。一种广泛持有的观点认为，swap 一旦发生可不意味着什么好事；当 Linux 系统的运行状态达到必须要换出匿名页的时候，其整体性能表现肯定已经很糟糕了。因此，我们经常会发现一些 Linux 系统根本就没有配置交换空间（swap space，译者注，即上文所提到的用于备份的存储设备，下文也称为 “交换设备”）。暂且不论是否是相对较差的 swapping 性能造成了以上的观点和现象。但越来越为大家所明了的是，现在使用 swapping 的情况 [正在变得越来越多](https://lwn.net/Articles/690079/)，因此仍然有必要继续提高 swapping 的执行速度。

> Swapping is becoming more attractive as the performance of storage devices — solid-state storage devices (SSDs) in particular — increases. Not too long ago, moving a page to or from a storage device was an incredibly slow operation, taking several orders of magnitude more time than a direct memory access. The advent of persistent-memory devices has changed that ratio, to the point where storage speeds are approaching main-memory speeds. At the same time, the growth of cloud computing gives providers a stronger incentive to overcommit the main memory on their systems. If swapping can be made fast enough, the performance penalty for overcommitting memory becomes insignificant, leading to better utilization of the system as a whole.

随着存储设备，特别是固态存储设备（solid-state storage devices，简称 SSD）性能的提高，swapping 正变得越来越具有吸引力。不久之前，将数据在主存和二级存储设备之间移动的操作还非常缓慢，比直接访问内存的速度要低好几个数量级。但持久存储（[persistent-memory][10]）设备的出现改变了这个状况，目前这类存储设备的访问速度已经快要接近访问主存的速度了。与此同时，云计算的发展也使得服务提供商对其系统上的主存的使用需求变得愈来愈大（译者注：overcommit，即 Memory Overcommit，这是一个专业术语，在云计算场景下，比如：在一个拥有 8G 内存的物理机器上，我们可以创建两个（或更多）虚拟机，每个 6G，这导致虚拟机的内存之和会远大于物理机所能提供的内存量。）。如果能够足够快地运行 swapping，可以起到抵消过度使用内存所造成的性能损失，从而导致整体系统的使用效率得到提高。

> As Tim Chen noted in a recently posted [patch set](https://lwn.net/Articles/704359/), the kernel currently imposes a significant overhead on page faults that must retrieve a page from swap. The patch set addresses that problem by increasing the scalability of the swap subsystem in a few ways.

正如 Tim Chen 在最近发布的 [一个补丁集](https://lwn.net/Articles/704359/) 中所指出的，在当前的缺页异常处理过程中，内核为了将页数据从交换设备中恢复到主存引入了过多的开销。该补丁集采用了多种方式试图通过提高 swap 子系统的 “可扩展性”（scalability）来解决这个问题。

> In current kernels, a swap device (a dedicated partition or a special file within a filesystem) is represented by a `swap_info_struct` structure. Among the many fields of that structure is `swap_map`, a pointer to a byte array, where each byte contains the reference count for a page stored on the swap device. The structure looks vaguely like this:

在当前内核中，使用 `swap_info_struct` 这个结构体类型来表示一个交换设备（一个指定的磁盘分区或者是文件系统中的一个特殊文件）。该结构体类型由许多字段组成，其中一个叫做 `swap_map`，这是一个指向字节数组的指针，其中每一项（一个字节）的值对应着存储（备份）在交换设备上的一个页的引用计数。下图是该结构体简化后的样子：

![Swap file data structures](https://static.lwn.net/images/2016/swap_cluster.svg)

> Some of the swap code is quite old; a fair amount dates back to the beginning of the Git era. In the early days, the kernel would attempt to concentrate swap-file usage toward the beginning of the device — the left end of the `swap_map` array shown above. When one is swapping to rotating storage, this approach makes sense; keeping data in the swap device together should minimize the amount of seeking required to access it. It works rather less well on solid-state devices, for a couple of reasons: (1) there is no seek delay on such devices, and (2) the wear-leveling requirements of SSDs are better met by spreading the traffic across the device.

部分 swap 相关的代码已经有很长的历史了；几乎可以追溯到刚开始使用 Git 对内核进行管理的年代。在早期内核代码中，对交换文件的使用集中在设备的开头部分，即上图中 `swap_map` 数组的左端。当采用传统的机械硬盘时，这种方法是有意义的；因为通过将数据放置在一起可以最小化访问数据所需的寻道（seek）时间。但同样的方法应用在固态硬盘上效果却反而不好，具体有以下两个原因：（1）固态硬盘不存在寻道延迟，（2）将数据分散写到设备的不同的位置对于固态硬盘来说反而更好地满足了它对 [“损耗均衡（Wear leveling）”][1] 的要求。

> In an attempt to perform better on SSDs, the swap code was changed in 2013 for the 3.12 release. When the swap subsystem knows that it is working with an SSD, it divides the device into clusters, as shown below:

为了在 SSD 上表现得更好，swap 代码在 2013年的 3.12 版本中做了相应的修改（译者注，相关提交参考 ["swap: change block allocation algorithm for SSD"][2] 和 ["swap: make cluster allocation per-cpu"][3]）。当 swap 子系统知道它正在使用 SSD 时，它会将设备划分为 “簇”（cluster，译者注，下文直接使用不再翻译），如下图所示：

![Swap file data structures](https://static.lwn.net/images/2016/swap_cluster1.svg)

> The `percpu_cluster` pointer points to a different cluster for each CPU on the system. With this arrangement, each CPU can allocate pages from the swap device from within its own cluster, with the result that those allocations are spread across the device. In theory, this approach is also more scalable, except that, in current kernels, much of the scalability potential has not yet been achieved.

图中 `percpu_cluster` 成员是一个指针，指向系统上每个 CPU 自己的 cluster。通过这种设计，每个 CPU 可以优先从交换设备上属于自己的 cluster 中分配空间存储页数据（译者注，如果某个 CPU 确实无法获得专属的 cluster，它也会退而求其次从 `swap_map` 中搜索空闲的空间。），也就是说采用这种方式后数据在设备上的分布将不再聚集在一起。从理论上讲，这种方法也更具备可扩展性，但在当前的内核中，大部分可扩展性的潜力还未被发挥出来。

> The problem, as is so often the case, has to do with locking. CPUs do not have exclusive access to any given cluster (even the one indicated by `percpu_cluster`), so they must acquire the `lock` spinlock in the `swap_info_struct` structure before any changes can be made. There are typically not many swap devices on any given system — there is often only one — so, when swapping is heavy, that spinlock is heavily contended.

之所以会这样，通常情况下总是和锁处理（locking）有关。CPU 访问任意给定的某个 cluster（即便是 `percpu_cluster` 所指向的属于自己的那个 cluster）时并不具备排他性，因此在进行任何数据修改之前，它们必须尝试获取一个自旋锁，即 `swap_info_struct` 结构体中定义的那个成员变量 `lock`。一般来说一个系统上通常并没有很多交换设备，大部分情况下只有一个，所以，当交换操作很频繁时，对自旋锁的争用是非常激烈的。（译者注，典型多个 CPU 同时访问交换设备的例子，譬如对于 NUMA 系统，每个 NUMA 的 node 都会有一个自己的 kswapd 线程会执行 swap；或者考虑多个线程执行直接页框回收的情况。）

> Spinlock contention is not the path to high scalability; in this case, that contention is not even necessary. Each cluster is independent and can be allocated from without touching the others, so there is no real need to wait on a single global lock. The first order of business in the patch set is thus to add a new lock to each entry in the `cluster_info` array; a single-bit lock is used to minimize the added memory consumption. Now, any given CPU can allocate pages from (or free pages into) its cluster without contending with the others.

对自旋锁的争用自然会降低可扩展性；而针对 swap 的问题，这种争用实际上是不必要的。因为每个 cluster 都是独立的，完全可以在处理过程中不涉及其他的 cluster，更没有必要相互之间等待一个全局的锁。因此，补丁集中的首个修改就是为 `cluster_info` 数组中的每一项添加一个新的锁（译者注，`cluster_info` 数组元素的类型是 `struct swap_cluster_info`，所以这里的修改就是为 `struct swap_cluster_info` 添加一个自旋锁类型的成员 `lock`，具体参考提交的修改 ["mm/swap: add cluster lock"][4]）。为了节省内存，采用了单个比特方式定义该锁（译者注，实际代码并非如此，估计是补丁合入主线前采用的方式）。引入以上修改后，每个 CPU 都可以从其自己的 cluster 中为页框分配用于备份的存储空间（或者释放存储空间），而无需与其他 CPU 发生竞争。

> Even so, there is overhead in taking the lock, and there can be cache-line contention when accessing the lock in other CPUs' clusters (as can often happen when pages are freed, since nothing forces them to be conveniently within the freeing CPU's current cluster). To minimize that cost, the patch set adds new interfaces to allocate and free swap pages in batches. Once a CPU has allocated a batch of swap pages, it can use them without even taking the local cluster lock. Freed swap pages are accumulated in a separate cache and returned in batches. Interestingly, freed pages are not reused by the freeing CPU in the hope that freeing them all will help minimize fragmentation of the swap space.

即便如此，在获取锁时还是存在额外的开销，原因是一个 CPU 可能会访问属于另一个 CPU 的 cluster，也就是多个 CPU 竞争同一把锁，这会引起缓存行争用（cache-line contention）问题（这通常发生在页换入时，因为当前的机制并没有规定执行页换入的 CPU 一定能在自己的 cluster 中找到该页的备份（译者注，由于任务切换，发生缺页异常的 CPU 可能并不是当初执行换出操作的 CPU））。为了最大限度地降低开销，补丁集添加了新的接口可以批量地分配和归还交换页。一旦 CPU 分配了一批交换页面，它就可以在不持有本地 cluster 锁的情况下使用它们。而归还交换页时可以将单独的页先放在另一个独立的缓存中，累积到一定数量后再一次性返回。值得注意的是，内核会避免 CPU 又被分配刚释放的交换页，这么做将有助于最大限度地减少交换空间的碎片。（译者注，稍微补充一下对这部分的修改说明。补丁集首先通过 ["mm/swap: allocate swap slots in batches"][5] 和 ["mm/swap: free swap slots in batch"][6] 扩展了交换空间的分配和归还接口，允许一次申请和释放多个页框大小的空间（in batch）。然后在此基础上引入 ["mm/swap: add cache for swap slots allocation"][7]，即在交换空间和执行交换的用户之间建立了一个缓存机制，避免每次换出和换入时都要直接访问交换空间（这会争用 cluster 的锁），缓存会将交换用户的操作累积起来，并调用 in batch 接口访问交换空间，减少了访问锁的频率。）

> There is one other contention point that needs to be addressed. Alongside the `swap_info_struct` structure, the swap subsystem maintains an `address_space` structure for each swap device. This structure contains the mapping between pages in memory and their corresponding backing store on the swap device. Changes in swap allocation require updating the [radix tree](https://lwn.net/Articles/175432/) in the `address_space` structure, and that radix tree is protected by another lock. Since, once again, there is typically only one swap device in the system, that is another global lock for all CPUs to contend for.

除此之外，还存在一个需要解决的有关竞争的地方。除 `swap_info_struct` 结构体外，swap 子系统还为每个交换设备维护了一个 `address_space` 结构。此结构保存了内存中的页框与交换设备上对应的备份页框之间的映射关系。当改变交换分配时需要更新 `address_space` 结构中包含的 [“基数树（radix tree）”](https://lwn.net/Articles/175432/)，而 radix tree 又被另一个锁所保护。同样的，因为典型系统中通常只有一个交换设备，所以这个全局的锁也会被所有 CPU 所竞争。

> The solution in this case is a variant on the clustering approach. The `address_space` structure is replicated into many structures, one for each 64MB of swap space. If the swap area is sized at (say) 10GB, the single `address_space` will be split 160 ways, each of which has its own lock. That clearly reduces the scope for contention for any individual lock. The patch also takes care to ensure that the initial allocation of swap clusters puts each CPU into a separate `address_space`, guaranteeing that there will be no contention at the outset (though, once the system has been operating for a while, the swap patterns will become effectively random).

针对这个问题的解决方法是采用和前文介绍的解决 clustering 类似的思想。将一个 `address_space` 结构分解复制成多份，每一份只负责交换空间中的一部分（目前定义每一部分覆盖 64MB 大小的地址空间）。举个例子，假设整个交换区域的大小为 10GB，则单个 `address_space` 将被拆分为 160 份，每份都有自己的锁。这显然减少了争用单个锁的地址范围。补丁同时还注意在对交换 cluster 的初始分配中将每个 CPU 对应一个单独的 `address_space`，从而确保一开始不会发生争用（当然，系统运行一段时间后，运行将变为随机模式）。（译者注，该部分的具体修改可以参考 ["mm/swap: split swap cache into 64MB trunks"][8]。）

> According to Chen, current kernels add about 15µs of overhead to every page fault that is satisfied by a read from a solid-state swap device. That, he says, is comparable to the amount of time it takes to actually read the data from the device. With the patches applied, that overhead drops to 4µs, a significant improvement. There have been no definitive comments on the patch set as of this writing, but it seems like the sort of improvement that the swap subsystem needs to work well with contemporary storage devices.

根据 Chen 的说法，基于当前的内核，每次缺页异常处理过程中为了将数据从基于固态硬盘的交换设备中读取出来，（因为内核代码逻辑的处理原因，去除实际的读取操作所花费的时间）额外会增加大约 15μs 的开销。他说，这额外增加的时间差不多和实际从设备读取数据花费的时间相当。但应用补丁后，额外开销降至 4μs，改进效果还是很明显的。在撰写本文时，对补丁集还没有人给出明确的评论，但看上去通过这类改进，在当代最新的存储设备上，swap 子系统可以工作得更好。（译者注，该补丁集 [随 4.11 版本合入内核主线][9]。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://en.wikipedia.org/wiki/Wear_leveling
[2]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=2a8f9449343260373398d59228a62a4332ea513a
[3]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=ebc2a1a69111eadfeda8487e577f1a5d42ef0dae
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=235b62176712b970c815923e36b9a9cc05d4d901
[5]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=36005bae205da3eef0016a5c96a34f10a68afa1e
[6]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=7c00bafee87c7bac7ed9eced7c161f8e5332cb4e
[7]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=67afa38e012e9581b9b42f2a41dfc56b1280794d
[8]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4b3ef9daa4fc0bba742a79faecb17fdaaead083b
[9]: https://kernelnewbies.org/Linux_4.11#Scalable_swapping_for_SSDs
[10]: https://en.wikipedia.org/wiki/Persistent_memory 