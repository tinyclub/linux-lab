---
layout: post
author: 'Wang Chen'
title: "LWN 685894: 后台回写（Background writeback）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-685894/
description: "LWN 文章翻译，后台回写"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Background writeback](https://lwn.net/Articles/685894/)
> 原创：By Jake Edge @ May. 4, 2016
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Wen Yang](https://github.com/w-simon)

> The problems with [background writeback](https://lwn.net/Articles/682582/) in Linux have been known for quite some time. Recently, there has been an effort to apply what was learned by network developers [solving the bufferbloat problem](https://lwn.net/Articles/616241/) to the block layer. Jens Axboe led a filesystem and storage track session at the 2016 Linux Storage, Filesystem, and Memory-Management Summit to discuss this work.

Linux 中的 [后台回写（background writeback）](/lwn-682582/) 问题已经为大家所了解有一段时间了。最近，社区正努力尝试将网络子系统的开发人员在 [解决 bufferbloat 问题][1] 上的经验移植到块设备子系统中来。Jens Axboe 在 2016 年年度 Linux 存储，文件系统和内存管理峰会上主持了一个有关文件系统和存储最新动态的会议，以讨论这项工作。

> The basic problem is that flushing block data from memory to storage (writeback) can flood the device queues to the point where any other reads and writes experience high latency. He has posted several versions of [a patch set](https://lwn.net/Articles/685236/) to address the problem and believes it is getting close to its final form. There are fewer tunables and it all just basically works, he said.

这个问题的根本原因在于：writeback 在将块数据从内存刷新到存储设备上时，可能会在设备队列上产生太多的读写请求，这会影响其他的，对同一个存储设备的读取和写入操作，甚至导致产生很大的延迟。针对该问题他提交的 [补丁][2] 已经迭代了好几个版本，相信离最终提交已为时不远。Axboe 说，可调整的地方已经不多并且基本上可以正常工作了。

![Jens Axboe](https://static.lwn.net/images/2016/lsf-axboe-sm.jpg)

> The queues are managed on the device side in ways that are "very loosely based on [CoDel](https://en.wikipedia.org/wiki/CoDel)" from the networking code. The queues will be monitored and write requests will be throttled when the queues get too large. He thought about dropping writes instead (as CoDel does with network packets), but decided "people would be unhappy" with that approach.

目前设备端队列的管理方式借鉴了一部分网络子系统中所采用的 [CoDel 算法][3] 的思想。通过在运行过程中监控队列的状态并在队列过长时抑制（throttle）对设备的写入请求。他曾经考虑参考网络数据报处理中应用 CoDel 算法的方式，当队列最大长度超过限制时，直接丢弃写入请求，但因为考虑到 “大家一定会对这种方法不满意”，所以最终并没有这么做。（译者注，有关代码中基于 CoDel 算法的修改参考补丁 [blk-wbt: add general throttling mechanism][4]）

> The problem is largely solved at this point. Both read and write latencies are improved, but there is still some tweaking needed to make it work better. The algorithm is such that if the device is fast enough, it "just stays out of the way". It also narrows in on the right queue size quickly and if there are no reads contending for the queues, it "does nothing at all". He did note that he had not yet run the "crazy Chinner [test case](https://lwn.net/Articles/683353/)" again.

通过如上方式这个问题在很大程度上得到了解决。读取和写入延迟都得到了改进，但最新的补丁中又加入了一些优化使其工作得更好（译者注，最新的补丁版本 [PATCHSET v5][5] 中添加的一个比较大的改动就是对可调参数实现动态自适应）。该优化算法是这样的，如果设备足够快，则抑制并不会发生（"just stays out of the way"）。新算法可以快速缩小队列的大小到合适的程度，并且如果对同一个设备不存在读取操作和写入发生竞争的话，算法也不会对写入进行抑制。另外 Axboe 特别提醒大家他还没有再次运行 “Chinner 所建议的压力测试”。

> Ted Ts'o asked about the interaction with the I/O controller for control groups that is trying to do proportional I/O. Axboe said he was not particularly concerned about that. Controllers for each control group will need to be aware of each other, but it should all "probably be fine".

Ted Ts'o 询问当不同的控制组（control group）试图对 I/O 执行按比例（proportional）控制时，补丁的改动对 I/O 控制器（I/O controller）是否会有影响。Axboe 说他并不特别担心这个问题。每个控制组（control group）的控制器（controller）需要彼此了解（各自的运行状态），但补丁的修改对它们来说 “应该影响都还好”。

> David Howells asked about writeback that is going to multiple devices. Axboe said that still needs work. Someone else asked about background reads, which Axboe said could be added. Nothing is inherently blocking that, but the work still needs to be done.

David Howells 询问有关多个设备的 writeback 问题。Axboe 说对于这方面还有工作要做。另一些人询问了对后台读取（background reads）的支持，Axboe 说可以添加。目前实现该功能并没有什么困难，需要的只是一点工作量。（译者注，该补丁集最终 [随 4.10 合入内核主线][6]。）

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/616241/
[2]: https://lwn.net/Articles/685236/
[3]: https://en.wikipedia.org/wiki/CoDel
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=e34cbd307477ae07c5d8a8d0bd15e65a9ddaba5c
[5]: https://lwn.net/Articles/685236/
[6]: https://kernelnewbies.org/Linux_4.10#Improved_writeback_management
