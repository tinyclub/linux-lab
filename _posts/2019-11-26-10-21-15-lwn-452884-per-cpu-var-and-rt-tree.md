---
layout: post
draft: false
top: false
author: 'Wang Chen'
title: "LWN 452884: 实时 Linux 中的 Per-CPU 变量处理"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-452884/
description: "LWN 中文翻译，实时 Linux 中的 Per-CPU 变量处理"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - realtime
  - per-cpu
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Per-CPU variables and the realtime tree](https://lwn.net/Articles/452884/)
> 原创：By Jonathan Corbet @ Jul. 26, 2011
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Libin Zhao](https://github.com/Bennnyzhao)

> One of the problems with relying on out-of-tree kernel code is that one can never be sure when that code might be updated for newer kernels. Keeping up with the kernel can be painful even for maintainers of small patches; it's much more so for those who maintain a large, invasive patch series. It is probably safe to say that, if the realtime preemption developers do not keep their patches current, there are very few other developers who are in a position to take on that work. So it was certainly discouraging for some realtime users to watch multiple kernel releases go by while the realtime patch series remained stuck at 2.6.33.

对于使用游离于内核主线之外的补丁的用户来说，最痛苦的问题之一就是，他们永远无法确定何时这些补丁能够跟上最新的内核版本。对于补丁的维护者来说，即使补丁很小，要和内核主线保持同步也不是一件容易的事情；更不用说对于那些大型的，体量巨大的补丁了。可以肯定地说，如果实时抢占补丁（译者注，即 PREEMPT_RT 补丁）的开发人员不能及时更新他们的代码，那么很少会有其他开发人员能够代替他们承担这项工作。因此，当实时补丁仍旧徘徊在 2.6.33 版本，而内核主线版本却在不停地升级时，此时此景，一些实时系统的用户一定会感到万分沮丧。

> The good news is that the roadblock has been overcome and there is now a new realtime tree for the 3.0 kernel. Even better news is that the realtime developers may have come up with a solution for one of the most vexing problems keeping the realtime code out of the mainline. The only potential down side is that this approach relies on an interesting assumption about how per-CPU data is used; this assumption will have to be verified with a lot of testing and, likely, a number of fixes throughout the kernel.

好消息是形势正在有所好转，现在针对 3.0 的内核已经有了一个对应的新的实时补丁。更好的消息是，在一个最棘手的，涉及妨碍实时补丁合入内核主线的问题上，实时开发人员可能已经找到了一个解决方案。唯一潜在的问题是这种方法依赖于对内核在使用 Per-CPU 数据方式上的一个有趣的假设；这个假设必须通过大量测试来验证，并且可能涉及对多处内核代码进行改动。

> Symmetric multiprocessing systems are nice in that they offer equal access to memory from all CPUs. But taking advantage of the feature is a guaranteed way to create a slow system. Shared data requires mutual exclusion to avoid concurrent access; that means locking and the associated bottlenecks. Even in the absence of lock contention, simply moving cache lines between CPUs can wreck performance. The key to performance on SMP systems is minimizing the sharing of data, so it is not surprising that a great deal of scalability work in the kernel depends on the use of per-CPU data.

“对称多处理（Symmetric MultiProcessing， 简称 SMP）” 系统的优点在于，所有的处理器平等地享有对内存的访问权利。但是这么做容易导致整体上系统处理效率的降低。共享数据需要互斥以避免并发访问；这意味着需要提供相应的锁机制以及伴随而来的性能瓶颈问题。即使不存在对锁的争用，仅仅是因为在处理器之间对 “缓存行（cache line）” 数据进行移动就足以对性能造成影响（译者注，这里指的是由于多个处理器的缓存行中存放了同一个全局变量的副本，任何一个处理器对本地缓存行中该变量的修改都会导致其他处理器的缓存行中副本的失效，为此必须实现对该场景下缓存行中数据副本的同步刷新操作）。所以提高 SMP 系统性能的关键举措就是要最大限度地减少数据共享，正因为如此，为了解决 “扩展性（scalability）” 的问题，内核中引入了大量的 Per-CPU 变量（译者注，Per-CPU 变量是自 2.6 以来内核引入的一个有趣的特性，主要是为了解决 SMP 系统上的变量访问问题。当建立一个 Per-CPU 变量时，系统中的每个处理器都会拥有该变量的特有副本。因为每个处理器在其自己的副本上工作，所以对 Per-CPU 变量的访问不需要加锁；Per-CPU 变量还可以保存在对应的处理器的高速缓存中，这样，在频繁更新时可以获得更好的性能。如果需要更详细的说明请参考 [LWN 上对 Per-CPU 的介绍][2]）。

> A per-CPU variable in the Linux kernel is actually an array with one instance of the variable for each processor. Each processor works with its own copy of the variable; this can be done with no locking, and with no worries about cache line bouncing. For example, some slab allocators maintain per-CPU lists of free objects and/or pages; these allow quick allocation and deallocation without the need for locking to exclude any other CPUs. Without these per-CPU lists, memory allocation would scale poorly as the number of processors grows.

Linux 内核中的 Per-CPU 变量本质上是一个数组，数组的每个元素对应一个处理器。每个处理器都使用自己的变量副本；这么做可以在无锁的情况下完成对数据的访问操作，并且不用担心 “缓存行” 的 “bouncing” 问题（译者注，有关 “bouncing” 问题，参考 [网上的一段解释][3]）。例如，一些 slab 分配器为每个处理器维护一份自己的（Per-CPU）空闲对象以及内存页的链表；由于不存在其他处理器的并发访问，我们可以在无需加锁的情况下实现快速的分配和释放。如果没有这些 Per-CPU 类型的链表，随着处理器数量的增长，共享内存变量的 bouncing 问题就会愈发突出，自然造成整体内存访问效率变差，扩展性降低。

> Safe access to per-CPU data requires a couple of constraints, though: the thread working with the data cannot be preempted and it cannot be migrated while it manipulates per-CPU variables. If the thread is preempted, the thread that replaces it could try to work with the same variable; migration to another CPU could cause confusion for fairly obvious reasons. To avoid these hazards, access to per-CPU variables is normally bracketed with calls to `get_cpu_var()` and `put_cpu_var()`; the `get_cpu_var()` call, along with providing the address for the processor's version of the variable, disables preemption. So code which obtains a reference to a per-CPU data will not be scheduled out of the CPU until it releases that reference. Needless to say, any such code must be atomic.

但是，对 Per-CPU 数据的安全访问需要遵循一些限制前提：首先，访问数据的线程不能被抢占；其次，访问数据的线程在操作 Per-CPU 变量期间也不可以被迁移到其他处理器上去。如果线程被抢占，替换它的线程可能会尝试访问相同的变量；类似的原因，如果线程在访问过程中被迁移到另一个处理器上也可能会导致类似的混乱。为了避免这些风险，通常需要在访问 Per-CPU 变量的代码段的前后分别调用 `get_cpu_var()` 和 `put_cpu_var()`；对 `get_cpu_var()` 的调用，除了返回当前处理器对应的变量的地址外（译者注，即下文所谓的获得对 Per-CPU 变量的引用），还会禁用抢占。因此，一个（调用了 `get_cpu_var()` 的）任务在（通过调用对应的 `put_cpu_var()` 函数）释放该引用之前，是不会被调度出当前处理器的（译者注，即其他任务也无法使用该处理器），从而保证了对 Per-CPU 变量访问的原子性。

> The conflict with realtime operation should be obvious: in the realtime world, anything that disables preemption is a possible source of unwanted latency. Realtime developers want the highest-priority process to run at all times; they have little patience for waiting while a low-priority thread gets around to releasing a per-CPU variable reference. In the past, this problem has been worked around by protecting per-CPU variables with spinlocks. These locks keep the code preemptable, but they wreck the scalability that per-CPU variables were created to provide and complicate the code. It has been clear for some time that a different solution would need to be found.

但这么做很显然和实时性需求存在冲突：在实时世界中，任何禁用抢占的操作都是造成延迟的潜在诱因。实时开发人员总是希望最高优先级的进程能够及时获得处理器；它们可没有耐心等待低优先级的线程释放 Per-CPU 变量。目前采用的解决方法是通过使用 “自旋锁（spinlock）” 保护 Per-CPU 变量。这些锁（译者注，在 PREEMTP_RT 补丁中）可以使代码仍然保持可抢占性，但它们破坏了当初为了提高扩展性而创建 Per-CPU 变量的初衷，并使得代码变得复杂。很明显，我们需要一个更好的解决方案，但一直还未找到。

> With the [3.0-rc7-rt0](https://lwn.net/Articles/452266/) announcement, Thomas Gleixner noted that "`the number of sites which need to be patched is way too large and the resulting mess in the code is neither acceptable nor maintainable.`" So he and Peter Zijlstra sat down to come up with a better solution for per-CPU data. The solution they came up with is surprisingly simple: whenever a process acquires a spinlock or obtains a CPU reference with `get_cpu()`, the scheduler will refrain from migrating that process to any other CPU. That process remains preemptable - code holding spinlocks can be preempted in the realtime world - but it will not be moved to another processor.

随着 [3.0-rc7-rt0][1] 实时补丁的发布，Thomas Gleixner 指出 “`需要修改的地方实在太多，这导致代码过于凌乱，这是无法接受的也不具备可维护性。`” 所以他和 Peter Zijlstra 找了一个机会仔细讨论了一下该如何解决有关 Per-CPU 的问题。他们最终提出的方案竟然是如此的简单，他们认为：一旦一个任务获取了自旋锁或通过调用 `get_cpu()` 获取了对处理器的引用，内核调度器要做的仅仅是避免将该任务迁移到其他处理器上去。也就是说，在此期间任务仍然可以被抢占（在 PREEMPT_RT 补丁中自旋锁是可以被抢占的），但不会被迁移到另一个处理器上去。

> Disabling migration avoids one clear source of trouble: a process which is migrated in the middle of manipulating a per-CPU variable will end up working with the wrong CPU's instance of that variable. But what happens if a process is preempted by another process that needs to access the same variable? If preemption is no longer disabled, this unfortunate event seems like a distinct possibility.

禁用任务迁移避免了一个明显的麻烦：如果一个任务在访问 Per-CPU 变量的过程中被迁移到其他处理器上则可能会访问别的处理器上的错误的变量实例。但是，如果这个任务被另一个需要访问同一变量的任务抢占，又会发生什么呢？由于抢占不再被禁止，这种不幸的事看上去发生的可能性还是蛮大的。

> After puzzling over this problem for a bit, the path to enlightenment became clear: just ask Thomas what they are thinking with this change. What they are thinking, it turns out, is that any access to per-CPU data needs to be protected by some sort of lock. If need be, the lock itself can be per-CPU, so the locking need not reintroduce the cache line bouncing that the per-CPU variable is intended to prevent. In many cases, that locking is already there for other purposes.

这个问题曾经困扰了大家一阵子，但现在思路变得清晰了许多：可以问一下 Thomas 他们的最新看法。目前看起来，他们的想法是，对 Per-CPU 数据的任何访问都需要通过某种锁来施加保护。必要的话，锁本身也需要是一个 Per-CPU 变量，以此来避免再次引入不必要的缓存失效问题。大部分情况下，由于各种其他的原因，现有代码对 Per-CPU 都已经添加了此类锁保护（译者注，也就是说对于抢占可能引起的问题，并不需要对现有代码进行太大的改动）。

> The realtime developers are making the bet that this locking is already there in almost every place where per-CPU data is manipulated, and that the exceptions are mostly for data like statistics used for debugging where an occasional error is not really a problem. When it comes to locking, though, a gut feeling that things are right is just not good enough; locking problems have a way of lurking undetected for long periods of time until some real damage can be done. Fortunately, this is a place where computers can help; the realtime tree will probably soon acquire an extension to the locking validator that checks for consistent locking around per-CPU data accesses.

实时补丁的开发人员打赌说内核中所有涉及 Per-CPU 变量操作的地方都已通过加锁的方式施加了保护，当然也存在一些例外，但这些例外所涉及的，主要都是形如那些对用于调试的统计数据的操作，对于这些情况，偶尔的错误并不会引起什么大的问题。当然，由于涉及到锁处理，虽然直觉上感觉这么考虑并没有错但并不让人百分之百地放心；和锁相关的问题（译者注，主要是各类死锁问题）很可能会潜伏在那里长时间不被我们所注意，直到造成真正的破坏时才被我们发现。幸运的是，我们可以利用程序帮助我们检查；实时内核代码仓库很快会对 “锁检验器（locking validator，译者注，即 lockdep）” 完成扩展升级，使其可以针对 Per-CPU 数据的加锁一致性问题进行检查。

> Lockdep is very good at finding subtle locking problems which are difficult or impossible to expose with ordinary testing. So, once this extension has been implemented and the resulting problem reports investigated and resolved, the assumption that all per-CPU accesses are protected by locking will be supportable. That process will likely take some time and, probably, a number of fixes to the mainline kernel. For example, there may well be bugs now where per-CPU variables are manipulated in interrupt handlers but non-interrupt code does not disable interrupts; the resulting race will be hard to hit, but possibly devastating when it happens.

Lockdep 非常擅长发现那些微妙的和锁有关的问题，这些问题很难暴露，几乎不可能通过普通测试来发现。因此，一旦在此升级的基础上（利用 Lockdep）找到并解决了发现的所有问题，就可以验证所有对 Per-CPU 变量的访问的确都已经处于正确的锁保护之下了。这个过程肯定需要一些时间，还可能需要对主线内核进行一些修改。例如，现在可能存在某些错误，譬如中断处理程序中访问了 Per-CPU 变量，但其他任务上下文的访问代码中忘记了禁用中断；由此产生的竞争问题很难被触发，但一旦发生所造成的后果将是毁灭性的。

> So, as has happened before, the realtime effort is likely to result in fixes which improve things for non-realtime users as well. Some churn will be involved, but, once it is done, there should be a couple of significant benefits: the realtime kernel will be more scalable on multiprocessor systems, and the realtime patches should be that much closer to being ready for merging into the mainline.

因此，正如之前所看到的那样，在实时性工作上的努力将同样有助于改进非实时内核的性能。这会涉及一些比较大的改动，但是，一旦完成，会给内核带来一些显著的好处：实时内核在多处理器系统上的扩展性将大大增强，同时对于实时补丁来说，其距离被合并到主线中的目标将会更近一步。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/452266/
[2]: https://lwn.net/Articles/22911/
[3]: https://www.quora.com/What-is-cache-line-bouncing-How-may-a-spinlock-trigger-this-frequently
