---
layout: post
author: 'Wang Chen'
title: "LWN 439298: 可靠地通过网络执行页交换（swapping）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-439298/
description: "LWN 文章翻译，可靠地通过网络执行页交换（swapping）"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Safely swapping over the net](https://lwn.net/Articles/439298/)
> 原创：By corbet @ Apr. 19, 2011
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Anle Huang](https://github.com/hal0936)

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> Swapping, like page writeback, operates under some severe constraints. The ability to write dirty pages to backing store is critical for memory management; it is the only way those pages can be freed for other uses. So swapping must work well in situations where the system has almost no memory to spare. But writing pages to backing store can, itself, require memory. This problem has been well solved (with mempools) for locally-attached devices, but network-attached devices add some extra challenges which have never been addressed in an entirely satisfactory way.

与 “页回写”（writeback）一样，“页交换”（swapping，译者注，下文直接使用不再翻译）会在一些内存紧张的情况下被执行。将脏页（dirty pages）写入后备存储设备（译者注，譬如磁盘，针对本文的 swapping 操作我们一般称该设备为 “页交换设备”）的能力对于内存管理至关重要；因为这是唯一可以将这些页框（释放出来）用于其他用途的方法。因此，在系统空闲内存极度紧张的情况下，swap 必须确保能够正常工作。但是，将页框上的数据写入磁盘这个操作本身也可能需要内存。当（页交换设备是）本地连接的设备时，这个问题已经被很好地解决了（通过使用 mempools 技术），但是对于（页交换设备是）网络连接设备时，实现的难度变得更大，而且面对这些困难，目前还未找到完全令人满意的解决方法。

> This is not a new problem, of course; LWN [ran an article about swapping over network block devices](https://lwn.net/Articles/129703/) (NBD) almost exactly six years ago. Various approaches were suggested then, but none were merged; it remains to be seen whether [the latest attempt](https://lwn.net/Articles/438407/) (posted by Mel Gorman based on a lot of work by Peter Zijlstra) will be more successful.

当然，这绝不是一个新问题; 差不多就在六年前，LWN [曾经发表过一篇有关基于网络块设备（network block devices，简称 NBD）实现 swap](https://lwn.net/Articles/129703/) 的文章。当时提出了多种方法，但都没有被内核所采纳；[最近的尝试]((https://lwn.net/Articles/438407/))（由 Mel Gorman 提交，该工作基于许多前期由 Peter Zijlstra 贡献的成果）是否会成功，还有待进一步的观察。（译者注，本文介绍的 Mel 提交的补丁集最终 [随 3.6 版本合入主线][1]。）

> The kernel's page allocator makes a point of only giving out its last pages to processes which are thought to be working to make more memory free. In particular, a process must have either the `PF_MEMALLOC` or `TIF_MEMDIE` flag set; `PF_MEMALLOC` indicates that the process is currently performing [memory compaction](https://lwn.net/Articles/368869/) or direct reclaim, while `TIF_MEMDIE` means the process has run afoul of the out-of-memory killer and is trying to exit. This rule should serve to keep some memory around for times when it is needed to make more memory free, but one aspect of this mechanism does not work entirely well: its interaction with slab allocators.

内核的页框分配器（buddy 系统）在分配内存时，有一条重要的原则，就是：当剩余空闲内存非常少（译者注，譬如低于最低水印线（low watermark））的时候，除非申请内存的进程能够促使更多的内存被释放出来，否则是不会允许为其分配内存的。具体来说，这样的进程必须设置了 `PF_MEMALLOC` 或 `TIF_MEMDIE` 标志；`PF_MEMALLOC` 表示该进程当前正在执行 [“内存规整（memory compaction）”](/lwn-368869) 或 “直接回收（direct reclaim）”，而 `TIF_MEMDIE` 则表示该进程已经触发了内存不足清理（out-of-memory killer）并且正在尝试退出（译者注，以上这些操作都可能导致更多的内存页框被释放）。针对以上情况，为确保释放更多内存的动作能够顺利完成，我们需要遵守的一个原则就是应该为它们保留一些必要的内存，但在具体实施中，slab 分配器的行为可能会破坏这个原则。

> The slab allocators grab whole pages and hand them out in smaller chunks. If a process marked with `PF_MEMALLOC` or `TIF_MEMDIE` requests an object from the slab allocator, that allocator can use a reserved page to satisfy the request. The problem is that the remainder of the page is then made available to any other process which may make a request; it could, thus, be depleted by processes which are making the memory situation worse, not better.

slab 分配器会提前申请多个连续的页框（组成所谓的 slab）然后将它们分成更小的内存块（译者注，即 slab 对象）。如果标记为 `PF_MEMALLOC` 或 `TIF_MEMDIE` 的进程向 slab 分配器申请 slab 对象，则分配器可能会使用这些 “保留” 的页框来满足其请求（译者注，所谓 “保留（reserved）” ，可以理解成低于 low watermark 的那部分内存，内核一般不轻易分配这部分内存，下文会多次提到这个概念）。但问题是此后该页框的其余空闲部分可能会被分配给其他提出内存请求的进程使用；而这些其他进程并不会释放内存，从而导致整体内存情况变得更紧张而不是更宽裕（译者注，换句话说，标记为 `PF_MEMALLOC` 或 `TIF_MEMDIE` 的进程可以认为具有特殊权限，而且它们肩负进一步释放内存的特殊使命，它们通过 slab （最终是从 buddy 系统）申请到了 “保留” 的页框。但 slab 并不会特殊对待这些珍贵的 “保留” 页框，可能在这些具备特殊使命的进程进一步使用之前（更谈不上释放更多的内存），就将 “保留” 页框上的其他剩余空间分配给了其他本没有足够的权限能申请到内存的进程，而这些其他进程并不会执行释放内存的工作，结果造成以上问题）。

> So one of the first things Mel's patch series does is to adapt a patch by Peter that adds more awareness to the slab allocators. A new boolean value (`pfmemalloc`) is added to `struct page` to indicate that the corresponding page was allocated from the reserves; the recipient of the page is then expected to treat it with due care. Both slab and SLUB have been modified to recognize this flag and reserve the rest of the page for suitably-marked processes. That change should help to ensure that memory is available where it's needed, but at the cost of possibly failing other memory allocations even though there are objects available.

因此，Mel 的补丁集中所做的第一件事就是采纳了 Peter 当初提交过的一个补丁修改，使得 slab 分配器能够知道一个已分配的页框具备特殊用途。具体来说就是在 `struct page` 中添加了一个新的布尔类型的成员（`pfmemalloc`），用于标识该页框是否是从保留区分配的，需要特别对待。相应的，slab 和 SLUB 的逻辑也需要修改，如果发现该标志被置位则为那些带有特殊标记（译者注，即前文所述持有 `PF_MEMALLOC` 或 `TIF_MEMDIE` 标志）的进程保留该页框的其余部分（不分配给其他没有特殊标记的进程）。这么做的好处是确保这些保留的内存能被用于优先级更高的操作（譬如释放内存），但代价是这么一来，即使 slab 分配器还有空闲内存可以分配 slab 对象，（其他没有特殊标记的进程）也无法申请得到。（译者注，相关的提交参考 [“mm: sl[au]b: add knowledge of PFMEMALLOC reserve pages”][2]。）

> The next step is to add a `__GFP_MEMALLOC` GFP flag to mark allocation requests which can dip into the reserves. This flag separates the marking of urgent allocation requests from the process state - a change will be useful later in the series, where there may be no convenient process state available. It will be interesting to see how long it takes for some developer to attempt to abuse this flag elsewhere in the kernel.

下一步的工作是添加了一个 名为 `__GFP_MEMALLOC` 的 GFP 标志用来指示分配内存时允许使用保留的页框。利用该新标志可以避免在申请保留内存时必须依赖于进程的状态值，这个改动会给将来的开发工作带来好处，即使当前进程状态不是 `PF_MEMALLOC`，我们也可以在调用 buddy 接口申请内存时通过指定 `__GFP_MEMALLOC` 来申请从保留内存中分配页框。唯一值得担心的是引入这个新的 GFP 标志位后，可能会导致一段时间内开发人员在内核中的其他地方滥用此标志，且让我们对此保持关注。（译者注，相关的提交参考 [“mm: introduce __GFP_MEMALLOC to allow access to emergency reserves”][3]。）

> The big problem with network-based swap is that extra memory is required for the network protocol processing. So, if network-based swap is to work reliably, the networking layer must be able to access the memory reserves. Quite a bit of network processing is done in software interrupt handlers which run independently of any given process. The `__GFP_MEMALLOC` flag allows those handlers to access reserved memory, once a few other tweaks have been added as well.

基于网络执行 swap 过程中需要考虑的一个大问题是：网络协议处理需要许多额外的内存。因此，如果希望基于网络的 swap 能够可靠地工作，则网络层必须能够访问保留的内存。相当多的网络处理都是在软中断处理程序中完成的，这些处理程序的执行独立于任何给定的进程。为此补丁中添加了一些改动，允许在软中断处理函数中通过指定 `__GFP_MEMALLOC` 标志访问保留内存。（译者注，相关提交参考 [“mm: allow PF_MEMALLOC from softirq context”][4]）

> It is not desirable to allow any network operation to access the reserves, though; bittorrent and web browsers should not be allowed to consume that memory when it is urgently needed elsewhere. A new function, `sk_set_memalloc()`, is added to mark sockets which are involved with memory reclaim. Allocations for those sockets will use the `__GFP_MEMALLOC` flag, while all other sockets have to get by with ordinary allocation priority. It is assumed that only sockets managed within the kernel will be so marked; any socket which ends up in user space should not be able to access the reserves. So swapping onto a FUSE filesystem is still not something which can be expected to work.

但是，我们并不希望所有的网络操作都可以访问保留的内存；特别是当其他地方迫切需要使用保留内存时，我们更不应该允许像 bittorrent 和 Web 浏览器这类应用也使用保留内存。为此补丁中添加了一个新的函数 `sk_set_memalloc()` 来标记与内存回收有关的套接字（socket）。标记后的套接字在分配内存时将使用 `__GFP_MEMALLOC` 标志，否则套接字仅使用普通的分配优先级。我们假定只有内核中管理的套接字才会被设定该标记；任何用户空间可以访问的套接字都不应该被允许访问保留内存。因此，任何基于用户空间文件系统（Filesystem in USErspace，简称 FUSE）实现的的交换都无法使用该特性。（译者注，相关提交参考 [“netvm: allow the use of __GFP_MEMALLOC by specific sockets”][5]）

> There is one other problem, though: incoming packets do not have a special "needed for memory reclaim" flag on them. So the networking layer must be able to allocate memory to hold ***all*** incoming packets for at least as long as it takes to identify the important ones. To that end, any network allocation for incoming data is allowed to dip into the reserves if need be. Once a packet has been identified and associated with a socket, that socket's flags can be checked; if the packet was allocated from the reserves and the destination socket is not marked as being used for memory reclaim, the packet will be dropped immediately. That change should allow important packets to get into the system without consuming too much memory for unimportant traffic.

但是还有另外一个问题：系统接收的数据包不可能特殊标明自己 “用于内存回收”。因此，网络层必须能够为 ***所有*** 接收到的数据包分配内存，确保在将其进一步识别为是否是需要特殊处理的数据包之前能够将其一直保存在内存中。为此，必要的话，应该允许网络层在为接收到的数据分配内存时可以使用保留的页框。一旦识别出该数据包关联的套接字，就可以继续检查该套接字的标志；如果发现一个使用了保留页框的数据包其关联的目标套接字并未标记为用于内存回收，则该数据包将立即被丢弃。这么做的好处是在接收重要的数据包的同时又不会为不重要的数据流量消耗太多内存。（译者注，相关提交参考 [“netvm: allow skb allocation to use PFMEMALLOC reserves”][6]。）

> The result should be a system where it is safe to swap over a network block device. At least, it should be safe if the low watermark - which controls how much memory is reserved - is high enough. Systems which are swapping over the net may be expected to make relatively heavy use of the reserves, so administrators may want to raise the watermark (found in `/proc/sys/vm/min_free_kbytes`) accordingly. The final patch in the series keeps an eye on the reserves and start throttling processes performing direct reclaim if they get too low; the idea here is to ensure that enough memory remains for a smaller number of reclaimers to actually get something done. Adjusting the size of the reserves dynamically might be the better solution in the long run, but that feature has been omitted for now in the interest of keeping the patch series from getting too large.

所有以上改动的目标就是使得系统在使用网络块设备（network block device，简称 NBD）实现 swap 时更加安全可靠。至少，只要用于限定保留内存大小的低水印线（low watermark）足够高，那么这么做就应该是安全的。由于通过网络实现交换的系统相对来说会更多地使用保留的内存，因此管理员可能需要适当地提高水印线的标准（通过设置 `/proc/sys/vm/min_free_kbytes`）。为此。该补丁集的最后一个子补丁所做的事情就是在检测到保留内存的容量过低时会主动抑制（throttling）那些运行直接回收（direct reclaim）的进程；其想法就是利用有限的内存确保执行回收的进程中的一小部分能够顺利完成任务（译者注，即避免争抢过于激烈导致谁都无法完成回收的工作，相关提交参考 [“mm: throttle direct reclaimers if PF_MEMALLOC reserves are low and swap is backed by network storage”][7]）。当然，从长远来看，动态调整保留内存的大小可能是更好的解决方案，但是为了避免补丁集改动太大，该特性（指动态调整保留内存大小）暂未实现。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://kernelnewbies.org/Linux_3.6#Safe_swap_over_NFS.2FNBD
[2]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=072bb0aa5e062902968c5c1007bba332c7820cf4
[3]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=b37f1dd0f543d9714f96c2f9b9f74f7bdfdfdf31
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=907aed48f65efeecf91575397e3d79335d93a466
[5]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=7cb0240492caea2f6467f827313478f41877e6ef
[6]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=c93bdd0e03e848555d144eb44a1f275b871a8dd5
[7]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=5515061d22f0f9976ae7815864bfd22042d36848
