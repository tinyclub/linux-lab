---
layout: post
author: 'Wang Chen'
title: "LWN 574962: 时钟广播框架（The tick broadcast framework）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-574962/
description: "LWN 文章翻译，时钟广播框架"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[The tick broadcast framework](https://lwn.net/Articles/574962/)
> 原创：By Preeti U Murthy @ Nov. 26, 2013
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> Power management is an increasingly important responsibility of almost every subsystem in the Linux kernel. One of the most established power management mechanisms in the kernel is the [cpuidle framework](https://lwn.net/Articles/384146/) which puts idle CPUs into sleeping states until they have work to do. These sleeping states are called the "C-states" or CPU operating states. The deeper a C-state, the more power is conserved.

对于 Linux 内核中的每个子系统来说，电源管理工作变得越来越重要。内核中最为成熟的电源管理机制之一是 [cpuidle 框架](https://lwn.net/Articles/384146/)，它会将空闲的处理器置于休眠状态，直到它们有新的工作要做。这些睡眠状态被称为 “C 状态”（C-states）或处理器操作状态（译者注：下文直接译为 C-state）。C-state 睡眠的程度越深，节能的效果越好。

> However, an interesting problem surfaces when CPUs enter certain deep C-states. Idle CPUs are typically woken up by their respective local timers when there is work to be done, but what happens if these CPUs enter deep C-states in which these timers stop working? Who will wake up the CPUs in time to handle the work scheduled on them? This is where the "tick broadcast framework" steps in. It assigns a clock device that is not affected by the C-states of the CPUs as the timer responsible for handling the wakeup of all those CPUs that enter deep C-states.

但是，当处理器进入某些深度 C-state 时，会出现一个有趣的问题。一般情况下为执行新的任务，睡眠态的处理器通常由各自的本地定时器（local timer，译者注：本文这里特指 Advanced Programmable Interrupt Controller （简称 APIC）的 local timer ）负责唤醒，可是一旦处理器进入深度 C-state 后这些定时器也会停止工作，那么谁来及时唤醒处理器呢？这就是 “时钟广播框架” （“tick broadcast framework”，译者注：下文直接译为 tick broadcast framework）所要解决的问题。它通过指定一个不受 C-state 影响的时钟设备来负责唤醒所有进入深度 C-state 的处理器。

# 时钟广播框架（tick broadcast framework）概述（Overview of the tick broadcast framework）

> In the case of an idle or a semi-idle system, there could be more than one CPU entering a deep idle state where the local timer stops. These CPUs may have different wakeup times. How is it possible to keep track of when to wake up the CPUs, considering a timer is merely a clock device that cannot keep track of more information than the time at which it is supposed to interrupt? The tick broadcast framework in the kernel provides the necessary infrastructure to handle the wakeup of such CPUs at the right time.

在一个系统处在空闲或半空闲的情况下，可能会有不止一个处理器进入深度睡眠状态以致其本地定时器也不再工作。这些处理器的唤醒时间可能并不相同。考虑到硬件定时器仅仅是一个时钟设备，除了在设定的时间触发中断外并不能跟踪更多的信息，那么如何利用它来唤醒这些处理器呢？内核中的 tick broadcast framework 提供了必要的措施，以便在正确的时间唤醒这些处理器。

> Before looking into the tick broadcast framework, it is important to understand how the CPUs themselves keep track locally of when their respective pending events need to be run.

在深入研究 tick broadcast framework 之前，有必要先了解一下处理器本身是如何跟踪事件的到期时间的。

> The kernel keeps track of the time at which a deferred task needs to be run based on the concept of timeouts. The timeouts are implemented using clock devices called timers which have the capacity to raise an interrupt at a specified time. In the kernel, such devices are called the "clock event" devices. Each CPU is equipped with a local clock event device that is programmed to interrupt at the time of the next-to-run deferred task on that CPU, so that said task can be scheduled on the CPU. These local clock event devices can also be programmed to fire periodically to do regular housekeeping jobs like updating the jiffies value, checking if a task has to be scheduled out, etc. These timers are therefore called the "tick devices" in the kernel and are represented by `struct tick_device`.

内核基于超时（timeouts）的概念来跟踪需要推迟执行的任务的时间。在硬件上，超时是利用一种特殊的时钟设备（也叫定时器（timers））实现的，定时器能够在指定的时间触发中断。在内核中，这样的设备被称为“时钟事件”（"clock event"）设备。每个处理器上有一个本地的时钟事件设备，如果我们有一个任务需要在以后的某个时刻运行，我们可以通过编程把这个期望时间设置给该设备，它就会在期望的时间点触发中断从而通知内核在处理器上调度执行该任务。这些本地时钟事件设备也可以被设定为定期触发中断以便运行周期性的事务，譬如更新 jiffies 值，检查是否可以执行任务调度等。因此这些定时器被称为 "tick devices"（译者注：从习惯和方便出发，下文 "tick devices" 不再翻译），在内核中对应的结构体类型是 `struct tick_device`。

> A per-CPU `tick_device` representing the local timer is declared using the variable `tick_cpu_device`. Every CPU keeps track of when its local timer needs to interrupt it next in its copy of `tick_cpu_device` as `next_event` and programs the local timer with this value. To be more precise, the value can be found in `tick_cpu_device->evtdev->next_event`, where `evtdev` is an instance of the clock event device mentioned above.

对应每个处理器（per-CPU）的本地定时器（local timer）对象，内核定义了一个 `tick_device` 类型的变量 `tick_cpu_device`。内核为每个处理器的本地定时器维护下一次触发中断的时间。具体地，这个时间值保存在 `tick_cpu_device->evtdev->next_event`，其中 `evtdev` 是 "tick devices" 所对应的时钟事件设备的一个实例。

> The external clock device that is required to stand in for the local timers in some deep idle states is just another tick device, but is not normally required to keep track of events for specific CPUs. This device is represented by `tick_broadcast_device` (defined in `kernel/time/tick-broadcast.c`), in contrast to `tick_cpu_device`.

当处理器进入某些深度睡眠状态后，会需要一个外部时钟事件设备（译者注：相对于处理器内部的本地定时器）来代替本地定时器运行，它也是一种 "tick devices"，但通常不利用它跟踪特定处理器的事件。内核中将该设备定义为 `tick_broadcast_device`（参考 `kernel/time/tick-broadcast.c` 中的定义）。 

# 为 `tick_broadcast_device` 注册一个定时器（Registering a timer as the `tick_broadcast_device`）

> During the initialization of the kernel, every timer in the system registers itself as a `tick_device`. In the kernel, these timers are associated with some flags which define their properties. That property which is of special interest to us is represented by the flag `CLOCK_EVT_FEAT_C3STOP`. This means that in the C3 idle state, the timer stops. Although the C3 idle state is specific to the x86 architecture, this feature flag is generally used to convey that the timer stops in one of the deep idle states.

在内核初始化期间，系统中的每个定时器设备都将自己注册为一个 `tick_device` 类型的实例。而且每个定时器都具有一些属性，通过相应的标志位来定义。我们特别感兴趣的一个属性对应 `CLOCK_EVT_FEAT_C3STOP` 标志位。拥有此属性的定时器在处理器进入 C3 级别的睡眠态后会停止工作。要注意的是 C3 态是一个特定于 x86 架构的概念，内核只是借用这个术语表示定时器在某种深度睡眠状态下会停止工作。

> Any timers which do not have the flag `CLOCK_EVT_FEAT_C3STOP` set are potential candidates for `tick_broadcast_device`. Since all local timers have this flag set on architectures where they stop in deep idle states, all of them become ineligible for this role. On architectures like x86, there is an external device called the HPET — High Precision Event Timer — which becomes a suitable candidate. Since the HPET is placed external to the processor, the idle power management for a CPU does not affect it. Naturally it does not have the `CLOCK_EVT_FEAT_C3STOP` flag set among its properties and becomes the choice for `tick_broadcast_device`.

任何没有设置 `CLOCK_EVT_FEAT_C3STOP` 属性标志的定时器都是 `tick_broadcast_device` 的潜在候选者。如果在某种体系架构上，一旦处理器进入深度睡眠后其本地定时器会停止工作，则该定时器需要在属性上设置该标志位，从而避免被内核选为 `tick_broadcast_device`。对于 x86 架构，在处理器外部存在一种设备，叫做“高精度事件定时器”（High Precision Event Timer，简称 HPET），它就很适合作为 `tick_broadcast_device`。原因是 HPET 放置在处理器的外部，管理处理器睡眠的电源模块影响不了它。自然，它的属性中不会设置 `CLOCK_EVT_FEAT_C3STOP` 标志位，可以被选择作为 `tick_broadcast_device`。

# 跟踪处于深度睡眠态的处理器（Tracking the CPUs in deep idle states）

> Now we'll return to the way the tick broadcast framework keeps track of when to wake up the CPUs that enter idle states when their local timers stop. Just before a CPU enters such an idle state, it calls into the tick broadcast framework. This CPU is then added to a list of CPUs to be woken up; specifically, a bit is set for this CPU in a "broadcast mask".

现在我们回到 tick broadcast framework，来看看对于进入睡眠态的处理器，当它的本地定时器不再工作后，我们该如何跟踪并唤醒它们。处理器在进入深度睡眠之前，它会调用框架提供的接口，将该处理器添加到需要唤醒的处理器列表中; 具体来说，该列表的实现方式是一个 “广播掩码”（“broadcast mask”），每一个处理器占据该掩码的一个位（译者注：所谓的添加到列表中就是对掩码中对应的位置 `1`）。

> Then a check is made to see if the time at which this CPU has to be woken up is prior to the time at which the `tick_broadcast_device` has been currently programmed. If so, the time at which the `tick_broadcast_device` should interrupt is updated to reflect the new value and this value is programmed into the external timer. The `tick_cpu_device` of the CPU that is going to deep idle state is now put in `CLOCK_EVT_MODE_SHUTDOWN` mode, meaning that it is no longer functional.

然后内核会进行检查，看看这个处理器需要被唤醒的时间是否在 `tick_broadcast_device` 当前设置的下一次事件时间之前。如果是这样，`tick_broadcast_device` 会更新自身的下一次触发中断的时间以反映该新值，并对硬件上对应的外部定时器进行设置。最后在处理器进入深度睡眠之前将其自身的 `tick_cpu_device` 设置为 `CLOCK_EVT_MODE_SHUTDOWN` 模式，表示该处理器的本地定时器已停止工作。

> Each time a CPU goes to deep idle state, the above steps are repeated and the `tick_broadcast_device` is programmed to fire at the earliest of the wakeup times of the CPUs in deep idle states.

每当有一个处理器要进入深度睡眠时，都会重复上述步骤，并确保 `tick_broadcast_device` 所维护的下一次中断触发时间一定是所有需要被唤醒的处理器中最早的那一个。

# 唤醒处于深度睡眠的处理器（Waking up the CPUs in deep idle states）

> When the external timer expires, it interrupts one of the online CPUs, which scans the list of CPUs that have asked to be woken up to check if any of their wakeup times have been reached. That means the current time is compared to the `tick_cpu_device->evtdev->next_event` of each CPU. All those CPUs for which this is true are added to a temporary mask (different from the broadcast mask) and the appropriate next expiry time of the `tick_broadcast_device` is set to the earliest wakeup time of those CPUs. What remains to be seen is how the CPUs in the temporary mask are woken up.

当外部定时器到期时会选择一个没有睡眠的处理器并向其发送中断，触发该处理器扫描等待唤醒的处理器列表（译者注，即前文提到的 “广播掩码”），以检查是否存在到期的情况。这意味着我们需要将当前时间与列表中的每个处理器的 `tick_cpu_device->evtdev->next_event` 进行比较。所有满足条件的处理器被添加到另一个 “临时掩码” 中（与前面介绍过的 “广播掩码” 不是同一个），并且内核会重新设置 `tick_broadcast_device` 的下一个到期时间，确保该值是其余没有到期的处理器中的最早唤醒时间。接下来我们来看看 “临时掩码” 中的处理器是如何被唤醒的。

> Every tick device has a "broadcast method" associated with it. This method is an architecture-specific function encapsulating the way inter-processor interrupts (IPIs) are sent to a group of CPUs. Similarly, each local timer is also associated with this method. The broadcast method of the local timer of one of the CPUs in the temporary mask is invoked by passing it the same mask. IPIs are then sent to all the CPUs that are present in this mask. Since wakeup interrupts are sent to a group of CPUs, this framework is called the "broadcast" framework. The broadcast is done in `tick_do_broadcast()` in `kernel/time/tick-broadcast.c`.

每个 tick device 都需要实现一个 broadcast 的回调函数接口。该接口的实现是体系架构相关的，它封装了向一组处理器发送“核间中断”（inter-processor interrupts，简称 IPI）的逻辑。换句话说，每个本地定时器都具备该回调函数（译者注：回忆一下，上文说过每个定时器对象都注册为一个 `tick_device`）。内核会从 “临时掩码” 中选择一个本地定时器，并调用其 `broadcast()` 方法向所有 “临时掩码” 中的处理器发送 IPI。正是基于这种将唤醒中断发送到一组处理器的行为，这个框架被称为 “广播” 框架。具体的实现请参考 `kernel/time/tick-broadcast.c` 中的 `tick_do_broadcast()` 函数。

> The IPI handler for this specific interrupt needs to be that of the local timer interrupt itself so that the CPUs in deep idle states wake up as if they were interrupted by the local timers themselves. The effects of their local timers stopping on entering an idle state is hidden away from them; they should see the same state before and after wakeup and continue running like nothing had happened.

响应 IPI 的中断处理程序和响应本地定时器中断的处理程序是同一个函数，这么做的好处在于，从处于深度睡眠的处理器的角度来看，唤醒它的中断就好像依然是来自其自身的本地定时器，换句话说，它根本就不会察觉到本地定时器曾经停止过；由于它们睡眠之前和唤醒之后看到的状态是相同的，就好像什么事情也没有发生过一样。

> While handling the IPI, the CPUs call into the tick broadcast framework so that they can be removed from the broadcast mask, since it is known that they have received the IPI and have woken up. Their respective tick devices are brought out of the `CLOCK_EVT_MODE_SHUTDOWN` mode, indicating that they are back to being functional.

在处理 IPI 的过程中，处理器将调用 tick broad framework 提供的函数，在函数处理中会将它们从 “广播掩码” 中移除，因为此时已经可以确认它们已收到 IPI 并已被唤醒。然后，它们各自对应的 tick 设备也会退出 `CLOCK_EVT_MODE_SHUTDOWN` 模式，从此恢复正常运行。

# 结论（Conclusion）

> As can be seen from the above discussion, enabling deep idle states cause the kernel to have to do additional work. One would therefore naturally wonder if it is worth going through this trouble, since it could hamper performance in the process of saving power.

从上面的讨论可以看出，一旦启用深度睡眠，会导致内核执行额外的工作。很自然地，人们会怀疑是否值得启用该功能，因为它虽然改善了节能效果，但影响了运行效率。

> Idle CPUs enter deep C-states only if they are predicted to remain idle for a long time, on the order of milliseconds. Therefore, broadcast IPIs should be well spaced in time and are not so frequent as to affect the performance of the system. We could further optimize the tick broadcast framework by aligning the wakeup time of the idle CPUs to a periodic tick boundary whose interval is of the order of a few milliseconds so that CPUs going to idle at almost the same time choose the same wakeup time. By looking at more such ways to minimize the number of broadcast IPIs sent we could ensure that the overhead involved is insignificant compared to the large power savings that the deep idle states yield us. If this can be achieved, it is a good enough reason to enable and optimize an infrastructure for the use of deep idle states.

处理器只会在预期存在较长的空闲期（毫秒级别）的情况下才会进入深度的 C-state 睡眠。因此，广播 IPI 的时间间隔应该尽量准时，并且不要太过频繁，因为这样会影响系统的整体性能。我们可以进一步优化 tick broadcast framework ，通过将空闲处理器的唤醒时间点与周期时钟的触发时间点尽量保持一致（周期时钟的频率单位也在毫秒级别），这样可以使那些进入睡眠的时间比较靠近的处理器在相同的时间点上被唤醒（译者注，即降低了唤醒广播的频率）。通过以上类似的措施，最大限度地减少广播 IPI 的发生，我们可以确保所涉及的性能开销与深度睡眠所带来的能耗节省相比起来显得微不足道。如果可以这样的话，那么为系统深度睡眠做这些优化还是值得的。

# 致谢（Acknowledgments）

> I would like to thank my technical mentor Vaidyanathan Srinivasan for having patiently reviewed the initial drafts, my manager Tarundeep Singh, and my teammates Srivatsa S. Bhat and Deepthi Dharwar for their guidance and encouragement during the drafting this article.

我要感谢我的技术导师 Vaidyanathan Srinivasan 耐心地审阅了初稿，以及我的经理 Tarundeep Singh 和我的队友 Srivatsa S. Bhat 和 Deepthi Dharwar 在起草本文期间的指导和鼓励。

> Many thanks to IBM Linux Technology Center and LWN for having provided this opportunity.

非常感谢 IBM Linux 技术中心和 LWN 为我提供的这个机会。

[1]: http://tinylab.org
