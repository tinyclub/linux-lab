---
layout: post
author: 'Wang Chen'
title: "LWN 152436: 一种实现内核定时器的新方法"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-152436-new-approach-to-ktimers/
description: "LWN 文章翻译，一种实现内核定时器的新方法"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[A new approach to kernel timers](https://lwn.net/Articles/152436/)
> 原创：By corbet @ Sept 20, 2005
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [???]()

> The kernel internal API includes a flexible mechanism for requesting that events happen at some point in the future. This timer subsystem is relatively easy to work with and efficient, but it has always suffered from a fundamental limitation: it is tied to the kernel clock interrupt, with the result that the resolution of timers is limited to the clock interrupt period. For a 2.6.13 kernel, on the i386 architecture, using the default clock interval, timers can be no more precise than 4ms. For many applications, that resolution is adequate, but some others (including real time work and some desktop multimedia applications) require the ability to sleep reliably for shorter periods. Thus, a number of developers have produced high-resolution timer patches over the years, but none of them have been merged into the mainline.

内核内部的编程接口（API）支持定时器功能，可用于方便地设定在未来的某个时刻得到通知。这个定时器子系统使用起来相对容易并且高效，但有一个根本的限制：就是它过于依赖内核的时钟中断，导致定时器的分辨率无法高于一个时钟中断的周期。举例来说，对于 2.6.13 版本的内核，在 i386 架构上，使用默认的时钟间隔，定时器的精度不会超过 4ms。对于许多应用程序而言，该精度已足够精确，但仍然存在一些其他的应用（譬如实时操作和一些桌面多媒体应用），需要以更短的周期可靠地进行休眠。因此，多年来众多的开发人员提供了各式各样的支持高分辨率的定时器补丁，但很可惜至今为止它们都没有被内核主线所接纳。

> Ingo Molnar's recently-released [2.6.13-rt6 tree](http://lwn.net/Articles/152266/), which contains the realtime preemption patch set, brought a surprise in the form of a new high-resolution timer implementation by Thomas Gleixner. Ingo has stated his intention to merge this new code ("ktimers") upstream, so it merits a look.

Ingo Molnar 最近发布了[版本为 2.6.13-rt6 的实时抢占内核源码树 ](http://lwn.net/Articles/152266/)，其中包含了一个由 Thomas Gleixner 提供的高精度定时器补丁，该定时器实现巧妙，看上去很不错。Ingo 已经表示他打算将这部分新代码合并到内核主线，因此值得给大家介绍一下（译者注：原文中有时用 “ktimers” 指代该内核定时器补丁，有时用 “ktimers” 直接作为内核定时器（kernel timers）的缩写。为不引起混淆，本文翻译时用“ktimers 补丁”指代该内核定时器补丁，而谈到内核定时器时则不再用 “ktimers” 而直接翻译为“内核定时器” ）。

> The ktimer implementation starts with the view that there are two fundamentally different types of timers used in the system. They are (using the terms adopted by the patch):

> - **Timeouts**. Timeouts are used primarily by networking and device drivers to detect when an event (I/O completion, for example) does not occur as expected. They have low resolution requirements, and they are almost always removed before they actually expire.
> - **Timers** are used to sequence ongoing events. They can have high resolution requirements, and usually expire.

要了解 ktimers 补丁的实现，需要首先理解内核中将定时器的应用区分为两种完全不同的场景，参考补丁中的术语描述如下：

- **超时（Timeouts）**类型定时器。考虑网络和设备的驱动程序中，经常会检测某个事件（例如，I / O 完成事件）是否会在预期的时间段内发生。它们的分辨率要求不高，并且该类定时器几乎总是在实际到期之前就会被删除。
- **周期（Timers）**类型定时器用于驱动某个事件按顺序持续地重复发生。他们一般会对分辨率有较高的要求，而且通常情况下总是会到期。

> The current kernel timer implementation is heavily oriented toward timeouts. To see how, consider the following diagram which, with sufficient imagination, can be construed as a model of the data structure used inside the kernel to manage timers:

目前内核定时器的实现主要面向**超时（Timeouts）**类型的应用场景。我们通过下面的图来解释其内部管理定时器的数据结构，该设计有点复杂，可能需要各位读者稍微发挥一下你们的想象力：

![Timer wheel diagram](https://static.lwn.net/images/ns/kernel/Timers.png)

> At the right side of the diagram is an array (tv1) containing a set of 256 (in most configurations) linked lists of upcoming timer events. This array is indexed directly by the bottom bits of a `jiffies` value to find the next set of events to execute. When the kernel has, over the course of 256 jiffies, cycled through the entire `tv1` array, that array must be replenished with the next 256 jiffies worth of events. That is done by using the next set of jiffies bits (six, normally) to index into the next array (`tv2`), which points to those 256 jiffies of timer entries. Those entries are "cascaded" down to `tv1` and distributed into the appropriate slots depending on their expiration times. When `tv2` is exhausted, it is replenished from `tv3` in the same way. This process continues up to `tv5`. The final entry in `tv5` is special, in that it holds all of the far-future events which do not otherwise fit into this hierarchy.

图的最右边的数组（tv1）包含 256 个数组项（在缺省配置下），这 256 个数组项依次对应从第 0 个到第 255 个时钟周期上即将到期的定时器事件（译者注：按照内核的历史习惯，称一个时钟周期为一个 `jiffy`，系统内部用一个 32 位的 `jiffies` 变量来记录自系统启动以来时钟中断发生的数目 ）。每个数组项实现为一个链表（译者注：之所以是一个链表，原因是对应一个可能的到期时刻，定时器事件的个数可能有一个或者多个）。对数组的索引和遍历可以直接使用系统变量 `jiffies` 的低 8 位来完成。当系统时间经过了 256 个时钟周期后，正好遍历处理完整个 `tv1` 数组，此时需要用下一组 256 个时钟周期来“替换”（`cascade`） `tv1` 中的内容（译者注：这有点类似数学减法运算中借位的概念，这里为方便阅读简单翻译为“替换”，但请读者自行发挥想象力体会一下 `cascade` 英文的原意，有“级联”，或者取其原意 - “层叠的小瀑布”）。“替换”的内容来自第二个数组（`tv2`），`tv2` 数组的每一项对应的时间范围不再是单个时钟周期，而是 256 个时钟周期这么长（译者注：每一项也是一个链表，保存着 256 个时钟周期范围内所有的定时器事件），通常情况下 `tv2` 数组的元素个数是 64，可以采用系统变量 `jiffies` 的次低 6 位（译者注：即低 9 位到低 14 位）来索引。具体“替换”（`cascade`）时会把 `tv2` 的当前索引项中链表上的的每一个定时器事件按照它们各自到期（`expiration`）时间分别移动到 `tv1` 数组的对应项中。依次类推，当 `tv2` 数组也遍历完后，继续用 `tv3` 数组中的内容来逐级“替换”（`cascade`），这个过程会持续发生，直到最后一级数组 `tv5`。`tv5` 数组中对应存放着系统可以支持的最大的定时器时间。（译者注：系统支持的定时器最大值不会超过 0xffffffff 个时钟周期，因为这是系统 `jiffies` 变量（32 位）可以表示的最大值。）

> This structure has some distinct advantages. It can retrieve all of the events to execute with a simple array lookup. Insertion of events is cheap, since their location in the structure is easy to calculate. Importantly, the removal of events is also cheap; there is no need to search through a long list of events to find a specific one to take out. Since most timeouts are removed before they expire, quick removal is a useful feature.

以上设计的最明显的优点就是可以通过数组下标来快速定位需要操作的事件对象。因为很容易计算新定时器事件在数据结构中的位置，所以插入一个定时器事件的操作十分高效。同样地，由于无需通过搜索一个很长的队列来定位事件对象，所以删除操作也很方便。考虑到该设计主要针对的是**超时（Timeouts）**类型定时器的场景，所以很有必要在特性上支持快速删除。

> On the other hand, this data structure is firmly tied to `jiffies` values, and cannot easily cope with timers with sub-jiffies resolution. The cascade process, which moves events from the higher arrays to the lower ones, can be expensive if there are a lot of events to work with. Events which are removed prior to expiration will often not have to be cascaded at all, while those which survive through to expiration will have to work their way through the structure. If the clock interrupt frequency is raised (to get better timer resolution), these cascades will happen more often, and the cost of the data structure goes up.

但在另一方面，这个数据结构的设计过于依赖 `jiffies` 的值，在分辨率上很难支持高于一个时钟周期的精度。同时在执行“替换”（`cascade`）操作时，由于需要将定时器事件对象从高一级数组移动到低一级的数组，一旦需要处理的事件数目很多，则计算量会急剧升高。对于**超时（Timeouts）**类型的场景来说绝大部分定时器在参与替换（`cascade`）之前就被删除了，所以影响很小，但对于**周期（Timers）**类型的场景（译者注：在该场景下定时器事件必须等到超时发生时才会被删除），“替换”（`cascade`）操作总是会发生。更糟糕的是如果我们希望通过简单地提高时钟中断频率以获得更好的定时器分辨率，则这些“替换”（`cascade`）操作的发生只会更频繁，从而导致计算成本进一步增加。

> The ktimers patch makes no changes to the existing API or data structure, which are deemed to be adequate and efficient for use with timeouts. Instead, it adds an entirely new API (and internal implementation) aimed at the needs of high-resolution timers. So ktimers are described entirely with human time units - nanoseconds, in particular. They are kept in a sorted, per-CPU list, implemented as a red-black tree. This structure provides for relatively quick insertion or removal, though it will be slower than the timeout structure shown above - but there is no need for the cascade operation.

考虑到当前的 API 和数据结构对于**超时（Timeouts）**类型的定时器应用场景已经足够高效，所以 ktimers 补丁代码并没有试图在这些方面进行更改，而是增加了一套全新的 API（以及内部的实现），以满足高分辨率定时器的需求。ktimers 补丁在内核中将描述定时器事件的基本时间单位完全替换为人类所习惯的时间单位（纳秒），同时将定时器事件以红黑树的形式保存在一个有序的列表中，每个处理器一个。这种数据结构支持相对快速的插入或删除操作，虽然它比上面介绍的现有方式慢 - 但其优点是不需要执行“替换”（`cascade`）操作。

> The core structure for ktimers is, unsurprisingly, `struct ktimer`. They must be initialized before use with one of the following functions:

ktimers 补丁的核心结构体是 `struct ktimer`。使用前必须使用以下函数之一对它们进行初始化：

	void init_ktimer_mono(struct ktimer *timer);
	void init_ktimer_real(struct ktimer *timer);

> Internally, each ktimer is tied to a "base," being the clock by which it is run. The ktimer patch provides two such clocks. The "monotonic" clock is similar to jiffies in that it is a straightforward, always-increasing count. The "realtime" clock, instead, tries to match time as known outside of the system; that clock can be corrected by the kernel or by the system administrator. A ktimer with a 5ms expiration will, if initialized with `init_ktimer_mono()`, expire 5ms in the future (with the usual proviso that delays can happen). That same timer, if initialized with `init_ktimer_real()`, will expire when the realtime clock says that 5ms have passed. But, since the realtime clock may be adjusted in the meantime, the actual elapsed time could differ.

内部实现上，每个内核定时器都基于一种时钟基准（base）进行计算。ktimers 补丁目前支持两种类型的时钟基准。第一类叫做“单调”（monotonic）类时钟，类似于系统维护的 jiffies 值，随着时间的推移其值是简单累加的。另一种叫做“实时”（realtime）类时钟，它会尝试和系统外部的时间进行同步；譬如通过内核或系统管理员进行纠正。如果使用 `init_ktimer_mono()` 初始化该定时器，并设定超时时间为 5ms，则该定时器确保会在未来 5ms 后到期（通常会有一定的延迟）。如果使用 `init_ktimer_real()` 进行初始化，超时时间仍然设定为 5ms，则该定时器将在真实世界的时钟经过 5ms 后才会到期。需要注意的是，在真实世界中的时钟是可能被人为调整的，所以具体到期的时间得看实际的调整结果。

> There are some caller-accessible fields in `struct ktimer`:

`struct ktimer` 中有一些调用者可访问的字段：

	void (*function)(void *);
	void *data;
	nsec_t expired;
	nsec_t interval;

> When the timer expires, `function()` will be called with `data` as its argument. The `expired` field will contain the time at which the timer actually expired, which might be later than requested. Interestingly, the high-resolution version of the ktimers patch does not set this field. Finally, `interval` is used for periodic timers.

当定时器到期时，函数 `function()` 将被内核调用并传入参数 `data`。`expired` 字段包含该计时器到期的实际时间，这个值可能比创建定时器时设定的值要晚。有趣的是，ktimers 补丁的高分辨率定时器版本并未设置此字段。最后，`interval` 字段用于周期定时器。

> A timer is set with a call to:

可以通过调用如下函数启动一个计时器：

	int start_ktimer(struct ktimer *timer, nsec_t *time, int mode);

> Here, `time` is the expiration time in nanoseconds, and `mode` describes how that `time` is to be interpreted. The possible `mode` values are:

> - `KTIMER_ABS`: the timer will expire at an absolute time.
> - `KTIMER_REL`: the given `time` value is a relative time, which must be added to the current time to get an absolute expiration time.
> - `KTIMER_INCR`: for timers which have been used before, the `time` value is added to the previous expiration time.
> - `KTIMER_FORWARD`: like `KTIMER_INCR`, except that the `time` value will be added repeatedly, if necessary, to obtain an expiration time in the future.
> - `KTIMER_REARM`: like `KTIMER_FORWARD`, except that the interval value stored in the timer is added.
> - `KTIMER_RESTART`: the expiration time of the timer is not changed at all.

该函数中，参数 `time` 是以纳秒为单位的到期时间，`mode` 用于区分如何解释参数 `time` 以便得到定时器到期的绝对时间值。`mode` 可以取以下值：

- `KTIMER_ABS`：`time` 参数指定的值就是定时器到期的绝对时间。
- `KTIMER_REL`：`time` 参数指定的值是相对时间值，定时器到期的绝对时间等于当前时间加上该相对时间值。
- `KTIMER_INCR`：对于之前使用过的定时器，定时器到期的绝对时间等于 `time` 参数时间值和原先设定的到期时间相加。
- `KTIMER_FORWARD`：与 `KTIMER_INCR` 类似，但 `time` 参数时间值可能会重复相加以确保最终得到的绝对时间一定是一个将来的时间。
- `KTIMER_REARM`：与 `KTIMER_FORWARD` 类似，但和`time` 参数时间值相加的不是过期时间，而是`struct ktimer`结构体中保存的 `interval` 时间。
- `KTIMER_RESTART`：简单地重启定时器但不会更改定时器的到期时间。

> For `KTIMER_FORWARD` and `KTIMER_REARM`, the ktimer code also maintains an integer `overrun` field in the ktimer structure. If a timer is started after the next expected expiration time (in other words, the system fell behind and did not restart the timer soon enough), `overrun` will be incremented to allow the calling code to compensate.

对于 `KTIMER_FORWARD` 和 `KTIMER_REARM`，ktimers 补丁代码还在 `struct ktimer` 中维护一个整数类型的 `overrun` 成员变量。如果某个定时器未能在设定的到期时间到来（换句话说，由于系统运行上的延迟导致未及时触发该定时器），则 `overrun` 将记录（累加）在此期间到期但未来得及触发的其他周期性定时器到期事件的次数，应用程序可以在接收到这个过期定时器事件时根据该值计算出实际流逝的时间。

> The return value will be zero, unless the timer is already expired, in which case the timer will not be started and the return value will be negative. If, however, the `mode` argument contains the bit `KTIMER_NOCHECK`, the timer will be started and executed normally, regardless of whether it is already expired.

正常情况下该函数的返回值将为零，除非调用该函数启动定时器时该定时器已经过期，在这种情况下，定时器将不会被启动，同时函数的返回值将为负值。但是，如果 `mode` 参数指定了 `KTIMER_NOCHECK` 位，则该函数将不检查上述的过期情况，定时器会正常启动并执行。

> Most of the other ktimer functions are reasonably self-explanatory for those who have seen the current timer API:

对于熟悉当前定时器编程接口的读者来说，大多数其他的内核定时器函数都不用作太多解释：

	int modify_ktimer(struct ktimer *timer, nsec_t *time, int mode);
	int try_to_stop_ktimer(struct ktimer *timer);
	int stop_ktimer(struct ktimer *timer);

> There is also a convenience function to make a process sleep on a ktimer:

ktimers 补丁还提供了一个函数方便进程利用内核定时器进行睡眠：

	nsec_t schedule_ktimer(struct ktimer *timer, nsec_t *time, 
                           int state, int mode);

> The additional argument here (`state`) should be `TASK_INTERRUPTIBLE` or `TASK_UNINTERRUPTIBLE`, depending on whether the sleep should be interrupted by signals or not. The return value is the number of nanoseconds remaining in the requested sleep time; it will be zero except when the sleep is ended prematurely.

其中 `state` 参数的取值应该是 `TASK_INTERRUPTIBLE` 或 `TASK_UNINTERRUPTIBLE`，这取决于睡眠是否允许被信号打断。返回值是剩余的睡眠时间，以纳秒为单位；如果睡眠正常结束，则该函数的返回值为 0，否则说明该进程的睡眠被提前终止了。

> The [standalone ktimers patch](http://lwn.net/Articles/152435/) posted by Thomas is the version most likely to be merged. This patch runs ktimers from the normal clock interrupt, with the result that it provides no better resolution than the existing timer API. All of the structure is there to do better, however, once the low-level timer code and architecture specific support is in place. A separate patch exists which enables ktimers to provide high-resolution timers on the i386 architecture.

Thomas 提交的 [ktimers 补丁](http://lwn.net/Articles/152435/) 是独立发布的，目前看起来最有可能被合入内核主线。该补丁基于正常的时钟中断实现 内核定时器，和内核现有的定时器实现相比，在运行精度上并无特别的优势。但是，一旦底层的定时器和体系架构相关的配合代码就绪，在整体上该新框架会表现得更好。社区已经基于该方案在 i386 架构上提供了一个独立的补丁用于实现高分辨率定时器的支持。

> So far, the largest objection to the ktimer implementation is the use of nanoseconds for time values. Nanosecond timekeeping requires 64-bit variables, which will slow things down a little on 32-bit systems. The response from the developers is that the additional overhead is almost zero and not worth worrying about. So, unless some other surprise turns up, ktimers could find their way into the kernel not too long after 2.6.14 comes out.

到目前为止，对 ktimers 补丁的最大反对意见在于该补丁用纳秒来表示时间值的基本单位。纳秒计时需要 64 位变量，在 32 位系统上这么做会使系统运行得稍微慢一点。补丁的开发人员认为这些额外的开销几乎为零，不值得担心。所以，顺利的话 ktimers 补丁会在 2.6.14 发布后不久就进入内核。

> (See also: [this posting from Thomas](http://lwn.net/Articles/152363/), which describes the motivation behind ktimers and its relation to other timing patches in detail).

（另见：[Thomas 发表的这篇文章](http://lwn.net/Articles/152363/)，其中详细描述了 ktimers 补丁 背后的开发动机及其与其他计时相关补丁的关系）。

[1]: http://tinylab.org
