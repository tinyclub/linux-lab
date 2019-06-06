---
layout: post
author: 'Wang Chen'
title: "LWN 333742: 降低存放可执行指令的页框被换出的可能性"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-333742/
description: "LWN 文章翻译，降低存放可执行指令的页框被换出的可能性"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Being nicer to executable pages](https://lwn.net/Articles/333742/)
> 原创：By corbet @ May 19, 2009
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Anle Huang](https://github.com/hal0936)

> In an ideal world, our computers would have enough memory to run all of the applications we need. In the real world, our systems are loaded with contemporary desktop environments, office suites, and more. So, even with the large amounts of memory being shipped on modern systems, there still never quite seems to be enough. Memory gets paged out to make room for new demands, and performance suffers. Some help may be on the way in the form of a new [patch](http://lwn.net/Articles/333489/) by Wu Fengguang which has the potential to make things better, should it ever be merged.

理想条件下，我们总是希望自己的计算机能够拥有足够的内存来运行所需要的所有应用程序。而现实情况是，我们的系统装满了最新版本的桌面环境，办公套件等等软件。因此，对于一台现代的计算机系统来说，即使安装了大量的内存，结果仍然是不够用。已分配的内存可以被换出（page out）以便为新的需求腾出空间，但因此系统的性能也会受到影响。Wu Fengguang 提交的一个新 [补丁](http://lwn.net/Articles/333489/) 或许可以改进这个问题，当然前提是它可以被顺利地合入内核主线。

> The kernel maintains two least-recently-used (LRU) lists for pages owned by user processes. One of these lists holds pages which are backed up by files - they are the page cache; the other list holds anonymous pages which are backed up by the swap device, assuming one exists. When the kernel needs to free up memory, it will do its best to push out pages which are backed up by files first. Those pages are much more likely to be unmodified, and I/O to them tends to be faster. So, with luck, a system which evicts file-backed pages first will perform better.

内核为用户进程的内存页框维护着两个 “最近最少使用（least-recently-used，简称 LRU）” 链表。其中一个链表中的页框缓存了（磁盘）文件数据，即所谓的页缓存（page cache，译者注，下文统一称页缓存中的页框为 cache page）；另一个链表中的页框我们称之为匿名页（anonymous page，译者注，下文直接使用该称谓不再翻译），其中存放的数据可以被交换到磁盘交换分区（假定该设备存在）。当内核需要释放内存时，它会优先针对 cache page 执行换出操作。这些 page 上的内容更有可能没被修改过，并且对它们的读写速度往往也更快。所以，顺利的话，首先换出 cache page 会使系统表现得更好。（译者注，具体针对页缓存和匿名页 LRU 的介绍可以参考 [这篇 LWN 文章](/lwn-286472/)）

> It may be possible to do things better, though. Certain kinds of activities - copying a large file, for example - can quickly fill memory with file-backed pages. As the kernel works to recover those pages, it stands a good chance of pushing out other file-backed pages which are likely to be more useful. In particular, pages containing executable code are relatively likely to be wanted in the near future. If the kernel pages out the C library, for example, chances are good that running processes will cause it to be paged back in quickly. The loss of needed executable pages is part of why operations involving large amounts of file data can make the system seem sluggish for a while afterward.

然而，（对 LRU 的处理）尚有改进的余地。在执行某些操作，譬如复制大文件时，会快速地申请页框填充页缓存。为了满足分配页框的需要，内核很有可能换出一些或许更有用的 cache page。特别是那些包含了可执行代码的页框，相对来说它们更有可能会在近期被再度使用。举个例子来说，如果换出的页框中存放的恰好是 C 库的代码，那么正在运行的进程极有可能会导致它又被快速地换回来。这也是为何一些涉及大量文件数据的操作可能会使系统在运行一段时间后看起来变得缓慢，其原因之一就是因为一些有用的包含可执行程序的页框被换出了。

> Wu's patch tries to improve the situation through a fairly simple change: when the page reclaim scanning code hits a file-backed, executable page which has the "referenced" bit set, it simply clears the bit and moves on. So executable pages get an extra trip through the LRU list; that will happen repeatedly for as long as somebody is making use of the page. If all goes well, pages running useful code will stay in RAM, while those holding less useful file data will get pushed out first. It should lead to a more responsive system.

Wu 的补丁试图通过一个相当简单的修改来改善这种情况：当页框回收算法的扫描逻辑选中一个包含了可执行程序的 cache page，但发现它的 “引用（“referenced”）” 位被设置了，则只是简单地清除该标志位并继续遍历下一个页框。这么做的效果是拥有可执行代码的页框在 LRU 链表中的生命周期得以延长；并且只要后继又有人访问并使用了该页框，类似的处理将会反复发生。如果一切顺利的话，存放了这些有用的代码的页框将被长时间地保留在缓存中，而那些保存的数据很少被访问的页框将优先被换出。最终的结果就是使得系统对外界的响应变得更快了。（译者注，具体的代码修改参考 [vmscan: make mapped executable pages the first class citizen](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=8cab4754d24a0f2e05920170c845bd84472814c6)）

> The code seems to be in a relatively finished state at this point. So one might well ask whether it will be merged in the near future. That is never a straightforward question with memory management code, though. This patch may well make it into the mainline, but it will have to get over some hurdles in the process. The first of those hurdles is [a simple question](https://lwn.net/Articles/333753/) from Andrew Morton:

>     Now. How do we know that this patch improves Linux?

介绍到这里补丁的修改也就这么多了。人们可能会问，它是否很快会被合入主线呢。很可惜，对于涉及内存管理的代码来说，这绝不是一个可以简单回答的问题。这个补丁很可能会合入主线，但在此过程中还有一些障碍需要克服。第一个障碍来自于 Andrew Morton 提出的一个简单的问题：

    现在。我们怎么知道这个补丁改进了 Linux 的行为？

> Claims like "it feels more responsive" are notoriously hard to quantify. But, without some sort of reasonably objective way to see what benefit is offered by this patch, the kernel developers are going to be reluctant to make changes to low-level memory management heuristics. The fear of regressions is always there as well; nobody wants to learn about some large database workload which gets slower after a patch like this goes in. In summary: knowing whether this kind of patch really makes the situation better is not as easy as one might wish.

众所周知，形如 “感觉上它更灵敏了” 这类说辞缺乏可信的量化指标。如果没有某种合理客观的方式来证明这个补丁的确给 Linux 带来了改进，内核开发人员绝对有充分的理由拒绝这种改动，特别是对像底层内存管理子系统中那些试探（heuristic）算法所做的修改（译者注：Linux 的内存管理子系统中充满了很多基于工程经验所总结出来的优化处理逻辑，通过一些经验公式对系统运行行为进行预测，社区中称之为 heuristics，这里翻译为 “试探”。所以如果期望对这些代码进行修改，唯一可以令人信服的就是提供充分和详细的对比测试报告以供审核，这已经多次在 LWN 的报道中所看到）。对此类补丁是否会导致内核性能衰退的担心总是存在；没有人会希望看到合入补丁后一些大型数据库在工作负载下变得更慢。总而言之：要搞清楚这类修改是否真的能让情况变得更好并不像人们想象的那么简单。

> The second problem is that this change would make it possible for a sneaky application to keep its data around by mapping its files with the "executable" bit set. The answer to this objection is easier: an application which seeks unfair advantage by playing games can already do so. Since anonymous pages receive preferable treatment already, the sneaky application could obtain a similar effect on current kernels by allocating memory and reading in the full file contents. Sites which are truly worried about this sort of abuse can (1) use the memory controller to put a lid on memory use, and/or (2) use SELinux to prevent applications from mapping file-backed pages with execute permission enabled.

第二个问题是，这个补丁会使得某些 “动机不良” 的应用程序可以通过在映射文件时设置 “可执行” 位（译者注，譬如调用 `mmap()` 时对 `prot` 参数指定 `PROT_EXEC`）从而达到使其数据长时间保持在内存中（不被换出）的目的。对这个问题的回答其实更简单：（即使没有合入这个补丁）当前的应用程序也可以通过其他手段达到这种不公平的目的。由于在回收页框过程中，匿名页会受到特殊的待遇（译者注，指相对于页缓存中的页框，匿名页不会被优先换出），因此应用程序完全可以通过分配内存（匿名页）并将文件数据读取并存放在这些内存中（而实现以上目的）。如果真的担心存在这种滥用的情况，可以采取的对策有（1）使用内存控制器（memory controller，译者注，涉及 control group）来限制内存使用，或者（2）使用 SELinux 来阻止应用程序映射文件时启用可执行权限，以上两种方法可以取其一或者同时采用。

> Finally, Alan Cox has [wondered](https://lwn.net/Articles/333758/) whether this kind of heuristic-tweaking is the right approach in the first place:

>     I still think the focus is on the wrong thing. We shouldn't be trying to micro-optimise page replacement guesswork - we should be macro-optimising the resulting I/O performance. My disks each do 50MBytes/second and even with the Gnome developers finest creations that ought to be enough if the rest of the system was working properly.

最后，Alan Cox [怀疑](https://lwn.net/Articles/333758/) 这种对试探（heuristic）算法的调整并不是正确的改进方向：

    我始终认为其着眼点是错误的。我们不应该继续纠缠于基于猜测而在细节上对页框回收算法进行改进，正确的做法应该是从宏观上对读写性能进行优化。在我的系统上，只要其他部分工作正常，即使每个磁盘的吞吐速度只有 50M 字节/秒，运行酷炫的 Gnome 桌面环境也没啥问题。

> Alan is referring to some apparent performance problems with the memory management and block I/O subsystems which crept in a few years ago. Some of these issues [have been addressed](http://lwn.net/Articles/328363/) for 2.6.30, but others remain unidentified and unresolved so far.

Alan 在这里谈到的有关宏观上所需要的改进指的是内存管理和磁盘输入输出（block I/O）子系统上出现的一些明显的性能问题，这些问题近几年来进展缓慢。其中一些问题已经随着 2.6.30 的发布得到了 [解决](http://lwn.net/Articles/328363/)，但到目前为止，还有一些尚未完全解决。

> Wu's patch will not change that, of course. But it may still make life a little better for desktop Linux users. It is sufficiently simple and well contained that, in the absence of clear performance regressions for other workloads, it will probably find its way into the mainline sooner or later.

当然，Wu 的补丁并不会解决 Alan 所谈到的以上问题。但它的确可以让 Linux 的桌面用户感受到更好的响应速度。它足够简单且对其他模块的影响很小，如果没有其他测试表明其会引入明显的性能衰退，相信该补丁迟早会进入主线。（译者注，该补丁随 2.6.31 合入内核主线。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

