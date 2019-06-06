---
layout: post
author: 'Yuan Xiaojie'
title: "LWN 155510: 自适应（Adaptive）文件预读（readahead）算法"
album: "LWN 中文翻译"
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-155510/
description: "LWN 文章翻译，自适应文件预读算法"
category:
  - LWN
tags:
  - Linux
  - page cache
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Adaptive file readahead](https://lwn.net/Articles/155510/)
> 原创：By corbet @ Oct. 12, 2005
> 翻译：By [Xiaojie Yuan](https://github.com/llseek)
> 校对：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]

> Readahead is a technique employed by the kernel in an attempt to improve file reading performance. If the kernel has reason to believe that a particular file is being read sequentially, it will attempt to read blocks from the file into memory before the application requests them. When readahead works, it speeds up the system's throughput, since the reading application does not have to wait for its requests. When readahead fails, instead, it generates useless I/O and occupies memory pages which are needed for some other purpose.

“预读（readahead）” 是内核尝试提高文件读取性能所使用的一种技术。如果内核有理由相信一个文件正在被顺序（sequentially）读取，那么它会在应用程序请求读取该文件之前预先把文件的块（block）读取到内存里。当预读算法生效时，应用程序不需要等待 I/O 请求完成（译者注：因为数据已经被预读到了主存，应用程序就不需要等待磁盘较慢的响应），从而提高了系统的吞吐率。反之，当预读算法失效时，将会产生无用的 I/O 并且占用可作其他用途的内存页面。

> The current kernel readahead implementation uses a window 128KB in length. When readahead seems appropriate, the kernel will speculatively bring in the next 128KB of file data. If the application continues to read sequentially through that data, the next 128KB chunk will be brought in when the application is part-way through the first one. This implementation works, but Wu Fengguang thinks that it can be made better.

目前内核中的预读算法实现使用了一个长度为 128KB 的窗口。当内核认为预读操作合适的时候，它会提前将 128KB 的文件数据读到内存中。如果应用程序在这段数据中继续顺序读取，那么当应用程序正在读这一块的时候，下一块 128KB 的数据将会被预读进内存。这种实现的确能奏效，但是 Wu Fengguang 认为还能进一步改进。

> In particular, Wu thinks that the fixed readahead window size should, instead, adapt to both the application's behavior and the global state of the system. His [adaptive readahead patch](https://lwn.net/Articles/155097/) is an implementation of this thought. It is a work of daunting complexity, but the core ideas are reasonably straightforward.

尤其是 Wu 认为原本固定的预读窗口的大小应该与应用程序的行为和系统的全局状态相适应（译者注：也就是说预读窗口大小应该是可变的）。他的[自适应（adaptive readahead）预读补丁](https://lwn.net/Articles/155097/)实现了这种想法。这项工作的复杂度令人生畏，但是核心的思路很简洁。

> The adaptive readahead patch tries to balance two constraints: readahead should be performed aggressively, but not to the point that the system starts thrashing or readahead pages get recycled before the application uses them. Every time a readahead decision is to be made for a specific file, the adaptive code looks at how much memory is available for readahead and how quickly the application has been working through the file. If memory is tight, or if the disk holding the file is congested, readahead will not be performed at all.

自适应预读补丁试着做了这种权衡：预读需要尽量频繁地执行，除非系统开始发生 “交换失效”（thrashing） 或者预读出来的页面在应用程序使用它们之前就已经被回收了。每次决定是否要对某个文件进行预读时，相应的代码会检查系统有多少可用的内存以及应用程序多快地操作文件。如果内存用量很紧张，或者文件所在的磁盘拥塞，那么预读不会被执行。（译者注：“交换失效” 的一个例子是，当系统内存不足时，PFRA (页框回收算法)全力把页写入磁盘以释放内存并从一些进程窃取相应的页框；而同时这些进程要继续执行，也全力访问它们的页。因此内核把 PFRA 刚释放的页框又分配给这些进程，并从磁盘读回其内容。其结果就是页被无休止地写入磁盘并且再从磁盘读回。大部分的时间耗在访问磁盘上，从而没有进程能实质性地运行下去。以上摘自《深入理解 Linux 内核》第三版 第十七章 交换标记）

> The code also looks at the pressure on the inactive page lists and tries to figure out whether any readahead pages are in danger of falling off that list and being reclaimed. In that situation, the readahead pages will be moved back up the list, keeping them in memory for a bit longer. This "rescue" operation helps to keep previous readahead work from being wasted; since it is only performed when the application consumes data from the file, it will not happen if the reading process has stalled entirely. But, when the application is working through the data, it will get another chance to benefit from readahead which has already been performed. No more readahead will be started in that situation, however.

预读代码也会检查非活跃页面链表（译者注：inactive page list 上的页面会被内核逐步回收）并尝试弄清楚是否有预读页面有被从这个链表移除并且回收的危险。在那种情况下，预读页面会被移回链表头（译者注：内核从链表尾部开始回收页面），从而让它们能在内存中驻留更长时间。这种“急救”操作能够防止之前的预读工作被浪费掉；由于这种操作只在应用程序从文件读取数据的时候执行，所以不会在进程完全停滞(stall)的时候发生。当应用程序正在使用这些数据的时候，这种“急救”操作能让它再一次有机会从预读中受益。然而，在那种情况下（有“急救”操作的情况下），内核不会开始更多的预读。

> If, instead, the application is making use of its readahead pages and the memory is available, the readahead window can grow up to 1MB. For streaming media or data processing applications which work their way sequentially through large files, this enlarged window can lead to significant performance gains.

反之，如果应用程序正在使用预读进来的页面并且系统有可用的内存，那么预读窗口会增长到 1MB 之多。流媒体或者数据处理类型的应用程序会顺序地读取大文件，这种加大后的预读窗口会带来显著的性能提升。

> In fact, Wu claims results which are "pretty optimistic." They include a 20-100% improvement for applications doing parallel reads, and the ability to run 800 1KB/sec simultaneous streams on a 64MB system without thrashing. The page cache hit rate is claimed to be 91%, which is quite good.

事实上，Wu 给出的测试结果 “相当乐观”：执行并行读取的应用程序有 20-100% 的性能提升；在 64MB 内存大小的系统中同时执行800个 1KB 每秒的读取操作不会发生交换失效。页面缓存(page cache)的命中率能达到 91%，这已经相当不错了。

> The adaptive readahead patch might, thus, be a worthwhile addition to the Linux memory management subsystem. There has been little discussion (none, actually) of the patch on the list, however. Complicated patches working in an obscure corner of memory management do not receive the same level of review as, say, new filesystems, it would seem. In any case, a patch of this nature will require a good deal of testing before it can be considered for any sort of merge. So, while adaptive readahead may indeed make its way into the mainline, it's not something to expect to see in the very near future.

这个自适应预读补丁应该是对 Linux 内存管理子系统的一个很有价值的补充。然而目前为止在邮件列表上关于这个补丁的讨论还很少（实际上还没有）。工作在内存管理子系统隐蔽角落里的复杂补丁不会像新的文件系统一样得到相同程度的审阅。无论如何，这种类型的补丁在被考虑合入主线之前需要经过大量的测试。所以尽管这个自适应预读补丁有可能会被合入内核主线，但也不会很快发生。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: http://tinylab.org
