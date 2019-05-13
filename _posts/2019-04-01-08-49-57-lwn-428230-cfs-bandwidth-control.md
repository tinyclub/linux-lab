---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 428230: CFS 带宽控制"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-428230/
description: "LWN 中文翻译，CFS 带宽控制"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - schedule
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[CFS bandwidth control](https://lwn.net/Articles/428230/)
> 原创：By Jonathan Corbet @ Feb. 16, 2011
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Chumou Guo](https://github.com/simowce)

> The CFS scheduler does its best to divide the available CPU time between contending processes, keeping the CPU utilization of each about the same. The scheduler will not, however, insist on equal utilization when there is free CPU time available; rather than let the CPU go idle, the scheduler will give any left-over time to processes which can make use of it. This approach makes sense; there is little point in throttling runnable processes when nobody else wants the CPU anyway.

CFS 调度器会尽最大的努力为相互竞争的进程分配可用的处理器时间，从而确保每个进程所获得的处理时间占比大致相同。但是，调度器并不会一直坚持公平的原则；当有多余的处理器时间时，它并不会让处理器简单地进入空闲状态，而是会将剩余时间分配给那些需要它的进程。这么做绝对是有意义的；反之，当某些进程不再需要处理器时，（为了实现绝对的公平）而限制其他需要处理器的进程运行才是毫无道理的。

> Except that, sometimes, that's exactly what a system administrator may want to do. Limiting the maximum share of CPU time that a process (or group of processes) may consume can be desirable if those processes belong to a customer who has only paid for a certain amount of CPU time or in situations where it is necessary to provide strict resource-use isolation between processes. The CFS scheduler cannot limit CPU use in that manner, but the [CFS bandwidth control](https://lwn.net/Articles/428175/) patches, posted by Paul Turner, may change that situation.

但是，有时候，从系统管理员的角度出发却可能希望要做这样的事情（译者注，指对进程的运行施加额外的限制，譬如在云计算场景中，用户租赁的虚拟主机对于真正的物理主机来说就是一个进程，用户需要为其使用的计算资源进行付费，如果此时调度器没办法对用户使用进程访问计算资源进行限制，那么对于云计算的提供商就是一个巨大的损失）。譬如，某些进程属于那些仅购买了有限的处理器使用时间的客户；或者，在一些场景下从资源使用的角度出发的确需要在进程之间施行严格的隔离，对于这些情况就很有必要对进程（或进程组），控制其可能消耗的处理器时间的最大份额。当前的 CFS 调度器代码并不支持以上述方式限制进程对处理器的使用，但 Paul Turner 提交的 [“CFS 带宽控制补丁”][1] 可能会改变当前这种状况。

> This patch adds a couple of new control files to the CPU control group mechanism: `cpu.cfs_period_us` defines the period over which the group's CPU usage is to be regulated, and `cpu.cfs_quota_us` controls how much CPU time is available to the group over that period. With these two knobs, the administrator can easily limit a group to a certain amount of CPU time and also control the granularity with which that limit is enforced.

该补丁在 CPU 控制组（control group）的虚拟文件系统下添加了几个用于参数控制的文件：`cpu.cfs_period_us` 用于定义一个时间周期长度，内核会在这个周期时间的基础上对一个组所能使用的处理器时间进行调整，具体调整时还需要设置另一个参数 `cpu.cfs_quota_us`，该值用于定义一个组在 `cpu.cfs_period_us` 所设置的周期长度时间内可以使用的处理器时间的限额（译者注，以上两个参数值的单位都是微秒。当一个组内的进程的运行时间超过 `cpu.cfs_quota_us` 后，就会被限制运行，直到当前周期结束（周期长度由 `cpu.cfs_period_us` 决定），下一个周期开始后，这个组会被重新调度）。基于这两个调节参数，管理员可以针对组方便地限制其对处理器的使用时间并控制该限制的大小。（译者注，更多有关这些控制参数的使用，请参考 [Documentation/scheduler/sched-bwc.txt][2]）

> Paul's patch is not the only one aimed at solving this problem; the [CFS hard limits patch set](https://lwn.net/Articles/368685/) from Bharata B Rao provides nearly identical functionality. The implementation is different, though; the hard limits patch tries to reuse some of the bandwidth-limiting code from the realtime scheduler to impose the limits. Paul has expressed concerns about the overhead of using this code and how well it will work in situations where the CPU is almost fully subscribed. These concerns appear to have carried the day - there has not been a hard limits patch posted since early 2010. So the CFS bandwidth control patches look like the form this functionality will take in the mainline.

Paul 的补丁并不是唯一一个旨在解决这个问题的方案；Bharata B Rao 的 [“CFS 强制限制补丁集（CFS hard limits patch set）”][3] 提供了几乎相同的功能。但两者实现的方式完全不同；“强制限制补丁” 尝试复用实时调度程序中的一些带宽限制代码来实现对进程运行的限制。Paul 认为使用这种方法会带来额外的开销并担忧在处理器满负荷状态下该机制是否可以工作。看上去这些担忧是有道理的，因为自 2010 年初以来该 “强制限制补丁” 就一直没有发布过更新。因此，看起来 Paul 的 “CFS 带宽控制补丁” 更有可能为内核主线所接纳（译者注，该补丁 [随 3.2 版本合入内核主线][4]）。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/428175/
[2]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/scheduler/sched-bwc.txt?id=HEAD
[3]: https://lwn.net/Articles/368685/
[4]: https://kernelnewbies.org/Linux_3.2#Process_bandwith_controller
