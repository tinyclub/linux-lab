---
layout: post
draft: false
top: false
author: 'Wang Chen'
title: "LWN 575497: 我们很快就可以有 Deadline 调度器了吗？"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-575497/
description: "LWN 中文翻译，我们很快就可以有 Deadline 调度器了吗？"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - scheduling
  - deadline
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Deadline scheduling: coming soon?](https://lwn.net/Articles/575497/)
> 原创：By Jonathan Corbet @ Dec. 4, 2013
> 翻译：By [unicornx](https://gitee.com/unicornx)
> 校对：By [Shaowei Wang](https://gitee.com/accfast)

> Deadline scheduling was first [covered here](https://lwn.net/Articles/356576/) in 2009. Like much of the code in the realtime tree, though, deadline scheduling appears not to be subject to deadlines when it comes to being merged into the mainline. That said, it seems entirely possible that this longstanding project will land in a stable kernel release fairly soon, so a look at the status of this patch set, and the proposed ABI in particular, seems in order.

我们曾经在 2009 年首次在 [这篇文章][1] 中给大家介绍了 “截止时间（Deadline）” 调度算法（译者注，下文直接称其为 Deadline 调度器，不再翻译为中文）。但是，与实时补丁仓库中的许多代码一样（译者注，这里的实时补丁仓库指的是 PREEMT_RT 补丁），关于 Deadline 调度器补丁何时能被合入内核主线中这个问题一直就没人可以给出一个确定的答案。但目前看起来这个长期游离于主线之外的补丁非常有可能很快会进入下一个稳定内核版本，因此接下来让我们了解一下这个补丁的最新状态，尤其是计划中希望实现的 [“应用程序二进制接口（Application Binary Interface，简称 ABI）”][2]（译者注，这里的 ABI 指的是针对 Deadline 调度器的控制接口，包括函数接口）。

> To recap briefly: deadline scheduling does away with the concept of process priorities that has been at the core of most CPU scheduler algorithms. Instead, each process provides three parameters to the scheduler: a "worst-case execution time" describing a maximum amount of CPU time needed to accomplish its task, a period describing how often the task must be performed, and a deadline specifying when the task must first be completed. The actual scheduling algorithm is then relatively simple: the task whose deadline is closest runs first. If the scheduler takes care to not allow the creation of deadline tasks when the sum of the worst-case execution times would exceed the amount of available CPU time, it can guarantee that every task will be able to finish by its deadline.

简要回顾一下：Deadline 调度算法并未采用大多数 CPU 调度程序中都使用的基于进程优先级的概念。取而代之的是，使用 Deadline 调度器时需要为每个进程指定三个参数：第一个叫 “最坏情况下的执行时间（worst-case execution time，简称 WCET）”，用于描述完成一次任务所需的最大 CPU 时间；第二个是 “周期（period）”，用于描述执行任务的频率；第三个是 “最大期限（deadline）”，用于指定一次任务必须在多长时间内完成。实际的调度算法则相对简单：剩余最大期限（即 deadline）越小的任务越优先被运行。只要调度器能够小心地限制新的 deadline 任务的创建，从而确保现有所有任务的 WCET 之和不超过系统允许的 CPU 时间，就可以确保（已经运行的）每个任务都能在其各自的 deadline 内完成。

> Deadline scheduling is thus useful for realtime tasks, where completion by a deadline is a key requirement. It is also applicable to periodic tasks like streaming media processing.

可见，Deadline 调度算法对于实现实时应用很有帮助，因为对于实时任务来说，满足其 deadline 是最关键的要求。该算法也适用于一些周期性的任务，例如流媒体处理。

> In recent times, work on deadline scheduling has been done by Juri Lelli. He has posted several versions, improving things along the way. His [v8 posting](https://lwn.net/Articles/570293/) in October generated a fair amount of discussion, including suggestions from scheduler maintainers [Peter Zijlstra](https://lwn.net/Articles/575502/) and [Ingo Molnar](https://lwn.net/Articles/575503/) that the time had come to merge this code. That merging did not happen for 3.13, but chances are that it will for a near-future kernel release, barring some sort of unexpected roadblock. The main thing that remains to be done is to get the user-space ABI nailed down, since that aspect is hard to change after it has been released in a mainline kernel.

最近，Juri Lelli 已经完成了 deadline 调度器的开发工作。他发布了多个版本，并在此过程中对补丁进行持续改进。他在 10 月份发布的 [第 8 个版本][3] 引起了广泛的讨论，其中包括来自内核调度程序的维护者 [Peter Zijlstra][4] 和 [Ingo Molnar][5] 的建议，他们都同意尽快合入该补丁。内核 的 3.13 版本没有来得及合入该改动，如果不出意外，很有可能随下一个版本的发布而合入（译者注，[Deadline 调度器补丁随内核 3.14 版本合入内核主线][6]）。剩下要做的主要的事情是确定用户空间的 ABI，一旦在内核主线中发布了 ABI，再想改变会变得很困难。

## 控制调度器的行为（Controlling the scheduler）

> To be able to guarantee that deadlines will be met, a deadline scheduler must have an incontestable claim to the CPU, so deadline tasks will run ahead of all other tasks — even those in the realtime scheduler classes. Deadline-scheduled processes cannot take all of the available CPU time, though; the amount of time actually available is controlled by a set of sysctl knobs found under `/proc/sys/kernel/`. The first two already exist in current kernels: `sched_rt_runtime_us` and `sched_rt_period_us`. The first specifies the amount of CPU time (in microseconds) available to realtime tasks, while the second gives the period over which that CPU time is available. By default, 95% of the total CPU time is made available to realtime processes, leaving 5% to give a desperate system administrator a chance to recover a system from a runaway realtime process.

为了确保 deadline 的要求得到满足，Deadline 调度器必须享有对 CPU 的优先使用权，因此，deadline 类型的任务将比所有其他任务（包括由实时（Realtime）调度器类管理的任务）先执行。但是，由 Deadline 调度器负责的进程不会百分之一百地占用 CPU 时间；我们可以通过设置（虚拟文件系统）`/proc/sys/kernel` 目录下的一组文件对其实际可获得的处理时间量进行控制。当前内核（译者注，指未合入 Deadline 调度器之前的版本）中已经提供了两个这样的控制参数：一个是 `sched_rt_runtime_us`，另一个是 `sched_rt_period_us`。第一个参数指定可用于实时任务的 CPU 时间量（以微秒为单位），第二个指定第一个参数所基于的时间周期值。默认情况下，实时进程可以使用总 CPU 时间的 95%，保留的 5% 用于确保当实时进程失控时，绝望的系统管理员有机会恢复对系统的控制（译者注，譬如登录并输入控制命令）。

> The new `sched_dl_runtime_us` knob is used to say how much of the realtime allocation is available for use by the deadline scheduler. The default setting allocates 40% for deadline scheduling, but a system administrator may well want to tweak that value. Note that, while realtime scheduling is supported by control groups, deadline scheduling has not yet been implemented at that level. How deadline scheduling should interact with group scheduling raises some interesting questions that have not yet been fully answered.

新增加的 `sched_dl_runtime_us` 参数用于设置 Deadline  调度器可获得的分配时间。默认设置是给 Deadline 调度器预留 40% 的时间，但系统管理员可能会希望调整该值。需要注意的是，控制组（control groups）目前只支持 Realtime 调度，而不支持 Deadline 调度。组调度如何支持 Deadline 调度这个问题目前还未找到合适的答案（译者注，至少到 5.6 版本为止还未看到内核在组调度上对 Deadline 特性的支持）。

> The other piece of the ABI allows processes to enter and control the deadline scheduling regime. The current system call for changing a process's scheduling class is:

ABI 的另一部分允许进程输入和控制 Deadline 调度器的行为。当前用于更改进程的调度类的系统调用是：

    int sched_setscheduler(pid_t pid, int policy, const struct sched_param *param);

> The `sched_param` structure used in this system call is quite simple:

此系统调用中使用 的 `sched_pa​​ram` 结构体定义非常简单：

    struct sched_param {
        int sched_priority;
    };

> So `sched_setscheduler()` works fine for the currently available scheduling classes; the desired class is specified with the `policy` parameter, while the associated process priority goes into `param`. But `struct sched_param` clearly does not have the space needed to hold the three parameters needed with deadline scheduling, and its definition cannot be changed without breaking the existing ABI. So a new system call will be needed. As of this writing the details are still under discussion, but the new ABI can be expected to look something like this:

`sched_setscheduler()` 这个函数接口对于内核当前实现的调度类（译者注，指加入 Deadline 调度类之前所支持的那些调度类，譬如 Normal、Realtime 等）支持的很好；所需的类别由 `policy` 参数指定，而相关的进程优先级则通过 `param` 指定。但是 `struct sched_pa​​ram` 显然没有足够的空间来容纳 Deadline 调度算法所需的三个参数，如果要改变其定义必然会破坏现有的 ABI。因此可能需要增加一个新的系统调用。截至撰写本文时，具体细节仍在讨论中，新的 ABI 看起来可能会是像这样（译者注，最终随 3.14 版本合入的形式和文章中给出的稍有不同，譬如去掉了 `sched_setscheduler2()`，在使用最新的内核版本编写应用时，我们可以使用 `sched_setattr()`/`sched_getattr()` 作为超集代替旧的 `sched_setscheduler()`/`sched_getscheduler()`）：

    struct sched_attr {
        int sched_priority;
        unsigned int sched_flags;
        u64 sched_runtime;
        u64 sched_deadline;
        u64 sched_period;
        u32 size;
    };

    int sched_setscheduler2(pid_t pid, int policy, const struct sched_attr *param);
    int sched_setattr(pid_t pid, const struct sched_attr *param);
    int sched_getattr(pid_t pid, struct sched_attr *param, unsigned int size);

> Where `size` (as both a parameter and a structure field) is the size of the `sched_attr` structure. If, in the future, the need arises to add more fields to that structure, the kernel will be able to use the `size` value to determine which version of the structure an application is using and respond accordingly. For the curious: `size` is meant to be specified within `struct sched_attr` when that structure is, itself, an input parameter to the kernel; otherwise `size` is given separately. The `sched_flags` field of `struct sched_attr` is not used in the current version of the patch.

其中，`size` 是 `sched_attr` 结构体的大小（既出现在函数参数中，又作为结构体的成员出现）。如果将来需要向该结构体添加更多字段，则内核将能够利用 `size` 的值区分应用程序正在使用的结构体版本，从而做出正确的响应。需要注意的是：当函数中需要传入 `struct sched_attr` 类型的参数时， 还需要将 `size` 作为另一个参数独立给出。`struct sched_attr` 结构体中的 `sched_flags` 字段在目前的补丁版本中并未使用。

> One other noteworthy detail is that processes running in the new `SCHED_DEADLINE` class are not allowed to fork children in the same class. As with the realtime scheduling classes, this restriction can be worked around by setting the scheduling class to `SCHED_DEADLINE|SCHED_RESET_ON_FORK`, which causes the child to be placed back into the default scheduling class. Without that flag, a call to `fork()` will fail.

另一个值得注意的细节是，注册为新的 `SCHED_DEADLINE` 调度类的进程不允许派生（fork）相同调度类的子进程。与实时调度类一样，可以通过将调度类设置为 `SCHED_DEADLINE | SCHED_RESET_ON_FORK` 来绕过这个限制，这么做会将子进程放回默认调度类中。没有该标志，对 `fork()` 的调用将失败。

## 何时合入主线？（Time to merge?）

> The deadline scheduling patch set has a number of loose ends left to be dealt with, many of which are indicated in the patches themselves. But there comes a point where it is best to go ahead and get the code into the mainline so that said loose ends can be tied down more quickly; the deadline scheduling patches may well have reached that point. Since deadline scheduling can be added without much risk of regressions on systems where it is not in use, there should not be a whole lot more that needs to be dealt with before it can be merged.

Deadline 调度器补丁还剩下一些问题没有解决，其中不少问题在补丁中已经被注明。但看上去，最好赶紧将代码合入主线，这会推动这些遗留的问题被尽快解决；这对 Deadline 调度器补丁来说是一件很重要的事情。由于这个新的调度器还没有被大家广泛使用，所以将其合入主线的风险不大，在这件事情上我们没有理由犹豫。

> ...except, maybe, for one little thing. When deadline scheduling was [discussed at the 2010 Kernel Summit](https://lwn.net/Articles/412745/), Linus and others clearly worried that there may not be actual users for this functionality. There has not been a whole lot of effort put into demonstrating users for deadline scheduling since then, though it is worth noting that the Yocto project has included the patch in some of its kernels. The [JUNIPER project](http://www.juniper-project.org/page/overview) is also planning to use deadline scheduling, and has been supporting its development. Users like these will definitely help the deadline scheduler's case; Linus has become wary of adding features that may not actually be used. If that little point can be adequately addressed, we may have deadline scheduling in the mainline in the near future.

... 但还有一个小问题需要考虑一下。在 2010 年内核峰会上 [讨论 Deadline 调度器的时候][7]，Linus 和其他人显然担心这个功能可能没有实际的用户。而且自从那次会议到现在，社区也并没有花费太多的精力演示并推广这个功能，但值得注意的是，Yocto 项目已在其支持的某些内核中包含了该补丁。另外 [JUNIPER 项目][8] 也计划使用 Deadline 调度器，并一直在支持它的发展。有这样的用户存在肯定对 Deadline 调度器合入内核有帮助；因为 Linus 已经明确表示会谨慎添加那些没有实际客户的功能。如果这个问题可以得到妥善解决，那么我们应该会在不久的将来在内核主线中看到 Deadline 调度器。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: /lwn-356576/
[2]: https://ja.wikipedia.org/wiki/Application_Binary_Interface
[3]: https://lwn.net/Articles/570293/
[4]: https://lwn.net/Articles/575502/
[5]: https://lwn.net/Articles/575503/
[6]: https://kernelnewbies.org/Linux_3.14#Deadline_scheduling_class_for_better_real-time_scheduling
[7]: https://lwn.net/Articles/412745/
[8]: http://www.juniper-project.org/page/overview
