---
layout: post
author: 'Wang Chen'
title: "LWN 616859: 设备树动态叠加技术"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-616859/
description: "LWN 文章翻译，设备树动态叠加技术"
category:
  - 设备树
  - LWN
tags:
  - Linux
  - device tree
  - overlays
---

> 原文：[Device tree overlays](https://lwn.net/Articles/616859/)
> 原创：By Jonathan Corbet @ Oct 22, 2014
> 翻译：By Unicornx of [TinyLab.org][1]
> 校对：By [w-simon](https://github.com/w-simon)

> Pantelis Antoniou started his LinuxCon Europe session on device tree overlays by noting that the device tree concept often draws complaints — frequently of the inflammatory variety. Those complaints did not prevent the room from filling up to capacity, though — it would have been standing room only except that the on-site German fire marshals took their job seriously and would not allow standing in the sessions. Device trees as currently implemented in the kernel, Pantelis said, are also not up to the task of describing current hardware. Work done by him and others should rectify that situation in the near future, though.

Pantelis Antoniou 在 “Linux 欧洲开发者大会” 上给大家带来了名为 “设备树动态叠加技术” 的主题演讲，作为开场白他首先提到了当前人们对设备树概念的抱怨和强烈抵触情绪。尽管如此，参与会议的观众依然热情高涨，把整个会议室都给塞满了，如果不是在场边负责安全的德国消防队员们的认真坚持，估计会场的人们全都只好站着听完整场报告。Pantelis 在会上表示，目前在内核中对设备树的实现还做不到对当前硬件的全面支持。但包括他本人在内的团队计划在不久的将来改变这种状况。

> He started with an overview of the device tree concept: a device tree is essentially a text file that describes the hardware to the kernel. Since many architectures do not have self-describing hardware, some sort of externally supplied description is needed for the kernel to understand the system it is running on; device trees are the solution of choice in the Linux world. But, like most technologies, device trees have their shortcomings. The device tree language is another thing that software and hardware developers have to learn; to make things worse, it is a cryptic language that presents a lot of complexity to beginners. The fact that the current device tree compiler performs no syntax checks does not help the situation; the first indication of an incorrect device tree file is typically a failure to boot. Being purely data-driven, device tree files cannot contain any imperative logic. And so on.

他首先简单回顾了一下设备树的概念：设备树本质上是一个用于向内核描述硬件信息的文本文件。在许多体系架构上，硬件无法主动上报自身能力，因此内核需要通过外部提供的描述信息来了解它所运行的系统；设备树就是 Linux 世界中的首选解决方案。但是，像大多数其他技术一样，设备树自身也有缺陷。首先，用来描述设备树的语法对于软硬件开发人员来说是全新的；更糟的是，该语法十分晦涩，给初学者带来了相当大的困难。由于当前设备树编译器并不执行语法检查；所以通常情况下开发人员只有在使用设备树启动系统发生失败时才会发现设备树文件描述中的语法错误。此外设备树文件的描述信息只包含数据定义，并不包含任何指令性的逻辑。诸如此类，以上都是目前设备树的不足之处。

![PantelisAntoniou](https://static.lwn.net/images/conf/2014/lce-lpc/PantelisAntoniou.jpg)

> But the worst problem, according to Pantelis, is that the static nature of device trees makes them incapable of describing contemporary hardware. It is not always possible to know what the hardware will look like prior to booting the system, but device trees are set in stone at boot time. For a self-contained system like a phone handset, the static nature of device trees is not a big problem. But consider hardware like the [BeagleBone](https://lwn.net/Articles/576434/), which can have any of a number of add-on "cape" boards that augment the hardware. Creating a device tree file for every combination of boards and capes is not a viable solution. Assembling a device tree in the bootloader is possible but difficult, and it falls apart when faced with multiple capes stacked onto a single system. It would be far better to be able to piece together, at boot time or afterward, separate device tree fragments representing the board and the cape(s), ending up with a description of the full system.

但根据 Pantelis 的说法，最糟糕的问题还在于设备树自身固有的静态特性使得它无法适应最新的硬件发展需求。设备树要求在系统启动之前就配置好，但现实情况是，在系统启动之前并不总是能够知道硬件的实际情况。对于像手机这样的封闭系统来说，设备树的静态特性不是什么大问题。但是考虑到像 [BeagleBone](https://lwn.net/Articles/576434/) 这样的设备，它支持通过扩展板（BeagleBone 称之为 “cape”）的方式给主板（译者注，即 “baseboard”）添加新功能。为每个主板和扩展板的组合都创建一个对应的设备树文件绝不是一种可行的解决方案。在引导程序（bootloader）中实时组装一个设备树是可行的，但是具体实施起来会很困难，特别是当存在多个扩展板堆叠的情况时就更显得无能为力了。最好的方法是采用独立的设备树文件分别描述主板和扩展板，然后在系统引导过程中分别加载它们并动态完成合并，最终形成对整个系统的描述。

> This problem comes up in other settings as well. The Raspberry Pi supports "hats" for the addition of hardware. Hardware built around a field-programmable gate array (FPGA) can vary wildly in nature depending on the firmware loaded into the array; such hardware cannot possibly be supported by a static device tree. Hardware, Pantelis said, is software now. But Linux makes dealing with the new hardware unnecessarily complex, driving hardware hackers to simpler (but far less capable) systems like the Arduino.

在其他硬件设备中也存在同样的问题。树莓派（Raspberry Pi）也支持类似的扩展板机制。基于 FPGA （Field-Programmable Gate Array）构建外围电路时随着固件的变化，外围硬件的组合也会随之变化；这些类型的硬件都无法通过静态的设备树来支持。按照 Pantelis 的说法，硬件现在变得越来越 “软” 了。在这点上，由于 Linux 跟不上新硬件的发展，导致硬件骇客（hacker）倾向于选择更简单的系统（当然性能上有所欠缺），比如 Arduino。

> The first attempt to solve the problem (in the BeagleBone context) was a subsystem called "[capebus](https://lwn.net/Articles/522087/)." But this proposal did not last long once reviewers got a look at it. It was modeling the cape problem around a bus abstraction, but capes do not sit on a bus. So another approach was indicated; in the end, it was decided that dynamically altering the system's device tree to reflect the actual hardware was the right solution to the problem.

解决问题的第一个尝试（基于 BeagleBone 的开发环境）是新建了一个名为 [“capebus”](https://lwn.net/Articles/522087/) 的子系统。但是，这个提议并没有通过审核。原因是该方案试图将扩展板抽象为连接在一种叫做扩展板虚拟总线（译者注，即 capbus）上的设备，但这与实际的物理硬件状况并不相符。最终的方案决定从更加真实反映硬件实际情况的角度出发，采用动态改变设备树的方法来解决这个问题。

> A piece of the solution has been in the kernel for some time; it is controlled by the CONFIG_OF_DYNAMIC configuration option. It allows run-time modification of the device tree, but it is only used by the PowerPC architecture. Editing of the tree is destructive, meaning that changes cannot be reverted later; that is problematic for hardware that can be hot-removed from a running system. Changes are also not performed in an atomic manner. There is no connection to the device model code, so users must make any system topology changes independently. In short, it is a piece of the puzzle, but it is far from a complete solution.

内核中早就存在类似的一套解决方案，该特性通过 `CONFIG_OF_DYNAMIC` 配置选项进行控制。它允许在运行时动态修改设备树，但目前只在 PowerPC 架构上使用。该方法对设备树的修改是不可逆的，这意味着修改后无法回退到原来的状态；所以无法支持可以热插拔的硬件系统。此外该方案对设备树的更改也不是以原子方式执行。更要命的是该方案并没有和内核的设备驱动模型建立联动，因此设备树发生修改后用户必须额外采取手段对内核设备拓扑关系进行更新。简而言之，该方案一定程度上支持了设备树的动态修改，但离一个完备的解决方案还相差甚远。

> The first step toward that complete solution, Pantelis said, is to rework the dynamic device tree code. Some control files have been moved from /proc to /sys. Nodes in the device tree are now proper kobjects, so they have lifecycle management built into them. Some changes to better define the semantics of the reconfiguration notifiers have been made. This work was all merged into the 3.17 kernel.

Pantelis 介绍说，向完备性迈出的第一步是重新设计现有的动态设备树方案。一些原来在 `/proc` 下的控制文件被移到 `/sys` 下。设备树中的节点（node）被实现为驱动模型中的 kobjects 对象，从而具备了内置的生命周期管理特性。同时改进了配置通知器（reconfiguration notifiers）的语法定义。以上这些工作已全部合并到 3.17 版本的内核中。

> The second step is "the meat of the problem," according to Pantelis. It is often necessary for one part of a device tree to refer to another part; a camera sensor description, for example, may include a pointer to the I2C bus that carries the sensor's control channel. These references are called "phandles"; they are symbolic within the human-readable device tree, but converted to simple integer values by the device tree compiler. Pantelis had to extend the compiler to keep track of all phandles used; when requested (with the arguably strange "-@" command-line option), the compiler will store a sort of symbol table in the root of the compiled device tree with the list of all phandles in the tree.

根据 Pantelis 的说法，改进的第二步乃是 “关键所在”。设备树中的一部分通常需要引用另一部分的内容；举个例子，一个摄像头设备通过某个 I2C 总线传输其控制信号（译者注，这意味着在设备树中描述摄像头设备节点时需要说明其 “引用” 了另一个设备节点 - 一个 I2C 总线控制器设备，具体的实现是通过给被引用对象 - 这里的 I2C 设备 - 定义一个 “别名”，即下文提到的 “phandle”，然后在说明摄像头设备时通过该 “phandle” 引用其依赖的 I2C 设备 ）。这里用于引用的的 “别名” 在设备树语法中称之为 “phandles”（译者注，即 pointer handles 的缩写，有点类似于 Linux 文件系统中的符号链接）；在文本类型的设备树描述中它们是人可以读懂的字符串标识符，经过设备树编译器处理后会被转换为简单的整数值。Pantelis 扩展了编译器的实现，在解析一个设备树文件的过程中记录了所有引用 “phandles” 的地方；具体实现为：只要编译时带了 “-@” 命令行选项（这个选项看上去有点怪怪的），编译器就会在输出的设备树目标文件中的 root 节点下保存一个符号表用来记录树中所有对 “phandles” 的引用。

> This mechanism allows the loading of a device tree fragment into the system's current device tree. The new fragment will contain references to phandles in the main tree; the new in-kernel resolver code will fix up those references to match the real phandles in that tree. The resolver will also relocate all of the phandles in the new fragment to ensure that they are unique within the device tree as a whole and adjust any internal references accordingly.

基于该机制，在内核已经加载了一个基本的设备树的前提下，当我们稍后再加载另一个独立的设备树描述片段（fragment）到系统中时，如果新的片段包含对已知 “phandles” 的 “引用”，则改进后的内核解析器将重定位这些 “引用”，使其指向合适的对象。同时由于该片段（fragment）中也可能会有新定义的 “phandles”，解析器将首先确保它们在设备树中是唯一的，然后继续重定位设备树中对这些新 “phandles” 的 “引用”，也使其指向正确的对象。

> Step three is to add the concept of device tree changesets to the kernel. A call to of_changeset_init() starts the addition of a changeset; then new device tree pieces can be added with of_changeset_attach_node(). Once the pieces are in place, it's a matter of locking the device tree and calling of_changeset_apply(). If the change needs to be reverted in the future (perhaps the hardware in question has been hot-unplugged from the system), of_changeset_revert() will put things back as they were before.

修改的第三步是引入 “设备树变更集合” （device tree changesets）的概念。我们可以通过调用 `of_changeset_init()` 标识添加一组变更（译者注：指前面所述的片段 “fragment”）的开始；然后通过使用 `of_changeset_attach_node()` 实际添加新设备树片段。一旦添加完成，则需要先锁定设备树（译者注，通过调用 `mutex_lock(of_mutex)`），然后再调用 `of_changeset_apply()` 使修改生效。如果将来需要恢复曾经做过的更改（譬如从系统中移除先前插入的那个硬件设备），那么通过调用 `of_changeset_revert()` 将会实现设备树的回滚。

> With this infrastructure in place, device tree overlays can be supported. An overlay can add nodes to the tree, but it can also make changes to properties in the existing tree. In the simplest case, an overlay might just change a device node's status from "disabled" to "enabled." This feature is useful for hardware hackers, Pantelis said; hardware presence can be turned on or off easily with no need to reboot the system or to dig into C code.

设备树动态叠加功能基于以上修改得以实现。动态叠加过程中除了可以给现有设备树添加节点（nodes），还可以更改树中节点的属性（properties）。举一个最简单的例子，通过动态叠加，我们可以将设备节点的状态从 “禁用” （"disabled"）更改为 “启用” （"enabled"）。Pantelis 说，这个功能对硬件骇客（hackers）太有用了；这意味着我们可以方便地 “启用” 或者 “禁用” 硬件，而无需重新启动系统，更用不着改写程序。

> The resolver code was merged into the 3.18 kernel; full overlay support should come soon. In the future, there is an overlay-based FPGA manager in the works, along with a BeagleBone cape manager. There is also interest in using this feature to support multiple versions of a given board from a single device tree. The end result of all this work is that device trees have become more dynamic — and more capable — than they were when the kernel first started using them.

解析器的代码修改已经合入了内核版本 3.18；对设备树动态叠加的全面支持很快就会实现。当前，基于该技术正在开发一个 FPGA 管理器（FPGA manager），以及另一个 BeagleBone 扩展板管理器（cape manager）。还有人计划使用此功能来实现通过单个设备树支持单个系统的多个版本。所有这些工作都向社区表明，相比于刚开始被引入内核的阶段，设备树这套机制正变得更具动态性，变得更强大。

> [Your editor would like to thank the Linux Foundation for supporting his travel to LinuxCon Europe.]

[在此谨对 Linux 基金会给予本文作者参加 “Linux 欧洲开发者大会” 所提供的支持表示诚挚的感谢。]

[1]: http://tinylab.org
