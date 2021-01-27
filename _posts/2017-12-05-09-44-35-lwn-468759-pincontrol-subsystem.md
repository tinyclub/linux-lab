---
layout: post
author: 'Wang Chen'
title: "LWN 468759: 引脚控制子系统"
album: "LWN 中文翻译"
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-468759/
description: "LWN 文章翻译，引脚控制子系统"
category:
  - 设备驱动
  - LWN
tags:
  - Linux
  - pin control
---

> 原文：[The pin control subsystem](https://lwn.net/Articles/468759/)
> 原创：By Jonathan Corbet @ Nov 22, 2011
> 翻译：By [unicornx](https://gitee.com/unicornx)
> 校对：By Tacinight & Falcon of [TinyLab.org][1]

> Classic x86-style processors are designed to fit into a mostly standardized system architecture, so they all tend, in a general sense, to look alike. One of the reasons why it is hard to make a general-purpose kernel for embedded processors is the absence of this standardized architecture. Embedded processors must be extensively configured, at boot time, to be able to run the system they are connected to at all. The 3.1 kernel saw the addition of the "pin controller" subsystem which is intended to help with that task; enhancements are on the way for (presumably) 3.2 as well. This article will provide a superficial overview of how the pin controller works.

经典的 x86 架构处理器设计致力于适应大多数标准化的系统架构，因此它们在接口上一般都尽可能地类似。而对于嵌入式处理器，之所以很难提供一个通用的内核，其主要原因之一就在于在架构上没有实现标准化。与嵌入式处理器相连接的系统千差万别，所以内核必须要通过复杂的配置才能够顺利地引导这些系统。为了支持该工作，3.1 版本的内核引入了一个全新的“引脚控制器”子系统; 该子系统目前还不够完善，想必随着 3.2 版内核的开发，针对该子系统的改进还会随之添加。本文将对该引脚控制器的工作原理给出一个入门级的介绍。

> A typical system-on-chip (SOC) will have hundreds of pins (electrical connectors) on it. Many of those pins have a well-defined purpose: supplying power or clocks to the processor, video output, memory control, and so on. But many of these pins - again, possibly hundreds of them - will have no single defined purpose. Most of them can be used as general-purpose I/O (GPIO) pins that can drive an LED, read the state of a pushbutton, perform serial input or output, or activate an integrated pepper spray dispenser. Some subsets of those pins can be organized into groups to serve as an I2C port, an I2S port, or to perform any of a number of other types of multi-signal communications. Many of the pins can be configured with a number of different electrical characteristics.

一个典型的片上系统（system-on-chip，简称 SOC）会有数百个引脚（电气连接线）。许多引脚具有明确的目的：譬如为处理器提供电源或时钟，视频输出，内存控制等。但是，其中的许多引脚 - 数量可能达到数百个之多 - 其功能定义并不单一。它们中的大多数可以被定义为通用输入 / 输出引脚（GPIO），用于控制 LED 灯的亮与灭，或者读取按键的状态，执行串行的输入或输出，乃至在一个集成的胡椒喷雾器设备中用于控制其工作状态。这些引脚中的一部分还可以被组织起来以分组的形式定义，用于实现 I2C 或者 I2S 这些包含多个电气信号的总线标准接口（译者注，I2C 接口至少需要两条信号线，一条数据线 SDA 和一条时钟线 SCL，而 I2S 接口至少需要三条信号线：串行时钟 SCK，声道选择 WS 和串行数据线 SD）。除此之外，片上系统的许多引脚还支持其他多种电气特性的配置。

> Without a proper configuration of its pins, an SOC will not function properly - if at all. But the right pin configuration is entirely dependent on the board the SOC is a part of; a processor running in one vendor's handset will be wired quite differently than the same processor in another vendor's cow-milking machine. Pin configuration is typically done as part of the board-specific startup code; the system-specific nature of that code prevents a kernel built for one device from running on another even if the same processor is in use. Pin configuration also tends to involve a lot of cut-and-pasted, duplicated code; that, of course, is the type of code that the embedded developers (and the ARM developers in particular) are trying to get rid of.

只有对这些引脚进行正确的配置，SOC 才能正常工作。但是正确的引脚配置完全取决于使用该 SOC 的电路板上和 SOC 所连接的其他元器件的布局与设计；可以想象即便是同一款处理器芯片，当它被用在一台手机中时其引脚连接的定义和它被用在另一款挤奶机中时的引脚连接定义一定是完全不同的。引脚配置工作通常作为特定的板级启动代码存在；由于这些代码和运行它的特定系统紧密相关，造成了无法提供一款通用的内核支持所有产品，即使它们采用的是相同的处理器也一样会存在这个问题。针对不同系统的引脚配置代码往往是重复而冗余的；这也是嵌入式开发人员（特别是针对 ARM 架构开发的程序员）所迫切希望改进的地方。

> The idea behind the pin control subsystem is to create a centralized mechanism for the management and configuration of multi-function pins, replacing a lot of board-specific code. This subsystem is quite thoroughly documented in [Documentation/pinctrl.txt](https://lwn.net/Articles/465077/). A core developer would use the pin control code to describe a processor's multi-function pins and the uses to which each can be put. Developers enabling a specific board can then use that configuration to set up the pins as needed for their deployment.

内核提供一个引脚控制子系统的初衷是创建一套集中的机制用于管理和配置多功能引脚，避免上述冗余重复的板级配置代码。这个子系统的详细介绍参考内核文档 [Documentation/pinctrl.txt][2]。内核开发人员可以利用该子系统提供的接口为处理器定义一个引脚控制器，描述清楚该处理器的引脚复用情况。而针对特定电路板定制内核的开发人员则可以基于该引脚控制器来配置引脚。

> The first step is to tell the subsystem which pins the processor provides; that is a simple matter of enumerating their names and associating each with an integer pin number. A call to pinctrl_register() will make those pins known to the system as a whole. The mapping of numbers to pins is up to the developer, but it makes sense to, for example, keep a bank of GPIO pins together to simplify coding later on.

定义引脚控制器的第一步是向内核引脚控制子系统描述清楚处理器提供的引脚情况；对每个引脚的描述包含该引脚的名称以及与之对应的一个整数类型的引脚编号。如果要向内核注册这些引脚可以调用 `pinctrl_register()` 函数。引脚的数字编号顺序取决于开发人员，但是原则上，编号要保证关联性，譬如一组相关的 GPIO 引脚可以在一起编号，这对以后使用上的便捷性是有积极意义的。

> One of the interesting things about multi-function pins is that many of them can be assigned as a group to an internal functional unit. As a simple example, one could imagine that pins 122 and 123 can be routed to an internal I2C controller. Other types of ports may take more pins; an I2S port to talk to a codec needs at least three, while SPI ports need four. It is not generally possible to connect an arbitrary set of pins to any controller; usually an internal controller has a very small number of possible routings. These routings can also conflict with each other; pin 77, say, could be either an I2C SCL line or an SPI SCLK line, but it cannot serve both purposes at the same time.

多功能引脚的一个有趣的地方在于，它们中的许多引脚可以按组被分配给一个内部功能单元作为输入输出。举一个简单的例子，122 号引脚和 123 号引脚在芯片内部可以被路由到一个 I2C 控制器。其他类型的接口可能需要更多的引脚; 一个与编解码器通信的 I2S 接口至少需要三个引脚，而 SPI 接口需要四个。通常基于设计并不可以任意组合引脚并将它们分配给任意一个内部的控制器；通常连接内部控制器的路由只有很少的几种可能。这些路由也可能相互冲突；譬如编号为 77 的引脚可以被设置为 I2C 接口的 SCL线 或 SPI 接口的 SCLK 线，但它不能同时用于这两个目的。

> The pin controller allows the developer to define "pin groups," essentially named arrays of pins that can be assigned as a group to a controller. Groups can (and often will) overlap each other; the pin controller will ensure that overlapping groups cannot be selected at the same time. Groups can be associated with "functions" describing the controllers to which they can be attached. Some functions may have a single pin group that can be used; others will have multiple groups.

引脚控制器允许开发人员定义“引脚组”，基本上一个“引脚组”对应着一个引脚编号的数组。“引脚组”中的引脚编号可以（并且经常会）彼此重叠；引脚控制器将确保实际工作时相互冲突的组不能被同时选中。组可以与特定的“功能”相关联（所谓功能，对应着芯片内部的一个功能控制器）。某些“功能”可能只与一个“引脚组”关联；也存在一个“功能”对应多个“引脚组”的情况。

> There are some other bits and pieces (some glue to make the pin controller work easily with the GPIO subsystem, for example), but the above describes most of the functionality found in the 3.1 version of the pin controller. Using this structure, board developers can register one or more pinmux_map structures describing how the pins are actually wired on the target system. That work can be done in a board file, or, presumably, be generated from a device tree file. The pin controller will use the mapping to ensure that no pins have been assigned to more than one function; it will then instruct the low-level pinmux driver to configure the pins as described. All of that work is now done in common code.

除此之外引脚控制子系统还具备一些其他的功能（例如提供一些辅助函数和结构体方便引脚控制器与 GPIO 子系统一起工作），但是上面的介绍已经基本涵盖了 3.1 内核版本所提供的引脚控制子系统的绝大部分功能。板级开发人员可以通过定义不止一个 `pinmux_map` 结构体来描述实际系统上引脚的连接情况并将其注册到内核中。该工作可以在板级配置文件中完成，或者通过定义设备树来由内核自动生成。引脚控制器将使用我们提供的映射信息来确保引脚不会被重复被分配给多个功能；同时它还会自动触发底层的管脚复用 (pinmux) 驱动程序按照我们的配置来设置引脚的工作状态。所有这些工作现在都由通用子系统代码完成。

> The pin multiplexer on a typical SOC can do a lot more than just assign a pin to a specific function, though. There is typically a wealth of options for each pin. Different pins can be driven to different voltages, for example; they can also be connected to pull-up or pull-down resistors to bias a line to a specific value. Some pins can be configured to detect input signal changes and generate an interrupt or a wakeup event. Others may be able to perform debouncing. It adds up to a fair amount of complexity which is often reflected in the board-specific setup code.

典型的一款 SOC，在其支持引脚复用功能的同时除了可以给引脚分配更多功能外，每个引脚还能支持非常多的配置选项。例如，可以通过配置内接上拉或者下拉电阻来设定引脚的偏置电压。某些引脚可以配置为通过检测输入信号变化可以产生中断或唤醒事件。还有一些引脚可以配置为支持去抖。引脚的这些功能增加了相当多的复杂性，这通常反映在板级特定的设置代码中。

> The [generic pin configuration interface](https://lwn.net/Articles/468770/), currently in its third revision, attempts to bring the details of pin configuration into the pin controller core. To that end, it defines 17 (at last count) parameters that might be settable on a given pin; they vary from the value of the pullup resistor to be used through slew rates for rising or falling signals and whether the pin can be a source of wakeup events. With this code in place, it should become possible to describe the complete configuration of complex pin multiplexors entirely within the pin controller.

以上需求所涉及的[通用引脚配置接口][3]，仍然由引脚控制子系统提供，目前还在开发中，处于第三次修订阶段。截至目前为止，接口支持为给定引脚提供最多 17 个参数选项设置；这些选项包括：上拉电阻的阻值设定；电压上升沿和下降沿检测中涉及的电压转换速率（slew rate）；以及引脚是否可以作为唤醒事件的来源等。等该功能完成后，我们就可以使用引脚控制子系统提供的接口对复杂的引脚多路复用进行完整的配置。

> The number of pin controller users in the 3.1 kernel is relatively small, but there are a number of patches circulating to expand its usage. With the addition of the configuration interface (in the 3.2 kernel, probably), there will be even more reason to make use of it. One of the more complicated bits of board-level configuration will be supported almost entirely in common code, with all of the usual code quality and maintainability benefits. It is hard to stick a pin into an improvement like that.

当前 3.1 版本的内核中，使用引脚控制子系统的用户数量还相对较少，但是围绕该子系统已经提供了一些补丁。随着配置接口的进一步完善（期望在 3.2 版内核中可以完成支持），我们将有更多的理由使用它。引入该子系统后板级配置中相对比较复杂的这部分内容（译者注：管脚配置）几乎都可以通过内核的通用代码所支持了，这对代码质量的提高和可维护性都是受益匪浅的事情，何乐而不为呢。

[1]: http://tinylab.org
[2]: https://lwn.net/Articles/465077/
[3]: https://lwn.net/Articles/468770/
