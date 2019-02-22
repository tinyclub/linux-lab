---
layout: post
author: 'Wang Chen'
title: "LWN 120850: 一个新的内核时间管理计时子系统"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-120850/
description: "LWN 文章翻译，一个新的内核时间管理子系统"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[A new core time subsystem](https://lwn.net/Articles/120850/)
> 原创：By corbet @ Jan. 26, 2005
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [guojian-at-wowo](https://github.com/guojian-at-wowo)

> Keeping track of the current time is one of the kernel's many jobs. In the Linux kernel, this task is handled in a very architecture-dependent way. Each architecture has its own sources of high-resolution time, and each performs its own calculations. This system works, but it results in quite a bit of code being duplicated across architectures, and it can be brittle. Patches which change time-related code often do not manage to correctly update all architectures.

跟踪当前的时间是内核提供的众多功能之一。在 Linux 内核中，当前该功能的处理方式非常依赖于底层的体系架构。每种架构在硬件上都使用自己的时钟源支持高分辨率的时间读取，并基于此按照自己的方式进行相关计算。这个系统虽然可以工作，但是它在不同的体系架构中存在相当多重复冗余的代码，导致极难维护。每当一个补丁要修改一个与时间相关的问题时，如何确保在所有体系架构上都可以工作是一件令人非常头痛的事情。

> John Stultz has been working for some months on a cleaner alternative. The result is [a new time subsystem](https://lwn.net/Articles/120588/) which, he hopes, will improve the situation.

为了改善这种局面，John Stultz 开发了[一个新的时间管理子系统](https://lwn.net/Articles/120588/)，该方案已经进行了好几个月了。

> Much of the patch can be seen as a refactoring of the time code. Common calculations are now performed in the timeofday core, rather than in architecture-specific code. The code for implementing the network time protocol (NTP), an interesting exercise in complexity itself, has been separated from the rest of the time code and hidden in its own file. Most of the core time code has been reworked to deal with time in nanoseconds, a format which gives adequate time resolution but which, in a 64-bit variable, is still good for centuries. The timeofday code no longer depends on the jiffies variable, meaning that it can work independently of the timer interrupt, which may be disabled in some situations. The overall result is kernel timing code which is much easier to read and understand.

大部分补丁修改都可以看作是对原有时间子系统的重构。通用的处理现在集中在一个称之为 timeofday 的核心模块中，而不再是分布于各个特定于体系架构的代码中。补丁中还包括对网络时间协议（network time protocol，简称 NTP）的修改，考虑到这部分代码比较复杂，所以将其独立出来，集中在独立的文件中。大多数与时间处理有关的核心代码经过重新修改后，都以纳秒为基本单位对时间进行处理，这为时间计算提供了足够的精度，但唯一的代价是要求使用一个 64 位变量来保存时间值，当然这么做带来的另一个好处就是可以确保系统连续运行好几个世纪不用重启。timeofday 模块也不再依赖于 jiffies 变量，这意味着它可以独立于定时器中断运行，不用担心那些定时器中断可能会被禁止的场景。总体结果是内核中有关时间处理的代码变得更加易于阅读和理解。

> In the end, however, the timing code must go to the hardware to actually get high-resolution time values. John made a couple of observations here. One is that, while time sources are architecture-dependent, many architectures share the same types of timing hardware. The other was that the code which deals with a time source is really just another device driver. So he isolated the time source information into its own structure:

当然，计时的逻辑最后总要和硬件交互才能真正获得高精度的时间值。John 经过一番观察后发现，一方面，虽然时钟源（译者注，原文是 time source，但考虑到下文介绍的结构体类型 `timesource_t` 在最终正式合入内核时更名为 `clocksource`，所以这里还是统一翻译为时钟源）依赖于体系架构，但许多体系架构会使用相同类型的计时硬件设备。另一方面，操作时钟源硬件的代码逻辑最终还是实现为一个设备驱动程序。所以他把时钟源的相关信息抽取出来定义了一个通用的结构体类型如下：

	struct timesource_t {
		char* name;
		int priority;
		enum {
			TIMESOURCE_FUNCTION,
			TIMESOURCE_CYCLES,
			TIMESOURCE_MMIO_32,
			TIMESOURCE_MMIO_64
		} type;
		cycle_t (*read_fnct)(void);
		void __iomem* mmio_ptr;
		cycle_t mask;
		u32 mult;
		u32 shift;
		void (*update_callback)(void);
	};

> Here, `name` is just a name for the source, and `priority` is used to choose between multiple available sources. The `type` field tells how this source can be read. If `type` is `TIMESOURCE_FUNCTION`, the `read_fnct()` will be called to read the source. The two `_MMIO_` variants are for hardware which can be read directly from I/O memory; in that case, the time code can just obtain a value from the location indicated by `mmio_ptr` with no need to call any outside functions. `TIMESOURCE_CYCLES` indicates that the processor's time stamp counter (TSC) is being used, so `get_cycles()` is called to get the actual value. In any of the above cases, the value returned by the time source is assumed to be some sort of counter. The `mask`, `mult`, and `shift` values are applied to turn a delta between two such values into a number of nanoseconds for the rest of the timekeeping code.

在这里，`name` 是时钟源的名称，`priority` 在多个可用时钟源之间进行选择时会用上。`type` 字段用于指定读取时钟源的值的方式。如果 `type` 取值为 `TIMESOURCE_FUNCTION`，则调用 `read_fnct()` 来读值。两个带 `_MMIO_` 字样的选项对应于采用内存映射 I/O 寻址方式的硬件。对于这种情况，子系统代码只需根据 `mmio_ptr` 字段所指定的内存地址获取值，而无需调用额外的函数。 `TIMESOURCE_CYCLES` 表示系统直接使用处理器的时间戳计数器（time stamp counter，简称 TSC），即系统可以调用 `get_cycles()` 函数来获得实际的时间值。在上述所有情况下，读取各种时钟源所返回的值都统一为简单的计数单位（译者注，读取值即底层硬件计数器的计数值，代码上体现为 `cycle_t` 类型）。在新的内核时间管理子系统中，内部的计时单位为纳秒，所以必要时需要使用该结构体中的 `mask`，`mult` 和 `shift` 字段来将 `cycle_t` 类型的值转换为单位为纳秒的值。

> With this structure in place, architecture-specific code need only fill in a `timesource_t` structure (possibly implementing a read function in the process) and pass it to `register_timesource()`. All the rest is then handled in the common code. John has provided [a set of time source drivers](https://lwn.net/Articles/120590/) for a few architectures which demonstrates how they can be written.

基于该结构体类型，体系架构相关的代码只需要定义一个 `timesource_t` （译者注，在正式的内核代码中该结构体类型被更名为 `clocksource`） 类型的时钟源变量（有必要的话可能还需要实现一个用于读取时钟源值的回调函数），然后调用 `register_timesource()` 将该时钟源变量作为参数传入（译者注，即向内核注册该时钟源）。其余部分都由子系统的通用代码处理。作为例子演示，John 为其中几个架构提供了[一组时钟源驱动程序](https://lwn.net/Articles/120590/)。

> The discussion of the patches suggests that, while developers like the general intent, there are some remaining concerns - especially among the architecture maintainers. In some architectures, the `gettimeofday()` system call can be handled entirely in user space, but the current patches do not yet support that. The current NTP implementation is also seen as being too expensive. Finding a way to cut the cost of NTP while maintaining accuracy could be a bit of a challenge, but John is working at it. Expect to see some more iterations on this one.

从社区对该补丁的讨论中可以看出来，虽然开发人员都喜欢一个通用的框架，但仍然存在一些有待解决的问题，特别是对于那些不同体系架构的维护人员。在某些体系架构中，`gettimeofday()` 这样的系统调用完全可以在用户态中实现，但目前的补丁程序尚不支持这种实现方式。而且目前的 NTP 实现也过于复杂。在保持准确性的同时寻找简单地实现 NTP 的方案可能会带来一些挑战，但 John 正在朝着这个目标而努力。在正式发布之前，该补丁应该还需要进一步的迭代改进。

[1]: http://tinylab.org
