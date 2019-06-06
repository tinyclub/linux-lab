---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 562211: 更加可靠的 OOM 处理"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-562211/
description: "LWN 中文翻译，更加可靠的 OOM 处理"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Reliable out-of-memory handling](https://lwn.net/Articles/562211/#oom)
> 原创：By Jonathan Corbet @ Aug. 6, 2013
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Zhiyuan Zhu](https://github.com/zzyjsjcom)

（译者注，本文翻译节选自 [A survey of memory management patches](https://lwn.net/Articles/562211/) 中一个有关 OOM 的补丁的介绍。）

## 更加可靠的 OOM 处理（Reliable out-of-memory handling）

> As was described in [this June 2013 article](https://lwn.net/Articles/552789/), the kernel's out-of-memory (OOM) killer has some inherent reliability problems. A process may have called deeply into the kernel by the time it encounters an OOM condition; when that happens, it is put on hold while the kernel tries to make some memory available. That process may be holding no end of locks, possibly including locks needed to enable a process hit by the OOM killer to exit and release its memory; that means that deadlocks are relatively likely once the system goes into an OOM state.

正如在 [这篇 2013 年 6 月的文章][3] 中所介绍的，内核中的 “内存不足杀手（Out-Of-Memory Killer，简称 OOM Killer。译者注，下文直接使用英文简称，不再翻译为中文）” 这个功能在可靠性（reliability）上一直存在一些问题。对于一个进程来说，当其触发内存不足（OOM）时，其函数调用栈可能已经深入内核内部；并且该进程还会在内核尝试释放某些内存时被挂起（译者注，所谓 “函数栈调用深”，意味着该进程可能会调用了不少其他模块的代码并拥有了一些常见的锁，譬如 `mmap_sem`。所谓 “尝试释放内存” 即触发了 OOM Killer，OOM Killer 会选择杀死一些进程来释放内存。触发 OOM Killer 的进程我们称之为 “OOM invoking task”，而被 OOM Killer 选中杀死的进程我们称之为 “OOM kill victim”，“OOM invoking task” 会被挂起等待 “OOM kill victim” 结束）。被挂起的进程可能已经持有了一些锁，而且（由于睡眠）无法释放，而 OOM Killer 选中的那些进程或许也希望获取这些锁，获取不到则意味着这些进程无法退出并释放内存；可见当系统进入 OOM 状态时，在一定程度上存在发生死锁的可能性。

> Johannes Weiner has posted [a set of patches](https://lwn.net/Articles/562091/) aimed at improving this situation. Following a bunch of cleanup work, these patches make two fundamental changes to how OOM conditions are handled in the kernel. The first of those is perhaps the most visible: it causes the kernel to avoid calling the OOM killer altogether for most memory allocation failures. In particular, if the allocation is being made in response to a system call, the kernel will just cause the system call to fail with an `ENOMEM` error rather than trying to find a process to kill. That may cause system call failures to happen more often and in different contexts than they used to. But, naturally, that will not be a problem since all user-space code diligently checks the return status of every system call and responds with well-tested error-handling code when things go wrong.

Johannes Weiner 发布了 [一个补丁集][4]，意图解决这个问题。基于一系列的清理工作，这些补丁对内核中 OOM 的处理方式引入了两处根本性的改动。第一处改动最为明显：其作用是在大多数内存分配失败的情况下避免触发 OOM Killer。考虑一个典型的例子，譬如程序调用了一个系统调用函数并导致了内存不足，改动后的补丁只会简单地让系统调用失败并返回 `ENOMEM` 错误，而不会去尝试杀死一个进程。这可能会导致在不同条件下系统调用发生失败的情况比过去更加频繁。但显然这并不会引起什么问题，因为所有用户空间的代码都应该仔细检查每个系统调用的返回值，并提供经过良好测试的错误处理机制，以便在问题出现时进行应对。（译者注，相关代码提交修改参考 ["mm: memcg: enable memcg OOM killer only for user faults"][1]。）

> The other change happens more deeply within the kernel. When a process incurs a page fault, the kernel really only has two choices: it must either provide a valid page at the faulting address or kill the process in question. So the OOM killer will still be invoked in response to memory shortages encountered when trying to handle a page fault. But the code has been reworked somewhat; rather than wait for the OOM killer deep within the page fault handling code, the kernel drops back out and releases all locks first. Once the OOM killer has done its thing, the page fault is restarted from the beginning. This approach should ensure reliable page fault handling while avoiding the locking problems that plague the OOM killer now.

另一处改动深入内核。当一个进程运行过程中发生缺页异常时，内核实际上只有两个选择：要么针对触发异常的虚拟地址提供有效的物理页框，要么杀死发生异常的进程。因此，为了解决缺页异常中出现的内存不足的情况，OOM Killer 必须被调用（译者注，换句话说，我们的原则当然是尽量避免杀死发生缺页异常的进程，而是通过 OOM Killer 尝试释放一些内存来满足缺页异常的要求）。但具体的处理逻辑会有所改变；（经过补丁修改后）缺页异常处理函数不再等待 OOM Killer 操作完成，而是尽快退出并首先释放所有拥有的锁。等 OOM Killer 完成了它的工作后，内核会再次重启缺页异常处理逻辑。采用这种方法可以避免当前困扰 OOM Killer 的死锁问题（译者注，参考第一小节的介绍），使得缺页异常处理更加可靠。（译者注，相关代码提交修改参考 ["mm: memcg: do not trap chargers with full callstack on OOM"][2]。）

（译者注，该补丁集 [随 3.12 版本合入内核主线][5]。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=519e52473ebe9db5cdef44670d5a97f1fd53d721
[2]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=3812c8c8f3953921ef18544110dafc3505c1ac62
[3]: https://lwn.net/Articles/552789/
[4]: https://lwn.net/Articles/562091/
[5]: https://kernelnewbies.org/Linux_3.12#Better_Out-Of-Memory_handling