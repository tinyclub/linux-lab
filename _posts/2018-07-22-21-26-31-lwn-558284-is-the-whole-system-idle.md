---
layout: post
author: 'Wang Chen'
title: "LWN 558284: 整个系统都空闲了吗？"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-558284-is-the-whole-system-idle/
description: "LWN 文章翻译，整个系统都空闲了吗？"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[Is the whole system idle?](https://lwn.net/Articles/558284/)
> 原创：By corbet @ July 10, 2013
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [guojian-at-wowo](https://github.com/guojian-at-wowo)

> The [full dynamic tick](https://lwn.net/Articles/549580/) feature that made its debut in the 3.10 kernel can be good for users who want their applications to have full use of one or more CPUs without interference from the kernel. By getting the clock tick out of the way, this feature minimizes kernel overhead and the potential latency problems. Unfortunately, full dynamic tick operation also has the potential to increase power consumption. Work is underway to fix that problem, but it turns out to require a bit of information that is surprisingly hard to get: is the system fully idle or not?

在 3.10 版本内核中首次支持的[完全动态时钟（full dynamic tick）](/lwn-549580-nearly-full-tickless-3.10)（译者注，从习惯和方便出发，下文直接引用 full dynamic tick， 不再翻译为中文）特性对那些希望使其应用程序充分利用一个或多个处理器而不受内核干扰的用户来说非常有用。取消 tick 后（译者注，即不再以固定周期性的方式触发时钟中断），可以最大限度地减少内核开销和潜在的延迟问题。但不幸的是，这么做仍然存在一定的可能性会导致功耗增加。社区目前正在努力试图解决这个问题，但发现在着手解决这个问题之前存在另一个比较棘手的问题需要克服，就是如何判断当前整个系统已经完全进入了空闲状态。（译者注：本文所介绍的修改最终随 3.12 版本合入内核主线，但在 4.13 版本上又被移除了，具体可以查看内核修改 [commit](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=fe5ac724d81a3c7803e60c2232718f212f3f38d4)，修改的原因是一直没有实际的应用（`was added in 2013 ......, but has not been used. This commit therefore removes it.`））

> The kernel has had the ability to turn off the periodic clock interrupt on idle processors for many years. Each processor, when it goes idle, will simply stop its timer tick; when all processors are idle, the system will naturally have the timer tick disabled systemwide. Fully dynamic tick — where the timer tick can be disabled on non-idle CPUs — adds an interesting complication, though. While most processors can (when the conditions are right) run without the clock tick, one processor must continue to keep the tick enabled so that it can perform a number of necessary system timekeeping operations. Clearly, this "timekeeping CPU" should be able to disable its tick and go idle if nothing else is running in the system, but, in current kernels, there is no way for that CPU to detect this situation.

内核支持对进入空闲态的处理器会尝试关闭周期性时钟中断，该特性已经存在了好几年（译者注，对该特性的支持从 2.6.21 开始，时间是在 2007 年 4 月）。每个处理器在进入空闲态时都会尝试停止本地的时钟 tick；当所有处理器都进入空闲态时，自然在整个系统范围内都不存在时钟 tick 了。Fully dynamic tick，更进一步，支持在非空闲的处理器上禁用时钟 tick，但实现上也变得更复杂。虽然大多数处理器（只要条件允许）都可以在没有时钟 tick 的情况下运行，但系统仍然必须要保留至少一个处理器继续启用时钟 tick，以便可以基于该处理器执行许多必要的系统计时管理事务（timekeeping）（译者注，从习惯和方便出发，下文直接使用 timekeeping，不再翻译为中文）。诚然，当系统中没有任何任务需要运行时，对这个 “负责 timekeeping 的处理器” 也最好能够禁用它的时钟 tick 从而让其进入睡眠，但是基于当前的内核实现，这个处理器却无法检测到这种条件（译者注：指上文 “系统中没有任何任务需要运行” 或者说所有的处理器都可以进入睡眠这个情况）。

> A naive solution to this problem will come easily to mind: maintain a global counter tracking the number of idle CPUs. Whenever a processor goes idle, it increments the counter; when the processor becomes busy again, it decrements the counter. When the number of idle CPUs matches the number of CPUs in the system, the kernel will know that no work is being done and the timekeeping CPU can take a break.

针对这个问题，很自然的一个解决方案是：维护一个全局的计数器来跟踪空闲的处理器的数量。一旦一个处理器进入空闲态，该计数器的值就加一；当该处理器再次变为繁忙时，该计数器的值就减一。当空闲的处理器的数量与系统中的处理器数量相同时，内核就知道当前系统上已经没有工作正在进行，“负责 timekeeping 的处理器” 也就可以休息了。

> The problem, of course, is that cache contention for that global counter would kill performance on larger systems. Transitions to and from idle are common under most workloads, so the cache line containing the counter would bounce frequently across the system. That would defeat some of the point of the dynamic tick feature; it seems likely that many users would prefer the current power-inefficient mode to a "solution" that carried such a heavy cost.

但问题在于，在一个大规模系统上，大量的处理器在访问存放该全局计数器的高速缓存时会产生竞争，从而导致整体性能下降。在通常的工作负载水平情况下，处理器在空闲态和工作态之间的切换很常见，所以包含计数器的高速缓存行（cache line）会在整个系统中频繁地被访问和修改。这对 dynamic tick 的特性运行会产生不小的影响；为此许多用户似乎宁愿接受当前较低效率的节能模式（译者注：指 Fully dynamic tick），也不愿意使用该 “方案”（译者注，即前文所述的 “维护一个全局的计数器来跟踪空闲的处理器的数量” 这个方案），因为它对系统整体的运行效率影响太大了。

> So something smarter needs to be done. That's the cue for an entry by Paul McKenney, whose [seven-part full-system idle patch set](https://lwn.net/Articles/558229/) may well be the solution to this problem.

看起来需要一个更加有效的解决方案。这引起了 Paul McKenney 的兴趣，他提供了[一个包含七个补丁的补丁集，名字叫做 "full-system idle"](https://lwn.net/Articles/558229/)，看上去是一个解决这个问题的好办法。

> As one might expect, the solution involves the maintenance of a per-CPU array of idle states. Each CPU can update its status in the array without contending with the other CPUs. But, once again, the naive solution is inadequate. With a per-CPU array, determining whether the system is fully idle requires iterating through the entire array to examine the state of each CPU. So, while maintaining the state becomes cheap, answering the "is the system idle?" question becomes expensive if the number of CPUs is large. Given that the timekeeping code is likely to want to ask that question frequently (at each timer tick, at least), an expensive implementation is not indicated; something else must be done.

正如人们所预料的那样，该解决方案针对每个处理器（per-CPU）单独维护一个空闲状态，所有处理器的空闲状态值组织成一个数组。每个处理器更新数组中对应自己的元素的状态而不会与其他处理器发生竞争。但是，同样地，光这么做是不够的。如果要确定整个系统是否完全空闲，则需要遍历整个数组，通过检查每个处理器的状态来得到最终结果。所以，在方便维护单个处理器状态的同时，当处理器的数量变得很大时，判断 “整个系统是否都空闲？” 的代价变得昂贵起来。考虑到 timekeeping 的代码可能需要频繁地对此进行判断（至少在每个时钟中断处理中），为避免系统开销过大；还必须引入一些其他的改进。

> Paul's approach is to combine the better parts of both naive solutions. A single global variable is created to represent the system's idle state and make that state easy to query quickly. That variable is updated from a scan over the individual CPU idle states, but only under specific conditions that minimize cross-CPU contention. The result should be the best of both worlds, at the cost of delayed detection of the full-system idle state and the addition of some tricky code.

Paul 的方法是将上面介绍的两种解决方案的优点结合起来。首先依然需要一个全局变量来维护整个系统的空闲状态，方便对系统状态的快速查询。同时对该变量的更新依然是通过扫描每个处理器自己维护的空闲状态值而获得，但此更新必须在特定条件下才可以发生，从而确保处理器之间的竞争对其操作的影响最小。最终的方案较好地平衡了原来两套方案的优缺点，但代价是在针对整个系统的空闲状态的检测上会存在一定的延迟，同时具体的代码实现看上去也不是那么的直观。

> The actual scan of the per-CPU idle flags is not done in the scheduler or timekeeping code, as one might expect. Instead (as others might expect), Paul put it into the read-copy-update (RCU) subsystem. That may seem like a strange place, but it makes a certain sense: RCU is already tracking the state of the system's CPUs, looking for "grace periods" during which unused RCU-protected data structures can be reclaimed. Tracking whether each CPU is fully idle is a relatively small change to the RCU code. As an added benefit, it is easy for RCU to avoid scanning over the CPUs when things are busy, so the overhead of maintaining the global full-idle state vanishes when the system has other things to do.

和大家想的有点不一样，实际扫描处理器空闲标志数组的操作并不是在调度器或 timekeeping 代码中完成的。说到这里，其他人可能会猜到，Paul 将这段逻辑放在 read-copy-update （RCU）子系统中。这看起来有点奇怪，但仔细想想还是有道理的：因为 RCU 代码中已经存在用于跟踪系统中处理器状态的逻辑，该逻辑会确保在 RCU 所谓的 “宽限期”（“grace periods”）内对那些受到 RCU 保护但已不再被使用的数据结构进行回收。所以在 RCU 代码中增加跟踪每个处理器是否完全空闲的操作并不复杂。同时还存在一个额外的好处，那就是，基于 RCU 逻辑可以很容易地避免在系统繁忙时对处理器进行扫描，换句话说系统会选择一个不那么忙的时间去扫描统计整个系统中空闲的处理器的总个数，从而避免了为了维护全局的 full-idle 变量而产生的计算开销对系统整体性能的影响。

> The actual idleness of the system is tracked in a global variable called full_sysidle_state. Updating this variable too often would bring back the cache-line contention problem, though, so the code takes a more roundabout path. Whenever the system is perceived to be idle, the code keeps track of when the last processor went idle. Only after a delay will the global idle state be changed. That delay drops to zero for "small" machines (those with no more than eight processors), it increases linearly as the number of processors goes up. So, on a very large system, all processors must be idle for quite some time before full_sysidle_state will change to reflect that state of affairs.

实际的系统空闲状态通过名为 `full_sysidle_state` 的全局变量进行跟踪。频繁更新这个变量仍然会导致缓存竞争的问题，所以实际代码并不会直接访问它，而是采用了如下策略。一旦察觉出系统进入空闲状态，内核会跟踪并获得最后一个处理器进入空闲态的时间点。以此时间点为基准，内核会延迟一段时间才去更新这个全局变量的值。对于 “小型” 的机器（指那些处理器数量不超过 8 个的机器），该延迟值几乎为零，但随着处理器数量的增加，该值会线性增加。因此，在一个非常大的系统上，只有在所有处理器都闲置一段时间后，`full_sysidle_state` 这个变量才会被更新以反映系统的实际状态。（译者注：内核通过配置支持以上功能，具体参考 3.12 版本的 `kernel/time/Kconfig` 文件中的 `NO_HZ_FULL_SYSIDLE` 和 `NO_HZ_FULL_SYSIDLE_SMALL`）

> The result is that detection of full-system idle will be delayed on larger systems, possibly by a significant fraction of a second. So the timer tick will run a little longer than it strictly needs to. That is a cost associated with Paul's approach, as is the fact that his patch set adds some 500 lines of core kernel code for what is, in the end, the maintenance of a single integer value. But that, it seems, is the price that must be paid for scalability in a world where systems have large numbers of CPUs.

其最终结果是，在较大的系统上，对整个系统的空闲状态的检测将存在一定的延迟，这个延迟值很可能会达到几分之一秒。所以内核停止时钟 tick 的时间会比理论上应该停止的时间晚一会。这与 Paul 的实现方法有关系，他的补丁集中仅仅为了维护这个全局状态变量就足足增加了大约 500 行代码。但是，对于解决大规模系统的可扩展性问题来说，这点代价还是值得的。

[1]: http://tinylab.org
