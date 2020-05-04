---
layout: post
draft: true
top: false
author: 'Wang Chen'
title: "LWN 563185: 优化抢占"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-563185/
description: "LWN 中文翻译，优化抢占"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - scheduling
  - preemption
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Optimizing preemption](https://lwn.net/Articles/563185/)
> 原创：By Jonathan Corbet @ Aug. 14, 2013
> 翻译：By [unicornx](https://gitee.com/unicornx)
> 校对：By [Xiaojie Yuan](https://gitee.com/llseek)

> The kernel's lowest-level primitives can be called thousands of times (or more) every second, so, as one might expect, they have been ruthlessly optimized over the years. To do otherwise would be to sacrifice some of the system's performance needlessly. But, as it happens, hard-won performance can slip away over the years as the code is changed and gains new features. Often, such performance loss goes unnoticed until a developer decides to take a closer look at a specific kernel subsystem. That would appear to have just happened with regard to how the kernel handles preemption.

内核中最底层的基础函数每秒钟会被调用数千次（乃至更多），因此，正如人们希望的那样，为了避免对系统的性能造成无谓的影响，多年来，它们已被尽可能地优化。但随着时间的推移和新功能的添加，代码会不停地被更改，来之不易的性能优化可能会在多年后突然就消失不见。通常，只有当开发人员开始仔细研究某个特定的内核子系统时，这种性能上的损失才会被注意到。最近，在关于内核如何处理抢占（preemption）的问题上也发生了类似的故事。

## 用户空间访问和自愿抢占（User-space access and voluntary preemption）

> In this case, things got started when Andi Kleen decided to make the user-space data access routines — `copy_from_user()` and friends — go a little faster. As he explained in [the resulting patch set](https://lwn.net/Articles/562936/), those functions were once precisely tuned for performance on x86 systems. But then they were augmented with calls to functions like `might_sleep()` and `might_fault()`. These functions initially served in a debugging role; they scream loudly if they are called in a situation where sleeping or page faults are not welcome. Since these checks are for debugging, they can be turned off in a production kernel, so the addition of these calls should not affect performance in situations where performance really matters.

故事源自 Andi Kleen 决定对一些会访问用户空间数据的函数（譬如 `copy_from_user()` 等）进行优化。正如他在 [最终提交的补丁集][1] 中所解释的那样，这些函数曾经针对 x86 系统已经做了很好的性能优化。但随后，有人在这些函数中增加了对 `might_sleep()` 和 `might_fault()` 函数的调用。这些函数最初只是用于调试目的；在某些不希望睡眠或发生缺页异常的环境中会输出内核告警信息（译者注，具体参考 内核 3.12 版本中 [`might_sleep()`][13] 函数会在 `CONFIG_DEBUG_ATOMIC_SLEEP` 开关打开的情况下调用 [`__might_sleep()`][14] 并在其中触发很多调试打印）。但由于这些检查只是为了调试，正式的生产环境内核版本中会关闭这些逻辑，因此，增加这些代码对一些性能非常敏感的运行场景并不会有什么影响。

> But, then, in 2004, core kernel developers started to take latency issues a bit more seriously, and that led to an interest in preempting execution of kernel code if a higher-priority process needed the CPU. The problem was that, at that time, it was not exactly clear when it would be safe to preempt a thread in kernel space. But, as Ingo Molnar and Arjan van de Ven noticed, calls to `might_sleep()` were, by definition, placed in locations where the code was prepared to sleep. So a `might_sleep()` call had to be a safe place to preempt a thread running in kernel mode. The result was the [voluntary preemption patch set](https://lwn.net/Articles/93604/), adding a limited preemption mode that is still in use today.

然而在 2004 年的时候，内核的一些核心开发人员开始更加认真地研究如何解决延迟问题，并试图实现当有更高优先级的进程需要处理器时，我们可以在内核态执行抢占。当时的问题在于，尚不清楚在代码中哪些地方可以安全地抢占内核态的线程。但是，正如 Ingo Molnar 和 Arjan van de Ven 所注意到的那样，根据原先的设计，原先所有调用 `might_sleep()` 的地方意味着内核将在此准备休眠。因此，所有调用 `might_sleep()` 的地方必然也是可以安全地抢占内核态任务的位置。这导致了最终的 [“自愿抢占（voluntary preemption）” 补丁集][2]（译者注，该补丁随 2.6.13 版本合入内核主线，下文直接使用英文，不再翻译），为内核添加了一种有限的抢占模式，并沿用至今。

> The problem, as Andi saw it, is that this change turned `might_sleep()` and `might_fault()` into a part of the scheduler; it is no longer compiled out of a kernel if voluntary preemption is enabled. That, in turn, has slowed down user-space access functions by (on his system) about 2.5µs for each call. His patch set does a few things to try to make the situation better. Some functions (`should_resched()`, which is called from `might_sleep()`, for example) are marked `__always_inline` to remove the function calling overhead. A new `might_fault_debug_only()` function goes back to the original intent of `might_fault()`; it disappears entirely when it is not needed. And so on.

这个新特性带来了一个问题，正如 Andi 所指出的那样，该补丁的引入使得 `might_sleep()` 和 `might_fault()` 这类函数成为了内核调度程序的一部分；一旦启用了 “voluntary preemption”，则这些函数将不会被条件编译所关闭。这会导致那些访问用户空间的函数（据 Andi 在他的系统上观察）每次被调用时性能损失了约 2.5µs。他的补丁集所做的事情，就是试图改进这个问题。某些函数（例如， `might_sleep()` 所调用的 `should_resched()` 被声明为 `__always_inline` 以免除函数调用的开销；同时增加一个新的函数 `might_fault_debug_only()` 代替了原有 `might_fault()` 的功能（只有在调试版本中才会定义该函数），以及其他修改。

> Linus had no real objection to these patches, but they clearly raised a couple of questions in his mind. One of his first comments was [a suggestion](https://lwn.net/Articles/563187/) that, rather than optimizing the `might_fault()` call in functions like `copy_from_user()`, it would be better to omit the check altogether. Voluntary preemption points are normally used to switch between kernel threads when an expensive operation is being performed. If a user-space access succeeds without faulting, it is not expensive at all; it is really just another memory fetch. If, instead, it causes a page fault, there will already be opportunities for preemption. So, Linus reasoned, there is little point in slowing down user-space accesses with additional preemption checks.

Linus 并没有对这些补丁提出什么真正的反对意见，但是很明显他想到了其他几个问题。其中之一是一个 [建议][3]，（Linus 认为）与其对 `copy_from_user()` 之类的函数中的 `might_fault()` 函数调用进行优化，不如完全取消该检查。我们在代码中添加这些 “自愿” 抢占点的目的通常是为了允许那些比较繁忙的内核线程可以有机会被切换出去。如果对用户空间的访问执行成功且没有发生缺页异常，那就不会产生什么额外的开销；这实际上只是相当于一次内存访问。相反，如果的确导致了缺页异常，则内核自然就有了抢占的机会。因此，Linus 有理由认为，这些额外的抢占检查只会减慢对用户空间的访问，是毫无意义的。

## “完全抢占” 的问题（The problem with full preemption）

> To this point, the discussion was mostly concerned about voluntary preemption, where a thread running in the kernel can lose access to the processor, but only at specific spots. But the kernel also supports "full preemption," which allows preemption almost anywhere that preemption has not been explicitly disabled. In the early days of kernel preemption, many users shied away from the full preemption option, fearing subtle bugs. They may have been right at the time, but, in the intervening years, the fully preemptible kernel has become much more solid. Years of experience, helped by tools like the locking validator, can work wonders that way. So there is little reason to be afraid to enable full preemption at this point.

到目前为止，讨论主要集中在 “voluntary preemption”，即内核态运行的线程可能会被切换出去，但抢占只能发生在某些特定的位置（译者注，即前文所介绍的调用了 `might_sleep()` 的地方）。但内核还支持 “完全抢占（full preemption）”（译者注，即 `CONFIG_PREEMPT` ，下文直接用英文，不再翻译），它允许在几乎所有没有明确禁用抢占的地方实现抢占。在内核刚开始支持 “full preemption” 的时候，许多用户因为担心可能存在潜在的问题而不敢尝试 “full preemption” 选项。在那个时候他们的想法可能是正确的，但经过这么多年进化，特别是在诸如 “locking validator” 之类工具的帮助下，这个功能已经相当成熟可靠。因此，现在启用 “full preemption” 绝对是没有任何问题的。

> With that history presumably in mind, H. Peter Anvin entered the conversation with [a question](https://lwn.net/Articles/563188/): should voluntary preemption be phased out entirely in favor of full kernel preemption? It turns out that there is still one reason to avoid turning on full preemption: as Mike Galbraith [put it](https://lwn.net/Articles/563189/), "PREEMPT munches throughput." Complaints about the cost of full preemption have been scarce over the years, but, evidently, it does hurt in some cases. As long as there is a performance penalty to the use of full preemption, it is going to be hard to convince throughput-oriented users to switch to it.

考虑到这段历史，H. Peter Anvin 也加入讨论并提出了一个 [问题][4]：既然已经有了 “full preemption”，我们是否可以逐步淘汰 “voluntary preemption” 了呢？答案显然是否定的，因为至少还存在一种场景下我们会避免开启 “full preemption” 选项：正如 Mike Galbraith  [所说的那样][5]，“抢占会影响系统的吞吐率（throughput）。” 多年来，对 “full preemption” 的抱怨并不多，但显然该模式在某些情况下确实对系统有影响。只要启用 “full preemption” 必然会导致性能降低，因此就很难说服对系统吞吐率敏感的用户使用它。

> There would not seem to be any fundamental reason why full preemption should adversely affect throughput. If the rate of preemption were high, there could be some associated cache effects, but preemption should be a relatively rare event in a throughput-sensitive system. That suggests that something else is going on. A clue about that "something else" can be found in Linus's [observation](https://lwn.net/Articles/563190/) that the testing of the preemption count — which happens far more often in a fully preemptible kernel — is causing the compiler to generate slower code.

之所以说开启 “full preemption” 会对吞吐率产生不利影响并没有什么深奥的原因。道理很简单，如果抢占频繁发生，会导致相关的缓存失效，但问题是在一个对吞吐率敏感的系统上，抢占发生的频率并不高，因此一定还有 “其他原因”。在 Linus 提供的 [观察][6] 中可以找到关于 “其他原因” 的线索：启用了 “full preemption” 后，条件编译会产生一些代码逻辑对 “抢占计数（preemption count）” 进行检查，这些代码会被频繁调用，极大影响内核的整体效率。（下面是 Linus 在邮件中的原话）

> `The thing is, even if that is almost never taken, just the fact that there is a conditional function call very often makes code generation *much* worse. A function that is a leaf function with no stack frame with no preemption often turns into a non-leaf function with stack frames when you enable preemption, just because it had a RCU read region which disabled preemption.`

`事实是，即使抢占没有发生，仅仅是由于执行条件判断的函数被调用得非常频繁，最终也会使得执行的效果变得 “非常糟糕”。原本作为一个 “leaf function”，即函数调用链中最后一个被调用的函数，是不会涉及栈操作的，但是当启用抢占后，条件编译使该函数（调用了其他函数）也会执行压栈出栈操作，而且仅仅是由于该函数涉及 RCU 读取操作并会禁用抢占。`（译者注，Linus 提到的函数请参考当时 3.12 内核版本中 [`__might_sleep()`][14] 函数的实现，注意 Linus 当时是在针对 Andi 的补丁所发表的评论，所以是针对 “voluntary preemption” 的讨论，但正如本文作者所说的，Linus 这里对 preemption count 的观察直接导致了下文中针对 “full preemption” 的进一步优化。）

> So configuring full preemption into the kernel can make performance-sensitive code slower. Users who are concerned about latency may well be willing to make that tradeoff, but those who want throughput will not be so agreeable. The good news is that it might be possible to do something about this problem and keep both camps happy.

因此，打开 “full preemption” 配置选项会使系统变慢。关注延迟的用户可能会乐意接受这个损失，但是这对那些对吞吐率敏感的用户则是无法接受的。好消息是，我们有办法解决这个问题，使得两方用户都感到满意。

## 针对 “full preemption” 的优化（Optimizing full preemption）

> The root of the problem is accesses to the variable known as the "preemption count," which can be found in the `thread_info` structure, which, in turn lives at the bottom of the kernel stack. It is not just a counter, though; instead it is a 32-bit quantity that has been divided up into several subfields:

问题的根源来自对所谓 “抢占计数（preemption count）” 变量的访问，这个变量定义在 [`thread_info`][8] 结构体中，该结构位于内核堆栈的底部。但是，它不是一个简单的计数器，作为一个 32 位的数，它被分成以下几个子域：

> - The actual preemption count, indicating how many times kernel code has disabled preemption. This counter allows calls like `preempt_disable()` to be nested and still do the right thing (eight bits).
> - The software interrupt count, indicating how many nested software interrupts are being handled at the moment (eight bits).
> - The hardware interrupt count (ten bits on most architectures).
> - The `PREEMPT_ACTIVE` bit indicating that the current thread is being (or just has been) preempted.

- 实际的抢占计数（preemption count，占 8 个比特位），指示内核代码已禁用抢占的次数。该计数器允许 `preempt_disable()` 这样的函数被嵌套调用而不会出问题。
- 软中断计数（software interrupt count，占 8 个比特位），指示当前正在处理多少个嵌套的软中断（8位）。
- 硬中断计数（hardware interrupt count，在大多数体系架构上占 10 个比特位）
- `PREEMPT_ACTIVE` 标志位，表示该线程正在（或者已经）被抢占。

> This may seem like a complicated combination of fields, but it has one useful feature: the preemptability of the currently-running thread can be tested by comparing the entire preemption count against zero. If any of the counters has been incremented (or the `PREEMPT_ACTIVE` bit set), preemption will be disabled.

这些字段的组合看上去有点复杂，但它具有一个有用的功能：我们可以通过将整个抢占计数变量与零进行比较来检查当前正在运行的线程是否可以被抢占。只要以上任何一个计数值非零（或设置了 `PREEMPT_ACTIVE` 位），内核抢占都会被禁用掉（译者注，准确地说应该是 “针对该线程的” 抢占会被禁止掉，这是当时内核的设计，也就是说当时的内核认为是否可以被抢占是线程的特性，是针对单个线程的，但从下文的介绍我们可以发现，很快这个观点会发生改变）。

> It seems that the cost of testing this count might be reduced significantly with some tricky assembly language work; that is being hashed out as of this writing. But there's another aspect of the preemption count that turns out to be costly: its placement in the `thread_info` structure. The location of that structure must be derived from the kernel stack pointer, making the whole test significantly more expensive.

看起来可以使用一些汇编技巧降低对这个计数值的测试开销。但截至撰写本文时，相关的优化已经做到极致。然而，对抢占计数的操作还存在另一个可以优化的地方：注意该变量被放置在 `thread_info` 结构中。对该结构的地址进行访问必须根据内核堆栈指针计算出来，这会使整个测试操作变得更加费时。

> The important realization here is that there is (almost) nothing about the preemption count that is specific to any given thread. It will be zero for every non-executing thread; and no executing thread will be preempted if the count is nonzero. It is, in truth, more of an attribute of the CPU than of the running process. And that suggests that it would be naturally stored as a per-CPU variable. Peter Zijlstra has posted [a patch](https://lwn.net/Articles/563088/) that changes things in just that way. The patch turned out to be relatively straightforward; the only twist is that the `PREEMPT_ACTIVE` flag, being a true per-thread attribute, must be saved in the `thread_info` structure when preemption occurs.

一个重要的发现是：这些抢占计数（preemption count）几乎都是与特定线程无关的。对于非运行状态的线程，这些计数器值都为 0，而当计数器值非零时也根本不会发生内核抢占。所以，与其说它是任务的一种属性，还不如说是 CPU 的一种属性。这意味着更好的做法是将这些计数值定义为 per-CPU 变量。基于这个思路，Peter Zijlstra 提交了一个 [补丁][9]。补丁的修改如上所述，但对 `PREEMPT_ACTIVE` 标志的处理是个例外，这个标志的语义是单个线程级别的，所以还是需要保存在 `thread_info` 这个结构体中。

> Peter's first patch didn't quite solve the entire problem, though: there is still the matter of the `TIF_NEED_RESCHED` flag that is set in the `thread_info` structure when kernel code (possibly running in an interrupt handler or on another CPU) determines that the currently-running task should be preempted. That flag must be tested whenever the preemption count returns to zero, and in a number of other situations as well; as long as that test must be done, there will still be a cost to enabling full preemption.

然而 Peter 补丁的第一版并没有完美地解决整个问题：为了方便内核在中断上下文中或者在另一个处理器上检查一个正在运行的任务是否可以被抢占，`TIF_NEED_RESCHED` 这个标志位仍然保存在 `thread_info` 结构中。每当抢占计数恢复为零时，以及在许多其他情况下，都必须测试该标志；只要必须执行该测试，“full preemption” 模式下的额外运行开销就仍然存在。

> Naturally enough, Linus has [a solution to this problem](https://lwn.net/Articles/563195/) in mind as well. The "need rescheduling" flag would move to the per-CPU preemption count as well, probably in the uppermost bit. That raises an interesting problem, though. The preemption count, as a per-CPU variable, can be manipulated without locks or the use of expensive atomic operations. This new flag, though, could well be set by another CPU entirely; putting it into the preemption count would thus wreck that count's per-CPU nature. But Linus has a scheme for dancing around this problem. The "need rescheduling" flag would only be changed using atomic operations, but the remainder of the preemption count would be updated locklessly as before.

看起来，Linus 已经考虑到了 [这个问题的解决方案][10]。`TIF_NEED_RESCHED` 这个标志也可以移到 per-CPU 的抢占计数中去，或许可以放在最高位。但是，这里存在一个有趣的问题。作为 per-CPU 变量的抢占计数可以在无锁情况下执行操作，也无需使用昂贵的原子操作。但是，这个新增加的标志位完全也可能会被另一个 CPU （上的内核代码）所设置；因此，将这个标志位放入抢占计数将破坏抢占计数值的 per-CPU 性质。好在 Linus 提供了一个解决方案。我们只需要遵守这样一个原则，即只使用原子操作对 `TIF_NEED_RESCHED` 这个标志位进行修改，而对抢占计数的其余部分仍然可以像以前一样在无锁状态下进行更新。

> Mixing atomic and non-atomic operations is normally a way to generate headaches for everybody involved. In this case, though, things might just work out. The use of atomic operations for the "need rescheduling" bit means that any CPU can set that bit without corrupting the counters. On the other hand, when a CPU changes its preemption count, there is a small chance that it will race with another CPU that is trying to set the "need rescheduling" flag, causing that flag to be lost. That, in turn, means that the currently executing thread will not be preempted when it should be. That result is unfortunate, in that it will increase latency for the higher-priority task that is trying to run, but it will not generate incorrect results. It is a minor bit of sloppiness that the kernel can get away with if the performance benefits are large enough.

混合使用原子操作和非原子操作通常不是个好方法。但是，在这种情况下却没有问题。对  `TIF_NEED_RESCHED` 标志位使用原子操作意味着任何 CPU 都可以安全地设置该位而不会破坏计数器。反之，当一个 CPU 更改其自身的抢占计数时，它却极有可能与另一个试图设置 `TIF_NEED_RESCHED` 标志位的 CPU 产生冲突，并导致该标志位丢失。这意味着当前正在该 CPU 上执行的、本应被抢占的线程不会被抢占。这么做的结果充其量只能被称之为是一种 “不幸（unfortunate）”，因为这只会延迟系统对高优先级任务的响应，但不会产生错误的结果。如果性能上的收益足够大那么这么做也是可以接受的。

> In this case, though, there appears to be a better solution to the problem. Peter came back with [an alternative approach](https://lwn.net/Articles/563259/) that keeps the `TIF_NEED_RESCHED` flag in the `thread_info` structure, but also adds a copy of that flag in the preemption count. In current kernels, when the kernel sets `TIF_NEED_RESCHED`, it also signals an inter-processor interrupt (IPI) to inform the relevant CPU that preemption is required. Peter's patch makes the IPI handler copy the flag from the `thread_info` structure to the per-CPU preemption count; since that copy is done by the processor that owns the count variable, the per-CPU nature of that count is preserved and the race conditions go away. As of this writing, that approach seems like the best of all worlds — fast testing of the "need rescheduling" flag without race conditions.

针对这个问题，似乎应该可以有更好的解决方法。Peter 给出了 [另一种方案][11]，他的方法是将 `TIF_NEED_RESCHED` 标志保留在 `thread_info` 结构中，但在抢占计数中添加了该标志位的副本。在当前版本中，每当内核设置 `TIF_NEED_RESCHED` 时，它还会触发 “处理器间中断（Inter-Processor Interrupt，简称 IPI）”，用以通知相关 CPU 需要执行抢占。Peter 的补丁在 IPI 的中断服务处理函数中将 `thread_info` 的 `TIF_NEED_RESCHED` 标志复制到 per-CPU 的抢占计数变量中；由于该复制操作是由该抢占计数所对应的 CPU 自己完成的，因此确保了该变量的 per-CPU 性质，并且避免了竞争。目前看来，该方法似乎是能想到的最好的方法了，可以做到无竞争状态下对 `TIF_NEED_RESCHED` 标志位进行快速的测试。

> Needless to say, this kind of low-level tweaking needs to be done carefully and well benchmarked. It could be that, once all the details are taken care of, the performance gained does not justify the trickiness and complexity of the changes. So this work is almost certainly not 3.12 material. But, if it works out, it may be that much of the throughput cost associated with enabling full preemption will go away, with the eventual result that the voluntary preemption mode could be phased out.

毋庸置疑，对这种底层的代码调整需要非常小心并进行充分的基准测试。当然也存在一种可能性，就是处理完所有细节后，所获得的性能提升与修改的复杂性以及我们所付出的辛勤工作相比并不匹配。但无论如何，几乎可以肯定的是，这项工作还不会随 3.12 版本合入内核主线（译者注，Peter 的补丁最终合入 3.13 版本，具体的提交参考 [这里][12]）。但是，如果这个补丁能够工作的话，启用 “full preemption” 后给系统吞吐量带来的影响可能会消失，这样或许我们就再也用不着 “voluntary preemption” 模式了。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://lwn.net/Articles/562936/
[2]: https://lwn.net/Articles/93604/
[3]: https://lwn.net/Articles/563187/
[4]: https://lwn.net/Articles/563188/
[5]: https://lwn.net/Articles/563189/
[6]: https://lwn.net/Articles/563190/
[7]: https://elixir.bootlin.com/linux/v3.12/source/include/linux/kernel.h#L146
[8]: https://elixir.bootlin.com/linux/v3.12/source/arch/x86/include/asm/thread_info.h#L25
[9]: https://lwn.net/Articles/563088/
[10]: https://lwn.net/Articles/563195/
[11]: https://lwn.net/Articles/563259/
[12]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=c2daa3bed53a81171cf8c1a36db798e82b91afe8
[13]: https://elixir.bootlin.com/linux/v3.12/source/include/linux/kernel.h#L163
[14]: https://elixir.bootlin.com/linux/v3.12/source/kernel/sched/core.c#L6574

