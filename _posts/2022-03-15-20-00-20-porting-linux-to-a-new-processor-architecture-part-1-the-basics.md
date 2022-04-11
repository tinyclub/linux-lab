---
layout: post
author: 'Nikq'
title: "将 Linux 移植到新的处理器架构，第 1 部分：基础"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /lwn-654783/
description: "本文是 Porting Linux to a new processor architecture 系列翻译的第一部分，后续还有两篇。该成果由 RISC-V Linux 内核兴趣小组输出。"
category:
  - 开源项目
  - Risc-V
  - 移植 Linux 内核
tags:
  - 移植
  - RISC-V
  - TSAR
  - Linux
---

> Title:      [Porting Linux to a new processor architecture, part 1: The basics](https://lwn.net/Articles/654783/)
> Author:     Joël Porquet@**August 26, 2015**
> Translator: 通天塔 <985400330@qq.com>
> Revisor:    lzufalcon <falcon@tinylab.org>
> Project:    [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)
 
## 前言

> Although a simple port may count as little as 4000 lines of code—exactly 3,775 for the mmu-less Hitachi 8/300 recently reintroduced in Linux 4.2-rc1—getting the Linux kernel running on a new processor architecture is a difficult process. Worse still, there is not much documentation available describing the porting process. The aim of this series of three articles is to provide an overview of the procedure, or at least one possible procedure, that can be followed when porting the Linux kernel to a new processor architecture.

虽然一个简单的移植可能仅需要 4000 行代码 —— 更确切地，在最近的 Linux 4.2-rc2 中引入的不带 MMU 的 Hitachi 8/300 只有 3775 行。但是，让 Linux 内核在一个全新的处理器架构上跑起来却并非易事。这个包含三篇文章的系列旨在概括一下这个过程，或者至少为后续的新架构移植提供一下参考。

> After spending countless hours becoming almost fluent in many of the supported architectures, I discovered that a well-defined skeleton shared by the majority of ports exists. Such a skeleton can logically be split into two parts that intersect a great deal. The first part is the boot code, meaning the architecture-specific code that is executed from the moment the kernel takes over from the bootloader until `init` is finally executed. The second part concerns the architecture-specific code that is regularly executed once the booting phase has been completed and the kernel is running normally. This second part includes starting new threads, dealing with hardware interrupts or software exceptions, copying data from/to user applications, serving system calls, and so on.

在对大量已支持的架构进行长期研究并烂熟于心后，我发现大多数移植之间有一个定义好的“骨架”，这种“骨架”可以从逻辑上划分为两部分，这两部分又在很大程度上相互交叉。第一个架构相关部分是引导代码，从内核接管 Bootloader 开始一直执行到 `init` 进程跑起来。另外一部分架构相关代码，则出现在引导阶段已经结束且内核正在运行的情况下，这部分包括启动新线程、处理硬件中断或者软件异常，与应用程序交换数据及服务系统调用等等。

##  如何确定到底是不是一个新的架构移植？（Is a new port necessary?）

> As LWN [reported](https://lwn.net/Articles/597351/) about another porting experience in an article published last year, there are three meanings to the word "porting".
>
> It can be a port to a new board with an already-supported processor on it. Or it can be a new processor from an existing, supported processor family. The third alternative is to port to a completely new architecture.

正如另外一篇发表在 LWN 上的关于移植的 [文章](https://lwn.net/Articles/597351/)所总结的那样，“移植” 这一词有三种含义：

- 第一种情况是，移植到一块新的开发板（用了一个已经支持好的处理器，比如有很多厂家基于 ARMv7 制作开发板）
- 另外一种情况是，移植到一个新的处理器（但是属于一个已经存在的支持好的处理器家族，比如 X86 的变体）
- 还有一种是，移植到一个全新架构（比如 Linux v4.15 那会新增加第一个 RISC-V 处理器实现）。

> Sometimes, the answer to whether one should start a new port from scratch is crystal clear—if the new processor comes with a new instruction set architecture (ISA), that is usually a good indicator. Sometimes it is less clear. In my case, it took me a couple weeks to figure out this first question.

有时候，要回答是否应该从头开始一个新的移植是十分清楚的 —— 如果新的处理器带来了新的指令集架构，这通常是一个非常好的指标。但另外一些时候，却有点模棱两可，就我而言，花了数周才厘清这这个问题。

> At the time, May 2013, I had just been hired by the French academic computer lab [LIP6](http://www.lip6.fr/?LANG=en) to port the Linux kernel to [TSAR](https://www-soc.lip6.fr/trac/tsar), an academic processor architecture that the system-on-chip research group was designing. TSAR is an architecture that follows many of the current trends: lots of small, single-issue, energy-efficient processor cores around a scalable network-on-chip. It also adds some nice innovations: a full-hardware cache-coherency protocol for both data/instruction caches and translation lookaside buffers (TLBs) as well as physically distributed but logically shared memory.

2013 年 5 月，那会我刚好受雇于法国学术计算机实验室 [LIP6](https://gitee.com/link?target=http%3A%2F%2Fwww.lip6.fr%2F%3FLANG%3Den)，主要工作是把 Linux 内核移植到 [TSAR](https://gitee.com/link?target=https%3A%2F%2Fwww-soc.lip6.fr%2Ftrac%2Ftsar)，这是 SOC 研究小组正在设计的学术处理器架构。TSAR 这种架构遵循了许多当下趋势：在一个可扩展的片上网络（NoC）之上接入了许多小巧、单发射但是高能效的处理器核。它也带来了一些可喜的创新：在数据&指令Cache 和 TLBs 之间设计了一种全硬件的缓存一致性协议，也设计了一种物理分布式但是逻辑上可共享的内存。

> My dilemma was that the processor cores were compatible with the MIPS32 ISA, which meant the port could fall into the second category: "new processor from an existing processor family". But since TSAR had a virtual-memory model radically different from those of any MIPS processors, I would have been forced to drastically modify the entire MIPS branch in order to introduce this new processor, sometimes having almost no choice but to surround entire files with `#ifndef TSAR ... #endif`.
>
> Quickly enough, it came down to the most logical—and interesting—conclusion:
>
> ```
>     mkdir linux/arch/tsar
> ```

我当时的困境是，处理器核心与 MIPS32 ISA 兼容，这意味着本次移植可能属于第二类：“现有处理器系列中的新处理器”。但是，由于TSAR的虚拟内存模型与任何 MIPS 处理器的虚拟内存模型完全不同，我不得不大幅修改整个 MIPS 分支，以引入这种新处理器，有时几乎别无选择，只能用 `#ifndef TSAR# ... #endif` 将整个文件包围起来。
所以，很快地，我们就得到了一个最符合逻辑且有趣的结论，那就是创建一个全新的架构目录：

```
mkdir linux/arch/tsar
```

## 了解你要移植硬件（Get to know your hardware）

> *Really* knowing the underlying hardware is definitely the fundamental, and perhaps most obvious, prerequisite to porting Linux to it.

真正熟悉底层硬件无疑是将Linux移植到它的基本前提，这是最明显的前提。

> The specifications of a processor are often—logically or physically—split into a least two parts (as were, for example, the recently published specifications for the new [RISC-V](http://www.riscv.org/) processor). The first part usually details the user-level ISA, which basically means the list of user-level instructions that the processor is able to understand—and execute. The second part describes the privileged architecture, which includes the list of kernel-level-only instructions and the various system registers that control the processor status.

处理器的规格书通常在逻辑上或物理上至少分为两部分（例如，最近发布的新 [RISC-V](http://www.riscv.org/) 处理器规格）。第一部分基本上是指用户级 ISA，这是处理器能够理解和执行的用户级指令列表。第二部分描述了特权架构，其中包括内核级特有指令列表和控制处理器状态的各种系统寄存器。

> This second part contains the majority—if not the entirety—of the information that makes a port special and thus often prevents the developer from opportunely reusing code from other architectures.

第二部分包含了需要移植的大部分信息（如果不是全部的话），这部分导致移植过程的独特性，并且因此常常让开发人员错失复用其他架构代码的机会

> Among the important questions that should be answered by such specifications are:

在很多重要的问题中，规格书能回答的是：

> - What are the virtual-memory model of the processor architecture, the format of the page table, and the translation mechanism?

- 处理器架构的虚拟内存模型、页表的格式和转换机制是什么？

> Many processor architectures (e.g. x86, ARM, or TSAR) define a flexible virtual-memory layout. Their virtual address space can theoretically be split any way between the user and kernel spaces—although the default layout for 32-bit processors in Linux usually allocates the lower 3GiB to user space and reserves the upper 1GiB for kernel space. In some other architectures, this layout is strongly constrained by the hardware design. For instance, on MIPS32, the virtual address space is statically split into two regions of the same size: the lower 2GiB is dedicated to user space and the upper 2GiB to kernel space; the latter even contains predefined windows into the physical address space.

许多处理器架构（如 x86、ARM 或 TSAR）定义了灵活的虚拟内存布局。理论上，它们的虚拟地址空间可以在用户空间和内核空间之间以任何方式分割，尽管Linux中 32 位处理器的默认布局通常将较低的 3GiB 分配给用户空间，并将较高的 1Gib 保留给内核空间。在其他一些架构中，这种布局受到硬件设计的强烈限制。例如，在 MIPS32 上，虚拟地址空间被静态分割为两个大小相同的区域：较低的 2GiB 专用于用户空间，较高的 2GiB 专用于内核空间；后者甚至包含映射到物理地址空间的预定义窗口。

> The format of the page table is intimately linked to the translation mechanism used by the processor. In the case of a hardware-managed mechanism, when the TLB—a hardware cache of limited size containing recently used translations between virtual and physical addresses—does not contain the translation for a given virtual address (referred to as *TLB miss*), a hardware state machine will transparently fetch the proper translation from the page table structure in memory and fill the TLB with it. This means that the format of the page table must be fixed—and certainly defined by the processor's specifications. In a software-based mechanism, a TLB miss exception is handled by a piece of code, which theoretically leaves complete liberty as to how the page table is organized—only the format of TLB entries is specified.

页表的格式与处理器转换机制密切相关。在使用硬件管理机制的情况下，当 TLB —— 一种大小受限的硬件缓存包含了最近使用的虚拟与物理地址转换信息 —— 但是不包含一个特定虚拟地址的转换信息（被称为 TLB miss），某种硬件状态机将从内存中的页表结构中透明地获取正确的转换信息并用来填充 TLB。这意味着页表的格式必须是固定的，并且必须由处理器的规范定义。在基于软件的机制中，TLB 未命中异常由一段代码处理，从理论上讲，只需指定 TLB 条目的格式，就可以完全自由地组织页表。

> - How to enable/disable the interrupts, switch from privileged mode to user mode and vice-versa, get the cause of an exception, etc.?

- 如何启用/禁用中断，从特权模式切换到用户模式，反之亦然，获取异常的原因，等等。

> Although all these operations generally only involve reading and/or modifying certain bit fields in the set of available system registers, they are always very particular to each architecture. It is for this reason that, most of the time, they are actually performed by small chunks of dedicated assembly code.

尽管所有这些操作通常只涉及读取或修改可用系统寄存器集中的某些位字段，但是不同架构的寄存器有不同的用法。正是因为这个原因，在大多数情况下，它们实际上是由小块专用汇编代码执行的。

> - What is the ABI?

- 什么ABI?

> Although one could think that the Application Binary Interface (ABI) is only supposed to concern compilation tools, as it defines the way the stack is formatted into stack-frames, the ways arguments and return values are given or returned by functions, etc.; it is actually absolutely necessary to be familiar with it when porting Linux. For example, as the recipient of system calls (which are typically defined by the ABI), the kernel has to know where to get the arguments and how to return a value; or on a context switch, the kernel must know what to save and restore, as well as what constitutes the context of a thread, and so on.

尽管人们可能会认为应用程序二进制接口（ABI）只与编译工具有关，因为它定义了堆栈格式化为堆栈帧的方式、函数传递参数和提交返回值的方式等；在移植 Linux 时，实际上绝对有必要熟悉它。例如，作为系统调用（通常由 ABI 定义）的接收者，内核必须知道从哪里获取参数以及如何返回值；或者在上下文切换过程中，内核必须知道要保存和恢复的内容，以及构成线程上下文的内容，等等。

## 了解内核(Get to know the kernel)

> Learning a few kernel concepts, especially concerning the memory layout used by Linux, will definitely help. I admit it took me a while to understand what exactly was the distinction between *low memory* and *high memory*, and between the *direct mapping* and *vmalloc* regions.

学习一些内核概念，尤其是关于 Linux 使用的内存布局，肯定会有所帮助。我承认，我花了一段时间才弄清楚低内存和高内存之间的区别，以及*直接映射*和*vmalloc*区域之间的区别。

> For a typical and simple port (to a 32-bit processor), in which the kernel occupies the upper 1GiB of the virtual address space, it is usually fairly straightforward. Within this 1GiB, Linux defines that the lower portion of it will be directly mapped to the lower portion of the system memory (hence referred to as low memory): meaning that if the kernel accesses the address `0xC0000000`, it will be redirected to the physical address `0x00000000`.

对于一个典型且简单的移植（对于 32 位处理器），内核占据了虚拟地址空间的上 1GiB ，它通常相当简单。在这个 1GiB 中，Linux 定义它的较低部分将直接映射到系统内存的较低部分（因此称为低内存）：这意味着如果内核访问地址 0xC0000000，它将被重定向到物理地址 0x00000000。

> In contrast, in systems with more physical memory than that which is mappable in the direct mapping region, the upper portion of the system memory (referred to as high memory) is not normally accessible to the kernel. Other mechanisms must be used, such as `kmap()` and `kmap_atomic()`, in order to gain temporary access to these high-memory pages.

相比之下，在物理内存多于直接映射区域中可映射内存的系统中，内核通常无法访问系统内存的上部（称为高内存）。必须使用其他机制，例如 `kmap（）` 和 `kmap_atomic（）`，以便临时访问这些高内存页。

> Above the direct mapping region is the vmalloc region that is controlled by `vmalloc()`. This allocation mechanism provides the ability to allocate pages of memory in a virtually contiguous way in spite of the fact that these pages may not necessarily be physically contiguous. It is particularly useful for allocating a large amount of memory pages in a virtually contiguous manner, as otherwise it can be impossible to find the equivalent amount of contiguous free physical pages.

在直接映射区之上是 vmalloc 区域，是由 `vmalloc（）` 控制的。这种分配机制提供了以虚拟连续的方式分配内存页的能力，尽管这些页不一定必须是物理上连续的。它对于以虚拟连续的方式分配大量内存页特别有用，否则可能无法找到等量的连续空闲物理页。

> Further reading about the memory management in Linux can be found in [*Linux Device Drivers* [PDF\]](https://lwn.net/images/pdf/LDD3/ch15.pdf) and this [LWN article](https://lwn.net/Articles/356378/).

如果想进一步阅读 Linux 内存管理相关的文章，推荐[ Linux 设备驱动程序\[PDF\]](https://lwn.net/images/pdf/LDD3/ch15.pdf)和[LWN文章](https://lwn.net/Articles/356378/)

## 如何开始(How to start?)

> With your head full of the processor's specifications and kernel principles, it is finally time to add some files to this newly created arch directory. But wait ... where and how should we start? As with any porting or even any code that must respect a certain API, the procedure is a two-step process.

当你对处理器规格书和内核原理熟透以后，终于到了向这个新创建的 arch 目录添加一些文件的时候了。但是等等。。。我们应该从哪里开始，如何开始？就像任何移植或任何代码都必须遵循某个 API 那样，这个过程也需要，可以分为两步：

> First, a minimal set of files that define a minimal set of symbols (functions, variables, defines) is necessary for the kernel to even compile. This set of files and symbols can often be deduced from compilation failures: if compilation fails because of a missing file/symbol, it is a good indicator that it should probably be implemented (or sometimes that some configuration options should be modified). In the case of porting Linux, this approach is particularly relevant when implementing the numerous headers that define the API between the architecture-specific code and the rest of the kernel.

首先，甚至只是为了满足内核编译，就需要最小的一组文件，用于定义最小的一个符号集（函数、变量、定义）。这组文件和符号通常可以从编译失败中推断出来：如果由于缺少文件/符号而导致编译失败，则很好地表明可能应该实现它（或者有时应该修改某些配置选项）。在移植 Linux 的情况下，当实现大量定义了 API（在架构特定代码与内核公共代码之间）的头文件时，这种方法尤其重要。

> After the kernel finally compiles and is able to be executed on the target hardware, it is useful to know that the boot code is very sequential. That allows many functions to stay empty at first and to only be implemented gradually until the system finally becomes stable and reaches the `init` process. This approach is generally possible for almost all of the C functions executed after the early assembly boot code. However it is advised to have the `early_printk()` infrastructure up and working otherwise it can be difficult to debug.

在内核最终编译并能够在目标硬件上执行之后，了解引导代码的执行流程非常有用。这允许许多函数在开始时保持为空，直到系统最终变得稳定并达到 `init` 进程，才逐渐实现。这种方法通常适用于在早期汇编引导代码之后执行的几乎所有 C 函数。不过，建议您先让 `early_printk` 工作好，否则可能很难调试。

## 终于开始了：非代码文件的最小集合(Finally getting started: the minimal set of non-code files)

> Porting the compilation tools to the new processor architecture is a prerequisite to porting the Linux kernel, but here we'll assume it has already been performed. All that is left to do in terms of compilation tools is to build a cross-compiler. Since at this point it is likely that porting a standard C library has not been completed (or even started), only a stage-1 cross-compiler can be created.

将编译工具移植到新的处理器架构是移植 Linux 内核的先决条件，但在这里，我们假设它已经准备好了。就编译工具而言，剩下要做的就是构建一个交叉编译器。由于此时很可能尚未完成（甚至尚未启动）标准 C 库的移植，因此只能创建一个阶段 1 交叉编译器。

> Such a cross-compiler is only able to compile source code for bare metal execution, which is a perfect fit for the kernel since it does not depend on any external library. In contrast, a stage-2 cross-compiler has built-in support for a standard C library.

这种交叉编译器只能编译裸机执行的源代码，这非常适合内核，因为它不依赖任何外部库。相比之下，stage-2 交叉编译器内置了对标准C库的支持。

> The first step of porting Linux to a new processor is the creation of a new directory inside `arch/`, which is located at the root of the kernel tree (e.g. `linux/arch/tsar/` in my case). Inside this new directory, the layout is quite standardized:

将 Linux 移植到新处理器的第一步是在` arch/ `中创建一个新目录，该目录位于内核树的根（例如，在我的例子中是 `Linux/arch/tsar/` ）。在这个新目录中，布局相当标准化：

> - `configs/`: default configurations for supported systems (i.e. `*_defconfig` files)
> - `include/asm/` for the headers dedicated to internal use only, i.e. Linux source code
> - `include/uapi/asm` for the headers that are meant to be exported to user space (e.g. the libc)
> - `kernel/`: general kernel management
> - `lib/`: optimized utility routines (e.g. `memcpy()`, `memset()`, etc.)
> - `mm/`: memory management

- `configs/`：支持系统的默认配置 (i.e. `*_defconfig` files)

- `include/asm/` ：Linux源码内部使用的头文件

- `include/uapi/asm`： 对于要导出到用户空间（例如 libc ）的头文件

- `kernel/`：通用内核管理

- `lib/`：优化过的那套函数 (e.g. `memcpy()`, `memset()`, etc.)

- `mm/`：内存管理

  > The great thing is that once the new arch directory exists, Linux automatically knows about it. It only complains about not finding a Makefile, not about this new architecture:

一旦新的 arch 目录存在，Linux 就会自动知道它。但是会报找不到 Makefile ，而不是找不到这种新的架构。
```bash
    ~/linux $ make ARCH=tsar
    Makefile: ~/linux/arch/tsar/Makefile: No such file or directory
```
>  As shown in the following example, a minimal arch Makefile only has a few variables to specify:

如以下所示，最小 arch Makefile 只有几个变量需要指定：

```
    KBUILD_DEFCONFIG := tsar_defconfig

    KBUILD_CFLAGS += -pipe -D__linux__ -G 0 -msoft-float
    KBUILD_AFLAGS += $(KBUILD_CFLAGS)

    head-y := arch/tsar/kernel/head.o

    core-y += arch/tsar/kernel/
    core-y += arch/tsar/mm/

    LIBGCC := $(shell $(CC) $(KBUILD_CFLAGS) -print-libgcc-file-name)
    libs-y += $(LIBGCC)
    libs-y += arch/tsar/lib/

    drivers-y += arch/tsar/drivers/
```
> - `KBUILD_DEFCONFIG` must hold the name of a valid default configuration, which is one of the `defconfig` files in the `configs` directory (e.g. `configs/tsar_defconfig`).
> - `KBUILD_CFLAGS` and `KBUILD_AFLAGS` define compilation flags, respectively for the compiler and the assembler.
> - `{head,core,libs,...}-y` list the objects (or subdirectory containing the objects) to be compiled in the kernel image (see [Documentation/kbuild/makefiles.txt](https://www.kernel.org/doc/Documentation/kbuild/makefiles.txt) for detailed information)

- `KBUILD_DEFCONFIG` 必须包含有效默认配置文件的名称，该配置是 configs 目录中的 defconfig 文件之一 (e.g. configs/tsar_defconfig).

- `KBUILD_CFLAGS `和` KBUILD_AFLAGS`用于定义编译 FLAGS（主要是一些功能特性的开关和设定），分别用于编译器和汇编器。

- `{head，core，libs，}-y`列出要在内核映像中编译的对象（或包含对象的子目录）（有关详细信息，请参阅[Documentation/kbuild/makefiles.txt](https://www.kernel.org/doc/Documentation/kbuild/makefiles.txt)）

> Another file that has its place at the root of the arch directory is `Kconfig`. This file mainly serves two purposes: it defines new arch-specific configuration options that describe the features of the architecture, and it selects arch-independent configuration options (i.e. options that are already defined elsewhere in Linux source code) that apply to the architecture.

另一个位于 arch 目录根目录下的文件是`Kconfig`。该文件主要用于两个目的：

- 定义描述架构的各种特性 arch 的配置选项。
- 选择适用于该架构的架构无关配置选项（即 Linux 源代码中其他地方已经定义的选项，比如 Perf, Ftrace 等公共选项）。

> As this will be the main configuration file for the newly created arch, its content also determines the layout of the menuconfig command (e.g. `make ARCH=tsar menuconfig`). It is difficult to give a snippet of the file as it depends very much on the targeted architecture, but looking at the same file for other (simple) architectures should definitely help.

由于这将是新创建的 arch 的主要配置文件，它的内容也决定了 menuconfig 命令的布局（例如 `make ARCH=tsar menuconfig`）。 很难给出一个例子，因为它在很大程度上取决于目标架构，但是可以参考一下其他简单架构的配置文件。

> The `defconfig` file (e.g. `configs/tsar_defconfig`) is necessary to complete the files related to the Linux kernel build system (kbuild). Its role is to define the default configuration for the architecture, which basically means specifying a set of configuration options that will be used as a seed to generate a full configuration for the Linux kernel compilation. Once again, starting from defconfig files of other architectures should help, but it is still advised to refine them, as they tend to activate many more features than a minimalistic system would ever need—support for USB, IOMMU, or even filesystems is, for example, too early at this stage of porting.

`defconfig` 文件（例如` configs/tsar_defconfig`）是完成与 Linux 内核构建系统（kbuild）相关的文件所必需的。 它的作用是定义架构的默认配置，这基本上意味着指定一组配置选项，这些选项将用作种子，以生成用于 Linux 内核编译的完整配置。 再一次，从其他架构的 defconfig 文件开始应该会有所帮助，但仍然建议对其进行改进，因为它们往往会能激活更多功能——支持 USB、IOMMU 甚至文件系统，不过在这个移植阶段搞这些还太早。

> Finally the last "not really code but still really important" file to create is a script (usually located at `kernel/vmlinux.lds.S`) that will instruct the linker how to place the various sections of code and data in the final kernel image. For example, it is usually necessary for the early assembly boot code to be set at the very beginning of the binary, and it is this script that allows us do so.

最后，要创建的最后一个“不是真正的代码但仍然很重要”的文件是一个脚本（通常位于 `kernel/vmlinux.lds.S`），它将指示链接器如何将各个代码段和数据段放置在最终的内核映像中 . 例如，通常需要在二进制文件的最开头设置早期汇编引导代码，正是这个脚本干的。

## 结论(Conclusion)

> At this point, the build system is ready to be used: it is now possible to generate an initial kernel configuration, customize it, and even start compiling from it. However, the compilation stops very quickly since the port still does not contain any code.

至此，构建系统就可以使用了：现在可以生成初始内核配置，对其进行自定义，甚至开始编译。 但是，编译很快就会停止，因为该移植仍然不包含任何代码。

> In the next article, we will dive into some code for the second portion of the port: the headers, the early assembly boot code, and all the most important arch functions that are executed until the first kernel thread is created.

在下一篇文章中，我们将深入探讨移植的第二部分的一些代码：头文件、早期的汇编引导代码，以及在创建第一个内核线程之前执行的所有最重要的 arch 函数。
