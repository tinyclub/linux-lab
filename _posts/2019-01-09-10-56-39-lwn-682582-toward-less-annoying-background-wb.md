---
layout: post
author: 'Wang Chen'
title: "LWN 682582: 改进后台回写（writeback）引入的延迟"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-682582/
description: "LWN 文章翻译，改进后台回写（writeback）引入的延迟"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Toward less-annoying background writeback](https://lwn.net/Articles/682582/)
> 原创：By corbet @ Apr. 13, 2016
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> It's an experience many of us have had: write a bunch of data to a relatively slow block device, then try to get some other work done. In many cases, the system will slow to a crawl or even appear to freeze for a while; things do not recover until the bulk of the data has been written to the device. On a system with a lot of memory and a slow I/O device, getting things back to a workable state can take a long time, sometimes measured in minutes. Linux users are understandably unimpressed by this behavior pattern, but it has been stubbornly present for a long time. Now, perhaps, a new patch set will improve the situation.

我们中的许多人或许都尝试过如下操作：在将一堆数据写入一个相对较慢的块设备后，再试着执行其他工作。在许多情况下，系统的反应会很慢，甚至有一段时间看起来好像停住不动了；直到对该设备的大量数据写入完成之后，系统才恢复正常。对于一个内存很大但输入输出设备的处理速度很慢的系统，在上述操作下恢复正常所需要的时间会更长，甚至以分钟计。可想而知，Linux 用户绝不会喜欢这种行为表现，但无奈的是这个问题已经存在了很长一段时间（也没有被解决）。现在，一个新的补丁集或许将改变这种状况。

> That patch set, from block subsystem maintainer Jens Axboe, is titled "[Make background writeback not suck](https://lwn.net/Articles/681763/)." "Background writeback" here refers to the act of flushing block data from memory to the underlying storage device. With normal Linux buffered I/O, a `write()` call simply transfers the data to memory; it's up to the memory-management subsystem to, via writeback, push that data to the device behind the scenes. Buffering writes in this manner enables a number of performance enhancements, including allowing multiple operations to be combined and enabling filesystems to improve layout locality on disk.

这个补丁集由块子系统（block subsystem）的维护者 Jens Axboe 开发，补丁标题为 [“改进后台回写”（“Make background writeback not suck”）](https://lwn.net/Articles/681763/) 。这里的 “后台回写（Background writeback）” 指的是将块数据从缓存中刷新（flushing）到底层存储设备的行为。当我们执行 `write()` 系统调用时，正常情况下，基于 Linux 的读写缓充区（buffered I/O）技术，写入的数据将被缓存在内存里；然后由内存管理子系统通过回写（writeback，译者注，下文直接使用不再翻译）的方式将数据推送（push）到底层的存储设备。在写入操作中利用缓存对提升性能有很多好处，包括将多次写入操作累积合并起来（一次性 writeback 入磁盘），这么做可以方便文件系统改进数据在磁盘上的布局（译者注，使得连续的数据在磁盘上的存放也是连续的）。

> So how is it that a performance-enhancing technique occasionally leads to such terrible performance? Jens's diagnosis is that it has to do with the queuing of I/O requests in the block layer. When the memory-management code decides to write a range of dirty data, the result is an I/O request submitted to the block subsystem. That request may spend some time in the I/O scheduler, but it is eventually dispatched to the driver for the destination device. Getting there requires passing through a series of queues.

为何采用了这种可以增强性能的技术后，反而在某些情况下又会引起如此糟糕的表现呢？Jens 诊断后发现这个问题和块层（block layer，译者注，下文直接使用不再翻译） 中的 I/O 请求队列有关。当内存管理模块决定向磁盘写入一系列 “脏” 页的数据时，会向 block 子系统提交一个 I/O 请求。I/O 调度器（I/O scheduler）处理该请求需要花费一段时间，在最终将其分派给目标设备的驱动程序之前，需要经历一系列排队处理。

> The problem is that, if there is a lot of dirty data to write, there may end up being vast numbers (as in thousands) of requests queued for the device. Even a reasonably fast drive can take some time to work through that many requests. If some other activity (clicking a link in a web browser, say, or launching an application) generates I/O requests on the same block device, those requests go to the back of that long queue and may not be serviced for some time. If multiple, synchronous requests are generated — page faults from a newly launched application, for example — each of those requests may, in turn, have to pass through this long queue. That is the point where things appear to just stop.

问题是，当存在大量的 “脏” 数据需要写入磁盘时，最终可能会出现大量（高达数千个）的请求需要排队等待设备。即便该设备处理性能很强也需要相当长的一段时间才能处理完这么多的请求。如果同时还发生其他的活动（譬如点击了 Web 浏览器中的链接，或者启动应用程序）也对同一个块设备发起 I/O 请求，则这些新的请求必然会被排在一个长长的队列的尾部，可能在很长一段时间内都得不到处理。如果此时恰好还生成了多个同步的读写请求，譬如一个新启动的应用程序触发了缺页（page faults）处理，那么这些请求同样也要经历这个长长的队列。最后看到的现象就是整个系统似乎都停止不动了。

> In other words, the block layer has a [bufferbloat](https://lwn.net/Articles/616241/) problem that mirrors the issues that have been seen in the networking stack. Lengthy queues lead to lengthy delays.

换句话说，block layer 中的这个问题有点类似于网络栈中曾经发现的一个 [bufferbloat](https://lwn.net/Articles/616241/) 问题。都是因为过长的队列导致了较长的延迟。

> As with bufferbloat, the answer lies in finding a way to reduce the length of the queues. In the networking stack, techniques like [byte queue limits](https://lwn.net/Articles/454390/) and [TCP small queues](https://lwn.net/Articles/507065/) have mitigated much of the bufferbloat problem. Jens's patches attempt to do something similar in the block subsystem.

与 bufferbloat 问题一样，解决的思路在于找到一种方法减小队列的长度。在网络栈中，采用的方法有 [byte queue limits](https://lwn.net/Articles/454390/) 和 [TCP small queues](https://lwn.net/Articles/507065/)，这些技术已经缓解了大部分 bufferbloat 问题。Jens 的补丁也尝试针对 block 子系统做类似的改进。

## 解决队列的问题（Taming the queues）

> Like networking, the block subsystem has queuing at multiple layers. Requests start in a submission queue and, perhaps after reordering or merging by an I/O scheduler, make their way to a dispatch queue for the target device. Most block drivers also maintain queues of their own internally. Those lower-level queues can be especially problematic since, by the time a request gets there, it is no longer subject to the I/O scheduler's control (if there is an I/O scheduler at all).

与网络一样，block 子系统在多个层中都会排队。发起的请求首先进入一个提交队列（submission queue），经过 I/O 调度器（I/O scheduler）的处理（包括排序或者合并）后，这些请求会进入另一个分发队列（dispatch queue），等待被分发到相应的设备上。大多数块设备的驱动程序内部也会维护自己的队列。那些较低层次的队列（译者注，指驱动程序中的队列）尤其会有问题，因为这些队列并不受 I/O 调度器的控制（虽然内核中是存在 I/O 调度器的）。

> Jens's patch set aims to reduce the amount of data "in flight" through all of those queues by throttling requests when they are first submitted. To put it simply, each device has a maximum number of buffered-write requests that can be outstanding at any given time. If an incoming request would cause that limit to be exceeded, the process submitting the request will block until the length of the queue drops below the limit. That way, other requests will never be forced to wait for a long queue to drain before being acted upon.

Jens 的补丁集旨在通过从一开始就限制提交的请求来减少所有队列中等待处理（in flight）的请求的数量。简而言之，每个设备都设定一个等待队列的最大限制值。如果新提交的请求将导致超出该限制值，则提交请求的进程将被阻塞，直到队列长度低于限制。这样，其他请求就不会因为等待队列太长而无法得到执行了。

> In the real world, of course, things are not quite so simple. Writeback is not just important for ensuring that data makes it to persistent storage (though that is certainly important enough); it is also a key activity for the memory-management subsystem. Writeback is how dirty pages are made clean and, thus, available for reclaim and reuse; if writeback is impeded too much, the system could find itself in an out-of-memory situation. Running out of memory can lead to other user-disgruntling delays, along with unleashing the OOM killer. So any writeback throttling must be sure to not throttle things too much.

当然，在现实世界中，事情并非如此简单。Writeback 不仅对确保缓存数据能够被及时同步到持久存储非常重要（尽管这当然非常重要）；它也是内存管理子系统所负责的一项关键工作。“脏” 页只有通过 writeback 才能得到及时清理，从而使得它们可被用于回收（reclaim）和重用（reuse）；如果 writeback 受到太多阻碍（译者注，指上节所介绍的补丁集在设备队列满时会阻塞执行 writeback 的 flusher 线程），系统可能会发现自己陷入了内存不足（out-of-memory）的境地。内存不足会引起其他导致用户不满的延迟，同时还会触发内核执行 OOM 清理（OOM killer）。所以任何对 writeback 的抑制（throttling）动作必须考虑 “适度”。

> The patch set tries to avoid such unpleasantness by tracking the reason behind each buffered-write operation. If the memory-management subsystem is just pushing dirty pages out to disk as part of the regular task of making their contents persistent, the queue limit applies. If, instead, pages are being written to make them free for reclaim — if the system is running short of memory, in other words — the limit is increased. A higher limit also applies if a process is known to be waiting for writeback to complete (as might be the case for an `fsync()` call). On the other hand, if there have been any non-writeback requests within the last 100ms, the limit is reduced below the default for normal writeback requests.

补丁集试图通过区分每个执行缓冲写（buffered-write）操作背后的原因（对抑制进行调整）来满足操作上的 “适度” 要求。如果内存管理子系统只是为了正常的同步将 “脏” 页推送到磁盘，则简单地对队列应用缺省的限制。相反，如果在 writeback 的同时发现系统内存不足，则抑制力度会增加。如果已知进程正在等待 writeback 完成（如执行 `fsync()` 的情况），则启用更高的抑制。另一方面，如果在最近 100ms 内的读写请求都和 writeback 无关，则将抑制力度降低到低于正常 writeback 请求的默认值。

> There is also a potential trap in the form of drives that do their own write caching. Such drives will indicate that a write request has completed once the data has been transferred, but that data may just be sitting in a cache within the drive itself. In other words, the drive, too, may be maintaining a long queue. In an attempt to avoid overfilling that queue, the block layer will impose a delay between write operations on drives that are known to do caching. That delay is 10ms by default, but can be tweaked via a sysfs knob.

如果驱动中实现了自己私有的写缓存（write caching），也会存在潜在的问题。对于这样的驱动，它会在收到写数据的请求后立即返回成功，但该数据可能只被放在驱动自身的高速缓存中（并没有被真正写到存储设备上）。换句话说，驱动中也可能维护着一个长的队列。为了避免该队列中缓存的数据太多，block layer 会针对这类支持私有缓存的设备驱动在发起写请求之间添加延迟。默认情况下，该延迟值为 10 毫秒，但可以通过 sysfs 暴露的接口进行调整。

> Jens tested this work by having one process write 100MB each to 50 files while another process tries to read a file. The reading process will, on current kernels, be penalized by having each successive read request placed at the end of a long queue created by all those write requests; as might be expected, it performs poorly. With the patches applied, the writing processes take a little longer to complete, but the reader runs much more quickly, with far fewer requests taking an inordinately long period of time.

Jens 对该补丁执行了如下测试，一个进程负责对 50 个文件执行写操作，每个文件写入 100MB，另一个进程尝试读取另一个文件。在当前内核上，由于写请求很多导致 I/O 请求队列很长，所以每个读请求只好排在队列的末尾；正如预料的那样，读操作表现不佳。应用补丁后，写入过程需要花费的时间会稍微长一点，但读出的速度要比以前快得多，那些执行时间过长的请求数量少了很多。

> This is an early-stage patch set; it is not expected to go upstream in the near future. Patches that change memory-management behavior can often cause unexpected problems with different workloads, so it takes a while to build confidence in a significant change, even after the development work is deemed to be complete (which is not the case here). Indeed, Dave Chinner has already [reported](https://lwn.net/Articles/683353/) a performance regression with one of his testing workloads. The tuning of the queue-size limits also needs to be made automatic if possible. There is clearly work still to be done here; the patch set is also likely to be a subject of discussion at the upcoming [Linux Storage, Filesystem, and Memory-Management Summit](http://events.linuxfoundation.org/events/linux-storage-filesystem-and-mm-summit). So users will have to wait a bit longer for this particular annoyance to be addressed.

这个补丁集目前还处在开发阶段的早期；预计进入内核主线还需要一段时间。对内存管理行为的修改在不同的工作环境下往往会引起意想不到的问题，所以如果改动较大则要花费较长的时间才能获得大家的认可，即便是开发工作已经完成的情况下（而本文所介绍的补丁开发工作显然还没有达到这个程度）。实际上，Dave Chinner 已经 [报告了](https://lwn.net/Articles/683353/) 在他的一个测试中发现了一定程度的性能倒退。另外，如果可能，对队列大小限制的调整最好是自动的。显然还有很多工作要做；这个补丁集可能会作为即将到来的 [Linux 存储，文件系统和内存管理峰会](http://events.linuxfoundation.org/events/linux-storage-filesystem-and-mm-summit) 中的一个主题进行讨论。因此，在这个问题被彻底解决之前，用户还需要再耐心等待一段时间。（译者注，该补丁集最终随 4.10 合入内核主线。）

  [1]: http://tinylab.org
