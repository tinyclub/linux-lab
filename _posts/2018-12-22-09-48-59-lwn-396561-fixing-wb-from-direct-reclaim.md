---
layout: post
author: 'Wang Chen'
title: "LWN 396561: 解决 direct reclaim 中的 writeback 问题"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-396561/
description: "LWN 文章翻译，解决 direct reclaim 中的 writeback 问题"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Fixing writeback from direct reclaim](https://lwn.net/Articles/396561/)
> 原创：By corbet @ Jul. 20, 2010
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Anle Huang](https://github.com/hal0936)

> "Writeback" is the process of writing the contents of dirty memory pages back to their backing store, where that backing store is normally a file or swap area. Proper handling of writeback is crucial for both system performance and data integrity. If writeback falls too far behind the dirtying of pages, it could leave the system with severe memory pressure problems. Having lots of dirty data in memory also increases the amount of data which may be lost in the event of a system crash. Overly enthusiastic writeback, on the other hand, can lead to excessive I/O bandwidth usage, and poorly-planned writeback can greatly reduce I/O performance with excessive disk seeks. Like many memory-management tasks, getting writeback right is a tricky exercise involving compromises and heuristics.

“回写”（"Writeback"，以下直接使用英文不再翻译）是指将被修改过的缓存的内容同步写回其对应的后备存储（backing store）的过程，这里所谓的 “后备存储” 通常指的是文件所对应的磁盘上的存放区域或者是交换（swap）区。正确处理 writeback 对于提高系统性能和保持数据的完整性都至关重要。如果 writeback 速度太慢，过多地落后于缓存被弄 “脏” 的速度，则不仅会给系统分配内存带来严重的压力。而且由于缓存中存在太多的 “脏” 数据未被及时同步到磁盘上，还会导致另一个问题，就是系统一旦崩溃，会丢失很多数据。反之，如果 writeback 过于频繁则会占用太多的 I/O 带宽，并且不恰当的 writeback 还会执行过多的磁盘搜索，大大降低了整体的 I/O 性能。像许多其他内存管理任务一样，如何确保 writeback 正确运行是​​一项十分具有挑战性的工作，需要充分地权衡各种利弊并发挥你的想象力。

> Back in April, LWN [looked at a specific writeback problem](http://lwn.net/Articles/384093/): quite a bit of writeback activity was happening in direct reclaim. Normally, memory pages are reclaimed (made available for new uses, with data written back, if necessary) in the background; when all goes well, there will always be a list of free pages available when memory is needed. If, however, a memory allocation request cannot be satisfied from the free list, the kernel may try to reclaim pages directly in the context of the process performing the allocation. Diverting an allocation request into this kind of cleanup activity is called "direct reclaim."

早在 4 月份，LWN [报道了一个有关 writeback 的问题](/lwn-384093)：在直接回收（direct reclaim，以下直接使用英文不再翻译）中发生了过多的 writeback 活动。通常，内核在后台对内存页进行回收（必要的情况下通过对缓存上的内容执行 writeback 从而将这些缓存释放出来以供新的内存分配需要）；如果一切顺利，内核应该在需要分配内存时就可以得到足够的空闲页。但是，如果此时发现空闲页数量不足，则内核可能会尝试直接在请求内存的进程的上下文中回收页面。我们把这种从分配内存转变为对内存进行清理的活动称为 “直接回收”（"direct reclaim"）。

> Direct reclaim normally works, and it is a good way to throttle memory-hungry processes, but it also suffers from a couple of significant problems. One of those is stack overflows; direct reclaim can happen from almost anywhere in the kernel, so it may be that the kernel stack is already mostly used before the reclaim process even starts. But if reclaim involves writing file pages back, it can be just the beginning of a long call chain in its own right, leading to the overflow of the kernel stack. Beyond that, direct reclaim, which reclaims pages wherever it can find them, tends to create seek-intensive I/O, hurting the whole system's I/O performance.

Direct reclaim 通常是有效的，当某些进程对内存的需求十分急迫时，可以用该方法予以解决，但它也存在一些明显的问题。其中一个是会导致栈溢出；direct reclaim 可以在内核中的几乎任何地方发生，因此很有可能在回收开始之前内核栈已经被用得差不多了。更何况如果回收还涉及对缓存了文件内容的页框执行 writeback，则该动作本身的函数调用栈就会很深，最终有可能导致内核栈溢出。除此之外，由于 direct reclaim 会尽其可能对页框进行回收，往往会在 I/O 上引起频繁的搜索（seek），从而损害整个系统的 I/O 性能。（译者注，对以上描述更详细的解释，请参考 [4 月份 LWN 报道的有关 writeback 的问题](/lwn-384093)）

> Both of these problems have been seen on production systems. In response, a number of filesystems have been changed so that they simply ignore writeback requests which come from the direct reclaim code. That makes the problem go away, but it is a kind of papering-over that pleases nobody; it also arguably increases the risk that the system could go into the dreaded out-of-memory state.

这两个问题在实际上线系统上都出现了。为了避免这个问题，内核对一些文件系统做了修改，方法是在 direct reclaim 处理中简单地忽略了 writeback 操作。但这么做只是暂时规避了这个问题，绝不是一种令人满意的解决方法；而且这么做从理论上来说还会增加系统进入可怕的 “内存不足（out-of-memory，即 OOM）” 的风险。

> Mel Gorman has been working on the reclaim problem, on and off, for a few months now. His [latest patch set](http://lwn.net/Articles/396512/) will, with luck, improve the situation. The actual changes made are relatively small, but they apparently tweak things in the right direction.

这几个月以来，Mel Gorman 断断续续地一直在致力于解决回收的问题。他的 [最新补丁集][1] 很有可能会给大家带来好消息。该补丁中所做的实际修改并不多，但看上去是一种正确的解决思路。（译者注，Mel Gorman 的补丁集中有关本文讨论的内容 [于版本 3.2 合入内核主线][2]）

> The key to solving a problem is understanding it. So, perhaps, it's not surprising that the bulk of the changes do not actually affect writeback; they are, instead, tracing instrumentation and tools which provide information on what the reclaim code is actually doing. The new tracepoints provide visibility into the nature of the problem and, importantly, how much each specific change helps.

解决问题的关键是要先理解问题的本质。所以，当我们看到这个补丁的大部分工作并不是直接针对 writeback 的修改，而是涉及改进代码跟踪和开发一些辅助工具时，也就不会感到奇怪了。这些辅助工作可以帮助我们理解回收的代码逻辑实际运行时的细节。新增的 tracepoints 让我们看清了问题的本质，重要的是，让我们了解到应该如何针对性地对问题进行修改。

> The core change is deep within the direct reclaim loop. If direct reclaim stumbles across a page which is dirty, it now must think a bit harder about what to do with it. If the dirty page is an anonymous (process data) page, writeback happens as before. The reasoning here seems to be that the writeback path for these pages (which will be going to a swap area) will be simpler than it is for file-backed pages; there are also fewer opportunities for anonymous pages to be written back via other paths. As a result, anonymous writeback might still create seek problems - but only if the swap area shares a spindle with other, high-bandwidth data.

主要的改动深入到 direct reclaim 的循环处理中。当 direct reclaim 在面对一个 “脏” 页需要处理时，现在的逻辑会变得复杂一些（译者注，参考 [代码提交记录][3]）。首先，如果 “脏” 页是匿名页（anonymous page，保存的是进程的数据），则 writeback 的处理还是和以前一样。原因是因为大部分的匿名页将被写回交换区，这比映射文件的物理页的处理逻辑更简单；当然也存在其他一些很少的情况，匿名页会通过其他路径被写回磁盘。所以说，针对匿名页的 writeback 操作过程也还是会引起磁盘搜索（seek）问题的，但这样的情况很少，而且前提是写回的交换区与其他大容量读写所操作的区域恰好在同一个磁盘上。

> For dirty, file-backed pages, the situation is a little different; direct reclaim will no longer try to write back those pages directly. Instead, it creates a list of the dirty pages it encounters, then hands them over to the appropriate background process for the real writeback work. In some cases (such as when [lumpy reclaim](/lwn-211505) is trying to free specific larger chunks of memory), the direct reclaim code will wait in the hope that the identified pages will soon become free. The rest of the time, it simply moves on, trying to find free pages elsewhere.

如果 “脏” 页缓存了文件，则处理的方式会有所不同；在 direct reclaim 处理过程中将不再对其执行直接回写到磁盘的操作。相反，它会将找到的 “脏页” 整理到一个列表中，然后将它们移交给适当的后台进程以进行实际的 writeback 工作（译者注，这部分的逻辑可以参考 [代码提交记录][4]，在正式合入主线时，直接将符合上述条件的页框标记为 `PG_reclaim` 并继续保持在不活跃 LRU 中留给 kswapd 来回收）。在某些情况下（例如当 [lumpy reclaim](/lwn-211505) 正在试图释放某块更大的内存块时），direct reclaim 处理将阻塞自己，并期望自己遇到的 “脏”页会被释放掉。剩下的情况，direct reclaim 则简单地试图在其他地方寻找空闲的页框。

> Handing the reclaim work over to the threads which exist for that task has a couple of benefits. It is, in effect, a simple way of switching to another kernel stack - one which is known to be mostly empty - before heading into the writeback paths. Switching stacks directly in the direct reclaim code had been discussed, but it was decided that the mechanism the kernel already has for switching stacks (context switches) was probably the right thing to use in this situation. Keeping the writeback work in kswapd and the per-BDI writeback threads should also help performance, since those threads try to order operations to minimize head seeks.

将回收工作交给专门用于处理该任务的其他线程有几个好处。首先，这么做是一种简单而有效的切换内核栈的方法，而且我们可以确保新的线程在实际开始处理 writeback 之前内核栈基本上是空的。相关人员曾经就是否可以在 direct reclaim 处理流程中直接切换栈做过一定的讨论，但最终的结论还是在该场景下采用内核中最常用的切换栈技术（即通过切换任务上下文）是最适宜的。另外，让 kswapd 和 per-BDI flusher 线程来负责 writeback 也有助于提高性能，因为这些线程会以有序的方式执行操作，从而最小化磁盘读写头的搜索频率。

> When this problem was discussed in April, Andrew Morton pointed out that, over time, the amount of memory written back in direct reclaim has grown significantly, with an adverse effect on system performance. He wanted to see thought put into why that change has happened rather than trying to mitigate its effects. The final patch in Mel's series looks like an attempt to address this concern. It changes the direct reclaim code so that, if that code starts encountering dirty pages, it pokes the writeback threads and tells them to start cleaning pages more aggressively. The idea here is to keep the normal reclaim mechanisms running at a fast-enough pace that direct reclaim is not needed so often.

在 4 月份讨论这个问题的时候，Andrew Morton 指出，随着内核的升级，direct reclaim 处理中被 writeback 的内存量显著地变多了，这对系统性能产生了负面影响。他希望开发人员研究一下发生这种变化的原因，而不是仅仅试图减少其影响。Mel 提供的补丁中的最后一个修改看起来像是试图要解决这个问题。他修改了 direct reclaim 的代码，如果处理中遇到 “脏”页，它会激活 writeback 线程并让它们更积极地开始清理页框。这里的想法是确保正常的回收机制以足够快的速度运行，这样就可以尽量避免 direct reclaim。

> This tweak seems to have a significant effect on some benchmarks; Mel says:

>     Apparently, background flush must have been doing a better job getting [pages] cleaned in time and the direct reclaim stalls are harmful overall. Waking background threads for dirty pages made a very large difference to the number of pages written back. With all patches applied, just 759 filesystem pages were written back in comparison to 581811 in the vanilla kernel and overall the number of pages scanned was reduced.

这个补丁所做的调整看上去对一些基准测试产生了积极影响；Mel 说：

    显然，后台的回写操作可以更好地及时清理 “脏” 页，相比 direct reclaim 要好得多。采用唤醒后台线程的方式对 writeback 的 “脏” 页数目影响很大。使用主线上的 vanilla 内核 writeback 了 581811 个文件系统的页框，而应用补丁后只回写了 759 个，整体上扫描的页框数也减少了。

> Anybody who likes digging through benchmark results is advised to look at Mel's patch posting - he appears to have run just about every test that he could to quantify the effects of this patch series. This kind of extensive benchmarking makes sense for deep memory management changes, since even small changes can have surprising results on specific workloads. At this point, it seems that the changes have the desired effect and most of the concerns expressed with previous versions have been addressed. The writeback changes, perhaps, are getting ready for production use.

建议所有喜欢深入研究基准测试结果的人都看一下 Mel 发布的补丁，看上去他已经尽了最大的努力，运行了所有可能的测试，对这个补丁系列的运行效果进行了量化和评估。这种广泛的基准测试对于深入修改内存管理方面的代码很有意义，因为即使很小的更改也会由于某些外部运行环境的不同产生令人惊讶的不同结果。就这一点来说，Mel 的补丁修改似乎已经达到了预期的效果，并且已经解决了以前版本中所发现的大多数问题。看起来，这次针对 writeback 的修改已经足够成熟，可以发布用于正式的产品级应用了（译者注，Mel Gorman 的相关补丁修改 [于版本 3.2 合入内核主线][2]）。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/396512/
[2]: https://kernelnewbies.org/Linux_3.2#I.2FO-less_dirty_throttling.2C_reduce_filesystem_writeback_from_page_reclaim
[3]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=ee72886d8ed5d9de3fa0ed3b99a7ca7702576a96
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=49ea7eb65e7c5060807fb9312b1ad4c3eab82e2c
