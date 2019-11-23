---
layout: post
draft: false
top: true
author: 'Wang Chen'
title: "LWN 302043: 中断线程化"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-302043/
description: "LWN 中文翻译，中断线程化"
category:
  - 中断与异常
  - LWN
tags:
  - Linux
  - interrupt
  - thread
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Moving interrupts to threads](https://lwn.net/Articles/302043/)
> 原创：By Jake Edge @ Oct. 8, 2008
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Yang Wen](https://github.com/w-simon)

> Processing interrupts from the hardware is a major source of latency in the kernel, because other interrupts are blocked while doing that processing. For this reason, the realtime tree has a feature, called ***threaded interrupt handlers***, that seeks to reduce the time spent with interrupts disabled to a bare minimum—pushing the rest of the processing out into kernel threads. But it is not just realtime kernels that are interested in lower latencies, so threaded handlers are being proposed for addition to the mainline.

硬件中断处理过程中会关中断，导致其他中断无法执行，这是内核中引发处理延迟的一个主要原因。为此，实时补丁集（译者注，即 PREEMPT_RT 补丁）中开发了一个称之为 “***中断线程化***” 的功能，该功能试图将内核在关中断状态下需要执行的工作量压缩到最低限度，同时将其余的中断处理全部安排到一个内核线程中去完成。不是只有实时内核才会对低延迟感兴趣，同样地，有人建议将 “中断线程化” 这个特性也添加到内核主线中去。

> Reducing latency in the kernel is one of the benefits, but there are other advantages as well. The biggest is probably reducing complexity by simplifying or avoiding locking between the "hard" and "soft" parts of interrupt handling. Threaded handlers will also help the debuggability of the kernel and may eventually lead to the [removal of tasklets](http://lwn.net/Articles/239633/) from Linux. For these reasons, and a few others as well, Thomas Gleixner has [posted](http://lwn.net/Articles/301890/) a set of patches and a "request for comments" to add threaded interrupt handlers.

降低内核中的延迟只是该特性带给我们的好处之一，除此之外它还具备其他方面的优点。其中最突出的一点是：由于中断线程化后简化乃至避免了整个中断处理流程中 “关中断处理（术语上称之为 “hard” 部分）” 和 “开中断处理（术语上称之为 “soft” 部分）” 两个阶段之间可能涉及的锁同步机制，从而降低了整体实现上的复杂性。中断处理线程化还将有助于内核的调试，并最终可能导致 tasklet 机制从 Linux 中 [被删除][1] 。出于以上原因，也由于其他的一些原因，Thomas Gleixner [提交了][2] 一组补丁和一个 “审阅请求（request for comments）”，希望在内核中加入 “中断线程化” 这个特性。

> Traditionally, interrupt handling has been done with ***top half*** (i.e. the "hard" irq) that actually responds to the hardware interrupt and a ***bottom half*** (or "soft" irq) that is scheduled by the top half to do additional processing. The top half executes with interrupts disabled, so it is imperative that it do as little as possible to keep the system responsive. Threaded interrupt handlers reduce that work even further, so the top half would consist of a "quick check handler" that just ensures the interrupt is from the device; if so, it simply acknowledges the interrupt to the hardware and tells the kernel to wake the interrupt handler thread.

传统上，中断处理流程由两部分处理逻辑协同完成，“***上半部（top half）***”（也被称为 “hard” irq）负责实际的对硬件中断的响应处理，“***下半部（bottom half）***”（或称之为 “soft” irq）由 “上半部” 负责调度并执行额外的处理。“上半部” 在禁用中断的情况下执行，因此必须尽可能地快，从而不会给系统响应造成太大的延迟。中断线程化后进一步压缩了这部分的工作量，“上半部” 的工作仅仅需要完成 “快速检查”，譬如确保中断的确来自期望的设备；如果检查通过，它将对硬件中断完成确认并通知内核唤醒中断处理线程完成中断处理的 “下半部”。

> In the realtime tree, nearly all drivers were mass converted to use threads, but the patch Gleixner proposes makes it optional—driver maintainers can switch if they wish to. Automatically converting drivers is not necessarily popular with all maintainers, but it has an additional downside as Gleixner notes: "`Converting an interrupt to threaded makes only sense when the handler code takes advantage of it by integrating tasklet/softirq functionality and simplifying the locking.`"

在应用实时补丁的内核中，几乎所有驱动程序中的中断处理都被转换为使用线程，但在 Gleixner 提交的补丁中这种转化不是强制的，驱动程序的维护人员可以根据自己的需要选择是否要实现这种转换。强制自动转换并不一定会受到所有驱动开发人员的欢迎，正如 Gleixner 所指出的，转换工作中存在额外的开销，“`任何驱动代码，如果试图将原来的中断处理逻辑修改为采用新的线程方式，必须充分评估修改后的结果，不仅要达到与原先采用 tasklet 或者 softirq 方式同样的效果，而且还能简化相应的锁逻辑，否则这种转化就失去了实际的意义。`”

> A driver that wishes to request a threaded interrupt handler will use:

如果一个驱动希望将其中断处理线程化可以使用如下新的注册接口：

	int request_threaded_irq(unsigned int irq, irq_handler_t handler,
				irq_handler_t quick_check_handler,
				unsigned long flags, const char *name, void *dev)

> This is essentially the same as `request_irq()` with the addition of the `quick_check_handler`. As [requested by Linus Torvalds](http://lwn.net/Articles/298840/) at this year's Kernel Summit, a new function was introduced rather than changing countless drivers to use a new `request_irq()`.

该函数的形式与 `request_irq()` 基本相同，除了新增了一个 `quick_check_handler` 参数。根据 [Linus Torvalds 在今年内核峰会上的要求][3]，这里采用的方式是引入了一个新函数，而不是修改现有的 `request_irq()` 函数，其目的是为了避免太多的驱动程序为此做出修改。

> The `quick_check_handler` checks to see if the interrupt was from the device, returning `IRQ_NONE` if it isn't. It can also return `IRQ_HANDLED` if no further processing is required or `IRQ_WAKE_THREAD` to wake the handler thread. One other return code was added to simplify converting to a threaded handler. A `quick_check_handler` can be developed prior to the `handler` being converted; in that case, it returns `IRQ_NEEDS_HANDLING` (instead of `IRQ_WAKE_THREAD`) which will call the handler in the usual way.

（译者注，以下有关 `quick_check_handler` 的描述在正式提交的补丁中已被更改，为尊重原文依然按原文翻译。准确的描述请参考实际代码提交 [“genirq: add threaded interrupt handler support”][4] 的描述。）这个新增的 `quick_check_handler` 回调函数用于检查是否当前中断来自你关心的设备，如果不是则返回 `IRQ_NONE`。它也可以返回 `IRQ_HANDLED` 用于通知内核不再需要进一步处理，或者返回 `IRQ_WAKE_THREAD` 告诉内核唤醒中断处理线程。为了简化中断线程化所需的代码移植工作，补丁还新定义了另一个返回码。开发人员可以在移植过程中为新参数 `quick_check_handler` 编写对应的回调函数而无需改写 `handler` 对应的回调函数；如果开发人员不希望采用线程方式执行 `handler` （即按照原有方式运行 `handler`），则可以在 `quick_check_handler` 函数中返回 `IRQ_NEEDS_HANDLING`（而不是 `IRQ_WAKE_THREAD`）。

> `request_threaded_irq()` will create a thread for the interrupt and put a pointer to it in the `struct irqaction`. In addition, a pointer to the `struct irqaction` has been added to the `task_struct` so that handlers can check the `action` flags for newly arrived interrupts. That reference is also used to prevent thread crashes from causing an oops. One of the few complaints seen so far about the proposal was a [concern about wasting four or eight bytes](https://lwn.net/Articles/302244/) in each `task_struct` that was not an interrupt handler (i.e. the vast majority). That structure could be split into two types, one for the kernel and one for user space, but it is unclear whether that will be necessary.

`request_threaded_irq()` 在为中断创建一个线程的同时，会设置 `struct irqaction` 结构体中的 `thread_fn` 成员，使其指向中断处理线程的执行函数。此外，补丁还在 `task_struct` 中添加了一个指向 `struct irqaction` 的指针（译者注，具体参考 [相关代码][5]），以便中断处理函数可以检查对应中断的 `action` 标志。该指针还用于防止由于中断处理线程崩溃导致系统异常。到目前为止，和该提案有关的少数几个意见之一是：在每个 `task_struct` 中浪费四个或八个字节（译者注，指 `task_struct` 中添加的指针成员）是不是有点浪费（更何况大部分情况下系统中的线程并没有对应一个中断）。或许可以把这个结构体分为两种类型，一种用于内核态，一种用于用户态，但不清楚是否有必要这么做。（译者注，在后继内核版本中，经过努力，已经不再需要在 `task_struct` 中保存该指针信息了，相应的改动随 [3.4][6] 和 [3.5][7] 合入内核主线。）

> Andi Kleen has a more general [concern](https://lwn.net/Articles/302245/) that threaded interrupt handlers will lead to bad code: "`to be honest my opinion is that it will encourage badly written interrupt code longer term,`" but he seems to be in the minority. There were relatively few comments, but most seemed in favor—perhaps many are waiting to see the converted driver as Gleixner promises to deliver "real soon". If major obstacles don't materialize, one would guess the `linux-next` tree would be a logical next step, possibly followed by mainline merging for 2.6.29.

Andi Kleen 更加 [关注][8] 中断线程化后对代码编写质量的影响：“说实话，我认为长此以往这会鼓励程序员写出很糟糕的中断代码，” 但看起来和他一样持类似观点的人只占少数。总的评论相对较少，而且其中大多数人似乎更喜欢这个补丁，也许许多人都在等着看驱动代码的转化是否会像 Gleixner 承诺的那样 “真的很方便”。如果没有什么主要反对意见的话，人们猜测该补丁首先会被合入 linux-next 代码仓库，再下来可能会随着 2.6.29 版本合入主线（译者注，该补丁最终随 2.6.30 合入内核主线）。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/239633/
[2]: https://lwn.net/Articles/301890/
[3]: https://lwn.net/Articles/298840/
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=3aa551c9b4c40018f0e261a178e3d25478dc04a9
[5]: https://elixir.bootlin.com/linux/v2.6.30/source/include/linux/sched.h#L1302
[6]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4bcdf1d0b652bc33d52f2322b77463e4dc58abf8
[7]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4d1d61a6b203d957777d73fcebf19d90b038b5b2
[8]: https://lwn.net/Articles/302245/
