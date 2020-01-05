---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 743740: Deadline 调度介绍的第一部分：简介与理论背景"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-743740/
description: "LWN 中文翻译，Deadline 调度介绍的第一部分：简介与理论背景"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - scheduling
  - deadline
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Deadline scheduling part 1 — overview and theory](https://lwn.net/Articles/743740/)
> 原创：By Daniel Bristot de Oliveira @ Jan. 16, 2018
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Shaojie Dong](https://github.com/ShaojieDong)

> Realtime systems are computing systems that must react within precise time constraints to events. In such systems, the correct behavior does not depend only on the logical behavior, but also in the timing behavior. In other words, the response for a request is only correct if the logical result is correct and produced within a deadline. If the system fails to provide the response within the deadline, the system is showing a defect. In a multitasking operating system, such as Linux, a realtime scheduler is responsible for coordinating the access to the CPU, to ensure that all realtime tasks in the system accomplish their job within the deadline.

所谓 “实时（Realtime）” 系统指的是系统必须精准地在限定时间内对发生的事件做出响应。对这样的系统，评价其行为是否正确不仅取决于行为是否符合逻辑上的要求，还取决于其在实现上是否符合时间上的要求。换句话说，当系统对外部请求产生响应时，不仅要保证逻辑结果正确，还要保证响应足够及时，不能超出所谓的 “最后截止时间（deadline，译者注，从习惯出发，下文对该词直接使用英文，不再翻译）”，只有这样我们才认为其行为是正确的。如果不能确保在有限时间内完成工作，则我们认为该系统是有瑕疵的（译者注，即不符合 “实时性” 的要求）。在 Linux 这样的多任务操作系统中，有专门为实时任务设计的 “实时调度器（realtime scheduler）” 负责协调任务对 CPU 的访问，从而确保系统中所有的实时任务都能在规定期限内完成它们的工作。

> The deadline scheduler enables the user to specify the tasks' requirements using well-defined realtime abstractions, allowing the system to make the best scheduling decisions, guaranteeing the scheduling of realtime tasks even in higher-load systems.

Deadline 调度器提供了定义良好的接口，可以方便用户根据实际需要创建实时任务，这有助于系统做出最佳的调度决策，确保在高负载的运行压力下系统也可以对实时任务进行有效的调度。

> This article provides an introduction to realtime scheduling and some of the theory behind it. The second installment will be dedicated to the Linux deadline scheduler in particular.

本文介绍了什么是实时调度及其背后的一些理论知识。本系列还有第二篇文章将专门针对 Linux 介绍其提供的 deadline 调度器。

## Linux 中的实时调度程序（Realtime schedulers in Linux）

> Realtime tasks differ from non-realtime tasks by the constraint of having to produce a response for an event within a deadline. To schedule a realtime task to accomplish its timing requirements, Linux provides two realtime schedulers: the POSIX realtime scheduler (henceforth called the "realtime scheduler") and the deadline scheduler.

实时任务与非实时任务的不同之处在于，前者必须在有限的时间期限内对发生的事件做出响应。为了调度实时任务以满足其在时间上的要求，Linux 提供了两种实时调度器：“POSIX 实时调度器”（也称为 “实时调度器”）和 “Deadline 调度器”。

> The POSIX realtime scheduler, which provides the FIFO (first-in-first-out) and RR (round-robin) scheduling policies, schedules each task according to its fixed priority. The task with the highest priority will be served first. In realtime theory, this scheduler is classified as a fixed-priority scheduler. The difference between the FIFO and RR schedulers can be seen when two tasks share the same priority. In the FIFO scheduler, the task that arrived first will receive the processor, running until it goes to sleep. In the RR scheduler, the tasks with the same priority will share the processor in a round-robin fashion. Once an RR task starts to run, it will run for a maximum quantum of time. If the task does not block before the end of that time slice, the scheduler will put the task at the end of the round-robin queue of the tasks with the same priority and select the next task to run.

“POSIX 实时调度器” 支持 “先进先出（FIFO，即 first-in-first-out）” 和 “轮转循环（RR，即 round-robin）” 两种 “调度策略（scheduling policies）”，并基于任务的固定优先级安排每个任务的运行。优先级高的任务将被优先处理。按照实时性相关理论，这样的调度器被归类为基于固定优先级的调度程序。当所调度的两个任务的优先级相同时，从对它们的处理方式的不同可以看出 FIFO 和 RR 两种调度策略的差异。当采用 FIFO 调度策略时，先获得处理的任务将独占处理器，处理器将一直运行该任务直到其进入睡眠。而采用 RR 调度策略时，具有相同优先级的任务将以轮转的方式分享处理器时间。一旦一个 RR 任务开始运行，除非该任务被阻塞，它将尽可能地用完分配给它的时间片（time slice）。然后调度器将剥夺该任务对处理器的使用权，并将其放到具备相同优先级的一个循环任务队列的尾部，同时选择该队列中的下一个任务投入运行。

> In contrast, the deadline scheduler, as its name says, schedules each task according to the task's deadline. The task with the earliest deadline will be served first. Each scheduler requires a different setup for realtime tasks. In the realtime scheduler, the user needs to provide the scheduling policy and the fixed priority. For example:

相反，对于 “Deadline 调度器” 来说，顾名思义，其调度任务的方式是基于任务的 “截止时间（deadline）”。截止时间最早的任务将优先被执行。不同类型的调度器（译者注，指 Linux 提供的 “POSIX 实时调度器” 和 “Deadline 调度器”）在创建任务时需要设置的参数各不相同。对于 “POSIX 实时调度器” 来说，用户需要指定调度策略（scheduling policy）类型和固定的任务优先级（fixed priority）。如下所示：

    chrt -f 10 video_processing_tool

> With this command, the `video_processing_tool` task will be scheduled by the realtime scheduler, with a priority of 10, under the FIFO policy (as requested by the `-f` flag).

该命令会创建实时任务执行 `video_processing_tool` 程序，对该实时任务的调度使用 FIFO 策略（`-f`），并设定其任务优先级的值为 10。

> In the deadline scheduler, instead, the user has three parameters to set: the period, the run time, and the deadline. The period is the activation pattern of the realtime task. In a practical example, if a video-processing task must process 60 frames per second, a new frame will arrive every 16 milliseconds, so the period is 16 milliseconds.

使用 “Deadline 调度器” 时，用户需要设置三个参数：“周期（period）”，“运行时间（run time）” 和 “最大期限（deadline）”（译者注，对于这三个参数，为和后面的例子代码表述一致，下文直接使用英文，不再翻译为中文）。实时任务总是周期性地执行一些动作。举一个实际的例子，假设一个处理视频的任务必须每秒处理 60 帧图像，则每一帧间隔大概在 16 毫秒，也就是说 “period” 为 16 毫秒。

> The run time is the amount of CPU time that the application needs to produce the output. In the most conservative case, the runtime must be the worst-case execution time (WCET), which is the maximum amount of time the task needs to process one period's worth of work. For example, a video processing tool may take, in the worst case, five milliseconds to process the image. Hence its run time is five milliseconds.

“run time” 是程序执行产生输出所需的处理器时间。保守情况下，“run time” 一般是指 “最坏情况下的执行时间（worst-case execution time，简称 WCET）”，也就是任务在每一个 “period” 中执行实际计算处理需要花费的最大的处理器时间值。例如，在最坏的情况下，视频处理任务可能需要最多五毫秒才可处理完一帧图像。因此，它的 “run time” 就是五毫秒（译者注，考虑到任务在实际工作过程中可能会被打断，所以 “run time” 应该指的是所有真正花费在有效处理上的时间总和或者理解为不间断工作所需的最大时长。）

> The deadline is the maximum time in which the result must be delivered by the task, relative to the period. For example, if the task needs to deliver the processed frame within ten milliseconds, the deadline will be ten milliseconds.

“deadline” 是用来描述一个任务（在每一个 “period” 内）完成工作所需要遵循的截止时间。例如，如果任务需要在十毫秒内完成对一帧的处理，则 “deadline” 被记为十毫秒。

> It is possible to set deadline scheduling parameters using the `chrt` command. For example, the above-mentioned tool could be started with the following command:

同样可以使用 `chrt` 命令设置以上和 deadline 调度相关的参数 。例如，可以使用以下命令运行 `video_processing_tool`：

    chrt -d --sched-runtime 5000000 --sched-deadline 10000000 \
    	    --sched-period 16666666 0 video_processing_tool

> Where:

> - `--sched-runtime 5000000` is the run time specified in nanoseconds
> - `--sched-deadline 10000000` is the relative deadline specified in nanoseconds.
> - `--sched-period 16666666` is the period specified in nanoseconds
> - `0` is a placeholder for the (unused) priority, required by the `chrt` command

这里：

- `--sched-runtime 5000000` 指定了 “run time”（以纳秒为单位，即 5 毫秒）
- `--sched-deadline 10000000` 指定了 “deadline”（以纳秒为单位，即 10 毫秒）。
- `--sched-period 16666666` 指定了 “period”（以纳秒为单位， 即大约 16 毫秒）
- `0` 是一个占位符，chrt 命令在格式上要求指定优先级，但 deadline 调度器并未使用这个参数。

> In this way, the task will have a guarantee of 5ms of CPU time every 16.6ms, and all of that CPU time will be available for the task before the 10ms deadline passes.

在上面的例子中，系统将保证该任务在每个 16.6 毫秒（“period”）中获得 5 毫秒的 CPU 时间（“run time”），并且这些 CPU 时间都将被安排在 10 毫秒的到期时间（“deadline”）之前提供给该任务。

> Although the deadline scheduler's configuration looks complex, it is not. By giving the correct parameters, which are only dependent on the application itself, the user does not need to be aware of all the other tasks in the system to be sure that the application will deliver its results before the deadline. When using the realtime scheduler, instead, the user must take into account all of the system's tasks to be able to define which is the correct fixed priority for any task.

尽管 deadline 调度器的配置看起来很复杂，但事实并非如此。用户在确定参数时仅仅需要考虑应用本身的要求，即用户只需要指定本应用任务完成工作的截止时间而无需考虑系统中其他任务的要求。相反，在使用 “POSIX 实时调度器” 时，用户必须统筹考虑系统中的所有任务，以便正确地为每一个任务指定固定优先级。

> Since the deadline scheduler knows how much CPU each deadline task will need, it knows when the system can (or cannot) admit new tasks. So, rather than allowing the user to overload the system, the deadline scheduler denies the addition of more deadline tasks, guaranteeing that all deadline tasks will have CPU time to accomplish their tasks with, at least, a bounded tardiness.

由于 “Deadline 调度器” 知道每个它管理的任务需要的 CPU 时间（“run time”）是多少，因此它知道系统何时可以（或不能）接受新的任务。也就是说，“Deadline 调度器” 会拒绝用户创建太多的 “Deadline” 任务，从而避免了系统过载，这确保了其管理的所有任务都将拥有足够的 CPU 时间来完成自己的工作，避免出现任务被无限期地延迟。

> In order to further discuss benefits of the deadline scheduler it is necessary to take a step back and look at the bigger picture. To that end, the next section explains a little bit about realtime scheduling theory.

为了进一步深入地了解 “Deadline 调度器” 带给我们的好处，有必要从更高的层次进一步审视这个问题。为此，下一部分让我们简单回顾一些有关实时调度的理论知识。

## 实时调度概述（A realtime scheduling overview）

> In scheduling theory, realtime schedulers are evaluated by their ability to schedule a set of tasks while meeting the timing requirements of all realtime tasks. In order to provide deterministic response times, realtime tasks must have a deterministic timing behavior. The task model describes the deterministic behavior of a task.

根据调度理论，考量一个实时调度器性能是否优秀，主要通过评估其在调度一组实时任务时是否可以满足它们对时间的要求。为了提供确定的响应时间，实时任务的行为必须在时间上体现出一定的确定性（译者注，譬如遵守 deadline）。我们通过 “任务模型（task model，译者注，可以认为是一种分类的方法）” 来描述任务行为上的这种确定性。

> Each realtime task is composed of N recurrent activations; a task activation is known as a **job**. A task is said to be **periodic** when a job takes place after a fixed offset of time from its previous activation. For instance, a periodic task with period of 2ms will be activated every 2ms. Tasks can also be **sporadic**. A sporadic task is activated after, at least, a minimum inter-arrival time from its previous activation. For instance, a sporadic task with a 2ms period will be activated after at least 2ms from the previous activation. Finally, a task can be **aperiodic**, when there is no activation pattern that can be established.

每个实时任务的执行过程由多次重复的动作（activation）组成；一次动作的执行称为 **job**（译者注，为方便理解，“job” 不再翻译为中文）。如果每两次 **job** 之间的时间间隔是固定的，则这样的任务被称为 **周期性（periodic）** 任务。例如，一个间隔为 2ms 的周期性任务每隔 2ms 被激活一次。任务的类型也可能是 **离散（sporadic）** 的。对于这样的任务，两次动作之间的间隔都至少大于一个最小值。例如，一个周期为 2ms 的离散型任务两次动作之间的间隔至少为 2ms（可以比这个值长且不固定）。最后，当一个任务其动作发生的频率不存在任何规律时，则我们称其为 **非周期性的（aperiodic）**。

> Tasks can have an **implicit deadline**, when the deadline is equal to the activation period, or a **constrained deadline**, when the deadline can be less than (or equal to) the period. Finally, a task can have an **arbitrary deadline**, where the deadline is unrelated to the period.

对于一个任务来说，如果其 “deadline” 和该任务的两次动作之间的间隔（这里也称之为周期（period））相同时，我们称这样的任务具有 **隐式期限（implicit deadline）**；当 “deadline” 小于（或等于）周期时，我们称其具备 **受限期限（constrained deadline）**。最后，任务可以是 **任意期限（arbitrary deadline）**，也就是说任务的 “deadline” 与周期无关。

> Using these patterns, realtime researchers have developed ways to compare scheduling algorithms by their ability to schedule a given task set. It turns out that, for uniprocessor systems, the Early Deadline First (EDF) scheduler was found to be optimal. A scheduling algorithm is optimal when it fails to schedule a task set only when no other scheduler can schedule it. The deadline scheduler is optimal for periodic and sporadic tasks with deadlines less than or equal to their periods on uniprocessor systems. Actually, for either periodic or sporadic tasks with implicit deadlines, the EDF scheduler can schedule any task set as long as the task set does not use more than 100% of the CPU time. The Linux deadline scheduler implements the EDF algorithm.

基于以上定义，研究实时性的人发明了可用于评价一个调度算法在面对一组任务执行调度时的能力水平的方法。经研究证明，对于单处理器系统，“最早期限优先（Early Deadline First，简称 EDF）” 调度算法是 “最优的（optimal）”。所谓最优指的是对于一个调度算法来说，所有其他调度算法在处理能力上都无法超越它。在单处理器系统上，“Deadline 调度器” 最适合处理 “deadline” 小于或等于其 “period” 的 “periodic” 或者是 “sporadic” 型的任务。实际上，对于一个任务集来说，只要该集合中的所有任务类型是属于 “implicit deadline” 的 “periodic” 或者是 “sporadic” 型任务，并且该任务集合中的所有任务所花费的 CPU 时间总和不超过 100%，EDF 调度程序就可以调度它们。Linux 的 “Deadline 调度器” 实现了 EDF 算法。

> Consider, for instance, a system with three  tasks with deadlines equal to their periods:

例如，考虑在一个系统中拥有三个 “periodic” 型任务且这些任务的 “deadline” 等于其 “period”：

![tasks set sample](/wp-content/uploads/2019/12/lwn-743740/1.png)

> The CPU time utilization (U) of this task set is less than 100%:

该任务集的 CPU 时间利用率（U）不超过 100%：

    U =  1/4 + 2/6 + 3/8 = 23/24 

> For such a task set, the EDF scheduler would present the following behavior:

对于这样的任务集，EDF 调度器的行为表现如下：

![Scheduling chart](/wp-content/uploads/2019/12/lwn-743740/2.png)

（译者注：参考下图的标注，该图标识出了上图中的每个周期中的 “period” 和 “run time”，可以看到对于 T1、T2 和 T3，每个 period 内的 run time 和 deadline 都得到了保证，也就是说 EDF 调度器可以在对任务实现调度的同时完美地支持实时性要求。）

![comments for Scheduling chart](/wp-content/uploads/2019/12/lwn-743740/8.png)

> However, it is not possible to use a fixed-priority scheduler to schedule this task set while meeting every deadline; regardless of the assignment of priorities, one task will not run in time to get its work done. The resulting behavior will look like this:

如果想要使用基于固定优先级的调度算法来调度这些任务，同时又要保证这些任务都满足其 deadline 要求，却是不可能的。无论如何指定任务的优先级，总会存在一项任务无法及时完成其工作。最终的行为将如下所示（译者注：从下图可以推测出来，在优先级上 T1 > T2 > T3。执行流程上，T1 先运行，因为 T1 的 “run time” 是 1 个时间单位，所以 T1 运行 1 个时间单位后主动放弃 CPU，然后 T2 获得处理器开始运行，T2 运行 2 个时间单位后用完它的 “run time” 并将处理器交给 T3，T3 的 “run time” 是 3 个时间单位，可是 T3 只跑了一个时间单位之后就被 T1 抢占，因为 T1 的第二个周期开始了；接下来 T1 用完了自己的 “run time”，由于 T2 的第二个周期还没开始，T3 得以继续运行，但很可惜它这次又只能跑一个时间单位，此时 T2 的第二个周期开始，再次打断了 T3 的运行；等第二次 T2 结束时，很不幸的是 T1 的第三个周期已到，所以 等到 T3 有机会使用它剩下的 “run time” 的时候已经超过它的 “deadline” 了，见标红色的部分。）：

![Scheduling chart](/wp-content/uploads/2019/12/lwn-743740/3.png)

> The main advantage of deadline scheduling is that, once you know each task's parameters, you do not need to analyze all of the other tasks to know that your tasks will all meet their deadlines. Deadline scheduling often results in fewer context switches and, on uniprocessor systems, deadline scheduling is able to schedule more tasks than fixed priority-scheduling while meeting every task's deadline. However, the deadline scheduler also has some disadvantages.

“Deadline” 调度算法的主要优点是，你只需要考虑单个任务的调度参数，而不是在分析完所有其他任务后才能够确定是否你的任务能满足其截止时间。通常情况下 “Deadline 调度器” 会使上下文切换次数更少，并且在单处理器系统上，“Deadline 调度算法” 比基于固定优先级的调度算法能够调度更多任务，同时又能满足每个任务的截止时间。当然，“Deadline” 调度算法也存在一些缺点。

> The deadline scheduler provides a guarantee of accomplishing each task's deadline, but it is not possible to ensure a minimum response time for any given task. In the fixed-priority scheduler, the highest-priority task always has the minimum response time, but that is not possible to guarantee with the deadline scheduler. The EDF scheduling algorithm is also more complex than fixed-priority, which can be implemented with O(1) complexity. In contrast, the deadline scheduler is O(log(n)). However, the fixed-priority requires an “offline computation” of the best set of priorities by the user, which can be as complex as O(N!).

“Deadline” 调度算法可以保证每个任务都在预期的截止时间之内完成其工作，但却无法对给定的某个任务确保其响应时间最短。采用固定优先级调度方式可以保证最高优先级的任务始终具有最短的响应时间，这是 “Deadline” 调度程序无法做到的。EDF 调度算法也比固定优先级算法更复杂，后者可以实现 O(1) 的时间复杂度。而 “Deadline” 调度程序的复杂度是 O(log(n))。但是，使用固定优先级调度算法的前提是需要用户手动计算并调整任务的优先级，在这一点上其复杂度最差或许会达到 O(N!)。

> If, for some reason, the system becomes overloaded, for instance due to the addition of a new task or a wrong WCET estimation, it is possible to face a domino effect: once one task misses its deadline by running for more than its declared run time, all other tasks may miss their deadlines as shown by the regions in red below:

如果由于某种原因（譬如添加了新任务或者是错误地估计了 WCET 值）导致系统过载，则有可能会引发多米诺效应：即一旦一个任务错过了最后期限，其运行时间超过了其定义的 “run time”，则所有其他任务都可能会超过它们的 “deadline”，如下图中红色区域所标出的那样（译者注：下图中所有任务的 “run time” 都是 2 个时间单位，T1, T2, T3, T4 四个任务的 “period”（假设这些任务的 “deadline” 等于其 “period”）分别为 5 个，6 个，7 个和 8 个时间单位，计算 CPU 利用率 U = 2/5 + 2/6 + 2/7 + 2/8 = 533 / 420 > 1，属于超负荷运行，从图上看很容易看出 T1 任务首先发生了超期的情况，接下来 T4, T2, T3 依次连锁反应发生了超期。）：

![Domino effect](/wp-content/uploads/2019/12/lwn-743740/4.png)

> In contrast, with fixed-priority scheduling, only the tasks with lower priority than the task which missed the deadline will be affected.

相反，对于基于固定优先级的调度方式，只有优先级比那些错过 deadline 的任务更低的任务才会受到影响。

> In addition to the prioritization problem, multi-core systems add an allocation problem. On a multi-core system, the scheduler also needs to decide where the tasks can run. Generally, the scheduler can be classified as one of the following:

- **Global**: When a single scheduler manages all M CPUs of the system. In other words, tasks can migrate to all CPUs.
- **Clustered**: When a single scheduler manages a disjoint subset of the M CPUs. In other words, tasks can migrate to just a subset of the available CPUs.
- **Partitioned**: When each scheduler manages a single CPU, so no migration is allowed.
- **Arbitrary**: Each task can run on an arbitrary set of CPUs.

除了优先级问题之外，多核系统需要额外考虑任务分配的问题。即针对一个多核系统，调度程序需要确定每个任务具体在哪个处理器上运行。通常，调度程序可以分为以下几类：

![Scheduler types](/wp-content/uploads/2019/12/lwn-743740/5.png)

- **全局（Global）**：单个调度器管理系统上所有的 CPU。也就是说，任务可以在所有的 CPU 之间迁移。
- **集群式（Clustered）**：整个系统上的所有 CPU 被划分为多个互不相交的子集，每个子集由一个调度器管理。采用这种方式，每个任务仅可以在某个 CPU 子集中发生迁移。
- **分区（Partitioned）方式**：每个调度器仅负责管理一个 CPU，在这种情况下，不存在迁移。
- **任意（Arbitrary）**：每个任务可以在任意一组 CPU 上运行。

> In multi-core systems, global, clustered, and arbitrary deadline schedulers are not optimal. The theory for multi-core scheduling is more complex than for single-core systems due to many anomalies. For example, in a system with M processors, it is possible to schedule M tasks with a run time equal to the period. For instance, a system with four processors can schedule four "BIG" tasks with both run time and period equal to 1000ms. In this case, the system will reach the maximum utilization of:

在多核系统中，“全局（global）”，“集群（clustered）” 和 “任意（arbitrary）” 方式下的 deadline 调度器都做不到最优。由于存在许多异常情况，多核系统调度理论比单核系统更为复杂。例如，在具有 M 个处理器的系统中，针对 M 个 “run time” 等于 “period” 的任务进行调度是可能的。例如，具有四个处理器的系统可以调度四个 “大（BIG）” 任务，所谓 “大”，指的是其 “run time” 和 “period” 均为 1000ms（译者注，在实时需求场景下，该值是一个相对较大的值）。在这种情况下，系统的最大利用率达到如下情况：

    4 * 1000/1000 = 4

> The resulting scheduling behavior will look like:

产生的调度行为将类似如下：

![Four big tasks](/wp-content/uploads/2019/12/lwn-743740/6.png)

> It is intuitive to think that a system with a lower load will be schedulable too, as it is for single-processor systems. For example, in a system with four processors, a task set composed of four small tasks with the minimum runtime, let's say 1ms, at every 999 milliseconds period, and just one task BIG task, with runtime and period of one second. The load of this system is:

直觉上我们可能会认为（多核情况）和单核系统类似，当系统的负载较轻时调度更不会有问题。例如，在具有四个处理器的系统中，一个任务集由四个 “period” 为 999 毫秒，而 “run time” 仅为 1 毫秒的 “小” 任务加上另一个 “run time” 和 “period” 均为 1 秒 的 “大” 任务 组成。则该系统的负载为：

    4 * (1/999) + 1000/1000 = 1.004

> As 1.004 is smaller than four, intuitively, one might say that the system is schedulable, But that is not true for global EDF scheduling. That is because, if all tasks are released at the same time, the M small tasks will be scheduled in the M available processors. Then, the big task will be able to start only after the small tasks have run, hence finishing its computation after its deadline. As illustrated below. This is known as the Dhall's effect.

因为 1.004 小于 4，从直觉上讲，有人可能会说对这样的系统进行调度是没有问题的，但是对于 “全局（global）” 的 EDF 调度器却不是这样。这是因为，假设同时释放所有任务，M 个小任务将在 M 个可用处理器上同时被调度。大任务仅在小任务运行后才能开始，很明显大任务运行完成时已经超期了。如下图所示。这就是所谓的 Dhall 效应。

![Dhall's effect](/wp-content/uploads/2019/12/lwn-743740/7.png)

> Distribution of tasks to processors turns out to be an NP-hard problem (a bin-packing problem, essentially) and, due to other anomalies, there is no dominance of one scheduling algorithm over any others.

为处理器分配任务实际上是一个 NP 难题（本质上是一个 bin-packing 问题，译者注，参考 [维基百科对 NP-hard 的定义][2]），并且由于其他特殊情形，所以目前不存在一个最优调度算法。

> With this background in place, we can turn to the details of the Linux deadline scheduler and the best ways to take advantage of its capabilities while avoiding the potential problems. See the second half of this series, to be published soon, for the full story.

有了这些背景知识后，接下来我们就可以更深入地了解 Linux 的 “Deadline” 调度器，以及研究如何在充分发挥其功效的同时避免那些潜在的问题。更多更完整的介绍，敬请期待即将发表的下半部分。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/518993/
[2]: https://en.wikipedia.org/wiki/NP-hardness
