---
layout: post
author: 'Wang Chen'
title: "LWN 357487: 内核峰会 2009: 通用设备树"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-357487-generic-device-trees/
description: "LWN 文章翻译，内核峰会 2009: 通用设备树"
category:
  - 设备树
  - LWN
tags:
  - Linux
  - device tree
---

> 原文：[KS2009: Generic device trees](https://lwn.net/Articles/357487/)
> 原创：By Jonathan Corbet @ October 19, 2009
> 翻译：By Unicornx of [TinyLab.org][1]
> 校对：By [WH2136](https://github.com/WH2136)

> Device trees have been the subject of some acrimonious mailing list discussions in the past, but developers don't always have a good sense for what the term means. In an effort to clarify the situation, Grant Likely and Ben Herrenschmidt ran a session on how this abstraction works.

过去一段时间以来，设备树成为内核邮件列表中的一个颇具争议的话题，但仍有不少开发人员并不十分清楚设备树是什么。为了解释清楚这个概念，Grant Likely 和 Ben Herrenschmidt 在峰会上为此做了一个专题报告。

> In essence, a device tree is a data structure for describing the hardware on a system. It has its origins in OpenFirmware, and it retains the format which was laid out there. The tree structure is simple, containing nodes (devices) which have an arbitrary number of properties. A typical device tree entry looks something like the following (taken from arch/powerpc/boot/dts/ep88xc.dts in the kernel source):

本质上来说，设备树是一个用于描述系统上硬件设备情况的数据结构。其概念来自 OpenFirmware，并采用了相同的格式。设备树的结构非常简单，由多个节点 (node)，即设备 (device) 构成，每个节点可以包含任意多个属性 (property)。一个典型的设备树的节点的例子如下所示 (例子来自内核源码的 `arch/powerpc/boot/dts/ep88xc.dts` )
	
	ethernet@e00 {
		device_type = "network";
		compatible = "fsl,mpc885-fec-enet",
					 "fsl,pq1-fec-enet";
		reg = <0xe00 0x188>;
		local-mac-address = [ 00 00 00 00 00 00 ];
		interrupts = <3 1>;
		interrupt-parent = <&PIC>;
		phy-handle = <&PHY0>;
		linux,network-index = <0>;
	};

> Most of the fields should be relatively self-explanatory; this node describes an Ethernet adapter, where its hardware resources are to be found, how it is connected into the system, and so on.

绝大部分字段是自解释的；这个节点描述了一个以太网适配器的基本信息，包括其硬件资源的分配情况以及该设备与系统中其他设备的关系等等。

> Traditionally, embedded Linux kernels run on special-purpose systems with hardware which cannot be probed for automatically. The configuration of the system usually comes down to some board-specific platform code which knows how the hardware has been put together. Device trees are an attempt to move that information out of the code and into a separate data structure. When done right, device trees can make it possible for a single kernel to support a wide range of boards - something which is hard to do when the system configuration is hardwired into the code. It can even be possible to support systems which do not exist when the kernel is built.

传统上，运行嵌入式 Linux 的专有系统上存在一些不支持自动检测的硬件设备。为此需要在内核中编写一些板级平台相关代码来向内核描述这些硬件设备是如何组装在一起成为一个系统的。设备树概念引入的目的就是试图将这些硬编码内容以配置的形式从内核中独立出来。如果处理得当的话，完全可以只用一份通用的内核镜像，再加上多份设备树配置文件来支持形式多样的硬件系统，而这是采用原来硬编码的方式所难以完成的。基于设备树的概念，我们甚至可以做到在硬件系统还未完全成型之前就完成内核镜像的制作。

> Device tree proponents assert that the "board port mindset" is broken. It should not be necessary to modify the kernel for each board which comes along. These modifications, beyond being ugly and painful, lead to a lot of ifdefs and platform-specific code paths in the kernel, all of which is hard to maintain. Device trees also make it possible to get the hardware configuration from a running kernel, even if the vendor is otherwise not forthcoming with that information.

设备树的拥护者宣称旧有的 “板级移植模式” 已经过时了。未来再也不需要为每种开发板分别修改内核代码。这些为了移植而增加的内核代码不仅十分晦涩难懂，而且充斥了 `ifdefs` 等条件编译语句以及平台 (platform) 设备相关的执行逻辑，很难维护。设备树的另外一个好处是，针对任何一个可以运行的内核，我们都能很方便地获取硬件的配置信息（译者注，指通过阅读设备树的描述获得这些硬件信息），就算供应商没有提供现成的硬件资料手册也没关系。

> The device tree abstraction is used by the PowerPC and MicroBlaze architectures now. There is a lot of interest in using it in the ARM architecture code, but the ARM maintainer is a bit skeptical of the idea. Still, it seems like it might be possible to convince him by carefully porting a subarchitecture or two to device trees first. There were some supportive words from the audience; Greg Kroah-Hartman liked how device trees made it possible to remove static device structures from the kernel, while Thomas Gleixner observed that his employees are much happier about doing ports to boards where device trees are used than to other systems. So the use of device trees in the kernel may expand, but, to a great extent, that depends on architecture maintainers who were not present at the summit.

当前 PowerPC 和 MicroBlaze 架构已经采纳了设备树的概念。内核开发者在 ARM 架构上尝试设备树的兴趣也很浓厚但 ARM 架构的主要维护人员对这一新事物仍然持保留态度。为了说服他看上去有必要先基于设备树移植一两个子系统看看效果。与会的观众中有不少支持的声音；Greg Kroah-Hartman 表示他非常喜欢设备树，因为使用它可以清理内核中那些静态的描述设备信息的结构，而 Thomas Gleixner 则指出，他的员工更加乐于在使用设备树的系统上开展移植工作。据此看来设备树在内核上的使用会逐步为大家所接受，当然很大程度上这仍然依赖于体系架构的维护人员的态度，可惜的是他们并没有出席此次峰会。
