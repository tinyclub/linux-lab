---
layout: post
author: 'Nikq'
title: "将 Linux 移植到新的处理器架构，第 2 部分：早期代码"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /lwn-656286/
description: "本文是 Porting Linux to a new processor architecture 系列翻译的第二部分，后续还有一篇。该成果由 RISC-V Linux 内核兴趣小组输出。"
category:
  - 开源项目
  - Risc-V
  - 移植 Linux 内核
tags:
  - 移植
  - RISC-V
  - TSAR
  - Linux 内核
  - 启动顺序
  - setup_arch
  - trap_init
  - mem_init
  - init_IRQ
  - time_init
---

> Title:      [Porting Linux to a new processor architecture, part 2: The early code](https://lwn.net/Articles/656286/)
> Author:     Joël Porquet@**September 2, 2015**
> Translator: 通天塔 <985400330@qq.com>
> Revisor:    lzufalcon <falcon@tinylab.org>
> Project:    [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## 前言

> In [part 1](https://lwn.net/Articles/654783/) of this series, we laid the groundwork for porting Linux to a new processor architecture by explaining the (non-code-related) preliminary steps. This article continues from there to delve into the boot code. This includes what code needs to be written in order to get from the early assembly boot code to the creation of the first kernel thread.

在本系列文章的 [第一部分](https://tinylab.org/lwn-654783/)，我们通过讲述初步的步骤（与代码无关的）来给我们移植 Linux 到新的处理器架构中做了准备。本文将继续深入研究启动代码。这包括从“早期汇编启动代码到创建第一个内核线程”所需要编写的那些代码。



## 头文件集合（The header files）

> As briefly mentioned in the previous article, the `arch` header files (in my case, located under `linux/arch/tsar/include/`) constitute the two interfaces between the architecture-specific and architecture-independent code required by Linux.

正如在前一篇文章中简要提到的，`arch` 头文件（在我的例子中，位于 `linux/arch/tsar/include/` 下）构成了 Linux 所需要的架构相关代码和架构无关代码之间的两个接口。

> The first portion of these headers (subdirectory `asm/`) is part of the kernel interface and is used internally by the kernel source code. The second portion (`uapi/asm/`) is part of the user interface and is meant to be exported to user space—even though the various standard C libraries tend to reimplement the headers instead of including the exported ones. These interfaces are not completely airtight, as many of the `asm` headers are used by user space.

这些头文件的第一部分（子目录 `asm/`）是内核接口的一部分，在内核源代码内部使用。第二部分（`uapi/asm/`）是用户接口的一部分，旨在导出到用户空间，尽管各种标准 C 库倾向于重新实现头文件，而不是包含导出的那些。这些接口不光是给内核设计的，因为很多 `asm` 头文件（指 `uapi` 部分）会被用户空间使用。

> Both interfaces are typically more than a hundred header files altogether, which is why headers represent one of the biggest tasks in porting Linux to a new processor architecture. Fortunately, over the past few years, developers noticed that many processor architectures were sharing similar code (because they often exhibited the same behaviors), so the majority of this code has been aggregated into a [generic layer of header files](https://lwn.net/Articles/333569/) (in `linux/include/asm-generic/` and `linux/include/uapi/asm-generic/`).

这两个接口总共约 100 多个头文件，这就是为什么编写这些头文件是移植 Linux 到新架构的最大任务之一，幸运的是在过去几年中，开发者们发现很多处理器架构共享一些相似的代码（因为它们常常表现出相同的行为）。所以这些代码的大部分被整合到 [头文件的通用层](https://lwn.net/Articles/333569/)（在 `linux/include/asm-generic/` 和 `linux/include/uapi/asm-generic/`）。

> The real benefit is that it is possible to refer to these generic header files, instead of providing custom versions, by simply writing appropriate `Kbuild` files. For example, the few first lines of a typical `include/asm/Kbuild` looks like:
>
> ```
>     generic-y += atomic.h
>     generic-y += barrier.h
>     generic-y += bitops.h
>     ...
> ```
>

这么做真正的好处就是只需要编写适当的 `Kbuild` 文件，就可以引用这些通用的头文件，而不是提供自定义的版本。例如，典型的 `include/asm/Kbuild` 文件前几行长这样：

```
 generic-y += atomic.h
 generic-y += barrier.h
 generic-y += bitops.h
 ...
```

> When porting Linux, I'm afraid there is no other choice than to make a list of all of the possible headers and examine them one by one in order to decide whether the generic version can be used or if it requires customization. Such a list can be created from the generic headers already provided by Linux as well as the customized ones implemented by other architectures.

当移植 Linux 的时候，我担心除了将所有可能的头文件列举出来，并且一个一个的审视他们是可以用通用版本还是需要自定义，可能没有别的方法了。这样的列表可以参考 Linux 提供的通用头文件和其他架构自定义的一些头文件进行创建。

> Basically, a specific version must be developed for all of the headers that are related to the details of an architecture, as defined by the hardware or by the software through the ABI: cache (`asm/cache.h`) and TLB management (`asm/tlbflush.h`), the ELF format (`asm/elf.h`), interrupt enabling/disabling (`asm/irqflags.h`), page table management (`asm/page.h`, `asm/pgalloc.h`, `asm/pgtable.h`), context switching (`asm/mmu_context.h`, `asm/ptrace.h`), byte ordering (`uapi/asm/byteorder.h`), and so on.

基本上，必须为所有架构细节相关的头文件开发一个特定的版本，这些架构相关的细节由硬件或者软件通过 ABI 来定义：缓存（`asm/cache.h`）和 TLB 管理（`asm/tlbflush.h`），ELF 格式（`asm/elf.h`），中断使能/中断禁用（`asm/irqflags.h`），页表管理（`asm/page.h`，`asm/pgalloc.h`，`asm/pgtable.h`），上下文切换（`asm/mmu_context.h`，`asm/ptrace.h`），字节顺序（`uapi/asm/byteorder.h`），等等。

## 启动顺序（Boot sequence）

> As explained in part 1, figuring out the boot sequence helps to understand the minimal set of architecture-specific functions that must be implemented—and in which order.

正如第一部分所述，理顺启动顺序能够帮助理解必须实现的特定架构最小功能集——以及实现顺序。

> The boot sequence always starts with a function that must be written manually, usually in assembly code (in my case, this function is called `kernel_entry()` and is located in `arch/tsar/kernel/head.S`). It is defined as the main entry point of the kernel image, which indicates to the bootloader where to jump after loading the image in memory.

启动顺序中的第一个函数必须得手写，通常用汇编代码（在我的例子中，这个函数名为 `kernel_entry()`，位于 `arch/tsar/kernel/head.S` 中）。它被定义为内核映像文件的主入口点，用于指示 bootloader 在加载完内核映像文件到内存后需要跳到哪里执行。

> The following trace shows an excerpt of the sequence of functions that is executed during the boot (starred functions are the architecture-specific ones that will be discussed later in this article):
>
> ```c
> kernel_entry*
>  start_kernel
>     setup_arch*
>      trap_init*
>         mm_init
>             mem_init*
>         init_IRQ*
>         time_init*
>         rest_init
>             kernel_thread
>             kernel_thread
>             cpu_startup_entry
>    ```

下面的执行路径显示了在引导过程中执行的部分函数序列（标注星号的函数是架构相关函数，这些函数将在本文的后面讨论）：

```c
 kernel_entry*
 start_kernel
     setup_arch*
     trap_init*
     mm_init
         mem_init*
     init_IRQ*
     time_init*
     rest_init
         kernel_thread
         kernel_thread
         cpu_startup_entry
```



## 早期汇编代码（Early assembly boot code）

> The early assembly boot code has this special aura that scared me at first (as I'm sure it did many other programmers), since it is often considered one of the most complex pieces of code in a port. But even though writing assembly code is usually not an easy ride, this early boot code is not magic. It is merely a trampoline to the first architecture-independent C function and, to this end, only needs to perform a short and defined list of tasks.

早期的汇编代码在一开始的时候让我有一种害怕的预感（我相信它让很多程序员都有这种感觉），因为它通常被认为是移植中最复杂的代码之一。但是尽管写汇编代码不是一件易事，早期的启动代码也并非魔法。它仅仅是通往第一个架构无关 C 函数的跳板，为此，它只需要执行一个简短的、定义好的任务列表。

> When the early boot code begins execution, it knows nothing about what has happened before: Has the system been rebooted or just been powered on? Which bootloader has just loaded the kernel in memory? And so forth. For this reason, it is safer to put the processor into a known state. Resetting one or several system registers usually does the trick, making sure that the processor is operating in kernel mode with interrupts disabled.

当早期引导代码开始执行时，它对之前发生的事情一无所知：系统是重新启动了还是刚刚上了电？哪个 bootloader 刚刚将内核加载到内存中？等等。因此，将处理器置于已知状态更安全。重置一个或几个系统寄存器通常可以做到确保处理器运行在中断被禁用的内核模式下。

> Similarly, not much is known about the state of the memory. In particular, there is no guarantee that the portion of memory representing the kernel’s `bss` section (the section containing uninitialized data) was reset to zero, which is why this section must be explicitly cleared.

类似地，对内存状态的了解也不多。特别地，不能保证内存中存放内核 `bss` 段（包含未初始化数据）的区域被重置为零。这就是为什么这个部分必须被清楚明确的清除。

> Often Linux receives arguments from the bootloader (in the same way that a program receives arguments when it is launched). For example, this could be the memory address of a [flattened device tree](http://www.devicetree.org/) (on ARM, MicroBlaze, openRISC, etc.) or some other architecture-specific structure. Often such arguments are passed using registers and need to be saved into proper kernel variables.

Linux 经常从 bootloader 接收参数（就像程序在启动时接收参数一样）。例如，这可能是 [扁平设备树](http://www.devicetree.org/) 的内存地址（在 ARM、MicroBlaze、openRISC 等上）或一些其他架构相关的结构体。通常，这些参数使用寄存器传递，并且需要保存到适当的内核变量中。

> At this point, virtual memory has not been activated and it is interesting to note that kernel symbols, which are all defined in the kernel's virtual address space, have to be accessed through a special macro: [pa()](http://lxr.free-electrons.com/source/arch/x86/kernel/head_32.S?v=4.2#L28) in x86,  [tophys()](http://lxr.free-electrons.com/source/arch/openrisc/kernel/head.S?v=4.2#L32) in OpenRISC, etc. Such a macro translates the virtual memory address for symbols into their corresponding physical memory address, thus acting as a temporary software-based translation mechanism.

在这个时间点上，虚拟内存还没有被激活，需要注意到特别有趣的是，内核符号都定义在内核的虚拟地址空间中，必须通过一个特殊的宏来访问：x86 中的 [pa()](http://lxr.free-electrons.com/source/arch/x86/kernel/head_32.S?v=4.2#L28)，OpenRISC 中的 [tophys()](http://lxr.free-electrons.com/source/arch/openrisc/kernel/head.S?v=4.2#L32)，等等。这样的宏将符号的虚拟内存地址转换为它们对应的物理内存地址，从而充当一个临时的基于软件的转换机制。

> Now, in order to enable virtual memory, a page table structure must be set up from scratch. This structure usually exists as a static variable in the kernel image, since at this stage it is nearly impossible to allocate memory. For the same reason, only the kernel image can be mapped by the page table at first, using huge pages if possible. According to convention, this initial page table structure is called `swapper_pg_dir` and is thereafter used as the reference page table structure throughout the execution of the system.

现在，为了启用虚拟内存，必须从头设置页表结构。这个结构通常作为一个静态变量存在于内核映像中，因为在这个阶段几乎不可能分配内存。出于同样的原因，只有内核映像可以首先由页表映射，如果可能的话使用大页。根据约定，这个初始页表结构称为 `swapper_pg_dir`，然后在整个系统执行过程中用作参考页表结构。

> On many processor architectures, including TSAR, there is an interesting thing about mapping the kernel in that it actually needs to be mapped twice. The first mapping implements the expected direct-mapping strategy as described in part 1 (i.e. access to virtual address `0xC0000000` redirects to physical address `0x00000000`). However, another mapping is temporarily required for when virtual memory has just been enabled but the code execution flow still hasn't jumped to a virtually mapped location. This second mapping is a simple identity mapping (i.e. access to virtual address `0x00000000` redirects to physical address `0x00000000`).

在包括 TSAR 在内的许多处理器架构中，关于映射内核有一个有趣的现象，即它实际上需要被映射两次。第一次映射实现了第 1 部分中描述的预期的直接映射策略（即访问虚拟地址 `0xC0000000` 重定向到物理地址 `0x00000000`）。但是，当刚刚启用虚拟内存但代码执行流仍然没有跳转到虚拟映射位置时，临时需要另一个映射。第二次映射是一个简单的身份映射（即对虚拟地址 `0x00000000` 的访问重定向到物理地址 `0x00000000`）。

> With an initialized page table structure, it is now possible to enable virtual memory, meaning that the kernel is fully executing in the virtual address space and that all of the kernel symbols can be accessed normally by their name, without having to use the translation macro mentioned earlier.

有了初始化的页表结构，现在就可以启用虚拟内存，这意味着内核完全在虚拟地址空间中执行，所有的内核符号都可以通过名称正常访问，而不必使用前面提到的翻译宏。

> One of the last steps is to set up the stack register with the address of the initial kernel stack so that C functions can be properly called. In most processor architectures (SPARC, Alpha, OpenRISC, etc.), another register is also dedicated to containing a pointer to the current thread's information (`struct thread_info`). Setting up such a pointer is optional, since it can be derived from the current kernel stack pointer (the `thread_info` structure is usually located at the bottom of the kernel stack) but, when allowed by the architecture, it enables much faster and more convenient access.

最后的步骤之一是用初始内核堆栈的地址建立堆栈寄存器，以便能够正确地调用 C 函数。在大多数处理器架构中（SPARC, Alpha, OpenRISC 等），另一个寄存器也用于包含一个指向当前线程信息的指针（`struct thread_info`）。设置这样的指针是可选的，因为它可以从当前内核堆栈指针派生（`thread_info` 结构通常位于内核堆栈的底部），但是，当架构允许时，它可以实现更快、更方便的访问。

> The last step of the early boot code is to jump to the first architecture-independent C function that Linux provides: `start_kernel()`.

早期引导代码的最后一步是跳到 Linux 提供的第一个架构无关 C 函数：`start_kernel()`。

## 启动第一个内核线程的路径（En route to the first kernel thread）

> [start_kernel()](http://lxr.free-electrons.com/source/init/main.c?v=4.2#L497) is where many subsystems are initialized, from the various virtual filesystem (VFS) caches and the security framework to time management, the console layer, and so on. Here, we will look at the main architecture-specific functions that `start_kernel()` calls during boot before it finally calls `rest_init()`, which creates the first two kernel threads and morphs into the boot idle thread.

 [start_kernel()](http://lxr.free-electrons.com/source/init/main.c?v=4.2#L497) 是许多子系统初始化的地方，从各种虚拟文件系统（VFS）缓存和安全框架到时间管理、控制台层（console layer）等等。在这里，我们将看看在引导过程中 `start_kernel()` 在最终调用 `rest_init()` 之前调用的主要架构特定函数，它创建了前两个内核线程并转变为引导空闲线程（boot idle thread）。

#### `setup_arch()`

> While it has a rather generic name, `setup_arch()` can actually do quite a bit, depending on the architecture. Yet examining the code for different ports reveals that it generally performs the same tasks, albeit never in the same order nor the same way. For a simple port (with device tree support), there is a simple skeleton that `setup_arch()` can follow.

虽然它有一个相当通用的名称，`setup_arch()` 实际上可以做很多事情，这取决于架构。然而，对不同移植的代码进行研究后发现，它通常执行相同的任务，尽管顺序和方式不同。对于一个简单的移植（支持设备树），`setup_arch()` 可以遵循一个简单的框架。

> One of the first steps is to discover the memory ranges in the system. A device-tree-based system can quickly skim through the flattened device tree given by the bootloader (using `early_init_devtree()`) to discover the physical memory banks available and to register them into the `memblock` layer. Then, parsing the early arguments (using `parse_early_param()`) that were either given by the bootloader or directly included in the device tree can activate useful features such as `early_printk()`. The order is important here, as the device tree might contain the physical address of the terminal device used for printing and thus needs to be scanned first.

第一步是发现系统中的内存范围。基于设备树的系统可以快速浏览由引导加载器给出的扁平设备树（使用 `early_init_devtree()`）来发现可用的物理内存库，并将它们注册到 `memblock` 层。然后，解析早期的参数（使用 `parse_early_param()`），这些参数要么是由引导加载器给出的，要么直接包含在设备树中，可以激活有用的特性，如 `early_printk()`。这里的顺序很重要，因为设备树可能包含用于打印的终端设备的物理地址，因此需要首先扫描。

> Next the memblock layer needs some more configuration before it is possible to map the low memory region, which enables memory to be allocated. First, the regions of memory occupied by the kernel image and the device tree are set as being *reserved* in order to remove them from the pool of free memory, which is later released to the buddy allocator. The boundary between low memory and high memory (i.e. which portion of the physical memory should be included in the direct mapping region) needs to be determined. Finally the page table structure can be cleaned up (by removing the identity mapping created by the early boot code) and the low memory mapped.

接下来，memblock 层需要一些更多的配置，才能映射低内存区域，从而能够分配内存。首先，内核映像和设备树所占用的内存区域被设置为*保留的*，以便将它们从空闲内存池中删除，该内存池稍后将被释放给伙伴分配器。需要确定低内存和高内存之间的边界（即物理内存的哪一部分应该包含在直接映射区域中）。最后，可以清理页表结构（通过删除早期引导代码创建的标识映射）和低内存映射。

> The last step of the memory initialization is to configure the memory zones. Physical memory pages can be associated with different zones: `ZONE_DMA` for pages compatible with the old ISA 24-bit DMA address limitation, and `ZONE_NORMAL` and `ZONE_HIGHMEM` for low- and high-memory pages, respectively. Further reading on memory allocation in Linux can be found in [*Linux Device Drivers* [PDF]](https://lwn.net/images/pdf/LDD3/ch08.pdf).

内存初始化的最后一步是配置内存分区。物理内存页面可以与不同的区域相关联：`ZONE_DMA` 用于兼容旧 ISA 24 位 DMA 地址限制的页面，`ZONE_NORMAL` 和`ZONE_HIGHMEM` 用于低内存和高内存页面。更多关于 Linux 内存分配的阅读可以在 [*Linux Device Drivers* [PDF]](https://lwn.net/images/pdf/LDD3/ch08.pdf) 中找到。

> Finally, the kernel memory segments are registered using the resource API and a tree of [struct device_node](http://lxr.free-electrons.com/source/include/linux/of.h?v=4.2#L49) entries is created from the flattened device tree.

最后，使用资源 API 注册内核内存段，并从扁平设备树创建一个 [struct device_node](http://lxr.free-electrons.com/source/include/linux/of.h?v=4.2#L49) 树节点入口。

> If `early_printk()` is enabled, here is an example of what appears on the terminal at this stage:
>
> ```
> Linux version 3.13.0-00201-g7b7e42b-dirty (joel@joel-zenbook) \
>      (gcc version 4.8.3 (GCC) ) #329 SMP Thu Sep 25 14:17:56 CEST 2014
> Model: UPMC/LIP6/SoC - Tsar
>  bootconsole [early_tty_cons0] enabled
> Built 1 zonelists in Zone order, mobility grouping on.  Total pages: 65024
>  Kernel command line: console=tty0 console=ttyVTTY0 earlyprintk
>```
>

如果启用了 `early_printk()`，这里有个例子，展示了该阶段打印在控制台的信息：

```c
 Linux version 3.13.0-00201-g7b7e42b-dirty (joel@joel-zenbook) \
     (gcc version 4.8.3 (GCC) ) #329 SMP Thu Sep 25 14:17:56 CEST 2014
 Model: UPMC/LIP6/SoC - Tsar
 bootconsole [early_tty_cons0] enabled
 Built 1 zonelists in Zone order, mobility grouping on.  Total pages: 65024
 Kernel command line: console=tty0 console=ttyVTTY0 earlyprintk
```

#### `trap_init()`

> The role of `trap_init()` is to configure the hardware and software architecture-specific parts involved in the interrupt/exception infrastructure. Up to this point, an exception would either cause the system to crash immediately or it would be caught by a handler that the bootloader might have set up (which would eventually result in a crash as well, but perhaps with more information).

`trap_init()` 的作用是配置涉及中断/异常机制的硬件和软件架构特定部分。到目前为止，异常要么会导致系统立即崩溃，要么会被引导加载程序可能已经设置的处理程序捕获（这最终也会导致崩溃，但可能会提供更多信息）。

> Behind (the actually simple) `trap_init()` hides another of the more complex pieces of code in a Linux port: the interrupt/exception handling manager. A big part of it has to be written in assembly code because, as with the early boot code, it deals with specifics that are unique to the targeted processor architecture. On a typical processor, a possible overview of what happens on an interrupt is as follows:
>
> - The processor automatically switches to kernel mode, disables interrupts, and its execution flow is diverted to a special address that leads to the main interrupt handler.
>- This main handler retrieves the exact cause of the interrupt and usually jumps to a sub-handler specialized for this cause. Often an interrupt vector table is used to associate an interrupt sub-handler with a specific cause, and on some architectures there is no need for a main interrupt handler, as the routing between the actual interrupt event and the interrupt vector is done transparently by hardware.
> - The sub-handler saves the current context, which is the state of the processor that can later be restored in order to resume exactly where it stopped. It may also re-enable the interrupts (thus making Linux re-entrant) and usually jumps to a C function that is better able to handle the cause of the exception. For example, such a C function can, in the case of an access to an illegal memory address, terminate the faulty user program with a `SIGBUS` signal.
>

`trap_init()` 背后（其实很简单）隐藏了 Linux 移植过程中另外一个更复杂的代码片段：即中断/异常处理管理。它的很大一部分必须用汇编代码编写，因为与早期引导代码一样，它处理的是目标处理器架构所特有的细节。在一个典型的处理器上，中断产生后的一般处理流程概述如下：

- 处理器自动切换到内核模式，禁用中断，它的执行流被转移到一个特殊的地址，该地址指向主中断处理函数。
- 这个中断主处理函数获取中断的确切原因，并且通常会跳转到一个专门针对这个原因的子处理函数。通常一个中断向量表被用来将一个子处理函数与一个特定的原因关联起来，在一些架构上不需要一个主中断处理函数，因为在实际的中断事件和中断向量之间的路由是由硬件直接完成的。
- 子中断处理函数保存当前上下文，即当前处理器的状态，可以在以后恢复，以便恢复到它停止的地方。它还可能重新启用中断（从而使 Linux 可重入），并且通常跳转到能够更好地处理异常原因的 C 函数。例如，在访问非法内存地址的情况下，这样的 C 函数可以用 `SIGBUS` 信号终止有故障的用户程序。

> Once all of this interrupt infrastructure is in place, `trap_init()` merely initializes the interrupt vector table and configures the processor via one of its system registers to reflect the address of the main interrupt handler (or of the interrupt vector table directly).

一旦所有的中断机制就绪，`trap_init()` 只会初始化中断向量表，并通过它的一个系统寄存器来配置处理器，以反映主中断处理器的地址（或者直接反映中断向量表的地址）。

#### `mem_init()`

> The main role of `mem_init()` is to release the free memory from the memblock layer to the buddy allocator (aka the [page allocator](https://lwn.net/Articles/320556/)). This represents the last memory-related task before the slab allocator (i.e. the cache of commonly used objects, accessible via `kmalloc()`) and the vmalloc infrastructure can be started, as both are based on the buddy allocator.

`mem_init()` 的主要作用是将内存块层（memblock layer）的空闲内存释放给伙伴分配器（又名 [页分配器](https://lwn.net/Articles/320556/)）。这表示，作为最后一个内存相关的任务，在 slab 分配器（即常用对象的缓存，通过 `kmalloc()` 访问） 和 vmalloc 功能能够被启用之前，伙伴分配器必须就绪，因为两者都依赖它。

> Often `mem_init()` also prints some information about the memory system:
>
> ```
>    Memory: 257916k/262144k available (1412k kernel code, \
>         4228k reserved, 267k data, 84k bss, 169k init, 0k highmem)
>    Virtual kernel memory layout:
>         vmalloc : 0xd0800000 - 0xfffff000 ( 759 MB)
>        lowmem  : 0xc0000000 - 0xd0000000 ( 256 MB)
>           .init : 0xc01a5000 - 0xc01ba000 (  84 kB)
>          .data : 0xc01621f8 - 0xc01a4fe0 ( 267 kB)
>           .text : 0xc00010c0 - 0xc01621f8 (1412 kB)
>```
>

通常 `mem_init()` 也会打印一些关于内存系统的信息:

```
    Memory: 257916k/262144k available (1412k kernel code, \
        4228k reserved, 267k data, 84k bss, 169k init, 0k highmem)
    Virtual kernel memory layout:
        vmalloc : 0xd0800000 - 0xfffff000 ( 759 MB)
        lowmem  : 0xc0000000 - 0xd0000000 ( 256 MB)
          .init : 0xc01a5000 - 0xc01ba000 (  84 kB)
          .data : 0xc01621f8 - 0xc01a4fe0 ( 267 kB)
          .text : 0xc00010c0 - 0xc01621f8 (1412 kB)
```



#### `init_IRQ()`

> Interrupt networks can be of very different sizes and complexities. In a simple system, the interrupt lines of a few hardware devices are directly connected to the interrupt inputs of the processor. In complex systems, the numerous hardware devices are connected to multiple programmable interrupt controllers (PICs) and these PICs are often cascaded to each other, forming a multilayer interrupt network. The device tree helps a great deal by easily describing such networks (and especially the routing) instead of having to specify them directly in the source code.

中断网络可以有非常不同的大小和复杂性。在一个简单的系统中，几个硬件设备的中断线直接连接到处理器的中断输入。在复杂系统中，大量的硬件设备连接到多个可编程中断控制器（PICs）上，这些 PICs 经常级联在一起，形成一个多层中断网络。设备树帮助很大，可以很容易地描述这些网络（尤其是路由），而不必在源代码中直接指定它们。

> In `init_IRQ()`, the main task is to call `irqchip_init()` in order to scan the device tree and find all the nodes identified as interrupt controllers (e.g PICs). It then finds the associated driver for each node and initializes it. Unless the targeted system uses an already-supported interrupt controller, that typically means the first device driver will need to be written.

在 `init_IRQ()` 中，主要任务是调用 `irqchip_init()`，以便扫描设备树并找到所有标识为中断控制器的节点（例如 PICs）。然后，它为每个节点找到相关的驱动程序并初始化它。除非目标系统使用已经支持的中断控制器，否则这通常意味着需要编写第一个设备驱动程序。

> Such a driver contains a few major functions: an initialization function that maps the device in the kernel address space and maps the controller-local interrupt lines to the Linux IRQ number space (through the [irq_domain](https://www.kernel.org/doc/Documentation/IRQ-domain.txt) mapping library); a mask/unmask function that can configure the controller in order to mask or unmask the specified Linux IRQ number; and, finally, a controller-specific interrupt handler that can find out which of its inputs is active and call the interrupt handler registered with this input (for example, this is how the interrupt handler of a block device connected to a PIC ends up being called after the device has raised an interrupt).

这样一个驱动包含几个主要函数：

* 一个初始化函数负责在内核空间映射设备并负责映射本地控制器中断线到 Linux IRQ 编号空间（通过 [irq_domain](https://www.kernel.org/doc/Documentation/IRQ-domain.txt) 映射库）；
* 一组 mask/unmask 函数用于配置控制器以便 mask 或者 unmask 特定的中断 IRQ 编号；
* 最后，控制器特定的中断处理函数能找出它的哪个输入是活动的并调用注册到该输入上的中断处理子函数（例如，当设备触发一个中断后，连接到 PIC 的块设备中断处理函数就是这样被调用的）。

#### `time_init()`

> The purpose of `time_init()` is to initialize the architecture-specific aspects of the timekeeping infrastructure. A minimal version of this function, which relies on the use of a device tree, only involves two function calls.

`time_init()` 的目的是初始化特定架构的计时机制。这个函数的最小版本依赖于设备树的使用，它只涉及两个函数调用。

> First, `of_clk_init()` will scan the device tree and find all the nodes identified as clock providers in order to initialize the [clock framework](https://www.kernel.org/doc/Documentation/clk.txt). A very simple clock-provider node only has to define a fixed frequency directly specified as one of its properties.

首先，`of_clk_init()` 将扫描设备树并找到所有标识为时钟提供者的节点，以便初始化 [时钟框架](https://www.kernel.org/doc/Documentation/clk.txt) 。在设备树中，一个非常简单的时钟提供者节点只需要定义一个固定频率，直接指定为它的属性之一。

> Then, `clocksource_of_init()` will parse the clock-source nodes of the device tree and initialize their associated driver. As described in the [kernel documentation](https://www.kernel.org/doc/Documentation/timers/timekeeping.txt), Linux actually needs two types of timekeeping abstraction (which are actually often both provided by the same device): a clock-source device provides the basic timeline by monotonically counting (for example it can count system cycles), and a clock-event device raises interrupts on certain points on this timeline, typically by being programmed to count periods of time. Combined with the clock provider, it allows for precise timekeeping.

然后，`clocksource_of_init()` 将解析设备树的时钟源节点，并初始化它们的相关驱动程序。正如在 [kernel 文档](https://www.kernel.org/doc/Documentation/timers/timekeeping.txt) 中所描述的，Linux 实际上需要两种类型的计时抽象（实际上这两种抽象都是由同一台设备提供的）：时钟源设备通过单调计数（例如，它可以计数系统周期）来提供基本的时间线，而时钟事件设备在这个时间线上的某些点上引发中断，通常是通过编程来计数时间周期。与时钟提供程序相结合，它允许精确计时。

> The driver of a clock-source device can be extremely simple, especially for a memory-mapped device for which the [generic MMIO clock-source driver](http://lxr.free-electrons.com/source/drivers/clocksource/mmio.c) only needs to know the address of the device register containing the counter. For the clock event, it is slightly more complicated as the driver needs to define how to program a period and how to acknowledge it when it is over, as well as provide an interrupt handler for when a timer interrupt is raised.

时钟源设备的驱动程序可能非常简单，特别地，对于一个内存映射设备，它采用 [通用 MMIO 时钟源驱动](http://lxr.free-electrons.com/source/drivers/clocksource/mmio.c)，仅需要知道一个包含计数器的设备寄存器地址。对于时钟事件，它稍微复杂一些，因为驱动程序需要定义如何编程一个周期，以及如何在它结束时应答它，以及在计时器中断被引发时提供一个中断处理函数。

## 结论（Conclusion）

> One of the main tasks performed by `start_kernel()` later on is to calibrate the number of loops per jiffy, which is the number of times the processor can execute an internal delay loop in one jiffy—an internal timer period that normally ranges from one to ten milliseconds. Succeeding in performing this calibration should mean that the different infrastructures and drivers set up by the architecture-specific functions we just presented are working, since the calibration makes use of most of them.

`start_kernel()` 执行后的主要任务之一是校准每秒的循环数，这是处理器在一秒内可以执行内部延迟循环的次数——内部定时器周期通常在 1 到 10 毫秒之间。成功地执行此校准应该意味着，我们刚才介绍的架构相关功能所设置的不同机制和驱动程序正在工作，因为校准使用了它们中的大多数。

> In the next article, we will present the last portion of the port: from the creation of the first kernel thread to the `init` process.

在下一篇文章中，我们将介绍移植的最后一部分：从创建第一个内核线程到运行 `init` 进程。

