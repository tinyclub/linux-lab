---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 106010: 实现 “实时（realtime）” Linux 的多种方法"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-106010/
description: "LWN 中文翻译，实现 “实时（realtime）” Linux 的多种方法"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - schedule
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Approaches to realtime Linux](https://lwn.net/Articles/106010/)
> 原创：By Jonathan Corbet @ Oct. 12, 2004
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Wei Huang](https://github.com/daway320)

> Using Linux systems for realtime tasks has long been an area of interest. In the last couple of weeks, a number of projects working to implement realtime response have posted their work. This article looks at the patches posted recently to get a sense for where the realtime projects are headed.

长期以来，在 Linux 系统上运行 “实时（realtime）” 应用一直是一个令人感兴趣的话题。在过去的几周里，一些致力于实现 Linux 支持实时响应的项目​​发布了他们的工作成果。本文将对这些最近发布的补丁分别做下介绍，以方便读者了解这些实时项目的发展动态。

## 和实时相关的 “Linux 安全模块（Linux Security Modules，简称 [LSM][4]）”（The realtime LSM）

> A relatively simple contribution is the [realtime security module](https://lwn.net/Articles/106009/) by Torben Hohn and Jack O'Quin. This module does not actually add any new realtime features to the kernel; instead, it uses the LSM hooks to let users belonging to a specific group use more of the system's resources. In particular, it adds the `CAP_SYS_NICE`, `CAP_IPC_LOCK`, and `CAP_SYS_RESOURCE` capabilities to the selected group. These capabilities allow the affected processes to raise their priority, lock memory into RAM, and generally to exceed resource limits. Granting capabilities in this way goes somewhat beyond the usual "restrictive hooks only" practice for security modules, but there have not been any complaints on that score.

这些成果中相对简单的一个贡献是来自 Torben Hohn 和 Jack O'Quin 发布的 “[实时安全模块（realtime security module）][5]”。该模块实际上并没有向内核添加任何新的有关实时的功能；它只是利用 LSM 提供的回调钩子（hooks）机制使得从属于特定组的用户可以使用更多的系统资源。特别的，它会对指定的用户组添加 `CAP_SYS_NICE`，`CAP_IPC_LOCK` 和 `CAP_SYS_RESOURCE` “能力（capability）”。这些能力会提高相关进程的优先级，执行内存锁定，以及放宽对进程申请使用资源的限制。采用这种方式提升用户的能力有点超出了安全模块机制所推荐的 “有限地实现回调控制” 的原则，但到目前为止还没有人对此提出异议。

## 来自 [MontaVista][3] 的补丁（MontaVista's patch）

> The event which really stirred up the discussion, however, was the posting of the [realtime kernel patch set](https://lwn.net/Articles/105866/) by MontaVista's Sven-Thorsten Dietrich. This highly intrusive patch attempts to minimize system response latency by taking the preemptible kernel approach to its limit. In comparison, the current preemption approach, which is considered to be too risky to use by most distributors, is a half measure at best.

然而，真正引起大家兴趣的是由 MontaVista 公司的 Sven-Thorsten Dietrich 所提交的 “[实时内核补丁集（realtime kernel patch set）][6]”。该补丁的改动很大，它试图尽最大可能，通过对内核实现可抢占来最小化系统响应延迟。相比之下，目前内核中实现抢占的做法，被大多数实际使用者认为风险太大，还远不够成熟。

> MontaVista's patch begins by adopting [the "IRQ threads" patch](https://lwn.net/Articles/95334/) posted by Ingo Molnar. This patch moves the running of most interrupt handlers into a separate kernel thread which competes with the others for processor time. Once that is done, interrupt handlers become preemptible and are far less likely to stall the system for long periods of time.

MontaVista 的补丁修改中，所涉及的第一个部分，采用了来自 Ingo Molnar 所开发的的 [“中断线程化（"IRQ threads"）” 补丁][7]。该补丁将大多数中断处理程序的执行放到一个单独的内核线程中，以线程的方式与其他内核线程竞争处理器。中断线程化后，中断的处理逻辑就可以被抢占，从而不太可能长时间阻塞系统（译者注：即不会导致其他任务被延迟太长时间）。

> The biggest source of latency in the kernel then becomes critical sections protected by spinlocks. So why not make those sections preemptible as well? To that end, the [PMutex patch](http://inf3-www.informatik.unibw-muenchen.de/research/linux/mutex/) has been adapted to the 2.6 kernel. This patch implements blocking mutexes, similar to the existing kernel semaphores. The PMutex version, however, has a simple priority inheritance mechanism; processes holding a mutex can have their priority bumped up temporarily so that they get their work done and release the mutex as quickly as possible. Among other things, this approach helps to minimize priority inversion problems.

除此之外，内核中最有可能导致延迟的地方是那些受 “[自旋锁（spinlock）][11]” 保护的 “[临界区（critical sections）][12]” 代码。有什么理由不让这些部分也可以被抢占呢？为此，Montavista 将 [PMutex 补丁][8] 移植到 Linux 的 2.6 系列的内核版本上。该补丁实现了用于实现任务阻塞的 “互斥锁（mutex）”，类似于现有内核中的 “信号量（semaphore）” 机制。但是，PMutex 的实现支持简单的 “[优先级继承（priority inheritance）][9]” 能力；拥有互斥锁的进程的优先级可以暂时得到提升从而使得它们可以尽快完成工作并释放锁。此外，支持该机制还有助于最小化 “[优先级反转（priority inversion）][10]” 问题的发生。

> The biggest change is replacing of most spinlocks in the system with the new mutexes; the patch uses a set of preprocessor macros to turn `spinlock_t`, and the operations on spinlocks, into their mutex equivalents. In one step, most critical sections become preemptible and no longer are part of the latency problem. As an added bonus, the moving of interrupt handlers to their own thread means that interrupt handlers can no longer deadlock with non-interrupt code when contending for the same lock; that means that it is no longer necessary to disable interrupts when taking a lock which might also be used by an interrupt handler.

补丁中最大的改进就是用新的互斥锁（译者注，即 PMutex）替换了大多数系统中的自旋锁；该补丁使用一组预处理宏将 `spinlock_t` 结构体的定义替换为 PMutex 并相应修改了自旋锁行为。通过这种简单的处理方式，使得内核中的大部分临界区变得可以被抢占，从而避免了临界区可能引入的延迟问题。这么做还带来一个额外的好处，随着将中断处理程序实现为一个线程后，当中断处理代码和另一段临界区代码争抢同一把锁时，不会引起系统死锁（译者注，想象一下如果没有这些新的机制，当一个任务先获取了一个自旋锁并进入临界区，但还未退出，此时发生一个中断，该中断当然会抢占处理器，而且该中断的处理函数也尝试去获取同一把锁时会发生什么）；这也反过来意味着，在编写保护临界区的代码而尝试获取一个和中断处理程序共享的锁时不再有禁用中断的必要。

> There are, of course, a few nagging little problems to deal with. Some code in the system really ***shouldn't*** be preempted while holding a lock. In particular, code which might be in the middle of programming hardware registers, the page table handling code, and the scheduler itself need to be allowed to do their job in peace. It is hard, after all, to imagine a scenario where preempting the scheduler will lead to good things. So a number of places in the kernel cannot be switched from spinlocks to the new mutexes.

当然，也存在一些棘手的小问题。系统中的某些代码确实不能在持有锁的情况下被抢占。譬如，一段设置硬件寄存器的代码，一段对页表进行处理的代码，或者是那些和调度器处理相关的代码，这些代码段在执行过程中是不可以被打断的。可以想象一下，如果一段连续的调度逻辑在执行过程中被抢占会带来什么样的后果。因此对内核来说，的确存在许多地方无法简单地将自旋锁改为新的互斥锁。

> The realtime patch attempts to handle these cases by creating a new `_spinlock_t` type, which is just the old `spinlock_t` under a newer, uglier name. The spinlock primitives have been renamed in the same way (e.g. `_spin_lock()`). Code which truly needs an old-style spinlock is then hacked up to use the new names, and it functions as before. Except for some files, where the developers were able to include `<linux/spin_undefs.h>`, which restores the old functionality under the old names. The header file rightly describes this technique as "a dirty, dirty hack." But it does make the patch smaller.

Montavista 的实时补丁试图通过创建一个新的 `_spinlock_t` 类型来处理以上问题，这个新的类型只不过是系统现有的 `spinlock_t` 的一个新的命名形式（虽然看上去总感觉不太习惯）。和原有自旋锁相关的操作函数也按照同样的风格进行了重命名（例如原来的 `spin_lock()` 被修改为 `_spin_lock()`）。那些仍然需要维持使用原有自旋锁功能的代码被修改为使用这个新的名称，并且像以前一样运行。除了某些文件外，开发人员如果想要让原有代码仍然按照旧的功能运行，只需要在相关的源文件的开头包含 `<linux/spin_undefs.h>` 这个头文件。在这个头文件中明确地将这种实现描述为 “一种非常丑陋的编码技巧（a dirty, dirty hack.）”（具体参考 [该补丁当初提交的邮件列表][13]）。但这么做确实使补丁变得更小了。

> Needless to say, the task of sifting through every lock in the kernel to figure out which ones cannot be changed to mutexes is a long and error-prone process. In fact, the job is nowhere near complete, and the MontaVista patch is, by its authors' admission, marginally stable on uniprocessor systems, unstable on SMP systems, and unrunnable on hyperthreaded systems. But you have to start somewhere.

毋庸置疑，逐个筛选内核中的每个锁以便确定这些锁是否可以更改为互斥锁是一个漫长且容易出错的过程。实际上，这项工作还远没有完成，MontaVista 补丁的作者承认，在单处理器系统上该补丁略显稳定，在 SMP 系统上则不太稳定，在超线程系统上则完全不可用。但无论如何我们毕竟已经迈出了第一步。

## Ingo 的完全抢占式内核补丁（Ingo's fully preemptible kernel）

> Ingo Molnar liked that start, but had some issues with it. So he went off for two days and [created a better version](https://lwn.net/Articles/105948/), which has been folded into his "voluntary preemption" series of patches. Ingo takes the same basic approach used by the MontaVista patch, but with some changes:

Ingo Molnar 非常喜欢 Montavista 的这个创意，但对他们的补丁却并不满意。所以他花费了两天的时间，[创建了一个更好的版本][14]，并将这部分修改并入了他的另一个 “自愿抢占（voluntary preemption）” 补丁集。Ingo 采用的方法与 MontaVista 补丁基本相同，不同的是存在以下修改：

> - The PMutex patch is not used; instead, Ingo uses the existing kernel semaphore implementation. His argument is that semaphores work on all architectures, while PMutexes currently only work on x86. It would be better to hack priority inheritance into the existing semaphores, and thus make it available to all of the current semaphore users as well as those converted over from spinlocks. Ingo's patch does not currently implement priority inheritance, however.

- 不使用 PMutex 补丁；相反，Ingo 利用了现有内核中的信号量机制。他的观点是：信号量适用于所有体系架构，而 PMutexes 目前仅适用于 x86。当然最好将优先级继承这个特性也添加到现有的信号量机制中，从而使其不仅可以满足那些原本就使用信号量的应用场景，同时也可以支持那些原本使用自旋锁，而现在替换为信号量的使用场景。但遗憾的是，Ingo 的补丁当前还没有实现这一点。

> - Through some preprocessor trickery, Ingo was able to avoid changing all of the spinlock calls. Preserving "old style" spinlock behavior is simply a matter of changing the type of the lock to `raw_spinlock_t` and, perhaps, changing the initialization of the lock. The actual `spin_lock()` and related calls do the right thing with either a "raw" spinlock or a new semaphore-based mutex. Think of it as a sort of poor man's polymorphic lock type.

- 通过一些预处理的技巧，Ingo 避免了修改所有调用自旋锁的代码。为了保留 “原来” 的自旋锁行为，采用的方法是将现有的 `spinlock_t` 更名为 `raw_spinlock_t`，并且修改了锁的初始化逻辑。实际的 `spin_lock()` 等相关调用（在条件编译的作用下）要么按 “原来” 的自旋锁方式工作，要么按照新的基于信号量的方式工作。之所以这么做，完全是因为必须基于 C 语言来实现锁的多态特性而采取的一种无奈之举。

> - Ingo found a much larger set of core locks which must use the true spinlock type. This was done partly through a set of checks built into the kernel which complain when the wrong type of lock is being used. With Ingo's patch, some 90 spinlocks remain in the kernel (in comparison, MontaVista preserved about 30 of them). Even so, thanks to the reworked locking primitives, Ingo's patch is much smaller than the MontaVista patch.

- Ingo 发现在内核的关键代码中存在更多的地方需要保留使用原来的自旋锁类型。这是通过在编译中运行内核内置的一组检查逻辑来完成的，这些检查一旦发现代码中使用了错误类型的锁时会产生告警。使用 Ingo 的补丁，内核中保留了大约 90 处地方仍然需要使用自旋锁（相比之下，MontaVista 只保留了大约 30 处）。即便如此，由于重新设计的锁的调用接口，Ingo 的补丁相比 MontaVista 补丁还是要小很多。

> Ingo would like to reduce the number of remaining spinlocks, but he warns that a number of "core infrastructure" changes will be required first. In particular, code using [read-copy-update](https://lwn.net/Articles/37889/) must continue to use spinlocks for now; allowing code which holds a reference to an RCU-protected structure to be preempted would break one of the core RCU assumptions. MontaVista has apparently taken a stab at the RCU issue, but does not yet have a patch which they are ready to circulate.

Ingo 希望减少剩余的仍然使用自旋锁的数量，但他提醒说，这首先需要对一些 “核心的代码逻辑” 进行改造。特别的，使用 [read-copy-update][15] 的代码现在必须继续使用自旋锁；如果允许对采用 RCU 机制进行保护的代码进行抢占将破坏最关键的某项 RCU 设计前提。MontaVista 显然已经针对 RCU 问题进行了改造尝试，但还没有正式提交一个可用的补丁。

> Ingo continues to post patches at a furious rate; things are evolving quickly on this front.

Ingo 正持续且激进地对代码进行改进；这导致了该补丁进展迅速。

## [RTAI/Fusion][1]

> Meanwhile, the real realtime people point out that none of this work provides deterministic, quantifiable latencies. It does help to reduce latency, but it cannot provide guarantees. A "realtime" system without latency guarantees may be suitable for a number of tasks, but it still isn't up to the challenge of running a nuclear power plant, an airliner's flight management system, or an extra-fast IRC spambot. If it absolutely, positively must respond within a few microseconds, you need a real realtime system.

与此同时，真正对实时应用有需求的人指出，以上的这些工作都无法保证所谓的 “确定性（deterministic）” 以及 “可量化的延迟（quantifiable latencies）”。它们确实有助于减少延迟，但却无法保证延迟限定在一个确定的范围内。没有延迟保证的 “实时” 系统或许可以应用于许多场景下，但却无法满足诸如核电站，客机的飞行管理系统或者处理速度超快的 [IRC][20] [spambot][21] 的需求。如果你需要确保系统必须在几微秒内对输入做出响应，那你仍然需要另外一个真正的实时系统。

> There are two longstanding Linux projects which are intended to provide this sort of deterministic response: [RTLinux](http://www.fsmlabs.com/products/openrtlinux/) and [RTAI](http://www.aero.polimi.it/~rtai/). There is the obligatory bad blood between the two, complicated by a software patent held by the RTLinux camp.

有两个长期的 Linux 项目旨在提供这种确定性的响应：[RTLinux][16] 和 [RTAI][17]。两者之间存在一些由来已久的历史渊源，并由于 RTLinux 阵营所持有的软件专利导致两者的关系变得更复杂。

> The RTLinux approach (and the subject of the patent) is to put the hardware under the control of a small, hard realtime system, and to run the whole of Linux as a single, low-priority task under the realtime system. Access to the realtime mode is obtained by writing a kernel module which uses a highly restricted set of primitives. Channels have been provided for communicating between the realtime module and the normal Linux user space. Since the realtime side of the system controls the hardware and gets first claim on its resources, it is possible to guarantee a maximum response time.

RTLinux 方法（以及相关专利的主要思想）是将硬件置于一个小型的硬实时系统的控制之下，而将整个 Linux 作为实时系统下的一个低优先级的任务运行。如果要支持实时应用，需要基于一套严格受限的接口，通过编程以一个内核模块的方式来实现。当前 RTLinux 已经提供了用于在实时模块和普通 Linux 用户空间任务之间进行通信的通道。由于系统的实时部分控制着硬件并可以优先访问其资源，因此可以保证最大响应时间不超过一个上限。

> RTAI initially used that approach, but has since shifted to running under the [Adeos kernel](http://www.gna.org/projects/adeos/). Adeos is essentially a "hyperviser" system which runs both Linux and a real-time system as subsidiary tasks, and allows the two to communicate. It allows a pecking order to be established between the secondary operating systems so that the realtime component can respond first to hardware events. This approach is said to be more flexible and also to avoid the RTLinux patent. Working with RTAI still requires writing kernel-mode code to handle the hard realtime part of the task.

RTAI 最初也使用了这种方法，但后来又转向基于 [Adeos 内核][18] 运行。本质上我们可以把 Adeos 看成是一种运行在物理硬件和上层子系统（包括 Linux 子系统和实时子系统）之间的中间软件层（“hyperviser”），基于该软件层可以允许两个子系统之间进行通信。它会按照一定的优先级处理上层的子系统，譬如让实时子系统优先响应硬件的事件。据说 RTAI 所采用的这种方法更灵活，也避免了 RTLinux 的专利问题。但基于 RTAI，为了实现任务支持硬实时仍然需要编写内核模式的代码。

> In response to the current discussion, Philippe Gerum surfaced with [an introduction to the RTAI/Fusion project](https://lwn.net/Articles/106016/). This project, which is "a branch" of the RTAI effort, is looking for a middle ground between the low-latency efforts and the full RTAI mode of operation; its goal is to allow code to be written for the Linux user space, with access to regular Linux facilities, but still being able to provide deterministic, bounded response times. To this end, RTAI/Fusion provides two operating modes for realtime tasks:

针对当前的讨论，Philippe Gerum [为大家介绍了 RTAI/Fusion 项目][19]。该项目是 RTAI 项目的另一个 “分支”，其目标是希望在追求低延迟与实现完全 RTAI 工作模式两者之间找到一种折中；它希望可以通过编写 Linux 用户态的代码，在使用常规的 Linux 功能的同时，仍然能够提供响应上的确定性，确保响应时间的上限。为此，RTAI/Fusion 为实时任务提供了两种运行模式：

> - The "hardened" mode offers strict latency guarantees, but programs must restrict themselves to the services provided by RTAI. A subset of Linux system calls are available as RTAI services, but most of them are not.

- “强化（hardened）” 模式提供严格的延迟保证，但代码只能调用 RTAI 提供的服务。RTAI 的这些服务实现为 Linux 系统调用的一个子集，这个子集只占全部 Linux 系统调用的一小部分。

> - When a task invokes a system call which cannot be implemented in the hardened mode, it is shifted over to the secondary ("shielded") scheduling mode. This mode is similar to the realtime modes implemented by MontaVista and Ingo Molnar; all Linux services are available, but the maximum latency may be higher. The RTAI/Fusion shielded mode defers most interrupt processing while the realtime task is running, which is said to improve latency somewhat.

- 如果一个任务调用了那些不支持强化模式的系统调用，它将被切换到另一个所谓的（“屏蔽（shielded）”）调度模式。此模式类似于 MontaVista 和 Ingo Molnar 实现的实时模式；所有 Linux 服务都可用，但最大延迟可能会更高。RTAI/Fusion 的屏蔽模式在实时任务运行时将大多数中断处理延后执行，从而达到改善整体延迟的效果。

> Processes may move between the two modes at will.

进程可以随意在两种模式之间切换。

> The end result is a blurring of the line between regular Linux processes and the hard realtime variety. Developers can select the mode which best suits their needs while running under the same system, and they can use different modes for different phases of a program's execution. RTAI/Fusion might yet succeed in the task of combining a general-purpose operating system with hard realtime operation.

最终结果是模糊了常规 Linux 任务与硬实时任务之间的界限。开发人员可以在同一系统下运行时选择最适合他们需求的模式，甚至可以在程序执行的不同阶段使用不同的模式。RTAI/Fusion 很有可能在将通用操作系统与硬实时操作相结合的工作中取得成功。

## 结论...（In conclusion...）

> Whether any of the work described here will make it into the mainline kernel is another question. The preemptible kernel patch, which was far less ambitious, has still not been accepted by many developers. Removing most spinlocks and making the kernel fully preemptible will certainly be an even harder sell. It is an intrusive change which could take some time to stabilize fully. If a fully-preemptible, closer-to-realtime kernel does pass muster with the kernel developers, it may well be the sort of development that finally forces the creation of a 2.7 branch.

且不论以上介绍的任何一项工作是否会被内核主线所接纳。即便是像 Ingo 所提交的内核可抢占这样的补丁，虽然远没那么雄心勃勃（译者注，指其很不成熟而且并没有期望能很快进入内核主线），也还没有为许多开发者所接受。移除大多数的自旋锁并使内核完全可抢占这个想法一定不会轻易就获得社区的支持。这是一个激进的改动，可能需要很长一段时间才能完全稳定下来。如果一个完全可抢占的，更接近实时的内核确实通过了内核开发人员的评审而进入主线，那很可能意味着我们将因为这个巨大特性的合入而升级内核的主版本号（从 2.6 升级为 2.7）。

> Another challenge will be building a consensus around the idea that the mainline kernel should even try to be suitable for hard realtime tasks. The kernel developers are, as a rule, opposed to changes which benefit a tiny minority of users, but which impose costs on all users. Merging intrusive patches for the sake of realtime response looks like that sort of change to many. Before mainline Linux can truly claim to be a realtime system, the relevant patches will have to prove themselves to be highly stable and without penalty for "regular" users.

另一个挑战是如何就围绕主线内核支持硬实时任务的想法达成共识。一般来说，内核开发人员通常会反对那些不考虑所有用户的感受、而只针对满足极少数用户的要求所做出的更改。为了实现实时响应而合入这些改动很大的补丁只会对大多数人造成影响。在 Linux 主线真正支持实时系统之前，相关补丁必须证明自己是高度稳定的，并且不会对 “常规” 用户造成损害。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://en.wikipedia.org/wiki/RTAI
[2]: https://en.wikipedia.org/wiki/RTLinux
[3]: https://en.wikipedia.org/wiki/MontaVista
[4]: https://en.wikipedia.org/wiki/Linux_Security_Modules
[5]: https://lwn.net/Articles/106009/
[6]: https://lwn.net/Articles/105866/
[7]: https://lwn.net/Articles/95334/
[8]: http://inf3-www.informatik.unibw-muenchen.de/research/linux/mutex/
[9]: https://en.wikipedia.org/wiki/Priority_inheritance
[10]: https://en.wikipedia.org/wiki/Priority_inversion
[11]: https://en.wikipedia.org/wiki/Spinlock
[12]: https://en.wikipedia.org/wiki/Critical_section
[13]: http://lkml.iu.edu/hypermail/linux/kernel/0410.1/0323.html
[14]: https://lwn.net/Articles/105948/
[15]: https://lwn.net/Articles/37889/
[16]: http://www.fsmlabs.com/products/openrtlinux/
[17]: http://www.aero.polimi.it/~rtai/
[18]: http://www.gna.org/projects/adeos/
[19]: https://lwn.net/Articles/106016/
[20]: https://en.wikipedia.org/wiki/Internet_Relay_Chat
[21]: https://en.wikipedia.org/wiki/Spambot
