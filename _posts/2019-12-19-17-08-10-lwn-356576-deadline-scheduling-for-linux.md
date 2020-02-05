---
layout: post
draft: true
top: false
author: 'Yuan Xiaojie'
title: "LWN 356576: Linux的截止时间调度（deadline scheduling）"
album: "LWN 中文翻译"
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-356576/
description: "LWN 文章翻译，自适应文件预读算法"
category:
  - LWN
tags:
  - Linux
  - scheduler
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Deadline scheduling for Linux](https://lwn.net/Articles/356576/)
> 原创：By corbet @ Oct. 13, 2009
> 翻译：By [Xiaojie Yuan](https://github.com/llseek)
> 校对：By [Bennny Zhao](https://github.com/Bennnyzhao)

> Much of the realtime scheduling work in Linux has been based around getting the best behavior out of the POSIX realtime scheduling classes. Techniques like priority inheritance, for example, exist to ensure that the highest-priority task really can run within a bounded period of time. In much of the rest of the world, though, priorities and POSIX realtime are no longer seen as the best way to solve the problem. Instead, the realtime community likes to talk about "deadlines" and deadline-oriented scheduling. In this article, we'll look at a deadline scheduler has recently been posted for review and related discussion at the recent Real Time Linux Workshop in Dresden.

Linux 里的许多实时调度工作立足于从 POSIX 实时调度类里得到最好的表现。比如说像优先级继承这种技术用来保证最高优先级的任务可以在一个时间段内得到执行。但是在很多其他场景下，优先级和 POSIX 实时不再被认为是解决该问题的最好办法。相反地，实时社区喜欢讨论“截止时间”和面向截止时间的调度。在这篇文章里，我们会来看看在 Dresden 举行的实时 Linux 研讨会上发布出来审阅的一个截止时间调度器和相关讨论。

> Priority-based realtime scheduling has the advantage of being fully deterministic - the highest-priority task always runs. But priority-based scheduling is subject to some unpleasant failure modes ([priority inversion](http://en.wikipedia.org/wiki/Priority_inversion) and starvation, for example), does not really isolate tasks running on the same system, and is often not the best way to describe the problem. Most tasks are more readily described in terms of an amount of work which must be accomplished within a specific time period; the desire to work in those terms has led to a lot of research in deadline-based scheduling in recent years.

基于优先级的实时调度的好处是完全可确定 - 也就是说最高优先级的任务总是能得到执行。但是基于优先级的调度有一些明显的缺点（比如说 [优先级反转][2]和任务请求饥饿），它并不能真正地隔离同一个系统上运行的任务，所以不是解决这种问题的最好方式。大部分任务可以被更容易地描述成一部分工作必须在某个时间段内完成，以这种方式工作的需求促成了近几年来很多针对基于截止时间调度的研究。

> A deadline system does away with static priorities. Instead, each running task provides a set of three scheduling parameters:
>    * A deadline - when the work must be completed.
>    * An execution period - how often the work must be performed.
>    * The worst-case execution time (WCET) - the maximum amount of CPU time which will be required to get the work done. 

截止时间系统不再使用静态优先级方式。每个运行的任务有三个调度参数：
* 截止期限 - 这项工作什么时候必须完成
* 执行周期 - 这项工作执行的频度
* 最坏情况下的执行时间 - 完成这项工作最多需要的 CPU 时间

> Deadline-scheduled tasks usually recur on a regular basis - thus the period parameter - but sporadic work can also be handled with this model.

之所以需要执行周期这个参数是因为按截止时间调度的任务通常会有规律地重复发生。但是零星任务[1]可以用这个模型来处理。

> There are some advantages to this model. The "bandwidth" requirement of a process - what percentage of a CPU it needs - is easily calculated, so the scheduler knows at the outset whether the system is oversubscribed or not. The scheduler can (and should) refuse to accept tasks which would require more bandwidth than the system has available. By refusing excess work, the scheduler will always be able to provide the requisite CPU time to every process within the specified deadline. That kind of promise makes realtime developers happy.

这个模型有一些好处，比如说，一个进程的“带宽”需求（指它需要多少百分比的 CPU 时间)很容易计算，所以调度器一开始就能知道这个系统是不是被超额预订了。如果新任务的带宽需求超过了系统当前所能提供的，调度器可以（并且应该)拒绝接受这项任务。通过拒绝超额任务，调度器可以在截止时间内给每个进程提供必要的 CPU 时间。这种承诺使实时开发者高兴。

> Linux currently has no deadline scheduler. There is, however, [an implementation posted for review](http://lwn.net/Articles/353797/) by Dario Faggioli and others; Dario also presented this scheduler in Dresden. This implementation uses the "earliest deadline first" (EDF) algorithm, which is based on a simple concept: the process with the earliest deadline will be the first to run. Essentially, EDF attempts to ensure that every process begins executing by its deadline, not that it actually gets all of its work done by then. Since EDF runs work as early as possible, most tasks should complete well ahead of their declared deadlines, though.

Linux 目前没有截止时间调度器，但是 Dario Faggioli 等人 [提出了一种实现等待审阅][3]； Dario 也在 Dresden 展示了他的调度器。他的实现使用了“最早截止时间最先调度” （EDF）算法。这个算法基于一个简单的概念：截止时间最早的进程最先运行。实质上，EDF 只尝试保证每个进程在它的截止时间之前开始运行，而并不保证在截止时间之前能够完成工作。因为 EDF 尽早执行工作，所以大部分任务应该能在它们声明的截止时间之前很好得跑完。

> This scheduler is implemented with the creation of a new scheduling class called `SCHED_EDF`. It does away with the distinction between the "deadline" and "period" parameters, using a single time period for both. The patch places this class between the existing realtime classes (`SCHED_FIFO` and `SCHED_RR`) and the normal interactive scheduling class (`SCHED_FAIR`). The idea behind this placement was to avoid breaking the "highest priority always runs" promise provided by the POSIX realtime classes. Peter Zijlstra, though, [thinks](https://lwn.net/Articles/356587/) that deadline scheduling should run at the highest priority; otherwise it cannot ensure that the deadlines will be met. That placement could be seen as violating POSIX requirements; to that, Peter responds, "In short, sod POSIX."

随着该调度器的实现同时也创建了一个名叫 `SCHED_EDF` 的调度类。它消除了“截止时间”和“执行周期”这两个参数的区别，只用了一个时间周期参数。补丁把这个调度类放在已有的实时调度类（`SCHED_FIFO` 和 `SCHED_RR` )和普通交互式调度类（`SCHED_FAIR`）之间。这背后的原因是为了避免打破 POSIX 实时调度类的“最高优先级任务总是运行”的原则。但是 Peter Zijlstra [认为][4] 截止时间调度应该运行在最高优先级，不然没法保证在截止时间内完成。放在这个位置可以看作是违背了 POSIX 的要求，Peter 就此回应道，“去他的 POSIX ”。

> Peter would also like to name the scheduler `SCHED_DEADLINE`, for the simple reason that EDF is not the only deadline algorithm out there. In the future, it may be desirable to switch to a different algorithm without forcing applications to change which scheduling class they request. At the moment, the other contender would appear to be "least laxity first" scheduling, which picks the task with the smallest amount of "cushion" time between its remaining compute time and its deadline. Least laxity first tries to ensure that each process can complete its computing by the deadline. It tends to suffer from much higher context-switching rates than EDF, though, and nobody is pushing such a scheduler for Linux at the moment.

Peter 也想把这个调度器叫做 `SCHED_DEADLINE`，因为 EDF 不是唯一一种截止时间算法。如果将来切换到另一种算法，应用程序不需要更改它们请求的调度类。目前其他截止时间调度算法是选择“缓冲”时间（到截止时间前剩余的计算时间）最少任务的“最少剩余度优先”调度。这个算法尝试保证每个进程能够在截止时间前完成计算，但缺点是比 EDF 更频繁的上下文切换，所以目前没有人为 Linux 推广这个调度器。

> One nice feature of deadline schedulers is that no process should be able to prevent another from completing its work before its deadline passes. The real world is messier than that, as we will see below, but, even in the absence of deeper problems, the scheduler can only make that guarantee if every process actually stops running within its declared WCET. The EDF scheduler solves that problem in an unsubtle way: when a process exceeds its bandwidth, it is simply pushed out of the CPU until its next deadline period begins. This approach is simple to implement and ensures that deadlines will be met, but it can be hard on a process which must do a bit of extra computing on occasion.

截止时间调度器的一个好特性是没有进程能够阻止另一个进程在它的截止时间之前完成。我们下面会看到现实世界比这个复杂得多。排除一些更加深奥的问题，有个简单的问题是，每个进程只有在它自己声明的 WCET 之前停止运行，调度器才能保证这个特性。EDF 调度器用了一种简单的办法来解决这个问题：当一个进程耗尽了它的带宽，它就会被踢出 CPU 直到它的下一个执行周期开始。这种方法实现起来很简单并且能保证进程们的截止时间符合预期，但是对于需要偶尔做一些额外计算的进程很不友好。

> In the `SCHED_EDF` patch, processes indicate the end of their processing period by calling `sched_yield()`. This modification to the semantics of that system call makes some developers uneasy, though; it is likely that the final patch will do something different. There may be a new "I'm done for now" system call added for this purpose.

在 `SCHED_EDF` 补丁中，进程通过调用 `sched_yield()` 来表明它自己的计算周期结束了，但是对于该系统调用的这种语义修改使一些开发者很不适应。在最终版的补丁中可能会有改动，比如为了这个目的新增一个表示“我现在跑完了”的系统调用。

> Peter also gave a talk in Dresden; his was mostly about why Linux does not have a deadline scheduler yet. The "what happens when a process exceeds its WCET" problem was one of the reasons he gave. Calculating the worst-case execution time is exceedingly difficult for any sort of non-trivial program. As Peter puts it, researchers have spent their entire lives trying to solve it. There are people working on automatically deriving WCET from the source, but they are far from being able to do this with real-world systems. So, for now, specification of the WCET comes down to empirical observations and guesswork.

Peter 在 Dresden 也发表了一个演讲，主要是关于为什么 Linux 还没有一个截止时间调度器。他给出的理由之一是“当一个进程耗尽了它的 WCET 怎么办”的问题还没解决。计算 WCET 对于一些复杂程序来说是及其困难的。就像 Peter 说的，研究者们已经花了毕生时间来解决这个问题。有些人正在研究从源码推导出 WCET，但是面对实际的系统还远没有成功。所以现在 WCET 的定义还是归结到经验主义和猜测。

> Another serious problem with EDF is that it works much better on single-processor systems than on SMP systems. True EDF on a multiprocessor system requires the maintenance of a global run queue, with all of the scalability problems that entails. One solution is to partition SMP systems, so that each CPU becomes an essentially independent scheduling domain; the SCHED_EDF patch works this way. Partitioned systems have their own problems, of course; the assignment of tasks to CPUs can be a pain, and it is hard (or impossible) to get full utilization if tasks cannot move between CPUs.

另一个严重的问题是 EDF 在单核系统上工作得远比在多核系统上好。真正的在多核系统上的 EDF 需要维护一个全局的运行队列，也就附带了所有的可扩展性问题。一个解决方案是给多核系统分区，以便每个 CPU 成为一个基本上独立的调度域，SCHED_EDF 补丁就在这种方式下工作。当然分区后的系统有它们自己的问题，比如分配任务到各 CPU 会很困难，并且如果任务不能在 CPU 间迁移那么很难（或者说不可能）达到充分利用 CPU。

> Another problem with partitioning is that some scheduling problems simply cannot be solved without occasional process migration. Imagine a two-CPU system running three processes, each of which needs 60% of a single CPU's time. The system clearly has the resources to run those three processes, but not if it is unable to move processes between CPUs. So a partitioned EDF scheduler needs to be able to migrate processes occasionally; the SCHED_EDF developers have migration logic in the works, but it has not yet been posted.

分区的另一个问题是不能通过偶尔的进程迁移来简单地解决一些调度问题。假设运行3个进程的2核 CPU 系统，每个进程需要 60% 的 CPU 时间。这个系统明显有运行这三个进程的资源，但是如果进程不能在 CPU 间迁移得话就不行了。所以分区后的 EDF 调度器需要偶尔迁移进程。SHED_EDF 开发者的成果里有这种迁移逻辑，但是还没有被公布出来。

> Yet another serious problem, according to Peter, is priority inversion. The priority inheritance techniques used to solve priority inversion are tied to priorities; it is not clear how to apply them to deadline schedulers. But the problem is real: imagine a process acquiring an important lock, then being preempted or forced out because it has exceeded its WCET. That process can then block the execution of otherwise runnable processes with urgent deadlines.

Peter 说的另一个严重问题是优先级反转。用来解决优先级反转的优先级继承技术是和优先级绑定的，所以并不清楚怎么把它应用到截止时间调度器上。但存在这样的问题：假设一个进程获取了一把关键的锁，然后因为超过了它的 WCET 而被抢占。那么这个进程可能就会堵塞其他截止时间将近的进程（这些进程拿到了这把锁就能变为可运行状态）。

> There are a few ways to approach this issue. Simplest, perhaps, is deadline inheritance: lock owners inherit the earliest deadline in the system for as long as they hold the lock. More sophisticated is bandwidth inheritance; in this case, a lock owner which has exhausted its WCET will receive a "donation" of time from the process(es) blocked on that lock. A variant of that technique is proxy execution: blocked processes are left on the run queue, but, when they "run," the lock owner runs in their place. Proxy execution gets tricky in SMP environments when multiple processes are blocked on the same lock; the result could be multiple CPUs trying to proxy-execute the same process. The solution to that problem appears to be to migrate blocked processes to the owner's CPU.

有一些方法能处理这个问题。最简单的也许是截止时间继承：只要它们持有着锁，锁的持有者就继承系统里最早的截止时间。更复杂的方法是带宽继承，在这种情况下，耗尽了 WCET 的锁持有者会收到阻塞在这把锁上的进程的“捐赠”时间。这种技术的一种变种是代理执行：被阻塞的进程留在运行队列里，但是当它们“运行”时，锁持有者代替它们运行。在多核环境多个进程阻塞在同一把锁的情境中，代理执行就变得很棘手，可能导致多个 CPU 都在尝试代理执行同一个进程。这个问题的解法似乎是把被阻塞的进程迁移到锁持有者的 CPU 上。

> Proxy execution also runs into difficulties when the lock-owning process is blocked for I/O. In that case, it cannot run as a proxy for the original blocked task, which must then be taken off the run queue. That, in turn, forces the creation of a "wait list" of processes which must be returned to a runnable state when a different process (the lock owner) becomes runnable. Needless to say, all this logic adds complexity and increases system overhead.

当持有锁的进程阻塞在 I/O 时，代理执行也会遇到困难。这种情况下，它不能为原来被阻塞的任务作为代理，因为它自己必须被从运行队列上拿走。这反过来迫使我们创建一个“等待列表”，当持有锁的进程变为可执行时，列表上的进程才能恢复到可执行状态。不用说，所有这些逻辑增加了复杂性和系统开销。

> The final problem, according to Peter, is POSIX, but it's an easy one to solve. Since POSIX is silent on the topic of deadline schedulers, we can do anything we want and life is good. He repeated that `SCHED_DEADLINE` will probably be placed above `SCHED_FIFO` in priority. There will be a new system call - `sched_setscheduler_ex()` - to enable processes to request the deadline scheduler and set the parameters accordingly; the `SCHED_EDF` patch already implements that call. So many of the pieces for deadline scheduling for Linux are in place, but a number of the details are yet to be resolved.

据 Peter 说的最后一个问题是 POSIX，但是这个好解决。因为 POSIX 还没有定义截止时间调度器相关的标准，我们可以做任何我们想做的。他重复强调说，在优先级上 `SCHED_DEADLINE` 大概会被放在 `SCHED_FIFO` 上面。`SCHED_EDF` 补丁已经实现了一个新的系统调用 - `sched_setscheduler_ex()` 来使进程请求截止时间调度器并且设置相应的参数。所以 Linux 截止时间调度器的很多部件都就位了，但是许多细节还没有被解决。

> The bottom line is that deadline schedulers in the real world are a non-trivial problem - something that is true of real-world scheduling in general. These problems should be solvable, though, and Linux should be able to support a deadline scheduler at some point in the future. That scheduler will probably make its first appearance in the realtime tree, naturally, but it could eventually find users well beyond the realtime community. Deadline schedulers are a fairly natural fit for periodic tasks like the management of streaming media, which could profitably make use of deadline scheduling to help eliminate jitter and dropped-data problems. But that remains a little while in the future; first, the code must be made ready for widespread use. And that, as we all know, is a process which recognizes few deadlines.

现实世界里的截止时间调度器并不是一个简单的问题 - 一般而言现实世界里的调度都是这样的。但是这些问题应该是可以解决的，Linux 应该可以在将来的某个时候支持截止时间调度器。这个调度器也许会很自然地在实时源码树里第一次出现，但是它最终会找到实时社区之外的更多用户。截止时间调度器很适合调度和类似流媒体管理的周期性任务，截止时间调度能帮助消除抖动和数据丢失问题。但截止时间调度器在将来的出现可能还仍要一会儿，因为首先这些代码必须已经准备好被广泛使用，另外众所周知的是代码进入 Linux 主线的流程是没有确定的截止日期的。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: 零星任务(sporadic task)类似于周期性任务(periodic task)，但是只定义了最小的时间间隔，比如假设最小时间间隔是20ms，那么可能距上一次发生间隔20ms，也可能间隔30ms，但肯定不会少于20ms
[2]: http://en.wikipedia.org/wiki/Priority_inversion
[3]: http://lwn.net/Articles/353797/
[4]: https://lwn.net/Articles/356587/