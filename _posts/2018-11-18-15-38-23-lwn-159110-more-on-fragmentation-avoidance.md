---
layout: post
author: 'Guo Chumou'
title: "LWN 159110: 更多有关避免内存碎片化的报道（More on fragmentation avoidance）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-159110/
description: "LWN 文章翻译，更多有关避免内存碎片化的报道"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[More on fragmentation avoidance](https://lwn.net/Articles/159110/)
> 原创：By corbet @ Nov. 8, 2005
> 翻译：By [simowce](https://github.com/simowce)
> 校对：By [unicornx](https://github.com/unicornx)

> [Last week's article](http://lwn.net/Articles/158211/) on fragmentation avoidance concluded with these famous last words:

>     But there are legitimate reasons for wanting this capability in the kernel, and the issue is unlikely to go away. Unless somebody comes up with a better solution, it could be hard to keep Mel's patch out forever.

[上周关于避免碎片化的文章][3] 在最后提到：

    但是我们真的有那么多的理由为内核添加这种功能啊，所以这个问题不太可能就此结束。除非有人提出更好的解决方案，否则我相信 Mel 的补丁迟早还是会被合入内核主线的。

> One thing which *can* keep a patch out of the kernel, however, is opposition from Linus, and that is what has happened in this case. His [position](https://lwn.net/Articles/159111/) is that fragmentation avoidance is "totally useless," and he concludes:

>     Don't do it. We've never done it, and we've been fine.

当然只有一种情况能够阻止一个补丁进入内核主线，那就是 Linus 先生也对此表示反对，而在这件事上他确实也这么做了。Linus [认为][2]避免碎片化是 “完全没用的”，他的原话如下：

    别这么干。我们从来没有这么做过，也没见出过什么问题。

> The right solution, according to Linus, is to create a special memory zone on the (rare) systems which need to be able to free up large, contiguous blocks of memory. Kernel memory allocations would not be allowed in that zone, so it would only contain user-space pages. Those pages are relatively easy to move when the need arises, so most needs would be satisfied. A certain amount of kernel tuning would be required, but that is the price to be paid for running highly-specialized applications.

Linus 认为，正确的解决方案是针对那些（少数）需要清理出大量物理上连续的内存块的系统创建一个特殊的域（zone）。这个域中不允许分配内核地址空间的页框，因此只会有用户地址空间的页框。当需要分配物理上连续的大内存时，这些页框相对来说比较容易迁移，从而满足大部分的需求。采用这种方案需要一些额外的，内核上的调优，但这也是为了满足这种特定需求所必须付出的代价。

> This approach is not pleasing to everybody involved. Andi Kleen [noted](https://lwn.net/Articles/159112/):

>     You have two choices if a workload runs out of the kernel allocatable pages. Either you spill into the reclaimable zone or you fail the allocation. The first means that the huge pages thing is unreliable, the second would mean that all the many problems of limited lowmem would be back.

可是 Linus 的这个方案并没有让所有人满意。Andi Kleen [指出][4]:

    当内核可分配内存耗尽时你现在有两个选择，要么是从这个特殊的域（zone）中分配页框，要么就让本次内存分配失败。采用第一种方式意味着针对巨页的分配请求并不能被可靠地满足（译者注，之所以不可靠，即参考上面 Linus 的想法，这个特殊的 zone 里的页必须要满足是可回收的，即必须是用于用户空间的，那么对于如果请求分配的巨页是用于内核空间的情况就会失败。），而第二种方式则意味着我们又得重新面对类似原先处理有限的低端内存时所遇到的那些问题。

> Others have noted that it can be hard to tune a machine for all workloads, especially on systems with a large number of users. Objections notwithstanding, it begins to look like active fragmentation avoidance is not likely to go into the 2.6 kernel anytime soon.

其他人还指出，针对一台设备的所有工作负载情况进行调优是非常困难的，特别是那些有大量用户的系统。因此，尽管 Linus 的提议遭到了不少反对（译者注，这些反对的声音实际上起到了支持 Mel 先生的作用），但是 Mel 的主动避免内存碎片（active fragmentation avoidance）补丁看上去还是不会很快被 2.6 版本的内核所接纳。


[1]: http://tinylab.org
[2]: https://lwn.net/Articles/159111/
[3]: /lwn-158211/
[4]: https://lwn.net/Articles/159112/
