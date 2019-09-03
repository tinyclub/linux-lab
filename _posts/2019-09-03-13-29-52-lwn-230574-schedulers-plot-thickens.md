---
layout: post
draft: false
author: 'Wang Chen'
title: "LWN 230574: 内核调度器替换方案的激烈竞争"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-230574/
description: "LWN 文章翻译，内核调度器替换方案的激烈竞争"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Schedulers: the plot thickens](https://lwn.net/Articles/230574/)
> 原创：By corbet @ Apr. 17, 2007
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Yang Wen](https://github.com/w-simon)

> The [RSDL scheduler](http://lwn.net/Articles/224865/) (since renamed the staircase deadline scheduler) by Con Kolivas was, for a period of time, assumed to be positioned for merging into the mainline, perhaps as soon as 2.6.22. Difficulties with certain workloads made the future of this scheduler a little less certain. Now Con would appear to have rediscovered one of the most reliable ways of getting a new idea into the kernel: post some code then wait for Ingo Molnar to rework the whole thing in a two-day hacking binge. So, while Con has recently [updated the SD scheduler patch](http://lwn.net/Articles/230500/), his work now looks like it might be upstaged by Ingo's new [completely fair scheduler](http://lwn.net/Articles/230501/) (CFS), at [version 2](http://lwn.net/Articles/230752/) as of this writing.

曾经有一段时间，Con Kolivas 开发的 [RSDL 调度器][7]（后被重新命名为 Staircase Deadline 调度器。译者注，即下文提到的 SD 调度器）被大家认为很有可能为内核主线所接受，也许最快是在 2.6.22 发布周期中。但由于它在某些应用场景上所遭遇的困难，使得该调度器的前景变得不确定起来。在为内核引入新设计这件事情上，现在 Con 似乎又将再次面对过去经常发生的那一幕：某些人提交了一个补丁，然后 Ingo Molnar 快速地基于该补丁的思想进行了重构（并提出了新的设计）。因此，虽然 Con 最近 [更新了 SD 调度器的补丁][8]，但目前看起来他的工作很有可能会被 Ingo 设计的另一个新的 [完全公平调度器（completely fair scheduler，简称 CFS）][13] 所取代，在撰写本文时该新调度器的补丁 [版本号已经升到版本 2][9]。

> There are a number of interesting aspects to CFS. To begin with, it does away with the arrays of run queues altogether. Instead, the CFS works with a single [red-black tree](http://lwn.net/Articles/184495/) to track all processes which are in a runnable state. The process which pops up at the leftmost node of the tree is the one which is most entitled to run at any given time. So the key to understanding this scheduler is to get a sense for how it calculates the key value used to insert a process into the tree.

CFS 有许多有趣的特性。首先，它完全取消了运行队列的数组。CFS 代之以使用一个 [红黑树（red-black tree）][10] 来跟踪处于可运行状态的所有 “进程”（process，译者注，调度的基本单位虽然已经是线程（thread）而不再是进程（process），但在内核的文章中，由于历史习惯的原因，仍然有时候会称之为 process，有时候也会称之为 task（中文翻译为 “任务”，而且译者窃以为 task 更贴切）。从尊重原文的角度出发，本文仍然按照字面上的意思来翻译，以下同）。在树的最左边节点上的进程将被优先选择取出并投入运行。因此，理解此调度器的关键是要了解进程被插入树中时所使用的键（key）值是如何计算的。

> That calculation is reasonably simple. When a task goes into the run queue, the current time is noted. As the process waits for the CPU, the scheduler tracks the amount of processor time it would have been entitled to; this entitlement is simply the wait time divided by the number of running processes (with a correction for different priority values). For all practical purposes, the key is the amount of CPU time due to the process, with higher-priority processes getting a bit of a boost. The short-term priority of a process will thus vary depending on whether it is getting its fair share of the processor or not.

计算的方法其实相当简单。当任务进入运行队列时，（调度器）会记下它当前的时间。当进程离开 CPU 并处于等待状态时，调度器会跟踪并计算它本应被分配的处理器时间；计算的方法是将等待时间除以正在运行的进程数（并根据进程所属的不同优先级值进行修正）。出于实际的需要，对该键值修正的方法是：以每个进程应该享有的 CPU 时间量为基准，如果一个进程的优先级较高则对其键值进行一定的提升。因此，进程的短期优先级（short-term priority，译者注，这应该指的是在进行任务切换选择时调度器所使用的经过换算后的优先级，相对于用户配置的静态优先级）将取决于它是否公平地获得了处理器的使用份额。（译者注，本文对 CFS 的核心思想的描述谈不上细致，感兴趣的读者可以阅读 CFS 正式合入内核时提供的 [CFS 设计文档][1]。请注意的是，CFS 最早于 2.6.23 版本合入内核，当时计算键值利用的是 [`struct sched_entity` 中的 `wait_runtime` 成员][2]，但自 2.6.24 版本开始，计算的方式有所改变，`wait_runtime` 成员被替换成了 [`vruntime`][3]，相应的设计文档修改比较滞后，得看 [2.6.28 版本的][4]。）

> It is only a slight oversimplification to say that the above discussion covers the entirety of the CFS scheduler. There is no tracking of sleep time, no attempt to identify interactive processes, etc. In a sense, the CFS scheduler even does away with the concept of time slices; it's all a matter of whether a given process is getting the share of the CPU it is entitled to given the number of processes which are trying to run. The CFS scheduler offers a single tunable: a "granularity" value which describes how quickly the scheduler will switch processes in order to maintain fairness. A low granularity gives more frequent switching; this setting translates to lower latency for interactive responses but can lower throughput slightly. Server systems may run better with a higher granularity value.

上述介绍比较简单，远不足以覆盖整个 CFS 调度器的设计。新的设计还包括：不再跟踪（任务的）睡眠时间，也不再尝试识别某个进程是否是属于交互类进程，等等。从某种意义上说，CFS 调度器的代码甚至不再考虑时间片（time slices）的概念；而仅需要考虑在已知处于运行态的进程的数量的前提下，确定一个给定的进程是否获得了它应该享有的 CPU 使用份额。CFS 调度器只提供了一个用于调节的参数：称之为 “粒度（granularity）”（译者注，即 `/proc/sys/kernel/sched_granularity_ns`），用于描述为了维持公平性，调度器应该以多大的速度切换进程。较低的粒度值意味着更频繁的切换；这会给交互响应带来更低的延迟，代价是会略微降低吞吐量。服务器系统为了运行得更好可以设置较高的粒度值。

> Ingo claims that the CFS scheduler provides solid, fair interactive response in almost all situations. There's a whole set of nasty programs in circulation which can be used to destroy interactivity under the current scheduler; none of them, says Ingo, will impact interactivity under CFS.

Ingo 声称，CFS 调度器几乎在所有情况下都可以提供可靠、公平的交互式响应。对当前内核来说（基于现有的调度器），存在很多令人头痛的应用会破坏其交互性能；但 Ingo 说，这些应用中没有一个能影响 CFS 下的交互表现。

> The CFS posting came with another feature which surprised almost everybody who has been watching this area of kernel development: a modular scheduler framework. Ingo describes it as "an extensible hierarchy of scheduler modules," but, if so, it's a hierarchy with no branches. It's a simple linked list of modules in priority order; the first scheduler module which can come up with a runnable task gets to decide who goes next. Currently two modules are provided: the CFS scheduler described above and a simplified version of the real-time scheduler. The real-time scheduler appears first in the list, so any real-time tasks will run ahead of normal processes.

CFS 的补丁提交中附带了另一个让几乎所有关注内核开发领域的人都感到非常惊讶的功能：一个模块化的调度器框架。Ingo 将其描述为 “一个可扩展的用于管理调度器模块的层次结构”，但严格来说，该层次结构并不是树状结构。它仅仅是按优先级顺序将各个模块（译者注，即调度器类对象，每个对象是 `struct sched_class`）串联在一个链表上；（链表中）第一个能够挑选出可运行任务的模块决定了下一个将获得 CPU 的任务是谁。目前内核仅提供了两个模块：一个是上面提到的 CFS 调度器，还有一个是简化版本的实时（real-time）调度器。在链表中实时调度器排在前面，因此任何实时任务都将在 “普通（normal）” 进程（译者注，即由 CFS 负责调度的非实时任务）之前运行。

> There is a relatively small set of methods implemented by each scheduler module, starting with the queueing functions:

每个调度器模块都需要实现一组有限的回调函数，先从一组和运行队列管理相关的函数开始介绍：

	void (*enqueue_task) (struct rq *rq, struct task_struct *p);
	void (*dequeue_task) (struct rq *rq, struct task_struct *p);
	void (*requeue_task) (struct rq *rq, struct task_struct *p);

> When a task enters the runnable state, the core scheduler will hand it to the appropriate scheduler module with `enqueue_task()`; a task which is no longer runnable is taken out with `dequeue_task()`. The `requeue_task()` function puts the process behind all others at the same priority; it is used to implement `sched_yield()`.

当一个任务进入可运行状态时，核心调度器将通过调用 `enqueue_task()` 将该任务传递给适当的调度器模块；`dequeue_task()` 用于将不可运行的任务移出。通过调用 `requeue_task()` 函数可以将某个进程排在所有其他相同优先级的进程之后；该函数可被用于实现 `sched_yield()`。

> A few functions exist for helping the scheduler track processes:

以下是一些用于帮助调度器跟踪进程的函数：

	void (*task_new) (struct rq *rq, struct task_struct *p);
	void (*task_init) (struct rq *rq, struct task_struct *p);
	void (*task_tick) (struct rq *rq, struct task_struct *p);

> The core scheduler will call `task_new()` when processes are created. `task_init()` initializes any needed priority calculations and such; it can be called when a process is reniced, for example. The `task_tick()` function is called from the timer tick to update accounting and possibly switch to a different process.

核心调度器将在创建进程时调用 `task_new()`。 `task_init()` 函数会对所需的优先级完成初始化等工作；例如，在重新调整程序运行优先级时该函数会被调用（译者注，譬如执行 `renice` 命令）。定时器中断处理函数中会调用 `task_tick()` 函数完成统计数据更新以及执行进程切换。

> The core scheduler can ask a scheduler module whether the currently executing process should be preempted now:

核心调度器可以通过以下函数向具体的调度器模块询问当前正在执行的进程是否可以被抢占：

	void (*check_preempt_curr) (struct rq *rq, struct task_struct *p);

> In the CFS scheduler, this check tests the given process's priority against that of the currently running process, followed by the fairness test. When the fairness test is done, the scheduling granularity is taken into account, possibly allowing a process to run a little longer than strict fairness would allow.

在 CFS 调度器中，该函数会先将给定进程（译者注，由参数 `p` 决定）的优先级与当前正在运行的进程的优先级进行比较，然后再检查其公平性。完成公平性测试后，会考虑调度的粒度问题，这可能会调整进程的运行时间，使其比为了满足严格意义下的公平性所允许的时间长一些（译者注，有关这部分的代码细节可以参考 [`check_preempt_curr_fair()`][5]）。

> When it's time for the core scheduler to choose a process to run, it will use these methods:

当核心调度器选择要运行的进程时，它将调用以下方法：

	struct task_struct * (*pick_next_task) (struct rq *rq);
	void (*put_prev_task) (struct rq *rq, struct task_struct *p);

> The call to `pick_next_task()` asks a scheduler module to decide which process (among those in the class managed by that module) should be running currently. When a task is switched out of the CPU, the module will be informed with a call to `put_prev_task()`.

`pick_next_task()` 用于请求某个调度器模块在其管理的所有的同类进程中决定当前应该运行哪个进程。当任务从 CPU 被切换出来时，将通过调用 `put_prev_task()` 通知该模块。

> Finally, there's a pair of methods intended to help with load balancing across CPUs:

最后，有一对旨在支持跨 CPU 实现负载平衡（load balancing）的函数：

	struct task_struct * (*load_balance_start) (struct rq *rq);
	struct task_struct * (*load_balance_next) (struct rq *rq);

> These functions implement a simple iterator which the scheduler can used to work through all processes currently managed by the scheduling module.

这些函数实现了一个简单的迭代器，调度器可以使用它来遍历其管理的所有进程。

> One assumes that this framework could be used to implement different scheduling regimes in the future. It might need some filling out; there is, for example, no way to prioritize scheduling modules (or choose the default module) other than changing the source. Beyond that, if anybody ever wants to implement modules which schedule tasks at the same general priority level, the strict priority ordering of the current framework will have to change - and that could be an interesting task. But it's a start.

在人们看来，这个框架可以被用于在未来实现不同的调度机制。但可能还需要一些改进；例如，（当前的补丁实现中）除非更改源码，否则没有办法调整调度模块的执行优先级（以及选择默认的模块）。除此之外，如果有人想要实现以相同的一般优先级调度所有任务，那么也将不得不对当前框架下按固定优先级进行排序的逻辑进行修改，这可真是一项有趣的任务。但这毕竟还只是一个开始。

> The reason that this development is so surprising is that nobody had really been talking about modular schedulers. And the reason for that silence is that pluggable scheduling frameworks had been soundly rejected in the past - [by Ingo Molnar](http://lwn.net/Articles/109460/), among others:

> 	So i consider scheduler plugins as the STREAMS equivalent of scheduling and i am not very positive about it. Just like STREAMS, i consider 'scheduler plugins' as the easy but deceptive and wrong way out of current problems, which will create much worse problems than the ones it tries to solve.

之所以大家对这个新功能感到如此惊讶，是因为并没有人曾经真正提到过想要模块化调度器这个事。无人讨论的原因在于，可插拔的调度框架在过去曾经被很多人彻底拒绝了，甚至包括 [Ingo Molnar 本人][11]，他曾经说过：

	我认为调度器插件的作用等同于 STREAMS 那样的调度机制，我对它不是很看好。就像 STREAMS 一样，我认为 “调度程序插件” 针对当前问题的解决表面上看起来是比较简单，但实际上具有一定的欺骗性而且该方法本身就是错误的，这无助于问题的解决而只会使事情变得更糟糕。

> So the obvious question was: what has changed? Ingo has posted [an explanation](https://lwn.net/Articles/230628/) which goes on at some length. In essence, the previous pluggable scheduler patches were focused on replacing the entire scheduler rather than smaller pieces of it; they did not help to make the scheduler simpler.

所以显而易见的问题是：是什么改变了这一切？Ingo 发表了一个相当长的 [解释][12]。总的来说，以前的可插拔调度器补丁专注于替换整个调度程序而不是对其做局部性的修补；这只会使得代码变得更复杂。

> So now there are three scheduler replacement proposals on the table: SD by Con Kolivas, CFS by Ingo Molnar, and "nicksched" by Nick Piggin (a longstanding project which clearly deserves treatment on this page as well). For the moment, Con appears to have decided to take his marbles and go home, removing SD from consideration. Still, there are a few options out there, and one big chance (for now) to replace the core CPU scheduler. While Ingo's work has been generally well received, not even Ingo is likely to get a free pass on a decision like this; expect there to be some serious discussion before an actual replacement of the scheduler is made. Among other things, that suggests that a new scheduler for 2.6.22 is probably not in the cards.

所以现在存在三个调度器备选方案：Con Kolivas 的 SD，Ingo Molnar 的 CFS，以及 Nick Piggin 的 “nicksched”（一个长期的项目，也非常值得在这里一并列出）。目前，Con 似乎决定退出。尽管如此，他的补丁（至少目前）还是有很大的机会来替换核心 CPU 调度器。Ingo 的工作虽然受到大家的普遍欢迎，但这并不意味着 Ingo 在这件事情上就能够轻松胜出；在正式决定替换调度器之前必然还要经过一些认真的讨论。以上种种迹象表明，要想在 2.6.22 版本发布周期中替换掉现有的调度器还不太可能。（译者注，笑到最后的是 CFS 调度器，并于 [2.6.23 版本合入内核主线][6]，历经稍后几个版本的修修补补，一直稳定地使用到现在。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://elixir.bootlin.com/linux/v2.6.23/source/Documentation/sched-design-CFS.txt
[2]: https://elixir.bootlin.com/linux/v2.6.23/source/include/linux/sched.h#L896
[3]: https://elixir.bootlin.com/linux/v2.6.24/source/include/linux/sched.h#L873
[4]: https://elixir.bootlin.com/linux/v2.6.28/source/Documentation/scheduler/sched-design-CFS.txt
[5]: https://elixir.bootlin.com/linux/v2.6.23/source/kernel/sched_fair.c#L979
[6]: https://kernelnewbies.org/Linux_2_6_23#The_CFS_process_scheduler
[7]: https://lwn.net/Articles/224865/
[8]: https://lwn.net/Articles/230500/
[9]: https://lwn.net/Articles/230752/
[10]: https://lwn.net/Articles/184495/
[11]: https://lwn.net/Articles/109460/
[12]: https://lwn.net/Articles/230628/
[13]: https://lwn.net/Articles/230501/
