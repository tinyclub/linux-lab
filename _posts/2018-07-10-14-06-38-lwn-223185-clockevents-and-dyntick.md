---
layout: post
author: 'Wang Chen'
title: "LWN 223185: 时钟事件（Clockevents）和动态时钟（dynamic tick）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-223185/
description: "LWN 文章翻译，时钟事件（Clockevents）和动态时钟（dynamic tick）"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[Clockevents and dyntick](https://lwn.net/Articles/223185/)
> 原创：By corbet @ Feb. 21, 2007
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [guojian-at-wowo](https://github.com/guojian-at-wowo)

> One of the last patch sets to be merged before the 2.6.21 window closed was the clockevents and dyntick work from the real-time tree. These patches have been in the works for some time, and were originally targeted for merging in 2.6.19. In the process, the developers (primarily Ingo Molnar and Thomas Gleixner) discovered one of the fundamental laws of kernel development: if your patches break Andrew Morton's laptop, they are unlikely to make it into the mainline. That little difficulty has now been overcome, with the result that 2.6.21 will include some interesting core changes.

在 2.6.21 集成窗口期关闭之前还有最后一批补丁需要合入，其中有两个来自 real-time 代码库，一个是时钟事件（clockevents）补丁，还有一个是动态时钟（dynamic tick，简称 dyntick）补丁（译者注，考虑到术语和习惯，对 clockevents 和 dyntick 这两个词下文不再翻译为中文）。这两个补丁的历史由来已久，最初的合入目标是 2.6.19。在等待合入的这段日子里，补丁的开发人员（主要是 Ingo Molnar 和 Thomas Gleixner）发现了内核开发流程中一个有趣的潜规则，那就是：一旦你提交的补丁导致 Andrew Morton （译者注：当时 Linux 内核代码集成的实际掌控者）的笔记本电脑无法工作，那它（指这个补丁）想要进入内核主线可就悬了。所幸的是这两个补丁（译者注：指前文所指的 clockevents 和 dyntick 补丁）现在已经克服了这个小小的困难，它们的合入将给 2.6.21 内核带来一些有趣的变化。

> Dealing with clock devices has traditionally been handled in the kernel's architecture-specific code. The result has been a lot of duplicated code between architectures (there are more architectures than common timer devices) and no uniform interface for the core kernel to make use of these devices. John Stultz's generic time of day infrastructure resolved a number of those problems, at least for the timekeeping task, but anybody who wanted to program timer devices in a more general way still ended up dealing with architecture-specific code.

内核中有关时钟设备的操作传统上都是在特定于体系架构的代码中处理的。其结果是在不同的体系架构中存在大量重复的代码（相比于少量的通用定时器硬件，各个体系架构都有自己专用的定时器设备），并且内核中也没有统一的接口来操作这些设备。John Stultz 重写了通用的时间管理子系统（generic time of day），解决了部分问题，至少对于计时（timekeeping）相关的功能来说是这样，但是人们仍然无法使用比较通用的方法对定时器硬件设备进行操控，这部分工作仍然需要在体系架构相关的代码中实现。

> The "clockevents" patch set finishes this job. At its core, clockevents creates a driver API for devices which can deliver interrupts at a specific time in the future. The API tracks the capabilities of each timer (resolution and whether it can do one-shot or periodic interrupts, for example) and provides a simple interface for arming the timer. This API is defined in the core kernel, with only a low-level driver remaining in the architecture-specific code. The end result is that the kernel now has the means to query and use timer capabilities in an architecture-independent manner.

clockevents 补丁就是为解决这个问题而开发的。它为某类设备（特指可以支持在将来某个时刻触发中断的设备）创建了一个统一的驱动编程接口（译者注：即 `struct clock_event_device`）。该接口定义了每种定时器设备需要向内核注册的能力集合（例如计时精度，以及它是支持单次触发（one-shot）中断还是周期（periodic）触发中断）并提供了一个简单的接口用于设定下一次触发的时间（译者注，以 4.4 的版本为例，作者指的很有可能就是 `clockevents_program_event()` 这个函数）。 该编程接口（译者注，即 `struct clock_event_device`）在内核通用模块中定义，各个体系架构负责在各自驱动中按照该接口定义 clockevent 设备，并将其注册到内核中。之后，内核就能以独立于体系架构的方式对定时器设备进行查询和操作。

> With the clockevents mechanism in place, it becomes possible to support truly high-resolution timers. When such a timer is requested, all that is required is to pick a suitable clockevent device and arm it for the desired time. These devices can deliver interrupts with a high degree of precision, with the result that kernel timers, too, can offer high precision - a feature which is of clear utility to real-time users (among others).

随着 clockevents 机制的到位，就有可能实现真正意义上的高精度定时器。当需要一个高精度的定时器时，内核所要做的只是选择一个合适的 clockevent 设备并设置期望到期的时间。只要硬件上可以高精度地触发中断，那么内核定时器（译者注：即内核内部实现的软件定时器）也就可以保证相应的高精度，这对于有实时性需求的应用来说绝对是一大利好。

> The periodic timer tick is now implemented with a clockevent as well. It does all of the things the old timer-based interrupt did - updating jiffies, accounting CPU time, etc. - but it is run out of the new infrastructure.

周期性时钟处理（译者注：即内核按照配置的 HZ 为周期重复执行的事务处理，下文简称 tick）现在也基于 clockevent 实现。 它所完成的功能和基于旧的定时器中断处理中所做的事情一样，包括更新 jiffies，计算 CPU 处理时间等等，但它将完全基于新的框架来实现。

> All of this is an improvement, but there is still one thing which could be better: there is no real need for a periodic tick in the system. That is especially true when the processor is idle. An idle CPU can save quite a bit of power, but waking that CPU up 100 times (or more) per second will hurt those power savings considerably. With a flexible timer infrastructure, there is no point in turning the CPU back on until it has something to do. So, when the (i386) kernel goes into its idle loop, it checks the next pending timer event. If that event is further away than the next tick, the periodic tick is turned off altogether; instead, the timer is is programmed to fire when the next event comes due. The CPU can then rest unharrassed until that time - unless an interrupt comes in first. Once the processor goes out of the idle state, the periodic tick is restored.

以上所介绍的（译者注：指 clockevent）应该说只是对现有已支持功能的一种实现上的改进，另一个补丁（译者注：指 dyntick）则为内核增加了一项新功能：从此系统不再依赖于固定周期触发时钟中断。特别地，考虑到处理器空闲时尤其如此。CPU 进入空闲态后可以节省相当多的电量，但是如果将 CPU 每秒唤醒 100 次（甚至更多），则对节能影响很大。借助灵活的定时器实现框架，我们可以只在需要 CPU 工作时才唤醒它，其余时间都保持睡眠。所以，当内核（i386 上）进入空闲态时，它会检查下一个待处理的定时器事件。如果该事件的到期时间比下一个 tick 预期到期的时间足够迟，则内核会停止周期性 tick 定时器中断；同时将硬件设置为在下一个定时器事件到期时才触发中断。这样，CPU 可以在此期间不受打扰地进行睡眠，直到设置的定时器事件到期，或者有其他类型的中断来到。一旦处理器退出空闲态，周期性的 tick 就又恢复运行。

> What's in 2.6.21 is, thus, not a full dynamic tick implementation. Eliminating the tick during idle times is a good step forward, but there is value in getting rid of the tick while the system is running as well - especially on virtualized systems which may be sharing a host with quite a few other clients. The dynamic tick documentation file suggests that the developers have this goal in mind:

>     The implementation leaves room for further development like full tickless systems, where the time slice is controlled by the scheduler, variable frequency profiling, and a complete removal of jiffies in the future.

实事求是地说，2.6.21 中合入的 dyntick 补丁还没有实现完全意义上的 dynamic tick。目前所支持的，在处理器空闲期间消除 tick 是一大进步，但更高的目标是在系统运行时也消除 tick，特别是对于那种在一台主机上运行多个虚拟机客户端的场景。dynamic tick 的相关文档表明其开发人员已经设定了如下目标：

    当前的实现为将来进一步实现完全意义上的无固定周期时钟（full tickless）系统打下了基础，有待实现的工作包括：完全由调度器所控制的时间片，动态周期时钟条件下的内核性能剖析以及将来完全移除 jiffies。

> So expect some interesting work in the future - the removal of jiffies alone has a number of interesting implications. The developers also have support for the x86_64 and ARM architectures, though that support has not been merged for 2.6.21; MIPS and PowerPC support is in the works as well.

因此，让我们期待未来更有趣的工作吧，就移除 jiffies 这一点来说就颇具挑战。目前 dyntick 已经可以支持 x86_64 和 ARM 这两个体系架构，但尚未合并入 2.6.21；对 MIPS 和 PowerPC 的支持也正在开发中。

[1]: http://tinylab.org
