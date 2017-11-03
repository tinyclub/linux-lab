---
layout: post
author: 'Wang Chen'
title: "LWN 215996: 设备资源管理"
album: lwn
group: translation
permalink: /lwn-215996-device-resource-management/
description: "LWN 文章翻译，设备资源管理"
category:
  - 设备驱动
  - LWN
tags:
  - Linux
  - device resource management
  - 设备资源管理
---

> 原文：[Device resource management](https://lwn.net/Articles/215996/)
> 原创：By Jonathan Corbet @ January 2, 2007
> 翻译：By Unicornx of [TinyLab.org][1] @ Oct 19, 2017

> Writing device drivers can be a tricky task. Simply getting a piece of hardware to operate as desired - perhaps working from erroneous or nonexistent documentation - can be a frustrating process. Beyond that, however, the driver must allocate several different types of resources for the device; these resources can include I/O memory mappings, interrupt lines, blocks of memory, DMA buffers, registrations with multiple subsystems, etc. All of these allocations must be returned to the system when the device (or its driver) goes away. It is not uncommon for driver writers to forget to deallocate something, leading to resource leaks.

编写设备驱动程序常常是一件棘手的任务。为了让硬件正确工作，开发人员面对的常常是一些充满错误的文档说明，更有甚者这些文档可能压根儿就找不到，这可真是一个令人沮丧的事情。除此之外，编写驱动程序过程中还必须为设备分配多种不同类型的资源; 这些资源包括 I/O 存储器映射，中断线，内存块，DMA 缓存，并为它们向多个子系统进行注册等。当设备断开（或者驱动程序被卸载时），所有这些已经分配的资源必须全部被归还到系统去。不幸的是驱动开发人员忘记释放点东西是常见的事情，这常常导致了内核运行中的资源泄漏问题。

> The problem can get worse, however, in the face of initialization errors. If the driver is unable to properly set up its device, it must undo any registrations which had been done up to the point of failure. Attempts to handle initialization failures usually take the form of several goto labels within the initialization function or some sort of global "initialization state" variable describing where cleanup should begin. Either way, these paths tend not to be well tested, so the chances of an initialization failure leading to some sort of resource leak are quite good.

这个问题在设备检测过程中一旦遭遇设备初始化失败会变得更糟。如果驱动程序无法正确配置其设备，应当在发生失败时回滚撤消所做过的所有资源分配和注册动作。驱动代码中通常采用会使用 goto 语句或者一些全局的初始化状态变量来标识初始化过程运行到哪一个阶段以便实现正确的回滚。无论哪种方式，要做到对各种失败情况进行全面的覆盖测试都是一件困难的工作，所以一旦发生初始化失败就很容易导致某种资源发生泄露。

> Tejun Heo, who has done much to improve the Linux serial ATA subsystem over the last year, has had enough of these sorts of initialization problems. So he has put together [a device resource management patch](http://lwn.net/Articles/215861/) which, if accepted, has the potential to make driver code simpler and more robust. The core idea is simple: every time a driver allocates a resource, the management code remembers the allocation and any information needed to free that allocation. When the driver disconnects from the device, all of the remembered allocations are returned to the system.

在过去一年中，Tejun Heo 为改进 Linux 的 serial  ATA 子系统做了大量工作，在此期间他遇到了太多的诸如此般的初始化问题。所以他为内核提供了[一个设备资源管理补丁](http://lwn.net/Articles/215861/)，该补丁一旦被内核主线接受，有可能使驱动程序开发变得更简单和更健壮。其核心思想很简单：每当驱动程序分配资源时，管理代码会记住所分配的资源以及和该资源相关的用于释放的任何信息。当驱动程序与设备断开连接时，管理代码会负责将曾经分配的资源返还给系统。

> This sort of allocation tracking cannot be added to the current API in any sort of coherent way. Tejun's patch, instead, creates new "managed" versions of various allocation functions. The new functions look like the old ones with (1) the addition of "m" (or "devm") to the name, and (2) a struct device argument if the function did not already have one. So, for example, the managed versions of the interrupt allocation functions are:

这种对资源分配的跟踪机制无法在现有的接口基础上直接修改。所以，Tejun 的补丁为现有接口创建了一套新的支持“资源管理”的版本。新的函数命名上看起来和旧的接口形式很类似，除了以下两点不同：（1）在函数名中添加了后缀 “m”（或前缀 “devm”），以及（2）确保每个新接口拥有一个 `struct device` 类型的参数，如果对应的原函数没有就增加一个。例如，中断分配函数所对应的资源管理版本形式如下所示：

	int devm_request_irq(struct device *dev, unsigned int irq,
			     irq_handler_t handler, unsigned long irqflags,
			     const char *devname, void *dev_id);
	void devm_free_irq(struct device *dev, unsigned int irq,
			   void *dev_id);

> The patch also includes managed functions for dealing with DMA buffers, I/O memory regions, plain memory allocations, and PCI device setup. They allow the driver author to replace a whole set of deallocation calls with a simple call to devres_release_all(), simplifying the code significantly. In fact, even that call is unnecessary; the driver core will call it when the driver detaches from the device.

补丁新增的管理函数涵盖了包括处理 DMA 缓冲区，I/O 内存区域，普通内存分配和 PCI 设备设置的功能。它允许驱动程序开发人员只调用一个简单的函数 `devres_release_all()` 来替换一整套的分配调用，从而简化了代码。事实上，甚至该函数调用也不是必须的; 当设备断开导致驱动程序与设备分离时，内核的驱动框架将缺省调用它。

> For more complicated situations, there is also a "group" concept. Groups can be thought of as markers in the stream of allocations associated with a given device. The allocations performed within a specific group can be rolled back without affecting any others. In brief, the group API is:

对于更复杂的情况，还有一个“组”的概念。“组”被用来标识和一个给定设备相关联的一系列资源分配动作。在一个特定组中所分配的所有资源可以被自动回滚而不影响任何其他组内分配的资源。和“组”相关的编程接口总结如下：

	void *devres_open_group(struct device *dev, void *id, gfp_t gfp);
	void devres_close_group(struct device *dev, void *id);
	void devres_remove_group(struct device *dev, void *id);
	int devres_release_group(struct device *dev, void *id);

> A call to devres_open_group() will create a new group for the given device, identified by the id value. Any allocations performed thereafter will be considered to be a part of that group until devres_close_group() is called. If initialization works as desired, however, devres_remove_group() can be used to get rid of the group overhead while leaving the allocations (and their tracking information) untouched. In the failure path, devres_release_group() will return all allocations belonging to the given group.

对 `devres_open_group()` 的调用将为给定设备创建一个新的组，由 id 值标识（译者注：同时标识一个组开始）。此后执行的任何资源分配动作将被视为该组的一部分，直到调用 `devres_close_group()` 标识该组结束。初始化（译者注：特指资源分配）成功完成后，我们可以使用 `devres_remove_group()` 删除该组（译者注：原组中分配的资源不再受该组管理），但这么删除组的同时原组内分配的资源（及其跟踪信息）并不会被回收。在失败处理中，可以调用 `devres_release_group()` 执行组回滚操作，将属于给定组的所有资源返还给系统。

> There has been very little discussion of this patch set, as of this writing. Driver writers, perhaps, are still recovering from the holiday festivities. It is not too hard to imagine that there could be some discomfort about the extra overhead involved in tracking all of those allocations - especially since things do function normally almost all of the time. In the end, however, the promise of correct operation in a wider range of situations may be enough to motivate the inclusion of the new interface.

截至本文发稿为止，对这个补丁集的讨论和关注还不多。程序员们应该刚休假回来还没完全恢复。不难想象，为了支持资源管理所引入的额外开销一定会让大家感到稍有不适 - 特别是对那些目前运行得还不错的系统。然而，我相信，假以时日，大家一定会接受这套会对系统的健壮性带来好处的机制和编程接口。

[1]: http://tinylab.org
