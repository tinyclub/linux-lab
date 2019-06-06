---
layout: post
author: 'Wang Chen'
title: "LWN 495543: 一种更好的平衡 active/inactive 链表长度的算法（Refault Distance 算法）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-495543/
description: "LWN 文章翻译，一种更好的平衡 active/inactive 链表长度的算法（Refault Distance 算法）"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Better active/inactive list balancing](https://lwn.net/Articles/495543/)
> 原创：By corbet @ May 2, 2012
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Lingjie Li](https://github.com/lljgithub)

> Memory management is a notoriously tricky task, though the underlying objective is quite clear: look into the future and ensure that the pages that will be needed by applications are in memory. Unfortunately, existing crystal ball peripherals tend not to work very well; they also usually require proprietary drivers. So the kernel is stuck with a set of heuristics that try to guess future needs based on recent behavior. Adjusting those heuristics is always a bit of a challenge; it is easy to put in changes that will break obscure workloads years in the future. But that doesn't stop developers from trying.

众所周知，内存管理是一项棘手的任务，但它的基本目标其实非常明确：就是通过研究系统状态的未来走向从而确保运行期间应用程序所需的内容总是能在物理内存中被找到。不幸的是，现有的各种预测机制并不能很好地工作；而且它们通常也只能针对自己特定的场景起作用。所以内核常常只能从工程实践出发，采用试探（heuristics ）的方法，根据系统运行过程中当前的行为来推测其未来（对内存）的需求。针对这些试探方法的改进总是充满了挑战；往往一些很小的修改也会给系统的稳定运行带来很大的影响。但所有的这一切并没有阻止开发人员进行新的尝试。

> A core part of the kernel's memory management subsystem is a pair of lists called the "active" and "inactive" lists. The active list contains anonymous and file-backed pages that are thought (by the kernel) to be in active use by some process on the system. The inactive list, instead, contains pages that the kernel thinks might not be in use. When active pages are considered for eviction, they are first moved to the inactive list and unmapped from the address space of the process(es) using them. Thus, once a page moves to the inactive list, any attempt to reference it will generate a page fault; this "soft fault" will cause the page to be moved back to the active list. Pages that sit in the inactive list for long enough are eventually removed from the list and evicted from memory entirely.

Linux 内存管理子系统的核心部分实现了一对称之为 “活动”（“active”）和 “非活动”（“inactive”）的链表（译者注，下文直接使用 active list 和 inactive list，不再翻译成中文。另，有关 active list 和 inactive list 的设计可以参考 [LWN 的这篇文章](/lwn-286472)，或者参考 [该图][1]）。active list 中包含的页框分为匿名页（anonymous page，译者注，下文直接使用不再翻译）和文件缓存页（file-backed pages，译者注，下文直接使用不再翻译）两种类型，并且（内核认为）该链表上的这些页框上的数据会被系统上的进程经常（“积极（active）”地）访问。相反，inactive list 中的页框所包含的数据则被内核认为当前处于 “消极（inactive）” 访问状态（即较长时间内没有被访问过）。当 active list 上的某个页长时间未被使用时，它首先会被移动到 inactive list 上，同时使用该页的进程的地址空间到该物理页框的映射也会被取消（译者注，以上整个过程术语称之为 “demotion”）。因此，一旦一个页框被移动到 inactive list 后，任何对它的引用（访问）都将触发缺页异常（page fault）；这种 “软缺页”（“soft fault”，译者注，详细定义可以参考 [Wikipedia 中 Page fault 条目有关 `Minor` Types 的描述][2]）将导致页框被重新移回 active list（译者注，该过程术语称之为 “promotion”）。一旦某个页框在 inactive list 中停留了足够长的时间，最终会从 inactive list 中被移除并回收（译者注，该过程术语称之为 “reclaim”，LWN 文中也常称之为 “eviction”）。

> One could think of the inactive list as a sort of probational status for pages that kernel isn't sure are worth keeping. Pages can get there from the active list as described above, but there's another way to inactive status as well: file-backed pages, when they are faulted in, are placed in the inactive list. It is quite common that a process will only access a file's contents once; requiring a second access before moving file-backed pages to the active list lets the kernel get rid of single-use data relatively quickly.

我们可以将 inactive list 看成是内核在不确定是否立刻要回收一个页框时用于暂时保存该页框的一个场所。如上节所述，一个页框可以从 active list 被移入 inactive
list，除此之外，页框还有另一种进入 inactive
list 的方式：对于 file-backed page，当在缺页处理中被调入时，将被首先放置在 inactive list 中。这么做的好处是，由于一个进程运行过程中经常只会对某个文件访问一次；所以将 file-backed page 先放在 inactive list 有助于内核快速回收这些只会被访问一次的页框，如果一个 file-backed page 在加入 inactive list 后又被访问了一次内核自然会将其移入 active list。（译者注，下文的 “页框” 如不特殊说明，将只针对 file-backed page，本文重点介绍的 Refault-Distance 算法目前也只针对 file-backed page 和其对应 LRU 链表。）

> Splitting memory into two pools in this manner leads to an immediate policy decision: how big should each list be? A very large inactive list gives pages a long time to be referenced before being evicted; that can reduce the number of pages kicked out of memory only to be read back in shortly thereafter. But a large inactive list comes at the cost of a smaller active list; that can slow down the system as a whole by causing lots of soft page faults for data that's already in memory. So, as is the case with many memory management decisions, regulating the relative sizes of the two lists is a balancing act.

将页框分成 active 和 inactive 两组后首先会面临的一个问题是：每个链表应该多大才合适？维持一个较长的 inactive list 的好处是使得每个页框在被回收之前有充分的时间可以被再次访问（从而被 promote 并移入 active list）；这可以减少那些刚刚被回收又再次（由于访问缺页）被载入的页的数量（译者注，该现象即所谓的 [thrashing](https://en.wikipedia.org/wiki/Thrashing_(computer_science)) 的问题）。但是（由于内存总量有限）如果 inactive list 较长就意味着 active list 相对较小；这会引起大量的 “soft page fault”，最终导致整个系统的速度减慢。因此，作为内存管理决策的一部分，两个链表的相对大小也需要采取一定的策略加以调节并保持适当的平衡。

> The way that balancing is done in current kernels is relatively straightforward: the active list is not allowed to grow larger than the inactive list. Johannes Weiner has concluded that this heuristic is too simple and insufficiently adaptive, so he has come up with [a proposal for a replacement](https://lwn.net/Articles/495423/). In short, Johannes wants to make the system more flexible by tracking how long evicted pages stay out of memory before being faulted back in.

当前内核采取的平衡策略相对简单：仅仅确保 active list 的长度不要超过 inactive list 的长度。Johannes Weiner 认为这种经验公式过于简单且不够灵活，为此他提出了 [一个替代方案](https://lwn.net/Articles/495423/)。简而言之，Johannes 希望通过跟踪一个页框从被回收开始到（因为访问缺页）被再次载入所经历的时间长度来采取更灵活的平衡策略。

> Doing so requires some significant changes to the kernel's page-tracking infrastructure. Currently, when a page is removed from the inactive list and evicted from memory, the kernel simply forgets about it; that clearly will not do if the kernel is to try to track how long the page remains out of memory. The page cache is tracked via a [radix tree](https://lwn.net/Articles/175432/); the kernel's radix tree implementation already has a concept of "exceptional entries" that is used to track tmpfs pages while they are swapped out. Johannes's patch extends this mechanism to store "shadow" entries for evicted pages, providing the needed long-term record-keeping for those pages.

为此需要对内核的页框跟踪基础架构进行一些重大的更改。目前，当一个页框从 inactive list 中被移除并回收后，内核并不会保持对它的跟踪；自然也就无法支持 Johannes 的方案。当前对于页缓存（page cache， 即 file-backed page 的总体描述）内核采用 [基数树（radix tree）](https://lwn.net/Articles/175432/)的方式对其中的页框进行跟踪；内核的基数树实现中有一个 “异常条目（exceptional entries）” 的概念，原本在实现 tmpfs 的换出（swap out）操作时用于跟踪其相关内存页。Johannes 的补丁扩展了这种机制，利用它们为已经被回收的页框继续保存所需的信息（在 Johannes 的补丁中称这些条目为 “影子（shadow）” 项，译者注，下文直接使用 shadow entry，不再翻译。补丁合入主线时有关 shadow entry 的 commit 可以参考 [mm: filemap: move radix tree hole searching here][3] 和 [mm: keep page cache radix tree nodes in check][4]）。

> What goes into those shadow entries is a representation of the time the page was swapped out. That time can be thought of as a counter of removals from the inactive list; it is represented as an `atomic_t` variable called `workingset_time`. Every time a page is removed from the inactive list, either to evict it or to activate it, `workingset_time` is incremented by one. When a page is evicted, the current value of `workingset_time` is stored in its associated shadow entry. This time, thus, can be thought of as a sort of sequence counter for memory management events.

存放在 shadow entry 中的内容是一个页框离开 inactive list 时的时间戳的 “近似表示”。之所以叫 “近似表示”，是因为实际的值是 inactive list 中被移除的页框的个数的计数值；具体实现为一个名为 `workingset_time` 的 `atomic_t` 类型的变量。每次从 inactive list 中移除一个页框时（包括 eviction 或者是 promotion 两种情况），`workset_time` 的值都会加一。每当一个页框被回收时，当前的 `workingset_time` 值被存储在其对应的 shadow entry 中。因此，这个时间戳可以被认为是一种用于表示存储管理相关事件的流水号。（译者注，在该补丁最终合入内核主线时，`workingset_time` 被更名为 [`inactive_age`][5]。）

> If and when that page is faulted back in, the difference between the current `workingset_time` and the value in the shadow entry gives a count of how many pages were removed from the inactive list while that page was out of memory. In the language of Johannes's patch, this difference is called the "refault distance." The observation at the core of this patch set is that, if a page returns to memory with a refault distance of *R*, its eviction and refaulting would have been avoided had the inactive list been *R* pages longer. *R* is thus a sort of metric describing how much longer the inactive list should be made to avoid a particular page fault.

当该页框由于缺页异常而被再次调入时，我们可以利用当前 `workingset_time` 值减去与该页框所对应的 shadow entry 中保存的值从而得到从该页被回收一直到重新被调入期间所有从 inactive list 上被移除的页框的总数。根据 Johannes 补丁的描述，该差额值被称为 “refault distance”（译者注，该术语也是本补丁集中算法名称的由来，为方便理解不再硬性翻译为中文，从字面意思上理解，refault 就是 “第二次缺页异常” 的意思，distance 表达的即前文书所述从一个页框被回收到重新被缺页调入两个时间点之间所有从 inactive list 上被移除的页框的总数）。这个补丁集的核心思想是，假设一个页框被缺页调入时我们计算得到其对应的 refault distance 值为 *R*，那么如果我们可以确保 inactive list 在自身现有长度基础上再延长 *R* 个单位（单位为页框个数）的话，这个页框被加入 inactive list 后就可以避免前文所述的 thrashing 现象（即刚刚被回收却又因为再次被访问而发生缺页调入）。因此，*R* 可以被看成是一种衡量标准，它规定了一个 inactive list 应该确保延长多少从而可以针对 refault 的页框避免产生 thrashing 问题。

> Given that number, one has to decide how it should be used. The algorithm used in Johannes's patch is simple: if *R* is less than the length of the active list, one page will be moved from the active to the inactive list. That shortens the active list by one entry and places the formerly-active page on the inactive list immediately next to the page that was just refaulted in (which, as described above, goes onto the inactive list until a second access occurs). If the formerly-active page is still needed, it will be reactivated in short order. If, instead, the working set is shifting toward a new set of pages, the refaulted page may be activated instead, taking the other page's place. Either way, it is hoped, the kernel will do a better job of keeping the right pages active. Meanwhile, the inactive list gets slightly longer in the hope of avoiding refaults in the near future.

我们可以基于该数字（指上文的 *R* 值）制订一些处理策略。Johannes 补丁中对它的使用很简单：如果 *R* 值小于当前 active list 的长度，则从 active list 中选择一个页框并将其 demote 到 inactive list。这将导致 active list 的长度缩短一项，同时这个原本属于 active list 的页框被加入 inactive list 后紧挨着刚刚 refault 而被加入的那个页框。如果原本属于 active list 的页框仍然有用，那么很快它就会被再次 promote。相反，则很可能是 refault 的那个页框被 promote，代替了原本属于 active list 的那个页框返回到 active list，这会导致整个工作集（working set，译者注，这里应该指的就是 inactive list）中的相应页框都往队列头部移动一个位置。无论哪种方式，内核都能更加准确地使得频繁被访问的页框保持为活动状态。当然，代价是 inactive list 会比目前稍微长一点，但好处是避免了不该有的二次缺页异常处理。（译者注，参考该补丁最终合入主线的代码我们可以发现，最终的实现和本文这里的描述并不一致。在最终代码提交中，*R* 值的定义并无变化，但基于该值的处理策略有调整。目前的做法是，如果 *R* 值小于当前 active list 的长度，则将 refault 的页框直接添加到 active list，利用 active list 的长度来保护该 refault 的页框，其余情况则依旧按照老规矩先入 inactive list。详细的修改原因和分析可以参考 commit: [mm: thrash detection-based file cache sizing][6]。）

> How well all of this works is not yet clear: Johannes has not posted any benchmark results for any sort of workload. This is early-stage work at this point, a long way from acceptance into a mainline kernel release. So it could evolve significantly or fade away entirely. But more sophisticated balancing between the active and inactive lists seems like an idea whose time may be coming.

所有这些工作所能够带来的改进效果尚不清楚：Johannes 也未提供针对各种工作负荷条件下的基准对比测试结果。当前该补丁还处于早期阶段，距离被内核主线接受还有很长的路要走。因此它可能还会发生显著的变化，更甚至会被完全抛弃。但是，可以预料到的是，一个针对 active 和 inactive list 的更加高级的平衡处理机制正在朝我们走来。（译者注，该补丁集 [随 3.15 合入内核主线][7]。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://elixir.bootlin.com/linux/v3.15/source/mm/workingset.c#L19
[2]: https://en.wikipedia.org/wiki/Page_fault#Minor
[3]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=e7b563bb2a6f4d974208da46200784b9c5b5a47e
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=449dd6984d0e47643c04c807f609dd56d48d5bcc
[5]: https://elixir.bootlin.com/linux/v3.15/source/include/linux/mmzone.h#L399
[6]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=a528910e12ec7ee203095eb1711468a66b9b60b0
[7]: https://kernelnewbies.org/Linux_3.15#Improved_working_set_size_detection
