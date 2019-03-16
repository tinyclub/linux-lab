---
layout: post
author: 'Li Yupeng'
title: "LWN 240474: CFS 组调度"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-240474/
description: "LWN 文章翻译，进程调度，CFS 组调度"
category:
  - 进程调度
  - LWN

tags:
  - Linux
  - processes schedule
  - CFS group schduling
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[CFS group scheduling](https://lwn.net/Articles/240474/)
> 原创：By Corbet @ July 2, 2007
> 翻译：By [Yupeng Li](https://github.com/linuxkoala)
> 校对：By [unicornx](https://github.com/unicornx)
> 修订：By [unicornx](https://github.com/unicornx)

> Ingo Molnar's [completely fair scheduler][2] (CFS) patch continues to develop; the current version, as of this writing, is [v18][3]. One aspect of CFS behavior is seen as a serious shortcoming by many potential users, however: it only implements fairness between individual processes. If 50 processes are trying to run at any given time, CFS will carefully ensure that each gets 2% of the CPU. It could be, however, that one of those processes is the X server belonging to Alice, while the other 49 are part of a massive kernel build launched by Karl the opportunistic kernel hacker, who logged in over the net to take advantage of some free CPU time. Assuming that allowing Karl on the system is considered fair at all, it is reasonable to say that his 49 compiler processes should, as a group, share the processor with Alice's X server. In other words, X should get 50% of the CPU (if it needs it) while all of Karl's processes share the other 50%.

Ingo Molnar 的 [完全公平调度算法(completely fair scheduler，简称 CFS)](/lwn-230574) 补丁不断演进，截至本稿撰写时，完全公平调度算法的补丁已经迭代到 [第 18 个][3] 版本。当前版本的 CFS 只实现了单个进程之间的公平性，这对许多潜在的用户来说存在一个明显的缺陷。如果系统中某个时刻存在 50 个可运行的进程，那么 CFS 能做到的仅是小心地保证这些进程各自分别享用 2% 的 CPU 资源。但是，考虑一种情况，如果在这些进程中，有一个运行 X server 的进程是属于用户 Alice 名下；其他 49 个用于编译内核的进程则由另一个不怀好意的内核黑客 Karl 所发起，那么他（指 Karl）完全可以通过简单地远程登录的方式就占用了大部分的 CPU 处理时间（译者注：98% 的处理器时间将归 Karl 所有）。如果系统要让 Karl 完全公平地和 Alice 共享资源，那么合理的方式应该是让他的 49 个执行编译的进程作为一个整体，与用户 Alice 的 X server 进程共享 CPU 资源。换句话说，X server 进程应该得到 50% 的 CPU 时间（只要它需要），而所有的 Karl 的进程则共享另外 50% 的 CPU 时间。

> This type of scheduling is called "group scheduling"; Linux has never really supported it with any scheduler. It would be nice if a "completely fair scheduler" to be merged in the future had the potential to be completely fair in this regard too. Thanks to work by Srivatsa Vaddagiri and others, things may well happen in just that way.

这种调度方式被称为 “组调度”（Group scheduling）；迄今为止，Linux 还没有任何一种调度器支持 “组调度”。如果将来合入主线的 “完全公平调度器” 能够支持 “组调度” ，那就更完美了。这里要感谢 Srivatsa Vaddagiri 及其他人所做的工作，在他们的努力下，让 CFS 调度器支持 “组调度” 的愿望即将成为现实。

> The first part of Srivatsa's work was merged into v17 of the CFS patch. It creates the concept of a "scheduling entity" - something to be scheduled, which might not be a process. This work takes the per-process scheduling information and packages it up within a `sched_entity` structure. In this form, it is essentially a cleanup - it encapsulates the relevant information (a useful thing to do in its own right) without actually changing how the CFS scheduler works.

Srivatsa 所做工作的第一部分已经合并入 CFS 补丁的 v17 版本。在这部分工作中，Srivatsa 建立了 “调度实体”（scheduling entity）的概念来表示将要被调度的对象，这个对象所代表的并不一定是单个的进程。该补丁将每个进程中与调度相关的信息提取出来并包装到 `sched_entity` 结构体中。这种处理方式，本质上是一种对代码的优化整理，它封装了相关的信息（这么做本身也是一件极有益的事情），同时也没有改变 CFS 调度器的工作方式。

> Group scheduling is implemented in [a separate set of patches][4] which are not yet part of the CFS code. These patches turn a scheduling entity into a hierarchical structure. There can now be scheduling entities which are not directly associated with processes; instead, they represent a specific group of processes. Each scheduling entity of this type has its own run queue within it. All scheduling entities also now have a `parent` pointer and a pointer to the run queue into which they should be scheduled.

到现在为止，组调度这个特性实现在 [一组单独的补丁][4] 中，还没有被合并到 CFS 代码中来。这些补丁将调度实体组织为一种层级结构（hierarchical structure）。最终的调度实体不再局限于代表一个进程，也可以是一组进程。这种设计下的每个调度实体都有自己的运行队列（译者注，即 `struct sched_entity` 的 [`my_q`][7] 成员）。所有的调度实体都有一个指针类型的成员 `parent` （译者注，用于指向上一级的调度实体，即 `struct sched_entity` 的 [`parent`][8] 成员）和一个指向自己所归属的运行队列的指针（译者注，即 `struct sched_entity` 的 [`cfs_rq`][9] 成员）。

> By default, processes are at the top of the hierarchy, and each is scheduled independently. A process can be moved underneath another scheduling entity, though, essentially removing it from the primary run queue. When that process becomes runnable, it is put on the run queue associated with its parent scheduling entity.

默认情况下，所有的进程都位于这个层级结构的顶层，并且每个进程都是独立调度的。但是，可以将进程移动到另一个调度实体下面，也就是说会将其从主运行队列（primary run queue，译者注，即 [每个 CPU 都会定义的一个全局的 `cfs_rq` 对象][10]）中移除。当该进程的状态变成可运行时，它将被添加至其父调度实体所管理的运行队列中。

> When the scheduler goes to pick the next task to run, it looks at all of the top-level scheduling entities and takes the one which is considered most deserving of the CPU. If that entity is not a process (it's a higher-level scheduling entity), then the scheduler looks at the run queue contained within that entity and starts over again. Things continue down the hierarchy until an actual process is found, at which point it is run. As the process runs, its runtime statistics are collected as usual, but they are also propagated up the hierarchy so that its CPU usage is properly reflected at each level.

当 CFS 调度器选择下一个将要运行的任务时，它先查看层级结构顶层的所有的调度实体，选出那个最值得拥有 CPU 的对象；如果该实体不是表示单个进程（即它是一个更高级别的调度实体），那么 CFS 调度器将继续查看该调度实体的运行队列并重复以上动作。以上过程沿着层级结构往下递归发生，直至找到一个表示单个进程的调度实体，此时这个进程就成为下一个运行的进程。在这个进程运行期间的统计信息会像往常一样被收集，同时也会在这个层级结构中向上层传递，以便在每个层级都能正确地反映其 CPU 的使用情况（译者注：本节的描述具体参考 [`scheduler_tick()`][11] 函数的实现）。

> So now the system administrator can create one scheduling entity for Alice, and another for Karl. All of Alice's processes are placed under her representative scheduling entity; a similar thing happens to all of the processes in Karl's big kernel build. The CFS scheduler will enforce fairness between Alice and Karl; once it decides who deserves the CPU, it will drop down a level and perform fair scheduling of that user's processes.

回到前面举的例子，按照以上设计，现在系统管理员可以分别为用户 Alice 和用户 Karl 创建各自的调度实体。Alice 的所有进程都放在代表她的调度实体之下，同样，Karl 的所有的执行内核编译的进程也都放在代表他的调度实体之下。CFS 调度器将确保 Alice 和 Karl 两个用户之间的公平性；一旦它决定了谁应该得到 CPU，CFS 调度器就会下降一层并对该用户的所有进程继续按照公平调度算法执行任务调度。

> The creation of the process hierarchy need not be done on a per-user basis; processes can be organized in any way that the administrator sees fit. The grouping could be coarser; for example, on a university machine, all students could be placed in one group and faculty in another. Or the hierarchy could be based on the type of process: there could be scheduling entities representing system daemons, interactive tools, monster cranker CPU hogs, etc. There is nothing in the patch which limits the ways in which processes can be grouped.

并非一定要基于每个用户来创建进程的层次结构；可以从管理员的角度出发，以任何合适的方式组织进程。分组的颗粒度可能更大；例如，在一所大学的计算机系统上，所有学生可以被安排在一个组中，而教师可以安排在另一个组中。再例如，层次结构可以基于进程的类型进行划分：譬如一个调度实体中包含所有的系统守护进程，一个调度实体中包含所有的交互式程序，另一个调度实体中包含计算密集型的任务（monster cranker CPU hogs）。补丁并不会限制进程分组的方式。

> One remaining question might be: how does the system administrator actually cause this grouping to happen? The answer is in the second part of the group scheduling patch, which integrates scheduling entities with the [process container][5] mechanism. The administrator mounts a container filesystem with the `cpuctl` option; scheduling groups can then be created as directories within that filesystem. Processes can be moved into (and out of) groups using the usual container interface. So any particular policy can be implemented through the creation of a simple, user-space daemon which responds to process creation events by placing newly-created processes in the right group.

最后一个问题是：系统管理员如何对任务进行分组操作？答案在组调度补丁的第二部分。这部分将调度实体与 [进程容器（process container）][5] 机制集成在一起。管理员在挂载容器文件系统时使用 `cpuctl` 选项；然后通过在该文件系统中创建目录来实现创建调度组。系统管理者可以使用通常我们使用的容器接口将进程从组外移入或从组内移出。因此，系统管理者可以通过创建一个简单的用户态的守护进程来实现任何特定的策略，该守护进程可以监听进程创建的事件通知并在进程被创建时将其添加到正确的组中。（译者注：这里提到的利用 container 的方式在最终提交的实现中被替换为基于 cgroup 虚拟文件系统。更准确的说总共有两种对任务进行分组的方式，一种是上文举例中提到的基于用户（user id），还有一种是利用 cgroup 虚拟文件系统，详细的操作介绍可以参考内核文档 [`sched-design-CFS.txt`][12]。注意在最新的内核中，不再区分两种方式，只保留了采用 cgroup 虚拟文件系统的方式。）

> In its current form, the container code only supports a single level of group hierarchy, so a two-level scheme (divide users into administrators, employees, and guests, then enforce fairness between users in each group, for example) cannot be implemented. This appears to be a "didn't get around to it yet" sort of limitation, though, rather than something which is inherent in the code.

在目前的形式下，容器代码只支持单层的层级结构，因此，两级方案（例如，将用户划分为管理员，员工和来宾三个组，然后对每个组中的用户之间确保公平）暂时还不能实现。这个问题目前看上去只是 “还没有来得及实现”，并不是设计上的固有问题。

> With this feature in place, CFS will become more interesting to a number of potential users. Those users may have to wait a little longer, though. The 2.6.23 merge window will be opening soon, but it seems unlikely that this work will be considered ready for inclusion at that time. Maybe 2.6.24 will be a good release for people wanting a shiny, new, group-aware scheduler.

一旦这个功能就绪，对于一些潜在的用户来说 CFS 将会变得更有吸引力。不过，这些用户可能需要再等一段时间。2.6.23 版本的合并窗口即将开放，但看上去还不太可能在此期间合入该项工作。对于希望有一个全新的，支持分组的调度器的用户来说，也许要等到下一个版本 2.6.24 了（译者注，CFS 对 “组调度” 的支持最终 [随 2.6.24 版本合入内核主线][13]）。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: http://tinylab.org
[2]: https://lwn.net/Articles/230574/
[3]: https://lwn.net/Articles/239553/
[4]: https://lwn.net/Articles/239619/
[5]: https://lwn.net/Articles/236038/
[6]: https://lwn.net/Articles/239619/
[7]: https://elixir.bootlin.com/linux/v2.6.24/source/include/linux/sched.h#L913
[8]: https://elixir.bootlin.com/linux/v2.6.24/source/include/linux/sched.h#L909
[9]: https://elixir.bootlin.com/linux/v2.6.24/source/include/linux/sched.h#L911
[10]: https://elixir.bootlin.com/linux/v2.6.24/source/kernel/sched.c#L180
[11]: https://elixir.bootlin.com/linux/v2.6.24/source/kernel/sched.c#L3476
[12]: https://elixir.bootlin.com/linux/v2.6.24/source/Documentation/sched-design-CFS.txt
[13]: https://kernelnewbies.org/Linux_2_6_24#CFS_improvements
