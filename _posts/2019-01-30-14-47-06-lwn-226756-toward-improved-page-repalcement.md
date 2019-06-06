---
layout: post
author: 'Wang Chen'
title: "LWN 226756: 改进页框回收（page replacement）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-226756/
description: "LWN 改进页框回收"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Toward improved page replacement](https://lwn.net/Articles/226756/)
> 原创：By corbet @ Mar. 20, 2007
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Shaowei Wang](https://github.com/shaoweiaaron)

（译者注：标题中的 “page replacement” 在 Linux 中也被称为 “Page Frame Reclaiming”， 即 “页框回收” 的另一种说法，为统一起见，本文统一翻译为 “页框回收”。）

> When memory gets tight (a situation which usually comes about shortly after starting an application like tomboy), the kernel must find a way to free up some pages. To an extent, the kernel can free memory by cleaning up its own internal data structures - reducing the size of the inode and dentry caches, for example. But, on most systems, the bulk of memory will be occupied by user pages - that is what the system is there for in the first place, after all. So the kernel, in order to accommodate current demands for user pages, must find some existing pages to toss out.

当内存变得紧张时（通常在启动像 tomboy 这样的应用程序后不久就会出现这种情况），内核必须找到一种方法来释放一些（已被占用的）内存页。在某种程度上，内核可以通过清理自己的内部数据结构来释放内存，例如，通过减少 inode 和 dentry 缓存的大小。但是，在大多数系统中，用户态内存页占用了所消耗的内存量的大头，毕竟，系统存在的第一要旨就是为应用服务。因此，为了满足当前（应用）对用户态内存页的分配需求，内核必须找到并释放（清理）一些已分配的内存页。

> To help in the choice of pages to remove, the kernel maintains two big linked lists for each memory zone. The "active" list contains pages which have been recently accessed, while the "inactive" list has those which have not been used in the recent past. When the kernel looks for pages to evict, it will scan through the inactive list, in the theory that the pages least likely to be needed soon are to be found there.

为了帮助挑选要清理的内存页，内核为每个内存域（zone）维护了两个大的链表。一个链表称之为 “活动” （“active”）链表，它保存了最近访问过的内存页，而另一个链表称之为 “非活动”（“inactive”）链表，包含了最近未使用过的内存页（译者注，下文直接使用 “active list” 和 “inactive list”， 不再翻译）。当内核在查找要清理的内存页时，它会扫描 inactive list，因为理论上那些近期最不可能会被访问到的页应该就在该链表上。

> There is an additional complication, though: there are two fundamental types of pages to be found on these lists. "Anonymous" pages are those which are not associated with any files on disk; they are process memory pages. "Page cache" pages, instead, are an in-memory representation of (portions of) files on the disks. A proper balance between anonymous and page cache pages must be maintained, or the system will not perform well. If either type of page is allowed to predominate at the expense of the other, thrashing will result.

但仔细考虑一下你会发现另一个复杂的问题：我们可以把这些链表上的内存页划分为两种基本类型。一种称之为 “匿名”（“anonymous”）页，它们与磁盘上的任何文件都无关；这些内存页保存了进程的内容（译者注，譬如用户通过 malloc 或者 mmap 申请的内存等）。另一种称之为 “页缓存”（“page cache”），保存了磁盘上文件（或者文件的一部分）的内容（译者注，下文直接使用 “anonymous page” 和 “cache page” 来指代这两种内存页，不再翻译为中文）。必须维持 anonymous page 和 cache page 之间数量上的适当平衡，否则系统将无法正常运行。无论是通过牺牲哪一种内存页为代价而让另一种内存页在数量上占优势，都会导致一种称之为 “交换失效” 的现象。（thrashing，译者注，具体参考 [Wiki 的定义](https://en.wikipedia.org/wiki/Thrashing_(computer_science))，具体表现为 “当系统内存不足时，页框回收算法（Page Frame Reclaiming Algrithom，简称 PFRA），会全力把页框上的内容写入磁盘以便回收这些本属于进程的页框；而同时由于这些进程要继续执行，也会努力申请页框存放（譬如缓存）其内容。因此内核把 PFRA 刚释放的页框又分配给这些进程，并从磁盘读回其内容。其结果就是数据被无休止地写入磁盘并且再从磁盘读回。大部分的时间耗费在访问磁盘上，而进程则无法实质性地运行下去。（摘自《深入理解 Linux 内核》第三版 第十七章 的 “The Swap Token” 一节））

> The kernel offers a knob called [swappiness](http://lwn.net/Articles/83588/) which controls how this balance is struck. If the system administrator sets a higher value of swappiness, the kernel will allow the page cache to occupy a larger portion of memory. Setting swappiness to a very low value is a way to tell the kernel to keep anonymous pages around at the expense of the page cache. In general, the system can be expected to perform better if page cache pages are reclaimed first; they can often be reclaimed without needing to be written back to disk, and their layout on the disk can make recovery faster should they be needed again. For this reason, the default value for swappiness favors the eviction of page cache pages; anonymous pages will only be targeted when memory pressure becomes relatively severe.

内核提供了一个名为 [swappiness](http://lwn.net/Articles/83588/) 的控制项（译者注， `/proc/sys/vm/swappiness`），可以调节这种平衡。如果系统管理员设置的 swappiness 值较高，则意味着内核允许在内存中保留较多的 cache page。将 swappiness 调低则是告诉内核回收更多的 cache page，保留较多的 anonymous page。通常，为了让系统运行得更好，我们倾向于先回收 cache page；因为大部分情况下回收 cache page 时并不需要将页框上的内容写回磁盘，并且如果再次需要的话，得益于磁盘上文件数据的布局比较紧凑所以将其恢复到内存的速度也更快。出于这个原因，swappiness 的默认值一般设置为有利于回收更多的 cache page；只有当内存压力变得相对严重时，才会选择回收 anonymous page。

> Swappiness clearly affects how the process of scanning pages for eviction candidates is done. If swappiness is low, anonymous pages will simply be passed over. As it turns out, this behavior can lead to performance problems; there may be a lot of anonymous pages which must be scanned over before the kernel finds any page cache pages, which are the ones it was looking for in the first place. It would be nice to avoid all of that extra work, especially since it comes at a time when the system is already under stress.

swappiness 的取值会明显影响为了挑选页框用于回收而对链表执行扫描的处理过程。如果 swappiness 值较低，将简单地忽略 anonymous page。事实证明，这种扫描行为可能导致性能问题；因为可能在内核找到合适的 cache page 之前需要过滤很多的 anonymous page。如果能够避免这些额外的遍历操作会更好，特别是当系统已经处于较高压力下的时候。

> Rik van Riel has posted [a patch](http://lwn.net/Articles/226658/) which tries to improve this situation. The approach taken is quite simple: the active and inactive lists are each split into two new lists: one pair (active and inactive) for anonymous pages and one pair for page cache pages. With separate lists for the page cache, the kernel can go after those pages without having to iterate over a bunch of uninteresting anonymous pages on the way. The result should be better scalability on larger systems.

Rik van Riel 发布了 [一个补丁](http://lwn.net/Articles/226658/) 试图改善这种情况。采用的方法非常简单：就是将 active list 和 inactive list 各自分别拆分为两个新的链表：一对（active 和 inactive）用于 anonymous page，一对用于 cache page。使用单独的 cache page 链表的好处是，内核可以在扫描这些 page 的过程中无需再处理一堆无关的 anonymous page。这么改进的结果应该会给更大的系统带来扩展性上的性能改进。

> The idea is simple, but the patch is reasonably large. Any code which puts pages onto one of the lists must be changed to specify which list is to be used; that requires a number of small changes throughout the memory management and filesystem code. Beyond that, the current patch does not really change how the page reclamation code works, though Rik does note:

>     For now the swappiness parameter can be used to tweak swap aggressiveness up and down as desired, but in the long run we may want to simply measure IO cost of page cache and anonymous memory and auto-adjust.

虽然思路很简单，但补丁的改动相当大。代码中所有涉及将页框添加到链表上的操作都必须补充说明具体添加的是哪一个链表；这需要对整个内存管理和文件系统的代码都进行一些小的更改。除此之外，当前的补丁本质上并没有改变页框回收代码的工作方式，尽管 Rik 确实提出：

    目前，swappiness 参数可用于根据需要调整交换（swap）的力度大小，但从长远来看，我们更期望通过简单检测 cache page 和 anonymous page 对磁盘读写的开销来实现自动调节。

> There tends to be a lot of sympathy for changes which remove tuning knobs in favor of automatic adaptation within the kernel itself. So if this approach could be made to work, it might well be adopted. Getting system tuning right is hard; it's often better if the computer can figure it out by itself.

对于在内核内部采用自适应的方式实现调节从而避免人工介入自然受到大家的欢迎。因此，如果可行的话，采用这种方法势必会被采纳。人为地对系统进行调优是一件困难的事情；如果计算机可以自己搞定通常会更好。

> Meanwhile, the list-splitting patch, so far, lacks widespread testing or benchmarking. So, at this point, it is difficult to say when (or in what form) this patch will find its way into the mainline.

同时，到目前为止，这个拆分链表（list-splitting）补丁还缺乏广泛的测试或基准测试。因此，考虑到这一点，还很难说清楚这个补丁会在何时（或以何种形式）被合入内核主线。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: http://tinylab.org
