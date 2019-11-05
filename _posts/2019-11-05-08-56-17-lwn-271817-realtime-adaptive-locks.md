---
layout: post
draft: false
top: true
author: 'Wang Chen'
title: "LWN 271817: 实时自适应锁"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-271817/
description: "LWN 中文翻译，实时自适应锁"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - realtime
  - lock
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Realtime adaptive locks](https://lwn.net/Articles/271817/)
> 原创：By Jonathan Corbet @ Mar. 5, 2008
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Shaowei Wang](https://github.com/shaoweiaaron)

> The realtime patchset has one overriding goal: provide deterministic response times in all situations. To that end, much work has been done to eliminate places in the kernel which can be the source of excessive latencies; quite a bit of that work has been merged into the mainline over the last two years or so. One of the biggest remaining out-of-tree components is the sleeping spinlock code. Sleeping spinlocks have advantages and disadvantages. A recently posted set of patches has the potential to significantly reduce one of the biggest disadvantages of the realtime spinlock code.

实时补丁集的首要目标就是：希望在任何情况下都能够保证 “确定的（deterministic）” 响应时延。为此，补丁对内核代码中很多地方做了修改，避免可能产生过长的延迟。在过去两年左右的时间里，相当多的工作已合入主线。剩下最大一块未合入的代码是有关可睡眠的自旋锁。可睡眠的自旋锁有其自身的优点和缺点。最近发布的一组补丁有可能对实时自旋锁代码的一个最大缺点产生显著的改进效果。

> Mainline spinlocks work by repeatedly polling a lock variable until it becomes available. This busy-waiting code thus "spins" while waiting for a lock. Spinlocks are quite fast, but they can also be a source of significant latencies: a processor which is holding a lock can delay others for indefinite amounts of time. In the mainline kernel, it is also not possible to preempt a thread which holds a spinlock - another source of latencies. (See [this article](http://lwn.net/Articles/267968/) for a more detailed description of the mainline spinlock implementation).

目前主线版本的自旋锁会周期性地查询锁变量的状态直到其变为可用。这种在等待锁的过程中采用 “忙等待（busy-waiting）” 的方式也是我们之所以称其为 “自旋（spin）” 锁的原因。自旋锁运行得非常快，但依然会造成显著的延迟：当一个任务拥有一把锁后（如果不能快速地释放），会造成其他需要该锁的任务无限期地在锁上自旋等待（译者注：考虑 SMP 的场景下，拥有锁的任务在一个处理器上长时间运行而不释放锁，另一个等待锁的任务在另一个处理器上自旋并长期占有该处理器）。而且，在主线内核版本中，一个持有自旋锁的线程是不可以被抢占的，这会导致另一种场景下的延迟（译者注，考虑 UP 的场景下，拥有锁的的低优先级任务禁止了抢占，高优先级的任务即使不与其争抢同一把锁也会因为无法抢占而得不到运行）。（有关主线自旋锁实现的更详细说明，请参阅 [此文][1]）。

> The realtime patch set addresses this problem in a couple of ways. One of those is to cause threads waiting for a contended lock to sleep rather than spin. As a result, lock contention cannot create latencies on processors which are not holding the lock. When spinning is removed, it is also possible to make code preemptible even when it holds a lock without causing deadlock problems. That allows a high-priority process to run regardless of any lower-priority processes which might currently hold locks on the current CPU. Finally, the realtime patch set has added priority awareness and priority inheritance to the locking code to ensure that the highest-priority process is always able to run.

实时补丁集通过一系列的改进来解决以上问题。改动之一是：等待锁的任务将进入睡眠而不是自旋。这么做的好处是不会因为一个任务因为自旋（等待锁释放）而长期占用处理器，结果使得其他任务无法运行，避免了由此所产生的延迟。由于不再自旋，我们无需对拥有锁的任务禁用抢占（改动之二），也无需担心这么做会引起死锁。这么做的好处是使得高优先级的任务总可以抢占一个低优先级的任务，无论该低优先级的任务当前是否拥有锁。最后，实时补丁集为锁代码添加了优先级处理能力以支持 “优先级继承（priority inheritance）”，从而确保了最高优先级的任务总能够被调度运行。

> This is all good stuff, but there is one little disadvantage: the extra overhead imposed by the more complicated locks can reduce system throughput considerably. This is a cost that the realtime developers have been willing to pay; it is often necessary to make trade-offs between throughput and latency. Recently, though, some developers at Novell have come to the conclusion that the throughput cost of the realtime patch set need not be as severe as it currently is; the resulting [adaptive realtime locks patch](http://lwn.net/Articles/270778/) brings the throughput of the realtime kernel to a level much closer to that found in the mainline - at least, for some workloads.

以上改动中美中不足的是：由于锁机制变得愈加复杂，其运行所带来的额外开销会大大降低系统整体的吞吐量。不得不说这是在实时应用场景下，为了在降低延迟和提高处理效率之间实现折中而不得不付出的代价。但最近来自 Novell 公司的一些开发人员认为，可以有措施使得内核在启用实时补丁后在处理效率上的损失不至于像现在这么严重；为此他们提出了一个称之为 [“自适应实时锁（adaptive realtime locks）” 的补丁][2]，可以将实时内核的吞吐量提高到与目前主线版本更接近的水平（至少在某些工作负载条件下）。

> The core observation encapsulated in this patch set is that hold times for spinlocks tend to be quite short, especially in the realtime kernel. So the cost of putting a waiting thread to sleep may well exceed the cost of simply busy-waiting until the lock becomes free. So adaptive locks behave more like their mainline counterpart and simply spin until the lock becomes available. There are some twists, though, which are necessitated by the realtime system:

开发这个补丁的核心思想源自通过研究发现自旋锁的保持时间往往很短，特别是在实时内核中。因此，在锁被释放之前，让等待锁的线程进入休眠状态所付出的成本甚至会超过简单自旋的成本。自适应锁的行为和主线版本中自旋锁的行为很类似，它简单地进行自旋等待直到锁变为可用。所不同的是，（在自适应锁补丁中）为了实时应用的需要：

> - The spinning cannot go on forever, since it may cause unacceptable latencies elsewhere in the system. So an adaptive lock will only spin up to a configurable number of times (the default is 10,000) before giving up and going to sleep.

- 自旋不会永远持续下去，否则正如我们前面分析的这会导致其他任务产生不可接受的延迟。在自适应锁的实现上，其自旋的次数有一个上限（根据配置，缺省为 10,000 次），一旦超过则不再自旋，转而进入休眠。

> - Since lock holders are preemptible in the realtime kernel, it is possible that the thread which currently holds the lock was previously running on the same CPU as the process trying to acquire the lock. In that situation, spinning for the lock is clearly a bad thing to do. In the absence of a loop counter, it would be a hard deadlock situation; with the counter, it would just be an unnecessary delay. Either way, the result is undesirable, so, if the lock owner is running on the same processor, the thread waiting for the lock simply goes to sleep.

- 由于在实时内核中锁的持有者是可抢占的，很有可能当前持有锁的线程（在被抢占之前）与尝试获取锁的任务在同一个处理器上运行。对于这种情况，（等待锁的任务）进行自旋显然不是一件好事。因为如果无限期地自旋（和现在自旋锁的做法一样），这将很容易导致死锁；而即使自旋是有上限的，其结果也将产生不必要的延迟。所以无论哪种方式，结果都不合适，因此，如果锁的持有者和等待者都在同一个处理器上，则等待锁的线程应该直接进入睡眠。

> - If the lock owner is, instead, itself sleeping while waiting for something, there is little point in having another thread stay awake in the hope that the owner will release the lock soon. So, in this case too, a thread contending for a lock will simply go to sleep rather than spin.

- 相反，如果锁的持有者本身因为在等待其他资源而处于睡眠态，那么让另一个（等待该锁的）线程处于运行态是没有意义的。因此，对于这种情况，希望获取锁的线程也应该进入睡眠而不是以自旋的方式进行等待。

> One other throughput improvement is obtained by changing the lock-stealing code. Locks in the realtime system are normally fair, in that threads waiting for a lock will get it in first-come-first-served order. A higher-priority process will jump the queue, however, and "steal" the lock from lower-priority processes which have been waiting for longer. The adaptive locks patch tweaks this algorithm by allowing a running process to steal a lock from another, equal-priority process which is sleeping. This change adds some unfairness to the locking code, but it allows the system to avoid a context switch and keep a running, cache-warm process going.

另一个着眼于提高吞吐率的改进是修改了有关 “窃取锁（lock-stealing）” 的逻辑。在实时系统中我们通常公平地对待一把锁的所有竞争者，采取的方式是让线程按先到先得的顺序获得锁。唯一例外的是，优先级较高的任务可以跳过排队，从那些等待时间较长的低优先级任务手中 “窃取” 锁的所有权。自适应锁补丁对该算法进行了补充，允许 “运行态” 的任务从另一个优先级相同但处于 “睡眠态” 的任务手中 “窃取” 锁。这种改变给锁的处理逻辑带来了一些不公平性，但好处是可以避免一次上下文切换从而使得运行态的任务被保留在缓存中（“cache-warm”）。

> [Some benchmark results [PDF]](ftp://ftp.novell.com/dev/ghaskins/adaptive-locks.pdf) have been posted. On the test system, the dbench benchmark runs at about 1500 MB/s on a stock 2.6.24 system, but at just under 170 MB/s on a system with the realtime patches applied. The adaptive lock patch raises that number back to over 700 MB/s - still far from a mainline system, but much better than before. The improvement in hackbench results is even better, while the change in the all-important "build the kernel" benchmark is small (but still positive). A fundamental patch like this will require quite a bit of review and testing before it might be accepted. But the initial results suggest that adaptive locks might be a big win for the realtime patch set.

[一些基准测试结果 [PDF]][3] 已发布。在测试系统上，使用 dbench 的基准测试表明，基于标准 2.6.24 内核版本其吞吐量为大约 1500 MB / s ，应用了实时补丁后速度降为不到 170 MB / s。但添加自适应锁补丁后该数值恢复到 700 MB / s 以上，这虽然还远未达到主线内核的水平，但至少比没有应用自适应锁补丁之前要好多了。采用 hackbench 基准测试，得到的改进效果甚至更好，而在非常为大家所看重的 “内核构建（即 build the kernel）” （译者注，譬如运行 `make -j 128`） 测试下改进效果并不明显（但测试数据仍然是积极的）。像这样影响到内核基础部分的补丁自然需要通过相当多的审查和测试才能被大家接受。但最初的测试结果表明，自适应锁对于实时补丁集来说极有可能是一次意义重大的改进。（译者注，该补丁辗转往复，经多人修改后终于随 2.6.30 版本合入了内核主线，具体的代码提交可以参考 [“mutex: implement adaptive spinning”][4]）

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: http://lwn.net/Articles/267968/
[2]: http://lwn.net/Articles/270778/
[3]: ftp://ftp.novell.com/dev/ghaskins/adaptive-locks.pdf
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=0d66bf6d3514b35eb6897629059443132992dbd7