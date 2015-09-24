---
title: Linux 技术报告：从 3.10 到 4.0
author: Wu Zhangjin
layout: post
permalink: /linux-technical-report-from-3-10-to-4-0/
views:
  - 67
tags:
  - 3.10
  - 4.0
  - Android
  - Linux
  - Performance
  - Power
  - Security
  - Stability
categories:
  - Linux
---

> By Falcon of [TinyLab.org][1]
> 2015/05/24


## Introduction

Android 5.x 至今都还在用 Linux 3.10，未来是否会迁移到更新的内核呢？我们来看一下，从 3.11 开始，Linux 内核引入了哪些可能影响用户体验的变更。下面从电源管理、性能优化、可靠性和安全四个方面展开汇总。

## Power Management

### 3.17: Improved power management features enabled for more Radeon GPUs

> Dynamic power management (dpm) has been re-enabled by default on Cayman and BTC devices.

Also, a new module parameter (radeon.bapm=1) has been added to enable bidirectional application power management (bapm) on APUs where it&#8217;s disabled by default due to stability issues.

### 3.17: scripts/analyze&#95;suspend.py: update to v3.0

> which includes back-2-back suspend testing, device filters to reduce the html size, the inclusion of device\_prepare and device\_complete callbacks, a USB topography list, and the ability to control USB device autosuspend

### 3.13: Power capping framework

  * [Power Capping Framework][2]

> This release includes a framework that allow to set power consumption limits to devices that support it. It has been designed around the Intel RAPL (Running Average Power Limit) mechanism available in the latest Intel processors (Sandy Bridge and later, many devices will also be added RAPL support in the future). This framework provides a consistent interface between the kernel and user space that allows power capping drivers to expose their settings to user space in a uniform way.

### 3.12: Improved timerless multitasking: allow timekeeping CPU go idle

  * [timerless multitasking][3]
  * [Is the whole system idle?][4]

> Linux 3.10 added support for timerless multitasking, that is, the ability to run processes without needing to fire up the timer interrupt that is traditionally used to implement multitasking. This support, however, had a caveat: it could turn off interrupts in all CPUs, except one that is used to track timer information for the other CPUs. But that CPU keeps the timer turned on even if all the CPUs are idle, which was useless. This release allows to disable the timer for the timekeeping CPU when all CPUs are idle.

## Performance

### 4.0: DAX &#8211; Direct Access, for persistent memory storage

  * [Supporting filesystems in persistent memory][5]

> DAX removes the extra copy incurred by the buffer by performing reads and writes directly to the persistent-memory storage device.

### 4.0: &#8220;lazytime&#8221; option for better update of file timestamps

  * [Introducing lazytime][6]

> Lazytime causes access, modified and changed time updates to only be made in the cache. The times will only be written to the disk if the inode needs to be updated anyway for some non-time related change, if fsync(), syncfs() or sync() are called, or just before an undeleted inode is evicted from memory. This is POSIX compliant, while at the same time improving the performance.

### 4.0: rcu: Optionally run grace-period kthreads at real-time priority

  * [RCU commit][7]

> Recent testing has shown that under heavy load, running RCU&#8217;s grace-period kthreads at real-time priority can improve performance and reduce the incidence of RCU CPU stall warnings

### 4.0: slub: optimize memory alloc/free fastpath by removing preemption on/off

  * [Slub commit][8]

### 4.0: memcontrol cgroup: a clearer model and improved workload performance

  * [memcontrol cgroup commit][9]

> Introduce the basic control files to account, partition, and limit memory using cgroups in default hierarchy mode. The old interface will be maintained, but a clearer model and improved workload performance should encourage existing users to switch over to the new one eventually

### 4.0: F2FS: Introduce a batched trim

  * [F2FS commit][10]

### 3.17: perf timechart adds I/O mode

> Currently, perf timechart records only scheduler and CPU events (task switches, running times, CPU power states, etc); this release adds I/O mode which makes it possible to record IO (disk, network) activity. In this mode perf timechart will generate SVG with I/O charts (writes, reads, tx, rx, polls).

### 3.16: cpufreq: stable frequency and cpuidle issue

> Add support for intermediate (stable) frequencies for platforms that may temporarily switch to a stable frequency while transitioning between frequencies commit
>
> governor: Improve performance of latency-sensitive bursty workloads commit

### 3.15: Faster erasing and zeroing of parts of a file

> This release adds two new fallocate(2) mode flags:
>
>   * FALLOC&#95;FL&#95;COLLAPSE&#95;RANGE: Allows to remove a range of a file without leaving holes, improving the performance of these operations that previously needed to be done with workarounds.
>
>   * FALLOC&#95;FL&#95;ZERO&#95;RANGE: Allows to set a range of a file to zero, much faster than it would take to do it manually (this functionality was previously available in XFS through the XFS\_IOC\_ZERO_RANGE ioctl)

### 3.15: zram: LZ4 compression support, improved performance

> Zram is a memory compression mechanism added in Linux 3.14 that is used in Android, Cyanogenmod, Chrome OS, Lubuntu and other projects. In this release zram brings support for the LZ4 compression algorithm, which is better than the current available LZO in some cases.

