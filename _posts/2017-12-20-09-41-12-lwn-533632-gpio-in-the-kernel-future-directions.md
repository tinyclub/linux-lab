---
layout: post
author: 'Wang Chen'
title: "LWN 533632: 内核 GPIO 子系统的未来发展方向"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-533632/
description: "LWN 文章翻译，内核 GPIO 子系统的未来发展方向"
category:
  - 设备驱动
  - LWN
tags:
  - Linux
  - GPIO
---

> 原文：[GPIO in the kernel: future directions](https://lwn.net/Articles/533632/)
> 原创：By Jonathan Corbet @ Jan 23, 2013
> 翻译：By Unicornx of [TinyLab.org][1] @ Nov 24, 2017
> 校对：By [lljgithub](https://github.com/lljgithub)

> [Last week's article](https://lwn.net/Articles/532714/) covered the kernel's current internal API for general-purpose I/O (GPIO) lines. The GPIO API has seen relatively little change in recent years, but that situation may be about to change as the result of a couple of significant patch sets that seek to rework how the GPIO API works in the interest of greater robustness and better performance.

[上周的文章](/lwn-532714)介绍了内核中有关 “通用目的输入输出”（General-Purpose I/O，下文简称 GPIO）API 的当前状态。这些年来，GPIO 的 API 几乎没有什么大的改动，但这种局面很快就会发生变化，因为最近社区提出了一些致力于改善其鲁棒性以及性能的重要补丁。

### 不再使用整数类型的引脚标识符 (No more numbers)

> The current GPIO API relies on simple integers to identify specific GPIO lines. It works, but there are some shortcomings to this approach. Kernel code is rarely interested in "GPIO #37"; instead, it wants "the GPIO connected to the monitor's DDC line" or something to that effect. For well-defined systems where the use of GPIO lines never changes, preprocessor definitions can be used to identify lines, but that approach falls apart when the same GPIO can be put to different uses in different systems. As hardware gets more dynamic, with GPIOs possibly showing up at any time, there is no easy way to know which GPIO goes where. It can be easy to get the wrong one by mistake.

目前的 GPIO API 使用简单的整数来标识不同的 GPIO 引脚。该方法有效但存在如下缺点。内核程序员其实很少关注形如 “编号为 37 的 GPIO 引脚” 这样的概念；相反，我们更关心诸如 “连接到显示器的 DDC 线的那个 GPIO 引脚” 这样的描述信息。对于那些引脚功能定义明确，很少改变的系统来说，采用宏定义的方式来给 GPIO 引脚编号是可以的，但是在那种会复用 GPIO 引脚的系统中，这么做就会导致问题。当前硬件的配置变得越来越灵活，每个 GPIO 引脚的功能也不再是固定不变的了，所以很难有简单的方法可以预先知道每个 GPIO 引脚的功能。再采用固定的整数方式进行编号很容易导致问题。

> As a result, platform and driver developers have come up with various ways to locate GPIOs of interest. Even your editor once submitted a [patch adding a gpio_lookup() function](https://lkml.org/lkml/2009/10/10/162) to the GPIO API, but that patch didn't pass muster and was eventually dropped in favor of a driver-specific solution. So the number-based API has remained — until now.

因此，平台和驱动的开发人员想出了各种方法来对自己关心的 GPIO 进行编号。作者本人也曾经提交过一个相关补丁 [“新增一个 gpio_lookup() 函数”](https://lkml.org/lkml/2009/10/10/162)，但最终该补丁未获通过而是选择在驱动层实现。总之，到目前为止内核中的 API 依然是使用整数编号来标识 GPIO 引脚的。

> Alexandre Courbot's [descriptor-based GPIO interface](https://lwn.net/Articles/531848/) seeks to change the situation by introducing a new struct gpio_desc * pointer type. GPIO lines would be represented by one of these pointers; what lives behind the pointer would be hidden from GPIO users, though. Internally, gpiolib (the implementation of the GPIO API used by most architectures) is refactored to use descriptors rather than numbers, and a new set of functions is presented to users. These functions will look familiar to users of the current GPIO API:

Alexandre Courbot 提交了一个新的补丁[“基于描述符的 GPIO 接口”](https://lwn.net/Articles/531848/)，试图通过引入一个新的结构体类型 `struct gpio_desc` 来改进当前的实现。GPIO 引脚对象将由该结构体类型指针来标识；所有的细节内容由该结构体类型所封装。在 gpiolib 内部（ gpiolib 模块封装实现了大多数体系结构所使用的 GPIO API）标识符被重构为使用描述符而不再是数字，同时提供了一套新的用户接口函数。这些函数对于当前 GPIO API 的用户来说看起来很熟悉：

	#include <linux/gpio/consumer.h>
	
	int gpiod_direction_input(struct gpio_desc *desc);
	int gpiod_direction_output(struct gpio_desc *desc, int value);
	int gpiod_get_value(struct gpio_desc *desc);
	void gpiod_set_value(struct gpio_desc *desc, int value);
	int gpiod_to_irq(struct gpio_desc *desc);
	int gpiod_export(struct gpio_desc *desc, bool direction_may_change);
	int gpiod_export_link(struct device *dev, const char *name,
			struct gpio_desc *desc);
	void gpiod_unexport(struct gpio_desc *desc);

> In short: the gpio_ prefix on the existing GPIO functions has been changed to gpiod_ and the integer GPIO number argument is now a struct gpio_desc *. There is also a new include file for the new functions; otherwise the interfaces are identical. The existing, integer-based API still exists, but it has been reimplemented as a layer on top of the descriptor-based API shown here.

简而言之：现有 GPIO 接口函数的 `gpio_` 前缀被修改为 `gpiod_`，原整数类型的 GPIO 编号参数被替换为一个结构体类型的指针 `struct gpio_desc *`。如果要使用这套新接口函数需要包含新的头文件（译者注：指上面代码中的 `#include <linux/gpio/consumer.h>`）； 除此之外两套接口是完全相同的。现有的基于整数的 API 仍然存在，但是它们已经被实现为一个封装层，内部直接调用新的基于描述符的 API 。

> What is missing from the above list, though, is any way of obtaining a descriptor for a GPIO line in the first place. One way to do that is to get the descriptor from the traditional GPIO number:

但是，要使用以上函数的前提是要首先获得 GPIO 引脚的描述符。一种方法是调用下列函数基于传统的 GPIO 整数类型编号获取对应的描述符：

	struct gpio_desc *gpio_to_desc(unsigned gpio);

> There is also a desc_to_gpio() for going in the opposite direction. Using this function makes it easy to transition existing code over to the new API. Obtaining a descriptor in this manner will ensure that no code accesses a GPIO without having first properly obtained a descriptor for it, but it would be better to do away with the numbers altogether in favor of a more robust way of looking up GPIOs. The patch set adds this functionality in this form:

系统提供了另一个函数 `desc_to_gpio()` 实现相反的功能。使用此函数（译者注，指 `gpio_to_desc()`）可以轻松地将现有的代码转换为使用新的 API。遵循这种方式总是可以保证代码使用正确的描述符去访问对应的 GPIO 引脚，但这么做显然还不够彻底，最好的方法是彻底避免直接使用整数类型的编号来查找 GPIO 引脚。补丁集提供以下函数支持这种能力：
 
	struct gpio_desc *gpiod_get(struct device *dev, const char *name);

> Here, dev should be the device providing the GPIO line, and "name" describes that line. The dev pointer is needed to disambiguate the name, and because code accessing a GPIO line should know which device it is working through in any case. So, for example, a video acquisition bridge device may need access to GPIO lines with names like "sensor-power", "sensor-reset", "sensor-i2c-clock" and "sensor-i2c-data". The driver could then request those lines by name with gpiod_get() without ever having to be concerned with numbers.

这里，参数 `dev` 是提供 GPIO 引脚的设备，`name` 是该引脚的描述。提供 `dev` 指针的作用是确保 `name` 不存在歧义，当然调用该函数的用户也应该很清楚地知道其当前访问的 GPIO 引脚是由哪个设备提供。举个例子，我们可以给某个视频采集桥接设备的一些 GPIO 引脚根据其功能分别命名为 "sensor-power"，"sensor-reset"，"sensor-i2c-clock" 和 "sensor-i2c-data"。驱动程序可以使用这些名字作为参数 `name` 来调用 `gpiod_get()`，而不必再关心那些整数的引脚编号。

> Needless to say, there is a gpiod_put() for releasing access to a GPIO line.

对应地，还有一个 `gpiod_put()` 函数来负责释放对 GPIO 引脚的访问。

> The actual association of names with GPIO lines can be done by the driver that implements those lines, if the names are static and known. In many cases, though, the routing of GPIO lines will have been done by whoever designed a specific system-on-chip or board; there is no way for the driver author to know ahead of time how a specific system may be wired. In this case, the names of the GPIO lines will most likely be specified in the device tree, or, if all else fails, in a platform data structure.

对于一些固定不变的或者众所周知的通用功能所对应的 GPIO 引脚，其名称（译者注：`name` 值） 可以由实现它们的驱动程序定义。但在许多情况下，GPIO 引脚具体对应的功能是由设计特定片上系统（SOC）或电路板的人员确定的，驱动程序开发人员并无法事先知道特定系统的排线情况。在这种情况下，GPIO 引脚的名称可以在设备树中指定，如果以上条件都不满足的话，则通过平台数据（platform data）进行定义。

> The response to this interface is generally positive; it seems almost certain that it will be merged in the near future. The biggest remaining concern, perhaps, is that the descriptor interface is implemented entirely within the gpiolib layer. Most architectures use gpiolib to implement the GPIO interface, but it is not mandatory; in some cases, the gpio_* functions are implemented as macros that access the device registers directly. Such an implementation is probably more efficient, but GPIO is not usually a performance-critical part of the system. So there may be pressure for all architectures to move to gpiolib; that, in turn, would facilitate the eventual removal of the number-based API entirely.

内核社区对这套新接口的评价还是不错的; 几乎可以肯定在不久的将来该改动会被合入内核主线。但目前存在一个最大的问题，就是这套基于描述符的接口完全实现在 gpiolib 层中。虽然大多数体系架构都已经在使用 gpiolib 来实现 GPIO 接口，但这并不是强制要求的；在个别体系架构中，考虑到代码运行的效率问题，仍然会直接使用现有的 `gpio_*` 函数接口，因为这些函数被实现为宏，可以直接访问设备的寄存器。考虑到 GPIO 通常并不是系统中影响性能的关键因素。所以相信最终所有的体系架构都会接受使用 gpiolib；这将有助于完全移除现有的基于整数编号方式标识 GPIO 引脚的接口函数。

### GPIO 组（Block GPIO）

> The GPIO interface as described so far is focused on the management of individual GPIO lines. But GPIOs are often used together as a group. As a simple example, consider a pair of GPIOs used as an I2C bus; one line handles data, the other the clock. A bit-banging driver can manage those two lines together to communicate with connected I2C devices; the kernel contains a driver in drivers/i2c/busses/i2-gpio.c for just this purpose.

到目前为止所介绍的 GPIO 接口所提供的功能主要集中于如何管理单个 GPIO 引脚实现独立的功能。但经常需要同时使用多个 GPIO 引脚来实现一个功能。举一个简单的例子，考虑一对用于模拟 I2C 总线接口的 GPIO 引脚；一个传输数据信号，另一个传输时钟信号。实现 I2C 模拟的驱动程序会同时管理这两条线路与连接的 I2C 设备进行通信（译者注，使用 GPIO 模拟 I2C 的技术称之为 “bit-banging”，即使用软件按位检测并处理的方式，具体解释可以参考[Wikipedia Bit Banging 的定义](https://en.wikipedia.org/wiki/Bit_banging)）；Linux 内核提供了一个驱动程序 `drivers/i2c/busses/i2-gpio.c` 可以实现该功能。

> Most of the time, managing GPIOs individually, even when they are used as a group, works fine. Computers are quite fast relative to the timing requirements of most of the serial communications protocols that are subject to implementation with GPIO. But there are exceptions, especially when the hardware implementing the GPIO lines themselves is slow; that can make it hard to change multiple lines in a simultaneous manner. But, sometimes, the hardware can change lines simultaneously if properly asked; often the lines are represented by bits in the same device register and can all be changed together with a single I/O memory write operation.

大多数情况下，即便逻辑上需要同时操作多个 GPIO 引脚，但具体操作时独立地设置它们也是可行的。因为采用 GPIO 引脚来模拟串行通讯协议一类接口时，相对于这些接口的时序要求，处理器的速度已经足够地快。当然也有例外，如果 GPIO 硬件控制单元本身反应就很慢的话，就会导致很难在非常短的时间内连续操作多个引脚。为了解决这个问题，硬件提供的解决方案是在一个寄存器中提供多个比特位，每个比特位对应一个 GPIO 引脚，这样处理器可以通过一次 I/O 内存访问（译者注，即读写一次寄存器）就同时操作多个引脚。

> Roland Stigge's [block GPIO patch set](https://lwn.net/Articles/533557/) is an attempt to make that functionality available in the kernel. Code that needs to manipulate multiple GPIOs as a group would start by associating them in a single block with:

Roland Stigge 提供的 [“block GPIO 补丁集”](https://lwn.net/Articles/533557/) 试图在内核中提供对该功能的支持。具体应用中如果需要同时操作多个 GPIO，可以通过以下接口函数将它们关联在一起：

	struct gpio_block *gpio_block_create(unsigned int *gpios, size_t size,
						const char *name);

> gpios points to an array of size GPIO numbers which are to be grouped into a block; the given name can be used to work with the block from user space. The GPIOs should have already been requested with gpio_request(); they also need to have their direction set individually. It's worth noting that the GPIOs need not be located on the same hardware; if they are spread out, or if the underlying driver does not implement the internal block API, the block GPIO interface will just access those lines individually as is done now.

参数 `gpios` 是一个指针，指向一个数组，该数组用于存放需要同时处理的一组 GPIO 引脚的编号，数组的大小通过第二个参数 `size` 指定；第三个参数 `name` 为字符串类型，用于指定从用户空间访问该组 GPIO 引脚的标识符。在调用该函数之前需要确保已经对相关的 GPIO 引脚调用了 `gpio_request()` 并设置了 I/O 的方向。值得注意的是，同一组中的 GPIO 可以位于不同的硬件设备上；对于这种情况，如果底层驱动程序内部没有实现 block 处理的逻辑，那么内核缺省仍然采用独立的方式访问那些引脚。

> Manipulation of GPIO blocks is done with:

同时访问一组 GPIO 引脚的函数接口如下：

	unsigned long gpio_block_get(struct gpio_block *block, unsigned long mask);
	void gpio_block_set(struct gpio_block *block, unsigned long mask,
			unsigned long values);

> For both functions, block is a GPIO block created as described above, and mask is a bitmask specifying which GPIOs in the block are to be acted upon; each bit in mask enables the corresponding GPIO in the array passed to gpio_block_create(). This API implies that the number of bits in a long forces an upper bound on number of lines grouped into a GPIO block; that seems unlikely to be a problem in real-world use. gpio_block_get() will read the specified lines, simultaneously if possible, and return a bitmask with the result. The lines in a GPIO block can be set as a unit with gpio_block_set().

以上两个函数，参数 `block` 是通过调用 `gpio_block_create()` 函数创建的 GPIO 组，参数 `mask` 是一个位掩码，用于指定该 GPIO 组中哪些 GPIO 将被处理；掩码中的每一位对应传递给 `gpio_block_create()` 的数组中的一个 GPIO 引脚。`mask` 的类型是 `long`, 这意味着一组 GPIO 中的引脚个数最多是 32 个；这应该不是问题，在现实应用中这个上限已经足够了。如果可能，`gpio_block_get()` 将同时读取指定的引脚，并以位掩码的方式返回结果。如果要同时写多个 GPIO 引脚可以使用 `gpio_block_set()`。
 
> A GPIO block is released with:

释放一组 GPIO 可以调用：

	void gpio_block_free(struct gpio_block *block);

> There is also a pair of registration functions:

还有一对函数用于实现 “GPIO 组” 的注册相关功能：

	int gpio_block_register(struct gpio_block *block);
	void gpio_block_unregister(struct gpio_block *block);

> Registering a GPIO block makes it available to user space. There is a sysfs interface that can be used to query and set the GPIOs in a block. Interestingly, registration also creates a device node (using the name provided to gpio_block_create()); reading from that device returns the current state of the GPIOs in the block, while writing it will set the GPIOs accordingly. There is an ioctl() operation (which, strangely, uses zero as the command number) to set the mask to be used with read and write operations.

一经注册，我们就可以在用户空间通过 sysfs 提供的相应接口对该组 GPIO 引脚进行查询和设置。有趣的是，注册的同时也会创建一个设备节点（节点的名称就来自调用 gpio_block_create() 时给定的 `name` 参数）；读该设备文件将返回该组 GPIO 的当前状态，写入时将相应地设置组内的 GPIO 引脚。我们可以通过 `ioctl()` 函数（奇怪的是，它使用值为零的命令编号）来设置用于读写操作的掩码。

> This patch set has not generated as much discussion as the descriptor-based API patches (it is also obviously not yet integrated with the descriptor API). Most likely, relatively few developers have felt the need for a block-based API. That said, there are cases when it is likely to be useful, and there appears to be no opposition, so this API can eventually be expected to be merged as well.

和前述的基于描述符的 API 修改补丁相比，这个补丁并没有引起大家的太多关注（它显然也还没有和前一个补丁集成）。最可能的原因是，需要该功能的开发人员并不多。当然，对于一个补丁来说，如果有其存在的必要性，同时又没有人反对的话，那么最终也可能被合并到主线中去。

[1]: http://tinylab.org
