---
layout: post
author: 'Wang Chen'
title: "LWN 448502: 平台设备和设备树"
album: lwn
group: translation
permalink: /lwn-448502-platform-devices-and-device-trees/
description: "LWN 文章翻译，平台设备和设备树"
category:
  - 设备树
  - LWN
tags:
  - Linux
  - platform device
  - device tree
---

> 原文：[Platform devices and device trees](https://lwn.net/Articles/448502/)
> 原创：By Jonathan Corbet @ June 21, 2011
> 翻译：By Unicornx of [TinyLab.org][1] @ Oct 10, 2017

> The [first part](https://lwn.net/Articles/448499/) of this pair of articles described the kernel's mechanism for dealing with non-discoverable devices: platform devices. The platform device scheme has a long history and is heavily used, but it has some disadvantages, the biggest of which is the need to instantiate these devices in code. There are alternatives coming into play, though; this article will describe how platform devices interact with the device tree mechanism.

[本系列文章的上篇](https://lwn.net/Articles/448499/)介绍了内核处理那些不能自动枚举的硬件(译者注，即平台设备)的方法。平台设备机制已经存在了很长一段时间并且被广泛应用，但该机制有一些缺点，其中最大的问题就是该方法要求采用硬编码的方式实例化硬件设备。然而情况有了一点变化，本文将继续介绍一种新的设备树机制是如何解决平台设备的问题的。

> The current platform device mechanism is relatively easy to use for a developer trying to bring up Linux on a new system. It's just a matter of creating the descriptions for the devices present on that system and registering all of the devices at boot time. Unfortunately, this approach leads to the proliferation of "board files," each of which describes a single type of computer. Kernels are typically built around a single board file and cannot boot on any other type of system. Board files sort of worked when there were relatively small numbers of embedded system types to deal with. Now Linux-based embedded systems are everywhere, architectures which have typically depended on board files (ARM, in particular) are finding their way into more types of systems, and the whole scheme looks poised to collapse under its own weight.

开发人员采用当前的平台设备处理机制来定制一个新的系统相对来说还是比较简单的。具体操作中只需要通过编码描述系统中的平台设备然后在系统引导过程中把它们注册到内核中即可。但不幸的是，由于针对每一种系统就要提供一个板级配置文件来描述系统的平台设备，所以这种处理方式会导致板级配置文件的数量急剧膨胀。具体制作内核时，每次只有一个板级配置文件参与编译，所以这么做出来的内核是无法在其他的系统上运行的。当嵌入式系统数目还不多的时候，板级配置文件这种做法还可行。但现在基于 Linux 的嵌入式系统随处可见，当越来越多的系统开始采用其架构的处理器时，如果该体系架构（尤以 ARM 为典型）依然采用板级配置文件这种机制来制作内核，则会发现，这种机制工作起来显得很笨拙。

> The hoped-for solution to this problem goes by the term "device trees"; in essence, a device tree is a textual description of a specific system's hardware configuration. The device tree is passed to the kernel at boot time; the kernel then reads through it to learn about what kind of system it is actually running on. With luck, device trees will abstract the differences between systems into boot-time data and allow generic kernels to run on a much wider variety of hardware.

解决的方法就是采用“设备树”；本质上来说，一个设备树就是一个特定系统的硬件配置的文本描述。在系统引导阶段该设备树描述被传递给内核；内核通过解析该描述得知其运行在一个什么样的系统之上。幸运的情况下，设备树可以将各种系统之间的差别全部在引导阶段就区分开，那么我们就可以只用一个通用的内核就可以支持非常广泛的不同类型的硬件平台了。

> [This article](http://devicetree.org/Device_Tree_Usage) is a good introduction to the device tree format and how it can be used to describe real-world systems; it is recommended reading for anybody interested in the subject.

[这篇文章](http://devicetree.org/Device_Tree_Usage)给出了设备树格式的很好的介绍以及它是如何被用来描述真实世界的系统的；推荐给所有对设备树感兴趣的人阅读。

> It is possible for platform devices to work on a device-tree-enabled system with no extra work at all, especially once [Grant Likely's improvements](https://lwn.net/Articles/448677/) are merged. If the device tree includes a platform device (where such devices, in the device tree context, are those which are direct children of the root or are attached to a "simple bus"), that device will be instantiated and matched against a driver. The memory-mapped I/O and interrupt resources will be marshalled from the device tree description and made available to the device's probe() function in the usual way. The driver need not know that the device was instantiated out of a device tree rather than from a hard-coded platform device definition.

一旦[Grant Likely 的改进补丁](https://lwn.net/Articles/448677/)被合入内核主线后，很有可能无需额外的工作我们就可以让平台设备在一个使用设备树的系统上运行起来。特别地，当系统的平台设备在设备树中是直接作为根节点的一级子节点被描述的，或者这些平台设备是连接在一个“简单总线”上时，内核能够自动帮助我们创建对应的设备对象同时匹配其驱动。内存映射端口和中断方面的资源信息会自动从设备树的描述中被提取出来并通过 `probe()` 函数被传递给驱动。在这种情况下，驱动无需关心该平台设备是通过旧的基于硬编码方式定义的还是通过设备树由内核自动创建的。

> Life is not always quite that simple, though. Device names appearing in the device tree (in the "compatible" property) tend to take a standardized form which does not necessarily match the name given to the driver in the Linux kernel; among other things, device trees really are meant to work with more than one operating system. So it may be desirable to attach specific names to a platform device for use with device trees. The kernel provides an of_device_id structure which can be used for this purpose:

但现实情况并不总是那么简单的。为了不使设备树的定义捆绑在一个操作系统上，设备树中设备的名字（填写在 "compatible" 属性中）的命名方式应该刻意避免和 Linux 中驱动定义的的名字相同。所以实际情况是我们需要反过来在驱动中为平台设备按照设备树的命名配置匹配的名字。内核提供了可用于此目的的 `of_device_id` 结构体类型：

	static const struct of_device_id my_of_ids[] = {
		{ .compatible = "long,funky-device-tree-name" },
		{ }
	};

> When the platform driver is declared, it stores a pointer to this table in the driver substructure:

定义平台驱动时，将该表的指针赋值给驱动对象结构体成员。


	static struct platform_driver my_driver = {
		/* ... */
		.driver	= {
			.name = "my-driver",
			.of_match_table = my_of_ids
		}
	};

> The driver can also declare the ID table as a device table to enable autoloading of the module as the device tree is instantiated:

驱动也可以通过如下宏声明该名字列表，这么做可以确保当设备树被实例化的时候能够自动将该驱动模块加载进来。

	MODULE_DEVICE_TABLE(of, my_of_ids);

> The one other thing capable of complicating the situation is platform data. Needless to say, the device tree code is unaware of the specific structure used by a given driver for its platform data, so it will be unable to provide that information in that form. On the other hand, the device tree mechanism is equipped to allow the passing of just about any information that the driver may need to know. Making use of that information will require the driver to become a bit more aware of the device tree subsystem, though.

另外一个会使问题复杂化的因素和平台设备数据有关。毫无疑问，由于平台设备数据的结构体定义是驱动自己定义的，设备树子系统不可能了解，所以在设备树中对平台设备数据的描述格式是一种和驱动无关的通用描述，包含了所有驱动可能需要的数据。反过来说，驱动倒是需要了解一点设备树的描述格式以便从设备树描述中提取自己关心的数据内容。

> Drivers expecting platform data should check the dev.platform_data pointer in the usual way. If there is a non-null value there, the driver has been instantiated in the traditional way and device tree does not enter into the picture; the platform data should be used in the usual way. If, however, the driver has been instantiated from the device tree code, the platform_data pointer will be null, indicating that the information must be acquired from the device tree directly.

一般来说，期望提取平台设备数据内容的驱动需要检查 `dev.platform_data` 指针。如果该值非空，说明内核是采用传统的非设备树的方式（译者注，即板级配置方式）初始化的，则驱动可以按照传统的方式对平台设备数据进行处理。如果系统是使用设备树初始化的，则该指针值为空，那么驱动就要尝试从设备树中提取信息。

> In this case, the driver will find a device_node pointer in the platform devices `dev.of_node` field. The various device tree access functions (`of_get_property()`, primarily) can then be used to extract the needed information from the device tree. After that, it's business as usual.

在使用设备树的情况下，驱动应该可以通过平台设备变量 `dev.of_node` 得到一个 `device_node` 类型的指针。以这个指针为入参，驱动可以调用访问设备树的 API （主要是 `of_get_property()`）来从设备树中提取需要的信息。其他的处理和以前没什么不同。

> In summary: making platform drivers work with device trees is a relatively straightforward task. It is mostly a matter of getting the right names in place so that the binding between a device tree node and the driver can be made, with a bit of additional work required in cases where platform data is in use. The nice result is that the static platform_device declarations can go away, along with the board files that contain them. That should, eventually, allow the removal of a bunch of boilerplate code from the kernel while simultaneously making the kernel more flexible.

总而言之，使平台设备驱动与设备树一起工作是一件相对直接的工作。主要的工作在于能够提供正确的名字以便内核根据设备树节点的定义将设备和相应的驱动绑定起来，除此之外还有一点对平台设备数据的处理。采用设备树机制后最好的结果是不再需要定义 `platform_device` 类型的静态定义，同时内核中的大量板级模版代码也可以被移除，这样内核也会变得更加轻便灵活。

[1]: http://tinylab.org