### 3.15: FUSE: improved write performance

  * [Fuse commit][11]

> FUSE can now use cached writeback support to fuse, which improves write throughput.

### 3.15: Introduce cancelable MCS lock

> it is a simple spinlock with the desirable properties of being fair, and with each CPU trying to acquire the lock spinning on a local variable. It avoids expensive cache bouncings that common test-and-set spinlock implementations incur

### 3.15: Per-thread VMA caching

  * [Optimizing VMA caching][12]

> cache last recently used VMA to improve VMA cache hit rate, for more details see the recommended LWN article

### 3.15: Speed up resume

  * As mentioned in the &#8220;prominent features&#8221; section, faster resume from power suspend in systems with hard disk drives

  * Speed up resume by resuming runtime-suspended devices later during system suspend

  * Speed up resume by using asynchronous threads for resume&#95;early commit, resume&#95;noirq commit, suspend&#95;late commit, suspend&#95;noirq commit, acpi&#95;thermal&#95;check

  * tools/power turbostat: Run on Intel Broadwell

### 3.15: ext4/ext3: Speedup sync

  * [Speedup sync][13]

> In the following test script sync(1) takes around 6 minutes when there are two ext4 filesystems mounted on a standard SATA drive. After this patch sync takes a couple of seconds so we have about two orders of magnitude improvement.

### 3.14: Deadline scheduling class for better real-time scheduling

  * [Deadline scheduling: coming soon?][14]

> Deadline scheduling gets away with the notion of process priorities. Instead, processes provide three parameters: runtime, period, and deadline. A SCHED&#95;DEADLINE task is guaranteed to receive &#8220;runtime&#8221; microseconds of execution time every &#8220;period&#8221; microseconds, and these &#8220;runtime&#8221; microseconds are available within &#8220;deadline&#8221; microseconds from the beginning of the period. The task scheduler uses that information to run the process with the earliest deadline, a behavior closer to the requirements needed by real-time systems.

### 3.14: scripts/analyze&#95;suspend.py

