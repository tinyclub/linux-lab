---
layout: post
draft: true
top: false
author: 'Wang Chen'
title: "LWN 600644: 扩展内核栈"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-600644/
description: "LWN 中文翻译，扩展内核栈"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - scheduling
  - stack
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Expanding the kernel stack](https://lwn.net/Articles/600644/)
> 原创：By Jonathan Corbet @ May. 29, 2014
> 翻译：By [unicornx](https://gitee.com/unicornx)
> 校对：By [Xu Wang](https://gitee.com/wangxuszcn)

> Every process in the system occupies a certain amount of memory just by existing. Though it may seem small, one of the more important pieces of memory required for each process is a place to put the kernel stack. Since every process could conceivably be running in the kernel at the same time, each must have its own kernel stack area. If there are a lot of processes in the system, the space taken for kernel stacks can add up; the fact that the stack must be physically contiguous can stress the memory management subsystem as well. These concerns have always provided a strong motivation to keep the size of the kernel stack small.

系统中的每个进程一旦被创建就会占用一定数量的内存。其中比较重要的一块内存用于内核栈（尽管内核栈所占空间不大）。考虑到内核中多个进程可以并发运行，所以每个进程必须拥有自己的内核栈区。因此当系统中有很多进程时，用于内核栈的内存累积起来也相当可观；同时用于栈的内存要求必须在物理上连续，这也给内存管理子系统带来了不小的压力。出于对这些问题的担忧，内核开发中一直追求将内核栈定义得比较小。

> For most of the history of Linux, on most architectures, the kernel stack has been put into an 8KB allocation — two physical pages. As recently as 2008 some developers [were trying to shrink the stack to 4KB](https://lwn.net/Articles/279229/), but that effort eventually proved to be unrealistic. Modern kernels can end up creating surprisingly deep call chains that just do not fit into a 4KB stack.

在 Linux 发展历史的大部分时间里，针对大多数的体系架构，内核栈都按照 8KB 的大小进行分配，即两个物理页面。直到 2008 年，一些开发人员 [试图将栈缩小到 4KB][6]，但最终证明这种努力是不现实的。现代内核运行中的函数调用栈可能会非常深，导致 4KB 的栈根本无法容纳。

> Increasingly, it seems, those call chains don't even fit into an 8KB stack on x86-64 systems. Recently, Minchan Kim tracked down a crash that turned out to be a stack overflow; he [responded](https://lwn.net/Articles/600645/) by proposing that it was time to double the stack size on x86-64 to 16KB. Such proposals have seen resistance before, and that happened this time around as well; Alan Cox [argued](https://lwn.net/Articles/600646/) that the solution is to be found elsewhere. But he seems to be nearly alone in that point of view.

在 x86-64 系统上，甚至发现 8KB 的栈空间也不够了。最近，Minchan Kim 跟踪了一次栈溢出引起的系统崩溃。他 [给出][1] 的建议是将 x86-64 上的栈大小增加一倍，达到 16KB。类似的提议以前曾遭到了反对，这次也不例外。Alan Cox [认为][2]，应该可以找到其他的解决方案。但这次似乎没有人同意他的观点。

> Dave Chinner often has to deal with stack overflow problems, since they often occur with the XFS filesystem, which happens to be a bit more stack-hungry than others. He was [quite supportive](https://lwn.net/Articles/600647/) of this change:

Dave Chinner 经常需要处理栈溢出的问题，这是由于和其他文件系统比起来，XFS 对内核栈的需求更大，导致 XFS 经常发生此类问题。他 [非常支持][3] 扩大栈空间的提议：

> `8k stacks were never large enough to fit the linux IO architecture on x86-64, but nobody outside filesystem and IO developers has been willing to accept that argument as valid, despite regular stack overruns and filesystem having to add workaround after workaround to prevent stack overruns.`

`对于 x86-64 上的 linux IO 架构来说，8k 大小的栈从来就不够用，但是文件系统和 IO 之外的开发人员从来就不愿意接受扩大这个值，所以每次栈溢出后只好在文件系统内部提供临时的解决方案。`

> Linus was unconvinced at the outset, and he [made it clear](https://lwn.net/Articles/600649/) that work on reducing the kernel's stack footprint needs to continue. But Linus, too, seems to have come around to the idea that playing "whack-a-stack" is not going to be enough to solve the problem in a reliable way:

Linus 一开始不确定是否要按照 Minchan 的建议扩大内核栈，他 [解释说][4] 优化内核栈使用的工作仍然需要继续。但是，Linus 似乎也感觉纠结于维持栈的大小对于最终解决问题并不是一个很靠谱的想法：

> `[S]o while I am basically planning on applying that patch, I _also_ want to make sure that we fix the problems we do see and not just paper them over. The 8kB stack has been somewhat restrictive and painful for a while, and I'm ok with admitting that it is just getting _too_ damn painful, but I don't want to just give up entirely when we have a known deep stack case.`

`我只是希望在决定接受这个修改的同时，我们仍然能够把目前明确看到的问题解决掉而不是就这么算了。8kB 的栈的问题已经有一段时间了，我承认它给我们带来了很多麻烦，但我希望在扩大它之前能够对栈的问题再深入研究一下。`

> Linus has also, unsurprisingly, made it clear that he is not interested in changing the stack size in the 3.15 kernel. But the 3.16 merge window can be expected to open in the near future; at that point, we may well see this patch go in as one of the first changes.

Linus 明确表示他对在 3.15 内核中引入修改栈大小不感兴趣。但是，可以预料 3.16 的合并窗口很快就会打开；到那时，这个补丁将很可能会成为第一批合入的补丁之一。（译者注，Minchan 对 x86_64 栈空间大小的修改最终还是随 3.15 版本和入了，具体的 commit 可以参考 [“x86_64: expand kernel stack to 16K”][5]。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://lwn.net/Articles/600645/
[2]: https://lwn.net/Articles/600646/
[3]: https://lwn.net/Articles/600647/
[4]: https://lwn.net/Articles/600649/
[5]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=6538b8ea886e472f4431db8ca1d60478f838d14b
[6]: https://lwn.net/Articles/279229/


