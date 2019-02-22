---
layout: post
author: 'Wang Chen'
title: "LWN 222860: 资源管理编程接口"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-222860/
description: "LWN 文章翻译，资源管理编程接口"
category:
  - 设备驱动
  - LWN
tags:
  - Linux
  - device resource management
---

> 原文：[The managed resource API](https://lwn.net/Articles/222860/)
> 原创：By Jonathan Corbet @ Feb 20, 2007
> 翻译：By Unicornx of [TinyLab.org][1] @ Oct 19, 2017
> 校对：By Falcon of [TinyLab.org][1]

> The [device resource management patch](http://lwn.net/Articles/215996/) was discussed here in January. That patch has now been merged for the 2.6.21 kernel. Since the API is now set - at least, as firmly as any in-kernel API is - it seems like a good time for a closer look at this new interface.

在一月份我们讨论了 [设备资源管理补丁](/lwn-215996)。该补丁现在已经合入内核版本 2.6.21 。鉴于该套 API 已经成为了内核所有的正式 API 的一部分 - 是时候好好给大家介绍一下这套新接口了。
 
> The core idea behind the resource management interface is that remembering to free allocated resources is hard. It appears to be especially hard for driver writers who, justly or not, have a reputation for adding more than their fair share of bugs to the kernel. And even the best driver writers can run into trouble in situations where device probing fails halfway through; the recovery paths may be there in the code, but they tend not to be well tested. The result of all this is a fair number of resource leaks in driver code.

提供这套资源管理接口的基本出发点是解决适时释放资源的难题。这是个一个令广大驱动开发人员倍感头痛的事情，驱动开发人员也因此常常被指责给内核引入了太多的 bug，虽然本文暂且不想去探讨这种指责是否有失公允。即使是最好的驱动开发人员，如果遇到设备探测中途失败的情况也会感到十分棘手；在他们的代码中一般也都会考虑失败发生后释放资源的操作，但常常由于条件限制很难被充分地测试。最终这些原因导致驱动程序给内核引入了大量资源泄漏问题。

> To address this problem, Tejun Heo created a new set of resource allocation functions which track allocations made by the driver. These allocations are associated with the device structure; when the driver detaches from the device, any left-over allocations are cleaned up. The resource management interface is thus similar to the [talloc() API](http://samba.org/ftp/unpacked/samba4/source/lib/talloc/talloc_guide.txt) used by the Samba hackers, but it is adapted to the kernel environment and covers more than just memory allocations.

为了解决这个问题，Tejun Heo 提出了一套全新的资源分配函数，可用于跟踪驱动代码中的资源分配。所有的资源分配都和对应的设备对象相关联; 当驱动程序与设备分离时，曾经分配给该设备的任何不再使用的资源都将被释放归还。这些资源管理调用接口非常类似于 Samba 系统中提供的 [talloc() API](http://samba.org/ftp/unpacked/samba4/source/lib/talloc/talloc_guide.txt) ，但更适用于内核环境，并且覆盖的不仅仅是内存资源分配。

> Starting with memory allocations, though, the new API is:

先从内存分配开始介绍，新的 API 是：
 
	void *devm_kzalloc(struct device *dev, size_t size, gfp_t gfp);
	void devm_kfree(struct device *dev, void *p);
 
> In a pattern we'll see repeated below, the new functions are similar to kzalloc() and kfree() except for the new names and the addition of the dev argument. That argument is necessary for the resource management code to know when the memory can be freed. If any memory allocations are still outstanding when the associated device is removed, they will all be freed at that time.

这些新函数，包括后面要介绍的，它们的形式很类似，先看以上两个，除了在函数名称上增加了前缀 `devm_` 以及添加了一个 `dev` 参数外，其他部分看上去和对应的 `kzalloc()` 和 `kfree()` 函数几乎一模一样。新增加的 `dev` 参数用于辅助资源管理模块的代码判断何时可以释放内存。如果在该设备被移除的时候其关联的任何内存仍未被释放，那么资源管理模块会检测出来并在此时自动完成释放操作。
 
> Note that there is no managed equivalent to kalloc(); if driver writers cannot be trusted to free memory, it seems, they cannot be trusted to initialize it either. There are also no managed versions of the page-level or slab allocation functions.

值得注意的是，内核没有提供对应于 `kalloc()` 的资源管理函数版本 ; 理由是如果在释放内存问题上驱动开发人员不值得被信任的话，那么在初始化内存这个问题上他们同样不能被信任（译者注，这里 `kalloc()` 应该是 `kmalloc()` 的笔误，另外 `kzalloc()` 和 `kmalloc()` 的主要区别是 `kzalloc()` 会在 `kmalloc()` 的基础上确保将申请的内存全部初始化为零，所以这里猜测内核不提供形如 `devm_kmalloc()` 这样的接口可能是出于一种推荐使用上的考虑，也就是鼓励大家多使用形如 `kzalloc()` 这样封装得更好的接口 ）。同样道理，在页面级别内存分配和 slab 分配上也没有提供相应的资源管理版本函数。

> Managed versions of a subset of the DMA allocation functions have been provided:

对应于 DMA 分配，内核编程接口的资源管理版本形式如下（注意内核提供的也只是一个子集，并没有对全部接口提供对应版本）：
 
	void *dmam_alloc_coherent(struct device *dev, size_t size,
			      dma_addr_t *dma_handle, gfp_t gfp);
	void dmam_free_coherent(struct device *dev, size_t size, void *vaddr,
			    dma_addr_t dma_handle);
	void *dmam_alloc_noncoherent(struct device *dev, size_t size,
			         dma_addr_t *dma_handle, gfp_t gfp);
	void dmam_free_noncoherent(struct device *dev, size_t size, void *vaddr,
			       dma_addr_t dma_handle);
	int dmam_declare_coherent_memory(struct device *dev, dma_addr_t bus_addr,
				     dma_addr_t device_addr, size_t size, 
				     int flags);
	void dmam_release_declared_memory(struct device *dev);
	struct dma_pool *dmam_pool_create(const char *name, struct device *dev,
				      size_t size, size_t align,
				      size_t allocation);
	void dmam_pool_destroy(struct dma_pool *pool);

> All of these functions have the same arguments and functionality as their dma_* equivalents, but they will clean up the DMA areas on device shutdown. One still has to hope that the driver has ensured that no DMA remains active on those areas, or unpleasant things could happen.

所有这些函数都具有与其对应的 `dma_*` 函数相同的参数和类似功能 ，但是在原有基础上会确保设备关闭时释放申请的 DMA 内存。注意资源管理模块只保证 DMA 内存会被释放，作为驱动代码来说依然要自己确保不要在 DMA 内存释放后还会去访问这些内存区域，否则会造成无法预期的后果。
 
> There is a managed version of pci_enable_device():

`pci_enable_device()` 函数的具备资源管理功能的版本如下 ：

	int pcim_enable_device(struct pci_dev *pdev);
 
> There is no pcim_disable_device(), however; code should just use pci_disable_device() as usual. A new function:

没有和 `pcim_disable_device()` 函数对应的版本; 我们仍然可以像过去一样使用 `pci_disable_device()` 来关闭 PCI 设备。另外一个资源管理模块提供的和 PCI 设备相关的新函数如下：

	void pcim_pin_device(struct pci_dev *pdev);
 
> will cause the given pdev to be left enabled even after the driver detaches from it.

调用该函数后会确保 `pdev` 所对应的设备在和驱动程序分离之后仍然处于启用状态（译者注，即不会因为对该设备曾经调用 `pcim_enable_device()` 而导致资源管理模块自动检测并关闭该设备）。
 
> The patch makes the allocation of I/O memory regions with pci_request_region() managed by default - there is no pcim_ version of that interface. The higher-level allocation and mapping interfaces do have managed versions:

针对 I/O 内存管理，设备资源管理补丁直接修改了现有的 `pci_request_region()` 函数的内部实现增加了相应的资源管理功能，并没有提供形如带有 `pcim_` 前缀的对应版本。但补丁对更高层次的分配和映射函数接口提供了资源管理版本，如下：

	void __iomem *pcim_iomap(struct pci_dev *pdev, int bar, 
                             unsigned long maxlen);
	void pcim_iounmap(struct pci_dev *pdev, void __iomem *addr);

> For the allocation of interrupts, the managed API is:

对于中断分配，相应的资源管理版本函数接口如下：
 
	int devm_request_irq(struct device *dev, unsigned int irq,
		         irq_handler_t handler, unsigned long irqflags,
		     	 const char *devname, void *dev_id);
	void devm_free_irq(struct device *dev, unsigned int irq, void *dev_id);

> For these functions, the addition of a struct device argument was required.

对于这些函数，注意添加了一个 `struct device` 的参数 `dev`。

> There is a new set of functions for the mapping of of I/O ports and memory:

对于 I/O 端口和内存的映射功能提供了一组新接口：

	void __iomem *devm_ioport_map(struct device *dev, unsigned long port,
				unsigned int nr);
	void devm_ioport_unmap(struct device *dev, void __iomem *addr);
	void __iomem *devm_ioremap(struct device *dev, unsigned long offset,
				unsigned long size);
	void __iomem *devm_ioremap_nocache(struct device *dev, 
					unsigned long offset,
					unsigned long size);
	void devm_iounmap(struct device *dev, void __iomem *addr);

> Once again, these functions required the addition of a struct device argument for the managed form.

同样注意出于资源管理的目的这些函数都新增了一个 `struct device` 的参数 `dev`。
 
> Finally, for those using the low-level resource allocation functions, the managed versions are:

最后，对于那些底层的资源分配函数，其资源管理版本有下面这些：
 
	struct resource *devm_request_region(struct device *dev,
				         resource_size_t start,
					 resource_size_t n, 
					 const char *name);
	void devm_release_region(resource_size_t start, resource_size_t n);
	struct resource *devm_request_mem_region(struct device *dev,
				             resource_size_t start,
					     resource_size_t n, 
					     const char *name);
	void devm_release_mem_region(resource_size_t start, resource_size_t n);

> The resource management layer includes a "group" mechanism, accessed via these functions:

资源管理层模块另外提供了一种所谓的 “组(group)” 机制，通过以下函数来使用：
 
	void *devres_open_group(struct device *dev, void *id, gfp_t gfp);
	void devres_close_group(struct device *dev, void *id);
	void devres_remove_group(struct device *dev, void *id);
	int devres_release_group(struct device *dev, void *id);

> A group can be thought of as a marker in the list of allocations associated with a given device. Groups are created with devres_open_group(), which can be passed an id value to identify the group or NULL to have the ID generated on the fly; either way, the resulting group ID is returned. A call to devres_close_group() marks the end of a given group. Calling devres_remove_group() causes the system to forget about the given group, but does nothing with the resources allocated within the group. To remove the group and immediately free all resources allocated within that group, devres_release_group() should be used.

“组”可以用来标识与给定设备相关联的一系列资源分配动作。我们可以使用 `devres_open_group()` 创建一个组并标识此后发生的资源分配都属于该组，调用该函数时可以通过参数 `id` 传入一个组的标识或者直接给空值 NULL 则该函数会自动生成该标识; 无论哪种方式，新建的组的标识都会通过函数的返回值返回。调用 `devres_close_group()` 可以标记给定组作用域结束。调用 `devres_remove_group()` 会删除当前组，但不会释放该组中分配的资源。要删除组并立即释放该组中分配的所有资源，应使用另一个函数 `devres_release_group()`。

> The group functions seem to be primarily aimed at mid-level code - the bus layers, for example. When bus code tries to attach a driver to a device, for example, it can open a group; should the driver attach fail, the group can be used to free up any resources allocated by the driver.

组函数看上去主要是供内核中的那些中间层组件 - 例如总线层 - 调用。例如，当总线代码尝试将驱动程序关联到一个设备时，它可以新建一个组; 如果驱动程序关联失败，内核可以利用该组记录的信息将驱动程序分配的资源全部释放掉。

> There are not many users of this new API in the kernel now. That may change over time as driver writers become aware of these functions, and, perhaps, as the list of managed allocation types grows. The reward for switching over to managed allocations should be more robust and simpler code as current failure and cleanup paths are removed.

现在内核中使用该新接口的用户还不多。但是随着驱动程序开发人员对这些函数的了解，以及随着资源管理类型的增加，这种状况可能会发生改变。使用该新接口的好处在于可以使我们的代码更健壮，伴随那些冗余的错误处理和清理代码被逐渐剔除，驱动的代码也会变得更简洁。

[1]: http://tinylab.org