[scripts/analyze&#95;suspend.py][15]

> Tool for suspend/resume performance analysis and optimization

### 3.14: futexes: Increase hash table size for better performance

  * [futexes improvement][16]

### 3.13: fuse: Implement writepages callback, improving mmaped writeout

  * [fuse mmaped writeout][17]

### 3.13: slab improvement

> Changes in the slab have been done to improve the slab memory usage and performance. kmem_caches consisting of objects less than or equal to 128 byte have now one more objects in a slab, and a change to the management of free objects improves the locality of the accesses, which improve performance in some microbenchmarks

### 3.12: Improved tty layer locking

  * [TTY Merge commit][18]

> The tty layer locking got cleaned up and in the process a lot of locking became per-tty, which actually shows up on some odd loads.

### 3.12: New lockref locking scheme, VFS locking improvements

  * [Introducing lockrefs][19]

> This release adds a new locking scheme, called &#8220;lockref&#8221;. The &#8220;lockref&#8221; structure is a combination &#8220;spinlock and reference count&#8221; that allows optimized reference count accesses. In particular, it guarantees that the reference count will be updated as if the spinlock was held, but using atomic accesses that cover both the reference count and the spinlock words, it can often do the update without actually having to take the lock. This allows to avoid the nastiest cases of spinlock contention on large machines. When updating the reference counts on a large system, it will still end up with the cache line bouncing around, but that&#8217;s much less noticeable than actually having to spin waiting for the lock. This release already uses lockref to improve the scalability of heavy pathname lookup in large systems.

### 3.12: IPC locking improvements

> This release includes improvements on the amount of contention we impose on the ipc lock (kern&#95;ipc&#95;perm.lock). These changes mostly deal with shared memory, previous work has already been done for semaphores in 3.10 and message queues in 3.11. With these chanves, a custom shm microbenchmark stressing shmctl doing IPC&#95;STAT with 4 threads a million times, reduces the execution time by 50%. A similar run, this time with IPC&#95;SET, reduces the execution time from 3 mins and 35 secs to 27 seconds.

### 3.11: Zswap: A compressed swap cache

  * [The zswap compressed swap cache][20]

> Zswap is a lightweight, write-behind compressed cache for swap pages. It takes pages that are in the process of being swapped out and attempts to compress them into a dynamically allocated RAM-based memory pool. If this process is successful, the writeback to the swap device is deferred and, in many cases, avoided completely. This results in a significant I/O reduction and performance gains for systems that are swapping

### 3.11: Add support for LZ4 compressed kernels

  * [LZ4 compressed kernels][21]

> Add support for LZ4 decompression in the Linux Kernel. LZ4 Decompression APIs for kernel are based on LZ4 implementation by Yann Collet.

### 3.11: Kswapd and page reclaim behaviour

> Kswapd and page reclaim behaviour has been screwy in one way or the other for a long time. One example is reports of a large copy operations or backup causing the machine to grind to a halt or applications pushed to swap. Sometimes in low memory situations a large percentage of memory suddenly gets reclaimed. In other cases an application starts and kswapd hits 100% CPU usage for prolonged periods of time and so on. This patch series aims at addressing some of the worst of these problems.

## Stability

### 4.0: kasan, kernel address sanitizer

> Kernel Address sanitizer (KASan) is a dynamic memory error detector. It provides fast and comprehensive solution for finding use-after-free and out-of-bounds bugs. Linux already has the kmemcheck feature, but unlike kmemcheck, KASan uses compile-time instrumentation, which makes it significantly faster than kmemcheck.

### 4.0: GDB scripts for debugging the kernel.

  * [Documentation/gdb-kernel-debugging.txt][22]

> If you load vmlinux into gdb with the option enabled, the helper scripts will be automatically imported by gdb as well, and additional functions are available to analyze a Linux kernel instance.

### 3.14: stackprotector: Introduce CONFIG&#95;CC&#95;STACKPROTECTOR&#95;STRONG

  * [Strong stackprotector][23]

> &#8220;Strong&#8221; is a new mode introduced by this patch. With &#8220;Strong&#8221; the kernel is built with -fstack-protector-strong (available in gcc 4.9 and later). This option increases the coverage of the stack protector without the heavy performance hit of -fstack-protector-all.

### 3.12: Better Out-Of-Memory handling

  * [Reliable out-of-memory handling][24]

> The Out-Of-Memory state happens when the computer runs out of RAM and swap memory. When Linux gets into this state, it kills a process in order to free memory. This release includes important changes to how the Out-Of-Memory states are handled, the number of out of memory errors sent to userspace and reliability. For more details see the below link.

## Security

### 4.0: Live patching: a feature for live patching the kernel code

  * [Merge commit][25]

> This release introduces &#8220;livepatch&#8221;, a feature for live patching the kernel code, aimed primarily at systems who want to get security updates without needing to reboot. This feature has been born as result of merging kgraft and kpatch, two attempts by SuSE and Red Hat that where started to replace the now propietary ksplice. It&#8217;s relatively simple and minimalistic, as it&#8217;s making use of existing kernel infrastructure (namely ftrace) as much as possible. It&#8217;s also self-contained and it doesn&#8217;t hook itself in any other kernel subsystems.

### 4.0: Add security hooks to the Android Binder

> Add security hooks to the Android Binder that enable security modules such as SELinux to implement controls over Binder IPC. The security hooks include support for controlling what process can become the Binder context manager, invoke a binder transaction/IPC to another process, transfer a binder reference to another process , transfer an open file to another process. These hooks have been included in the Android kernel trees since Android 4.3

## Reference

  * [www.lwn.net][26]
  * [Linux 4.0 Changes][27]
  * [Linux 3.xx Changes][28]





 [1]: http://tinylab.org
 [2]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/Documentation/power/powercap/powercap.txt
 [3]: http://kernelnewbies.org/Linux_3.10#head-62fadba76893e85ee7fb75d548536c5635baca54
 [4]: https://lwn.net/Articles/558284/
 [5]: http://lwn.net/Articles/610174/
 [6]: http://lwn.net/Articles/621046/
 [7]: https://git.kernel.org/linus/a94844b22a2e2b9155bbc0878c507850477221c2
 [8]: https://git.kernel.org/linus/9aabf810a67cd97e2d1a48f0bab338b7680f1929
 [9]: https://git.kernel.org/linus/241994ed8649f7300667be8b13a9e04ae04e05a1
 [10]: http://git.kernel.org/linus/bba681cbb231920a786cd7303462fb2632af6f36
 [11]: https://git.kernel.org/linus/4d99ff8f12eb20c6cde292f185cb1c8c334ba0ed
 [12]: http://lwn.net/Articles/589475/
 [13]: https://git.kernel.org/linus/10542c229a4e8e25b40357beea66abe9dacda2c0
 [14]: https://lwn.net/Articles/575497/
 [15]: https://git.kernel.org/linus/ee8b09cd60bfe45d856e7c3bef8742835686bf4e
 [16]: https://git.kernel.org/linus/a52b89ebb6d4499be38780db8d176c5d3a6fbc17
 [17]: http://git.kernel.org/linus/26d614df1da9d7d255686af5d6d4508f77853c01
 [18]: https://git.kernel.org/linus/2f01ea908bcf838e815c0124b579513dbda3b8c8
 [19]: https://lwn.net/Articles/565734/
 [20]: https://lwn.net/Articles/537422/
 [21]: http://git.kernel.org/linus/cffb78b0e0b3a30b059b27a1d97500cf6464efa9
 [22]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/gdb-kernel-debugging.txt
 [23]: https://git.kernel.org/linus/8779657d29c0ebcc0c94ede4df2f497baf1b563f
 [24]: https://lwn.net/Articles/562211/#oom
 [25]: http://git.kernel.org/linus/1d9c5d79e6e4385aea6f69c23ba543717434ed70
 [26]: http://www.lwn.net
 [27]: http://kernelnewbies.org/LinuxChanges
 [28]: http://kernelnewbies.org/LinuxVersions
