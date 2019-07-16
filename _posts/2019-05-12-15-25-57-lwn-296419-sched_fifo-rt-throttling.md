---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 296419: SCHED_FIFO 和实时任务抑制（throttling）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-296419/
description: "LWN 中文翻译，SCHED_FIFO 和实时任务抑制（throttling）"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - realtime
  - throttling
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[SCHED_FIFO and realtime throttling](https://lwn.net/Articles/296419/)
> 原创：By Jonathan Corbet @ Sept. 1, 2008
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Shaolin Deng](https://github.com/ShaolinDeng)

> The SCHED_FIFO scheduling class is a longstanding, POSIX-specified realtime feature. Processes in this class are given the CPU for as long as they want it, subject only to the needs of higher-priority realtime processes. If there are two SCHED_FIFO processes with the same priority contending for the CPU, the process which is currently running will continue to do so until it decides to give the processor up. SCHED_FIFO is thus useful for realtime applications where one wants to know, with great assurance, that the highest-priority process on the system will have full access to the processor for as long as it needs it.

SCHED_FIFO 是为了支持实时特性，遵循 POSIX 标准开发的调度器类，其存在已经有很长一段历史了。该类型的进程在运行时将一直占用处理器，除非被更高优先级的实时进程所抢占。如果有两个具有相同优先级的 SCHED_FIFO 进程竞争处理器，则当前正在运行的进程将一直运行，直到它主动放弃处理器。因此，SCHED_FIFO 调度类对于实时应用非常有用，因为在这些应用看来，（通过创建 SCHED_FIFO 类型的任务）可以明确地知道，只要任务的优先级足够高它就可以随心所欲地使用处理器。

> One of the many features merged back in the 2.6.25 cycle was realtime group scheduling. As a way of balancing CPU usage between competing groups of processes, each of which can be running realtime tasks, the group scheduler introduced the concept of "realtime bandwidth," or rt_bandwith. This bandwidth consists of a pair of values: a CPU time accounting period, and the amount of CPU that the group is allowed to use - at realtime priority - during that period. Once a SCHED_FIFO task causes a group to exceed its rt_bandwidth, it will be pushed out of the processor whether it wants to go or not.

“实时组调度（realtime group scheduling）” 是在 2.6.25 版本开发周期期间合入的众多特性之一。多个 “任务组（task group）” 以组为单位竞争处理器资源，每个任务组中都可以包含实时任务，为了调节和平衡各个组对处理器的使用，“组调度器（group scheduler）” 引入了 “实时带宽（realtime bandwidth）” 的概念，下文简称 rt_bandwith（译者注：参考 `struct task_group` 中的 `rt_bandwith`）。我们可以通过一对控制参数来完成对实时带宽的调节：一个用于设置  “处理器时间记账周期（CPU time accounting period）”（译者注：`/proc/sys/kernel/sched_rt_period_us`），还有一个用于针对一个任务组内的实时任务设置在一个记账周期单位内允许使用的处理器时间配额（译者注：`/proc/sys/kernel/sched_rt_runtime_us`）。一旦在一个周期单位内，某个 SCHED_FIFO 任务导致该组内的实时任务的运行时间总量超出了 rt_bandwidth 所允许的配额，则无论该组中的实时任务是否运行结束，都将被终止（直到下个周期单位开始再恢复运行）。

> This feature is required if one wants to allow multiple groups to split a system's realtime processing power. But it also turns out to have its uses in the default situation, where all processes on the system are contained within a single, default group. Kernels shipped since 2.6.25 have set the rt_bandwidth value for the default group to be 0.95 out of every 1.0 seconds. In other words, the group scheduler is configured, by default, to reserve 5% of the CPU for non-SCHED_FIFO tasks.

该特性可用于支持将系统的实时处理能力在多个组之间进行分配。同样该功能也会影响系统缺省情况下的行为（若不做特殊设置系统上的所有进程都处于一个默认的组中）。自 2.6.25 发布以来的内核已将默认组的 rt_bandwidth 值设置为每 1.0 秒中允许运行 0.95 秒。换句话说，组调度器的缺省配置是，SCHED_FIFO 类型的任务最多可以使用处理器计算能力的百分之九十五。

> It seems that nobody really noticed this feature until mid-August, when Peter Zijlstra posted a patch which set the default value to "unlimited." At that point it became clear that some developers have a different idea about how this kind of policy should be set than others do.

似乎并没有人真正注意到这个功能，直到 8 月中旬 Peter Zijlstra 提交了一个补丁，希望将默认值设置为 “无限制（unlimited）”（译者注，即允许实时任务使用 100 % 的处理器计算能力）。这引起了其他一些开发人员的注意，并对如何设置该策略提出了不同的看法。

> Ingo Molnar [disagreed](https://lwn.net/Articles/296422/) with the patch, saying:

Ingo Molnar 对该补丁发表了 [反对意见][1]，他说：

>	The thing is, i got far more bugreports about locked up RT tasks where the lockup was unintentional, than real bugreports about anyone _intending_ for the whole box to come to a grinding halt because a high-prio RT tasks is monopolizing the CPU.

	事实情况是，我收到了很多有关实时任务的问题报告，由于高优先级的实时任务独占了处理器导致系统无法正常运行，其中大部分报告的原因并不是由于用户有意想要这么做。

> Ingo's suggestion was to raise the limit to ten seconds of CPU time. As he (and others) pointed out: any SCHED_FIFO application which needs to monopolize the CPU for that long has serious problems and needs to be fixed.

Ingo 的建议是将 “记账周期” 的限制提高到 10 秒（译者注，这样会使得一个长时间独占处理器的实时任务所造成的影响更容易暴露出来）。正如他（和其他人）所认为的那样：如果一个 SCHED_FIFO 类型的应用独占处理器的时间会持续到这么久，那这个应用多半存在严重的问题，需要改进。

> There are real problems associated with letting a SCHED_FIFO process run indefinitely. Should that process never get around to relinquishing the CPU, the system will simply hang forevermore; there is no possibility of the administrator slipping in with a `kill` command. This process will also block important things like kernel threads; even if it releases the processor after ten seconds, it will have seriously degraded the operation of the rest of the system. Even on a multiprocessor system, there will typically be processes bound to the CPU where the SCHED_FIFO process is running; there will be no way to recover those processes without breaking their CPU affinity, which is not a step anybody wants to take.

允许 SCHED_FIFO 类型的进程无限期地运行绝对是个错误的想法。如果这个进程永远不放弃处理器，系统将永远被挂起；管理员甚至没有机会输入 `kill` 命令。这个进程还会阻塞像内核线程这样的重要任务运行；即便它在 10 秒后释放了处理器，也会严重影响系统中其他部分的运行。在一个多处理器系统上，通常某些进程会被设置为绑定（bound）在某个处理器上运行，一旦 SCHED_FIFO 类型的进程霸占了同一个处理器（导致绑定进程无法运行）；唯一的解决方法只有首先解除那些进程和处理器之间的绑定关系，但这不是所有的用户都可以接受的。

> So, it is argued, the rt_bandwidth limit is an important safety breaker. With it in place, even a runaway SCHED_FIFO cannot prevent the administrator from (eventually) regaining control of the system and figuring out what is going on. In exchange for this safety, this feature only robs SCHED_FIFO tasks of a small amount of CPU time - the equivalent of running the application on a slightly weaker processor.

因此，有人认为，rt_bandwidth 限制是一个重要的安全保障措施。有了它，即使 SCHED_FIFO 类型的进程运行失控也不会妨碍管理员（最终）重新获得对系统的控制，从而有助于管理员查清故障的原委。为了换取这种安全性，该功能需要占用 SCHED_FIFO 任务少量的处理器运行时间，其效果也就是等同于换了一个性能稍微差一点的处理器而已。

> Those opposed to the default rt_bandwidth limit cite two main points: it is a user-space API change (which also breaks POSIX compliance) and represents an imposition of policy by the kernel. On the first point, Nick Piggin [worries](https://lwn.net/Articles/296425/) that this change could lead to broken applications:

而那些反对提供缺省 rt_bandwidth 限制的人的主要理由包括以下两点：这是一个用户空间级别的接口更改（而且该改动还破坏了对 POSIX 标准的兼容性要求）；该缺省值的存在意味着从内核角度为用户强行施加了一种策略控制。对于第一点，Nick Piggin [担心][2] 这种变化可能会影响应用程序的执行：

> 	It's not common sense to change this. It would be perfectly valid to engineer a realtime process that uses a peak of say 90% of the CPU with a 10% margin for safety and other services. Now they only have 5%.

> 	Or a realtime app could definitely use the CPU adaptively up to 100% but still unable to tolerate an unexpected preemption.

	这么修改并不常见（译者注，指 Ingo 的建议）。大部分情况下，实时任务会使用 90% 的处理器计算量，同时为了系统安全和其他工作保留余下的 10%。现在的缺省配置只有 5%（这显然还不够）。

	有时候实时应用甚至需要 100% 地占用处理器，任何抢占行为都是无法容忍的。

> What could make the problem worse is that the throttle might not cut in during testing; it could, instead, wait until something unexpected comes up in a production system. Needless to say, that is a prospect which can prove scary for people who create and deploy this kind of system.

更糟糕的是，在测试阶段可能并不一定会触发对实时任务运行的限制；而到了实际工作现场这件事却可能会发生，并导致产生一些意想不到的后果。毋庸置疑，这对于创建和部署此类系统的人来说，是绝对不想看到的。

> The "policy in the kernel" argument was mostly [shot down by Linus](https://lwn.net/Articles/296427/), who pointed out that there's lots of policy in the kernel, especially when it comes to the default settings of tunable parameters. He says:

对于类似 “内核中提供策略” 的观点（译者注，指上文提到的那些反对设置缺省策略的人所提出的两点理由中的第二点）已经几乎彻底 [被 Linus 否定了][3]，他指出内核中一直存在很多策略，譬如针对那些可调参数的默认配置。他说：

> 	And the default policy should generally be the one that makes sense for most people. Quite frankly, if it's an issue where all normal distros would basically be expected to set a value, then that value should _be_ the default policy, and none of the normal distros should ever need to worry.

	默认策略通常应该满足大多数人的需求。坦率地说，如果大部分普通发行版都会设置同样的一个值，那么这个值就应该作为默认策略存在，这样普通的发行版本就不必为此担心了。

> Linus carefully avoided taking a position on which setting makes sense for the most people here. One could certainly argue that making systems resistant to being taken over by runaway realtime processes is the more sensible setting, especially considering that there is a certain amount of interest in running scary applications like PulseAudio with realtime priority. On the other hand, one can also make the case that conforming to the standard (and expected) SCHED_FIFO semantics is the only option which makes sense at all.

在 “究竟什么值才是最有意义的” 这个问题上，Linus 显得小心翼翼，并没有发表直接的观点。人们当然可以争辩说，在选择有意义的缺省值时，更明智的做法是考虑尽量避免系统由于实时任务失控而遭到破坏，特别是考虑到有些人会热衷于采用实时优先级策略来运行像 PulseAudio 这类可怕的应用程序。另一方面，人们也可以认为遵循标准的（和理想的）SCHED_FIFO 语义才是唯一有意义的做法。

> There has been some talk of creating a new realtime scheduling class with throttling being explicitly part of its semantics; this class could, with a suitably low limit, even be made available to unprivileged processes. Meanwhile, as of this writing, the 0.95-second limit - the one option that nobody seems to like - remains unchanged. It will almost certainly be raised; how much is something we'll have to wait to see.

还有人提出创建一个新的实时调度类，允许明确地对实时任务的运行进行限制；甚至可以降低要求，允许对非特权进程设置为这个调度类。与此同时，截至本稿撰写时，虽然看上去不那么招人待见，但 “0.95 秒” 这个限制值依然维持不变。这个问题肯定还会被提出来；让我们拭目以待究竟会如何变化吧。（译者注，这么多年过去了，这个值在内核主线代码中依然没什么变化，看起来大家似乎已经忘记了当年的那些争论 ;)。）

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/296422/
[2]: https://lwn.net/Articles/296425/
[3]: https://lwn.net/Articles/296427/

