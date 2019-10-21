---
layout: post
draft: false
author: 'Wang Chen'
title: "LWN 146861: 实时抢占补丁综述"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-146861/
description: "LWN 中文翻译，实时抢占补丁综述"
category:
  - 进程调度
  - LWN
  - 实时抢占
  - 实时性
tags:
  - Linux
  - schedule
  - realtime
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[A realtime preemption overview](https://lwn.net/Articles/146861/)
> 原创：By Paul McKenney @ Aug. 10, 2005
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Zhangjin Wu](https://github.com/lzufalcon)

> There have been a considerable number of papers describing a number of different aspects of and approaches to realtime, a few of which were listed in the RESOURCES section of [my "realtime patch acceptance summary"](https://lwn.net/Articles/143323/) from July.

已经有相当多的文章从各个方面介绍了有关实时（realtime）的概念以及如何实现实时的各种方法，其中有一些已经被我收集在七月份 [发表的 “实时补丁验收摘要”][1] 一文的 “资源（RESOURCES）” 章节中。

> However, there does not appear to be a similar description of the realtime preemption (PREEMPT_RT) patch. This document attempts to fill this gap, using the V0.7.52-16 version of this patch. However, please note that the PREEMPT_RT patch evolves very quickly!

但是，目前似乎还没有文章专门针对 “实时抢占（PREEMPT_RT）补丁” 作过详细的介绍。本文将试图填补这一空白（注：本文的描述基于该补丁的 V0.7.52-16 版本）。但提请各位读者注意的是，PREEMPT_RT 补丁正处于快速开发中（所以本文并不能保证以下所介绍的内容一定是最新的）！

## PREEMPT_RT 的设计思想（Philosophy of PREEMPT_RT）

> The key point of the PREEMPT_RT patch is to minimize the amount of kernel code that is non-preemptible, while also minimizing the amount of code that must be changed in order to provide this added preemptibility. In particular, critical sections, interrupt handlers, and interrupt-disable code sequences are normally preemptible. The PREEMPT_RT patch leverages the SMP capabilities of the Linux kernel to add this extra preemptibility without requiring a complete kernel rewrite. In a sense, one can loosely think of a preemption as the addition of a new CPU to the system, and then use the normal locking primitives to synchronize with any action taken by the preempting task.

PREEMPT_RT 补丁的核心思想是尽量减少不可抢占的内核代码路径，并且在提供可抢占性的同时，最大限度地避免对内核原有代码进行改动。从补丁的角度来看，临界区，中断处理程序和禁用中断条件下的某些代码执行路径通常都是可抢占的。PREEMPT_RT 补丁通过在 Linux 内核业已支持的 [“对称多处理器（Symmetric multiprocessing，简称 SMP）”][2] 特性的基础之上来增加对可抢占性的支持，这么做的好处是避免了对内核进行重写。从某种程度上来说，如果有人想了解抢占是怎么回事，可以粗略地想象一下我们为一个运行中的系统在线添加一个新的处理器的过程，以及在此期间为了同步可能发生抢占行为的任务而会用到的那些常见的锁操作原语。

> Note that this statement of philosophy should not be taken too literally, for example, the PREEMPT_RT patch does not actually perform a CPU hot-plug event for each preemption. Instead, the point is that the underlying mechanisms used to tolerate (almost) unlimited preemption are those that must be provided for SMP environments. More information on how this philosophy is applied is given in the following sections.

请注意不要机械地理解上述对补丁核心思想的描述，例如，PREEMPT_RT 补丁并不会为每次抢占行为处理一次 CPU 热插拔事件。相反，需要重点理解的是（PREEMPT_RT 补丁）提供了什么样的机制以及在 SMP 环境下，该机制又是如何应对（几乎）随时随地都会发生的抢占行为的。有关该设计原则的更多信息，请参阅文章的以下部分。

## PREEMPT_RT 提供的功能（Features of PREEMPT_RT）

> This section gives an overview of the features that the PREEMPT_RT patch provides.

> 1. Preemptible critical sections
> 2. Preemptible interrupt handlers
> 3. Preemptible "interrupt disable" code sequences
> 4. Priority inheritance for in-kernel spinlocks and semaphores
> 5. Deferred operations
> 6. Latency-reduction measures

> Each of these topics is covered in the following sections.

本章概述了 PREEMPT_RT 补丁所提供的如下功能。

1. 实现临界区可抢占
2. 实现中断处理可抢占
3. 实现 “禁用中断” 条件下代码执行路径可抢占
4. 对内核中的自旋锁和信号量支持优先级继承特性
5. 推迟执行
6. 减少延迟的措施

每一个功能分别用一个章节加以介绍。

### 实现临界区可抢占（Preemptible critical sections）

> In PREEMPT_RT, normal spinlocks (`spinlock_t` and `rwlock_t`) are preemptible, as are RCU read-side critical sections (rcu_read_lock() and rcu_read_unlock()). Semaphore critical sections are preemptible, but they already are in both PREEMPT and non-PREEMPT kernels (but more on semaphores later). This preemptibility means that you can block while acquiring a spinlock, which in turn means that it is illegal to acquire a spinlock with either preemption or interrupts disabled (the one exception to this rule being the `_trylock` variants, at least as long as you don't repeatedly invoke them in a tight loop). This also means that spin_lock_irqsave() does -not- disable hardware interrupts when used on a spinlock_t.

在 PREEMPT_RT 补丁中，大部分的自旋锁（包括 `spinlock_t` 和 `rwlock_t`）都是可抢占的（译者注，所谓自旋锁可以被抢占指的是执行被这些自旋锁所保护的临界区的任务不再独占处理器），RCU 读端的临界区部分（被 `rcu_read_lock()` 和 `rcu_read_unlock()` 括起来代码段）也是可抢占的。信号量（semaphore）保护的临界区原本就是可抢占的，而且信号量的使用从内核开始支持 “抢占（PREEMPT）模式” 和 “非抢占（PREEMPT_NONE）模式” 就存在于内核中了（后来信号量的使用更加普及）。PREEMPT_RT  补丁对自旋锁的改造（使其支持可抢占性）意味着我们在尝试获取锁时有可能会被阻塞（译者注，PREEMPT_RT 对自旋锁的改造将其替换为可睡眠的 `rt_mutex`），这反过来也告诉我们在获取自旋锁时内核不再禁止抢占或禁用中断（但此规则存在一个例外，就是对于那些带 `_trylock` 的锁操作原语（仍然会禁止抢占或者禁止中断），所以我们要注意的是不要在快速的循环体中反复调用它们）。另外需要注意的一点是（在应用 PREEMPT_RT 补丁后）对于 `spinlock_t` 调用 `spin_lock_irqsave()` 将不会禁用硬件中断。

>> **Quick Quiz #1:** How can semaphore critical sections be preempted in a non-preemptible kernel?

>> 快速测试一：在一个不支持抢占的内核中是否会导致信号量保护的临界区被抢占？（译者注，答案统一在文末提供。）

> So, what to do if you need to acquire a lock when either interrupts or preemption are disabled? You use a `raw_spinlock_t` instead of a `spinlock_t`, but continue invoking `spin_lock()` and friends on the `raw_spinlock_t`. The PREEMPT_RT patch includes a set of macros that cause `spin_lock()` to act like a C++ overloaded function -- when invoked on a `raw_spinlock_t`, it acts like a traditional spinlock, but when invoked on a `spinlock_t`, its critical section can be preempted. For example, the various `_irq` primitives (e.g., `spin_lock_irqsave()`) disable hardware interrupts when applied to a `raw_spinlock_t`, but do not when applied to a `spinlock_t`. However, use of `raw_spinlock_t` (and its `rwlock_t` counterpart, `raw_rwlock_t`) should be the exception, not the rule. These raw locks should not be needed outside of a few low-level areas, such as the scheduler, architecture-specific code, and RCU.

那么，如果想要在加锁时仍然禁用中断或禁用抢占该怎么办？答案是，您需要使用 `raw_spinlock_t` 而不是 `spinlock_t`，除此之外调用的锁原语接口仍然是和以前一样，譬如 `spin_lock()` 等。PREEMPT_RT 补丁引入一组预处理宏，这些宏使得 `spin_lock()` 的行为类似于 C++ 语言中的重载函数，当作用于一个 `raw_spinlock_t` 类型的锁对象时，`spin_lock()` 的行为和传统意义上的自旋锁一样，但是作用于 `spinlock_t` 类型的锁对象时，则该锁所保护的临界区可以被抢占。同样的，带有各种 `_irq` 的接口函数（例如，`spin_lock_irqsave()`）在应用于 `raw_spinlock_t` 类型的锁对象时会禁用硬件中断，而用于 `spinlock_t` 类型的锁时则不会禁用硬件中断。但需要注意的是，我们只应该会在很少的情况下使用 `raw_spinlock_t` 类型的锁（与 `rwlock_t` 类型对应的是 `raw_rwlock_t`）。这些情况包括那些底层的处理逻辑，譬如调度器逻辑，体系相关的逻辑以及 RCU 相关的处理。

> Since critical sections can now be preempted, you cannot rely on a given critical section executing on a single CPU -- it might move to a different CPU due to being preempted. So, when you are using per-CPU variables in a critical section, you must separately handle the possibility of preemption, since spinlock_t and rwlock_t are no longer doing that job for you. Approaches include:

由于临界区现在可以被抢占，因此您不能假设一段临界区代码只会在一个处理器上运行，由于抢占行为的存在，该段临界区代码的执行可能会从一个处理器被移动到另一个处理器上。因此，由于 `spinlock_t` 和 `rwlock_t` 不再禁用抢占，当您在临界区代码中访问 per-CPU 变量时，必须考虑抢占可能产生的影响。解决的方法包括：

> 1. Explicitly disable preemption, either through use of get_cpu_var(), preempt_disable(), or disabling hardware interrupts.

> 2. Use a per-CPU lock to guard the per-CPU variables. One way to do this is by using the new `DEFINE_PER_CPU_LOCKED()` primitive -- more on this later.

1. 通过调用 `get_cpu_var()`，`preempt_disable()` 显式地禁用抢占，或者干脆禁用硬件中断。

2. 使用 per-CPU 的锁来保护 per-CPU 的变量。采取的方法之一是使用新的 `DEFINE_PER_CPU_LOCKED()` 原语，稍后将详细介绍。

> Since `spin_lock()` can now sleep, an additional task state was added. Consider the following code sequence (supplied by Ingo Molnar):

由于 `spin_lock()` 现在可以休眠，因此添加了一个额外的任务状态。请考虑以下代码序列（由 Ingo Molnar 提供）：

	spin_lock(&mylock1);
	current->state = TASK_UNINTERRUPTIBLE;
	spin_lock(&mylock2);                    // [*]
	blah();
	spin_unlock(&mylock2);
	spin_unlock(&mylock1);

> Since the second `spin_lock()` call can sleep, it can clobber the value of `current->state`, which might come as quite a surprise to the `blah()` function. The new `TASK_RUNNING_MUTEX` bit is used to allow the scheduler to preserve the prior value of `current->state` in this case.

由于第二个 `spin_lock()` 函数调用会休眠，这会导致 `current->state` 的值被内核改变，从而影响 `blah()` 函数的执行逻辑。为此内核新增加了一个 `TASK_RUNNING_MUTEX` 状态值用于标识并指示调度器为此保留 `current->state` 先前设置的值。

> Although the resulting environment can be a bit unfamiliar, but it permits critical sections to be preempted with minimal code changes, and allows the same code to work in the PREEMPT_RT, PREEMPT, and non-PREEMPT configurations.

尽管最终的代码会让大家感觉有点不熟悉，但它允许使用最少的修改实现对临界区的抢占，并使得在不同的内核配置选项 `PREEMPT_RT`，`PREEMPT`和 `PREEMPT_NONE` 下共享同一份内核代码。

### 实现中断处理可抢占（Preemptible interrupt handlers）

> Almost all interrupt handlers run in process context in the PREEMPT_RT environment. Although any interrupt can be marked `SA_NODELAY` to cause it to run in interrupt context, only the fpu_irq, irq0, irq2, and lpptest interrupts have `SA_NODELAY` specified. Of these, only irq0 (the per-CPU timer interrupt) is normally used -- fpu_irq is for floating-point co-processor interrupts, and lpptest is used for interrupt-latency benchmarking. Note that software timers (`add_timer()` and friends) do not run in hardware interrupt context; instead, they run in process context and are fully preemptible.

应用 PREEMPT_RT 补丁后几乎所有的中断处理程序都在进程上下文中运行（译者注，指采用中断线程化技术）。虽然任何中断都可以通过设置 `SA_NODELAY` 标志使其依然在中断上下文中运行，但目前只有 fpu_irq，irq0，irq2 和 lpptest 中断指定了 `SA_NODELAY`。而且通常情况下系统只会启用 irq0（这是一个 per-CPU 的定时器中断），其他的譬如 fpu_irq 只用于浮点协处理器中断，以及 lpptest 用于中断延迟基准测试。需要注意的是，软件定时器（譬如通过调用 `add_timer()` 和其他类似的函数启动的定时器）处理函数并不在硬件中断上下文中运行；相反，它们运行在进程上下文中，所以也是完全支持可抢占的。

> Note that `SA_NODELAY` is not to be used lightly, as can greatly degrade both interrupt and scheduling latencies. The per-CPU timer interrupt qualifies due to its tight tie to scheduling and other core kernel components. Furthermore, `SA_NODELAY` interrupt handlers must be coded very carefully as noted in the following paragraphs, otherwise, you will see oopses and deadlocks.

请注意，不要轻易使用 `SA_NODELAY`，因为这会引起非常大的中断和调度延迟。而之所以 per-CPU 定时器中断仍然需要采用这种方式运行完全是因为此类中断被用于实现核心的调度算法和相关处理。此外，必须参考后继章节的介绍，小心地对采用 `SA_NODELAY` 方式执行的中断处理程序进行编码，否则，您将面临各种系统崩溃（oops）和死锁（deadlock）现象。

> Since the per-CPU timer interrupt (e.g., `scheduler_tick()`) runs in hardware-interrupt context, any locks shared with process-context code must be raw spinlocks (`raw_spinlock_t` or `raw_rwlock_t`), and, when acquired from process context, the `_irq` variants must be used, for example, `spin_lock_irqsave()`. In addition, hardware interrupts must typically be disabled when process-context code accesses per-CPU variables that are shared with the `SA_NODELAY` interrupt handler, as described in the following section.

由于 per-CPU 的定时器中断处理函数（例如，`scheduler_tick()`）在硬件中断上下文中运行，因此任何与进程上下文代码共享的锁必须是采用 raw 类型的自旋锁（`raw_spinlock_t` 或 `raw_rwlock_t`），并且当我们从进程上下文中试图获取这把锁时，必须使用带 `_irq` 的那些锁原语（译者注，以禁用中断），例如，`spin_lock_irqsave()`。此外，当在进程上下文代码中访问与设置为 `SA_NODELAY` 方式的中断处理程序共享的 per-CPU 变量时，通常必须禁用硬件中断，具体参考下一章的介绍。

### 实现 “禁用中断” 条件下代码执行路径可抢占（Preemptible "interrupt disable" code sequences）

> The concept of preemptible interrupt-disable code sequences may seem to be a contradiction in terms, but it is important to keep in mind the PREEMPT_RT philosophy. This philosophy relies on the SMP capabilities of the Linux kernel to handle races with interrupt handlers, keeping in mind that most interrupt handlers run in process context. Any code that interacts with an interrupt handler must be prepared to deal with that interrupt handler running concurrently on some other CPU.

在禁用中断的前提条件下对代码序列实现可抢占，这个概念在描述上似乎是自相矛盾的，但重要的是要记住 PREEMPT_RT 的设计思想。其理念基于 Linux 内核对 SMP 的支持能力来处理源自中断所产生的竞争，同时还需要记住的是大多数中断处理程序已经变为在进程上下文中运行。任何与中断处理程序有交集的代码都必须准备好随时处理在其他处理器上并发运行的中断处理程序。

> Therefore, `spin_lock_irqsave()` and related primitives need not disable preemption. The reason this is safe is that if the interrupt handler runs, even if it preempts the code holding the `spinlock_t`, it will block as soon as it attempts to acquire that `spinlock_t`. The critical section will therefore still be preserved.

因此，`spin_lock_irqsave()` 和相关锁操作原语并不需要禁用抢占。这么做是安全的，原因是如果一个中断处理程序开始运行，即便它抢占了持有 `spinlock_t` 类型的锁的代码执行序列，该中断处理程序也会在尝试获取同一把自旋锁时进入阻塞。因此，被自旋锁保护的临界区代码依然是安全的。

> However, `local_irq_save()` still disables preemption, since there is no corresponding lock to rely on. Using locks instead of `local_irq_save()` therefore can help reduce scheduling latency, but substituting locks in this manner can reduce SMP performance, so be careful.

但是，`local_irq_save()` 仍然会禁用抢占，因为使用该函数并无法利用任何锁机制来实现阻塞。因此，使用锁而不是 `local_irq_save()` 可以有助于降低调度延迟，但是以这种方式替换锁会降低 SMP 的性能，所以要小心。

> Code that must interact with `SA_NODELAY` interrupts cannot use `local_irq_save()`, since this does not disable hardware interrupts. Instead, `raw_local_irq_save()` should be used. Similarly, raw spinlocks (`raw_spinlock_t`, `raw_rwlock_t`, and `raw_seqlock_t`) need to be used when interacting with `SA_NODELAY` interrupt handlers. However, raw spinlocks and raw interrupt disabling should -not- be used outside of a few low-level areas, such as the scheduler, architecture-dependent code, and RCU.

必须与标记为 `SA_NODELAY` 类型的中断处理代码打交道的代码不能使用 `local_irq_save()`，因为该函数不会禁用硬件中断。为此，应该使用 `raw_local_irq_save()`。类似地，在与标记为 `SA_NODELAY` 类型的中断处理程序打交道时需要使用 raw 类型的自旋锁（`raw_spinlock_t`，`raw_rwlock_t` 和 `raw_seqlock_t`）。但是，对 raw 类型的自旋锁和禁用中断的使用应该只局限在少数底层代码中，例如调度程序，体系结构相关代码和 RCU。

### 对内核中的自旋锁和信号量支持优先级继承特性（Priority inheritance for in-kernel spinlocks and semaphores）

> Realtime programmers are often concerned about priority inversion, which can happen as follows:

> - Low-priority task A acquires a resource, for example, a lock.

> - Medium-priority task B starts executing CPU-bound, preempting low-priority task A.

> - High-priority task C attempts to acquire the lock held by low-priority task A, but blocks because of medium-priority task B having preempted low-priority task A.

实时用户经常会关注所谓 “优先级反转（priority inversion）” 的问题，一个典型的场景如下：

- 低优先级任务 A 先获取资源，例如，一把锁。
- 中优先级任务 B 开始在同一个处理器上执行，并抢占了低优先级任务 A。
- 高优先级任务 C 尝试获取低优先级任务 A 持有的锁，但由于中优先级任务 B 抢占了任务 A 导致任务 C 被阻塞。

> Such priority inversion can indefinitely delay a high-priority task. There are two main ways to address this problem: (1) suppressing preemption and (2) priority inheritance. In the first case, since there is no preemption, task B cannot preempt task A, preventing priority inversion from occurring. This approach is used by PREEMPT kernels for spinlocks, but not for semaphores. It does not make sense to suppress preemption for semaphores, since it is legal to block while holding one, which could result in priority inversion even in absence of preemption. For some realtime workloads, preemption cannot be suppressed even for spinlocks, due to the impact to scheduling latencies.

这种优先级反转会无限期地导致一个高优先级的任务被延迟。主要有两种方法可以解决这个问题：（方法一）抑制抢占和（方法二）优先级继承（priority inheritance）。采用方法一时，由于没有抢占，任务 B 不能抢占任务 A，从而阻止优先级反转的发生。该方法被 PREEMPT 模式下的内核用于自旋锁，但不用于信号量。抑制对信号量的抢占是没有意义的，因为在持有信号量时阻塞是合法的，即使没有抢占也可能导致优先级反转。对于某些实时场景，由于对调度延迟的影响，即使对于自旋锁也不能抑制抢占。

> Priority inheritance can be used in cases where suppressing preemption does not make sense. The idea here is that high-priority tasks temporarily donate their high priority to lower-priority tasks that are holding critical locks. This priority inheritance is transitive: in the example above, if an even higher priority task D attempted to acquire a second lock that high-priority task C was already holding, then both tasks C and A would be be temporarily boosted to the priority of task D. The duration of the priority boost is also sharply limited: as soon as low-priority task A releases the lock, it will immediately lose its temporarily boosted priority, handing the lock to (and being preempted by) task C.

优先级继承可用于无法抑制抢占的情况。这里的想法是，高优先级任务暂时将其高优先级权限让渡给持有锁的低优先级任务。这种优先级继承是临时的：在上面的例子中，如果一个更高优先级的任务 D 尝试获取高优先级任务 C 所已经拥有的第二个锁，则任务 C 和 A 的优先级都将被暂时提升到和任务 D 相同的水平。优先级提升所持续的时间会受到严格限制：一旦低优先级任务 A 释放了锁，则它临时被提升的优先级会被恢复，（从而被任务 C 抢占）并交出其拥有的锁。

> However, it may take some time for task C to run, and it is quite possible that another higher-priority task E will try to acquire the lock in the meantime. If this happens, task E will "steal" the lock from task C, which is legal because task C has not yet run, and has therefore not actually acquired the lock. On the other hand, if task C gets to run before task E tries to acquire the lock, then task E will be unable to "steal" the lock, and must instead wait for task C to release it, possibly boosting task C's priority in order to expedite matters.

但是，任务 C 真正开始运行可能需要一些时间，并且很可能另一个更高优先级的任务 E 将在此期间尝试获取锁。如果发生这种情况，任务 E 将从任务 C “窃取” 该锁，这是合法的，因为任务 C 尚未运行，因此实际上没有获得锁。另一方面，如果任务 C 在任务 E 尝试获取锁之前运行，则任务 E 将无法 “窃取” 锁，而必须等待任务 C 释放它，同时为了加快处理事宜，内核可能会提升任务 C 的优先级。。

> In addition, there are some cases where locks are held for extended periods. A number of these have been modified to add "preemption points" so that the lock holder will drop the lock if some other task needs it. The JBD journaling layer contains a couple of examples of this.

此外，在某些情况下，锁可以会被持有较长时间。其中一些地方已被修改并添加了 “抢占点”，以便锁的持有者可以在其他任务需要时放弃锁。[JBD][3] 日志层的代码包含了几个这样的例子。

> It turns out that write-to-reader priority inheritance is particularly problematic, so PREEMPT_RT simplifies the problem by permitting only one task at a time to read-hold a reader-writer lock or semaphore, though that task is permitted to recursively acquire it. This makes priority inheritance doable, though it can limit scalability.

目前发现，有关读写锁的优先级继承问题特别棘手，因此 PREEMPT_RT 补丁对该问题进行了简化，一次只允许一个读操作任务获取读写锁或者是读写信号量（并进入临界区），尽管允许该任务以递归方式获取它。这使得（针对读写锁的）优先级继承成为可能，但这么做明显会影响系统整体的扩展性。

>> **Quick Quiz #2:** What is a simple and fast way to implement priority inheritance from writers to multiple readers?

快速测试二：对于一个写端和多个读端的场景，实现优先级继承最简单快速的方法是什么？

> In addition, there are some cases where priority inheritance is undesirable for semaphores, for example, when the semaphore is being used as an event mechanism rather than as a lock (you can't tell who will post the event before the fact, and therefore have no idea which task to priority-boost). There are `compat_semaphore` and `compat_rw_semaphore` variants that may be used in this case. The various semaphore primitives (`up()`, `down()`, and friends) may be used on either `compat_semaphore` and semaphore, and, similarly, the reader-writer semaphore primitives (`up_read()`, `down_write()`, and friends) may be used on either `compat_rw_semaphore` and `rw_semaphore`. Often, however, the  is a better tool for this job.

此外，在某些情况下，信号量并不希望实现优先级继承，例如，当信号量被用于实现 “事件机制（event mechanism）” 而不是实现锁机制时（你无法知道谁将最终发送事件，因此不知道应该提升哪个任务的优先级。在这种情况下可以使用 `compat_semaphore` 和 `compat_rw_semaphore` 这类普通信号量的变体。可以针对 `compat_semaphore` 和标准的 semaphore 使用各种信号量操作原语（包括 `up()`，`down()` 和 相关函数），类似地，可以对 `compat_rw_semaphore` 和 `rw_semaphore` 使用针对 “读写信号量（reader-writer semaphore）” 的操作原语（包括 `up_read()`，`down_write()` 和相关函数）。然而，通常情况下，最好直接利用 “完成机制（completion mechanism）”。

> So, to sum up, priority inheritance prevents priority inversion, allowing high-priority tasks to acquire locks and semaphores in a timely manner, even if the locks and semaphores are being held by low-priority tasks. PREEMPT_RT's priority inheritance provides transitivity, timely removal of inheritance, and the flexibility required to handle cases when high priority tasks suddenly need locks earmarked for low-priority tasks. The `compat_semaphore` and `compat_rw_semaphore` declarations can be used to avoid priority inheritance for semaphores for event-style usage.

总而言之，使用优先级继承技术可避免优先级反转，即使锁和信号量当前被低优先级的任务所持有，也可以允许高优先级的任务及时获取锁和信号量。PREEMPT_RT 所实现的优先级继承能够及时恢复被提升的低优先级任务的优先级，从而确保足够的灵活性，在锁已经被低优先级任务所持有的情况下，一旦高优先级的任务立马需要锁也可以尽快获得。如果用户不希望在使用信号量时使用优先级继承特性，譬如对于某些事件通知类型的场景，也可以使用 `compat_semaphore` 和 `compat_rw_semaphore` 类型的信号量。

### 推迟执行（Deferred operations）

> Since `spin_lock()` can now sleep, it is no longer legal to invoke it while preemption (or interrupts) are disabled. In some cases, this has been solved by deferring the operation requiring the `spin_lock()` until preemption has been re-enabled:

由于 `spin_lock()` 现在会休眠，所以在禁用抢占（或者中断）情况下不可以调用该函数。解决的方法是推迟相关操作，等到抢占恢复后再调用 `spin_lock()`，譬如采取如下方式：

> - `put_task_struct_delayed()` queues up a `put_task_struct()` to be executed at a later time when it is legal to acquire (for example) the `spinlock_t alloc_lock` in `task_struct`.
> - `mmdrop_delayed()` queues up an `mmdrop()` to be executed at a later time, similar to `put_task_struct_delayed()` above.
> - `TIF_NEED_RESCHED_DELAYED` does a reschedule, but waits to do so until the process is ready to return to user space -- or until the next `preempt_check_resched_delayed()`, whichever comes first. Either way, the point is avoid needless preemptions in cases where a high-priority task being awakened cannot make progress until the current task drops a lock. Without `TIF_NEED_RESCHED_DELAYED`, the high-priority task would immediately preempt the low-priority task, only to quickly block waiting for the lock held by the low-priority task.
>   The solution is to change a "`wake_up()`" that is immediately followed by a `spin_unlock()` to instead be a "`wake_up_process_sync()`". If the process being awakened would preempt the current process, the wakeup is delayed via the `TIF_NEED_RESCHED_DELAYED` flag.

- 调用 `put_task_struct_delayed()` 将 `put_task_struct()` 操作排队，以便在稍后合适的时间再尝试获取锁（例如 `task_struct` 中的 `spinlock_t alloc_lock`）。
- 调用 `mmdrop_delayed()` 将 `mmdrop()` 操作排队等待稍后执行，类似于上面的 `put_task_struct_delayed()`。
- 设置 `TIF_NEED_RESCHED_DELAYED` 标志位，告诉调度器需要重新调度，但需要等到进程准备好将要返回用户空间前才会执行，或者直到下一次 `preempt_check_resched_delayed()`，以先到者为准。无论哪种方式，重点是避免由于当前锁被其他任务所占用使得高优先级任务被唤醒后又无法获取锁而百忙一场。如果没有 `TIF_NEED_RESCHED_DELAYED`，高优先级任务虽然会立即抢占低优先级任务，但由于锁被低优先级的任务所持有，所以该高优先级的任务只能又快速进入睡眠。

    解决方案是新增一个叫做 “`wake_up_process_sync()`” 的函数，该函数基于 “`wake_up()`” 函数修改，在其函数的最后调用 `spin_unlock()`。如果被唤醒的任务可以抢占当前任务，但内核检查 `TIF_NEED_RESCHED_DELAYED` 标志被设置则会推迟唤醒该任务。

> In all of these situations, the solution is to defer an action until that action may be more safely or conveniently performed.

在所有这些情况下，解决方案是推迟操作，直到可以更安全或更方便地执行该操作。

### 减少延迟的措施（Latency-reduction measures）

> There are a few changes in PREEMPT_RT whose primary purpose is to reduce scheduling or interrupt latency.

PREEMPT_RT 中还有一些更改，其主要目的是减少调度或中断延迟。

> The first such change involves the x86 MMX/SSE hardware. This hardware is handled in the kernel with preemption disabled, and this sometimes means waiting until preceding MMX/SSE instructions complete. Some MMX/SSE instructions are no problem, but others take overly long amounts of time, so PREEMPT_RT refuses to use the slow ones.

第一个相关改动涉及对 x86 MMX/SSE 硬件的操作。在内核中处理此硬件时会禁用抢占，这意味着有时调度必须要等到 MMX/SSE 指令完成之后才能恢复。这对于有些 MMX/SSE 指令来说没有问题，但对于其他指令会花费太长时间，因此 PREEMPT_RT 中不再使用那些执行较慢的指令。

> The second change applies per-CPU variables to the slab allocator, as an alternative to the previous wanton disabling of interrupts.

第二处改动是为 slab 分配器使用 per-CPU 变量，作为先前禁用中断的替代方法。

## PREEMPT_RT 原语摘要 （Summary of PREEMPT_RT primitives）

（译者注，该部分暂不翻译，感兴趣读者可以自行阅读原文。）

## PREEMPT_RT 配置选项（PREEMPT_RT configuration options）

（译者注，该部分暂不翻译，感兴趣读者可以自行阅读原文。）

## PREEMPT_RT 补丁所带来的一些额外奖励（Some unintended side-effects of PREEMPT_RT）

> Because the PREEMPT_RT environment relies heavily on Linux being coded in an SMP-safe manner, use of PREEMPT_RT has flushed out a number of SMP bugs in the Linux kernel, including some timer deadlocks, lock omissions in `ns83820_tx_timeout()` and friends, an ACPI-idle scheduling latency bug, a core networking locking bug, and a number of preempt-off-needed bugs in the block IO statistics code.

因为 PREEMPT_RT 环境在很大程度上依赖于 Linux 必须以 SMP 安全的方式进行编码，所以测试和开发 PREEMPT_RT 过程中帮助清除了 Linux 内核中许多有关 SMP 的错误，包括一些定时器死锁，`ns83820_tx_timeout()` 函数中忘记加锁的问题，ACPI-空闲调度延迟中的错误，一个核心网络锁错误，以及一些在块 IO 统计代码中涉及抢占的错误。

## 快速测试答案（Quick quiz answers）

> **Quick Quiz #1:** How can semaphore critical sections be preempted in a non-preemptible kernel?

>> Strictly speaking, preemption simply does not happen in a non-preemptible kernel (e.g., non-CONFIG_PREEMPT). However, roughly the same thing can occur due to things like page faults while accessing user data, as well as via explicit calls to the scheduler.

**快速测试一：** 在一个不支持抢占的内核中是否会导致信号量保护的临界区被抢占？

严格来说，在不支持抢占的内核中抢占就不会发生（例如，没有配置 `CONFIG_PREEMPT` 的情况）。但是，大致和访问用户数据时会发生缺页错误的原因类似，通过对调度程序的显式调用也会导致在一个不支持抢占的内核中被信号量保护的临界区被抢占。

> **Quick Quiz #2:** What is a simple and fast way to implement priority inheritance from writers to multiple readers?

>> If you come up with a way of doing this, I expect that Ingo Molnar will be very interested in learning about it. However, please check the LKML archives before getting too excited, as this problem is extremely non-trivial, there are no known solutions, and it has been discussed quite thoroughly. In particular, when thinking about writer-to-reader priority boosting, consider the case where a reader-writer lock is read-held by numerous readers, and each reader is blocked attempting to write-acquire some other reader-writer lock, each of which again is read-held by numerous readers. Of course, the time required to boost (then un-boost) all these readers counts against your scheduling latency.

>> Of course, one solution would be to convert the offending code sequences to use RCU. ;-) [Sorry, couldn't resist!!!]

**快速测试二：** 对于一个写端和多个读端的场景，实现优先级继承最简单快速的方法是什么？


如果你想出解决的办法，我相信 Ingo Molnar 会非常有兴趣了解它。但是，请在急着报告你的想法之前先检查一下内核邮件列表中存档的讨论内容，因为这个问题非常复杂，社区已经对此进行了相当深入的讨论，但目前还未找到解决的方案。譬如，在考虑如何针对读写者任务进行优先级提升时，如果一把读写锁已经被许多读任务所获取，但这些读任务却因为以写入者的身份尝试获取另外的读写锁而无法获得被阻塞，而这些另外的读写锁又许多其他的读任务所获取。当然，有关提升优先级（以及恢复初始优先级）所需要花费的时间也依赖于您所在系统的调度延迟效率。

当然，有一种解决方案是将相关代码改为使用 RCU。;-) [对不起，我又忍不住提到了 RCU!!!]

> ** Quick Quiz #3:** Why can't event mechanisms use priority inheritance?

>> There is no way for Linux to figure out which task to boost. With sleeping locks, the task that acquired the semaphore would presumably be the task that will release it, so that is the task whose priority gets boosted. In contrast, with events, any task might do the `down()` that awakens the high-priority task.

**快速测试三：** 为什么事件机制不能使用优先级继承？

Linux 无法确定对哪个任务提升优先级。当使用可睡眠的锁时，已获取信号量的任务被认为就是释放它的任务，因此这个任务就是需要被提升优先级的任务。相反，对于事件，任何任务都可以执行 `down()` 来唤醒高优先级任务。

> [Thanks to Ingo Molnar for his thorough review of a previous draft of this document].

[感谢 Ingo Molnar 对本文前一稿的全面审查]。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://lwn.net/Articles/143323/
[2]: https://en.wikipedia.org/wiki/Symmetric_multiprocessing
[3]: https://en.wikipedia.org/wiki/Journaling_block_device
