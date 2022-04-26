---
layout: post
author: 'Nikq'
title: "将 Linux 移植到新的处理器架构，第 3 部分：收尾"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /lwn-657939/
description: "本文是 Porting Linux to a new processor architecture 系列翻译的第三部分，也是最后一篇。该成果由 RISC-V Linux 内核兴趣小组输出。"
category:
  - 开源项目
  - Risc-V
  - 移植 Linux 内核
tags:
  - 移植
  - RISC-V
  - TSAR
  - Linux 内核
  - 内核线程
  - 进程管理
  - 进程调度
  - Page fault
  - init 进程
---

> Title:      [Porting Linux to a new processor architecture, part 3: To the finish line](https://lwn.net/Articles/657939/)
> Author:     Joël Porquet@**September 23, 2015**
> Translator: 通天塔 <985400330@qq.com>
> Date:       20220406
> Revisor:    lzufalcon <falcon@tinylab.org>
> Project:    [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

**编者按**：该系列共 3 篇译文介绍如何将 Linux 移植到新的处理器架构，此为第 3 篇，敬请收藏或推荐给周边朋友。特别感谢作者、译者和校订老师通宵达旦地撰写、翻译和校订，大家多多点赞支持与鼓励。感兴趣的同学也可以参加该翻译成果所属的开源活动，各种文字与视频成果正在泰晓科技网站和公众号连载，也在持续召集爱好者中，见 [刚组建的 RISC-V Linux 内核兴趣小组正在召集爱好者](https://tinylab.org/riscv-linux-analyse/)。

## 前言

> This series of articles provides an overview of the procedure one can follow when porting the Linux kernel to a new processor architecture. [Part 1](https://tinylab.org/lwn-654783/) and [part 2](https://tinylab.org/lwn-656286/) focused on the non-code-related groundwork and the early code, from the assembly boot code to the creation of the first kernel thread. Following on from those, the series concludes by looking at the last portion of the procedure. As will be seen, most of the remaining work for launching the `init` process deals with thread and process management.

本系列文章概述了将 Linux 内核移植到一个新的处理器架构可以遵循的过程。[Part 1](https://tinylab.org/lwn-654783/) 和 [Part 2](https://tinylab.org/lwn-656286/) 重点讲了代码无关的基础和早期代码，从汇编引导代码到第一个内核线程的创建。在前述工作的基础上，本文作为整个系列文章的收尾之作，将介绍整个移植过程的最后一部分。我们即将看到，`init` 进程启动工作的最后主要是处理好线程和进程的管理。


## 产生内核线程（Spawning kernel threads）

> When `start_kernel()` performs its last function call (to `rest_init()`), the memory-management subsystem is fully operational, the boot processor is running and able to process both exceptions and interrupts, and the system has a notion of time.

当 `start_kernel()` 执行了最后一个函数调用 （`rest_init()`），内存管理子系统完全运行起来，启动的处理器正在运行中并且能够处理所有的异常和中断，而且定时器和时间管理子系统也已经工作。

> While the execution flow has so far been sequential and mono-threaded, the main job handled by `rest_init()` before turning into the boot idle thread is to create two kernel threads: `kernel_init`, which will be discussed in the next section, and `kthreadd`. As one can imagine, creating these kernel threads (and any other kinds of threads for that matter, from user threads within the same process to actual processes) implies the existence of a complex process-management infrastructure. Most of the infrastructure to create a new thread is not architecture-specific: operations such as copying the `task_struct` structure or the credentials, setting up the scheduler, and so on do not usually need any architecture-specific code. However, the process-management code must define a few architecture-specific parts, mainly for setting up the stack for each new thread and for switching between threads.

虽然到目前为止执行流程是按照顺序，并且是单线程的，但在进入启动空闲线程（boot idle thread）之前，`reset_init` 的主要任务是创建两个内核线程：`kernel_init` 和 `kthreadd`。可以想象，创建这些内核线程（以及与此相关的任何其他类型的线程，从同一进程中的用户线程到实际进程）意味着存在一个复杂的进程管理机制。大多数的创建新线程的机制都是架构无关的：例如复制 `task_struct` 结构体或者凭证（credentials），设置调度器等，都不需要架构相关代码。然而，进程管理机制一定要定义一些架构相关部分，一方面为每个线程设置堆栈，另一方面提供线程间切换的架构支持。

> Linux always avoids creating new resources from scratch, especially new threads. With the exception of the initial thread (the one that has so far been booting the system and that we have implicitly been discussing), the kernel always duplicates an existing thread and modifies the copy to make it into the desired new thread. The same principle applies after thread creation, when the new thread's execution begins for the first time, as it is easier to resume the execution of a thread than to start it from scratch. This mainly means that the newly allocated stack must be initialized such that when switching to the new thread for the first time, the thread looks like it is resuming its execution—as if it had simply been stopped earlier.

Linux 总是避免从零开始创建新的资源，尤其是新线程。除了初始线程（到目前为止引导系统的那个线程，我们在之前已经简单讨论过），内核总是复制现有的线程，并修改该副本，使其成为所期望的新线程。同样的原则也适用于线程创建之后——当新线程第一次开始执行时，因为恢复执行线程比从头开始执行更容易。这主要意味着必须对新分配的堆栈进行初始化，以便在第一次切换到新线程时，线程看起来像是在恢复执行，就像它刚才被停止了一样。

> To further understand this mechanism, delving a bit into the thread-switching mechanism and more specifically into the switch of execution flow implemented by the architecture-specific context-switching routine `switch_to()` is required. This routine, which is always written in assembly language, is always called by the current (soon to be previous) thread while returning as the next (future current) thread. Part of this trick is achieved by saving the current context in the stack of the current thread, switching stack pointers to use the stack of the next thread, and restoring the saved context from it. As with a typical function, `switch_to()` finally returns to the "calling" function using the instruction address that had been saved on the stack of the newly current thread.

为了进一步理解这种机制，需要深入研究线程切换机制，更具体地说，需要研究架构相关的上下文切换函数 `switch_to()` 实现的执行流切换。这个事务（routine），总是由汇编语言写成，该函数总是被当前（很快变成前一个）线程调用同时作为下一个（未来的当前）线程的返回。通过在当前线程堆栈保存当前上下文，切换堆栈指针来使用下一个线程的堆栈，并且在这个堆栈中恢复之前保存的上下文来实现线程的切换。与典型的函数一样，`switch_to()` 通过使用已保存在新线程堆栈上的指令地址，最终返回到“calling”函数，

> In the case that the next thread had previously been running and was temporarily removed from the processor, returning to the calling function would be a normal event that would eventually lead the thread to resume the execution of its own code. However, for a brand new thread, there would not have been any function to call `switch_to()` in order to save the thread's context. This is why the stack of a new thread must be initialized to pretend that there has been a previous function call, enabling `switch_to()` to return after restoring this new thread. Such a function is usually setup to be a few assembly lines acting as a trampoline to the thread's code.

如果下一个线程之前已经运行过，并且暂时从处理器中删除了，那么返回调用函数将是一个正常的事件，最终将让线程恢复并继续执行它自己的代码。然而，对于一个全新的线程，将不会有任何函数调用 `switch_to()` 来保存线程的上下文。这就是为什么一个新线程的堆栈必须被初始化，以假装之前有一个函数调用，使 `switch_to()` 在恢复这个新线程后返回。这样的函数通常由几行汇编代码组成，充当线程代码的跳板（trampoline）。

> Note that switching to a kernel thread does not generally involve switching to another page table since the kernel address space, in which all kernel threads run, is defined in every page table structure. For user processes, the switch to their own page table is performed by the architecture-specific routine `switch_mm()`.

注意，切换到内核线程通常不涉及切换到另一个页表，因为所有内核线程运行的内核地址空间已经在每个页表结构中定义了。对于用户进程，切换到它们自己的页表是由架构相关函数 `switch_mm()` 执行的。

## 第一个内核线程（The first kernel thread）

> As explained in the [source code](http://lxr.free-electrons.com/source/init/main.c?v=4.2#L386), the only reason the kernel thread `kernel_init` is created first is that it must obtain PID 1. This is the PID that the `init` process (i.e. the first user space process born from `kernel_init`) traditionally inherits.

正如在 [源代码](http://lxr.free-electrons.com/source/init/main.c?v=4.2#L386) 中解释的那样，首先创建内核线程 `kernel_init` 的唯一原因是它必须获得 PID 1。这个 PID 是 `init` 进程（即从 `kernel_init` 中诞生的第一个用户空间进程）按照惯例继承的。

> Interestingly, the first task of `kernel_init` is to wait for the second kernel thread, `kthreadd`, to be ready. `kthreadd` is the kernel thread daemon in charge of asynchronously spawning new kernel threads whenever requested. Once `kthreadd` is started, `kernel_init` proceeds with the second phase of booting, which includes a few architecture-specific initializations.

有趣的是，`kernel_init` 的第一个任务是等待第二个内核线程 `kthreadd` 准备好，`kthreadd` 是内核的守护进程，负责无论何时被请求，异步生成新的内核线程。一旦 `kthreadd` 开始，`kernel_init` 就会进入启动的第二阶段，其中包括一些架构相关的初始化。

> In the case of a multiprocessor system, `kernel_init` begins by starting the other processors before initializing the various subsystems composing the driver model (e.g. devtmpfs, devices, buses, etc.) and, later, using the defined initialization calls to bring up the actual device drivers for the underlying hardware system. Before getting into the "fancy" device drivers (e.g. block device, framebuffer, etc.), it is probably a good idea to focus on having at least an operational terminal (by implementing the corresponding driver if necessary), especially since the early console set up by `early_printk()` is supposed to be replaced by a real, full-featured console shortly after.

在多处理器系统的情况下，`kernel_init` 首先启动其他处理器，然后初始化多个构成驱动模型的子系统（例如 devtmpfs，设备，总线等），然后，通过提前定义好的初始化调用（init calls）来启动为底层硬件系统编写的实际设备驱动。在进入复杂的设备驱动（例如块设备驱动、Framebuffer 驱动等）之前，把精力集中在拥有至少一个可操作终端（必要时需实现相应的驱动程序）是很必要的，特别是在 `early_printk()` 提供的早期控制台（译注：新版已经被 earlycon 取代）被一个全功能的真实控制台（console）替代之前。

> It is also through these initialization calls that the initramfs is unpacked and the initial root filesystem (rootfs) is mounted. There are a [few options](https://www.kernel.org/doc/Documentation/early-userspace/README) for mounting an initial rootfs but I have found [initramfs](https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt) to be the simplest when porting Linux. Basically this means that the rootfs is statically built at compilation time and integrated into the kernel binary image. After being mounted, the rootfs can give access to the mandatory `/init` and `/dev/console`.

也正是通过这些初始化调用（init calls），initramfs 被解压缩，初始根文件系统（rootfs）被挂载。有很多 [方法](https://www.kernel.org/doc/Documentation/early-userspace/README) 可用于挂载初始的 rootfs，但我发现 [initramfs](https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt) 是移植 Linux 时最简单的。基本上，initramfs 意味着文件系统是在编译时静态构建的，并集成到内核二进制的映像中。挂载后，文件系统将能够启动用户指定的 `/init` 和 `/dev/console`。

> Finally, the init memory is freed (i.e. the memory containing code and data that were used only during the initialization phase and that are no longer needed) and the `init` process that has been found on the rootfs is launched.

最后，init 内存被释放（即，内存中包含的代码和数据，这些内存只在初始化阶段使用，以后不再需要），并且 rootfs 中找到的 `init` 进程也被运行了。

## 执行 init（Executing init）

> At this point, launching `init` will probably result in an immediate fault when trying to fetch the first instruction. This is because, as with creating threads, being able to execute the `init` process (and actually any user-space application) first involves a bit of groundwork.

此时，当尝试获取第一个指令时，启动 `init` 可能会立即导致错误。这是因为，与创建线程一样，能够执行 `init` 进程（实际上是任何用户空间应用程序）首先需要一些基础工作。

> The function that needs to be implemented in order to solve the instruction-fetching issue is the page fault handler. Linux is lazy, particularly when it comes to user applications and, by default, does not pre-load the text and data of applications into memory. Instead, it only sets up all of the kernel structures that are strictly required and lets applications fault at their first instruction because the pages containing their text segment have usually not been loaded yet.

取指问题，需要实现的函数是页错误处理程序。Linux 很慵懒，特别是在用户应用程序方面，默认情况下，它不会将应用程序的文本和数据预加载到内存中。取而代之的是，它只创建被严格要求的所有内核结构，并让应用程序在执行第一个指令时出错，因为包含代码段的页通常还没有加载。

> This is actually perfectly intentional behavior since it is expected that such a memory fault will be caught and fixed by the page fault handler. This handler can be seen as an intricate switch statement that is able to treat every fault related to memory: from `vmalloc()` faults that necessitate a synchronization with the reference page table to stack expansions in user applications. In this case, the handler will determine that the page fault corresponds to a valid virtual memory area (VMA) of the application and will consequently load the missing page in memory before retrying to run the application.

这完全是故意的行为，因为这个内存错误将会被捕捉，并且被页错误处理函数解决。这个处理函数可以被看作一个复杂的 switch 语句，它能够处理所有与内存相关的错误：从需要与引用页表同步的 `vmalloc()` 错误到用户应用程序中的堆栈扩展。在这种情况下，处理函数将确定页错误对应于应用程序的有效虚拟内存区域（VMA），并因此在重新尝试运行应用程序之前将丢失的页面装入内存。

> Once the page fault handler is able to catch memory faults, it is likely that an extremely simple `init` process can be executed. However, it will not be able to do much as it cannot yet request any service from the kernel through system calls, such as printing to the terminal. To this end, the system-call infrastructure must be completed with a few architecture-specific parts. System calls are treated as software interrupts since they are accessed by a user instruction that makes the processor automatically switch to kernel mode, like hardware interrupts do. Besides defining the list of system calls supported by the port, handling system calls involves enhancing the interrupt and exception handler with the additional ability to receive them.

一旦页错误处理程序能够捕获内存错误，就可能执行一个极其简单的 `init` 进程。然而，进程还不能做很多事情，因为他还不能通过系统调用从内核中请求任何服务，比如打印到终端。为此，系统调用功能必须被一些架构相关的部分来完成。系统调用被视为软件中断，因为它们被用户指令访问，使处理器自动切换到内核模式，就像硬件中断一样。除了定义本次移植中已被支持的系统调用之外，处理系统调用还需要：
- 增强处理中断和异常的程序
- 接收中断和异常的能力

> Once there is support for system calls, it should now be possible to execute a "hello world" `init` that is able to open the main console and write a message. But there are still missing pieces in order to have a full-featured `init` that is able to start other applications and communicate with them as well as exchange data with the kernel.

一旦支持系统调用，现在应该可以执行一个“hello world”的 `init`，它能够打开主控制台并写一条消息。但是，离一个功能齐备的 `init` 还有一点距离。这样一个 `init` 要能启动其他应用程序、与它们通信并能与内核交换数据。

> The first step toward this goal concerns the management of signals and, more particularly, signal delivery (either from another process or from the kernel itself). If a process has defined a handler for a specific signal, then this handler must be called whenever the given signal is pending. Such an event occurs when the targeted process is about to get scheduled again. More specifically, this means that when resuming the process, right at the moment of the next transition back to user mode, the execution flow of the process must be altered in order to execute the handler instead. Some space must also be made on the application's stack for the execution of the handler. Once the handler has finished its execution and has returned to the kernel (via a system call that had been previously injected into the handler's context), the context of the process is restored so that it can resume its normal execution.

实现这一目标的第一步涉及信号管理，更具体地说，是信号传递（来自另一个进程或来自内核本身）。如果一个进程已经为一个特定的信号定义了一个处理程序，那么只要给定的信号处于未决状态，就必须调用这个处理程序。当目标进程即将再次被调度时，会发生此类事件。更具体地说，这意味着当恢复进程时，就在下一次转换回用户模式的时刻，为了执行信号处理程序，进程的执行流程必须做一些调整。还必须在应用程序的堆栈上留出一些空间来用于信号处理程序的执行。一旦处理程序完成执行并返回内核（通过先前已注入处理程序正文的系统调用），进程的上下文将恢复，以便它可以恢复其正常执行。

> The second and last step for fully running user-space applications deals with user-space memory access: when the kernel wants to copy data from or to user-space pages. Such an operation can be quite dangerous if, for example, the application gives a bogus pointer, which would potentially result in kernel panics (or security vulnerabilities) if it is not checked properly. To circumvent this problem, it is necessary to write architecture-specific routines that use some assembly magic to register the addresses of all of the instructions performing the actual accesses to the user-space memory in an exception table. As explained in this [LWN article](http://lwn.net/2001/0222/kernel.php3) from 2001, "if ever a fault happens in kernel mode, the fault handler scans through the exception table trying to match the address of the faulting instruction with a table entry. If a match is found, a special error exit is taken, the copy operation fails gracefully, and the system call returns a segmentation fault error."

完全运行用户程序的第二个也是最后一个步骤是用户空间的内存访问：当内核想要从用户空间页中读写数据。一些操作可能相当危险，例如，如果应用程序给出一个伪指针，如果指针不被严格的检查，可能会导致内核崩溃（或者安全漏洞）。为了解决这个问题，有必要编写架构相关的例程（routines），这些例程使用一些汇编代码，将所有指令（实际访问用户空间内存）的地址注册到一个异常表中。如 2001 年 [LWN article](http://lwn.net/2001/0222/kernel.php3) 所述：“如果在内核模式中发生错误，则错误处理程序通过异常表进行扫描，试图将错误指令与表项匹配。如果找到匹配，就会产生一个特殊的错误退出，内核读写用户空间的内存操作将优雅地失败，系统调用返回一个段错误。

## 结论（Conclusion）

> Once a full-featured `init` process is able to run and give access to a shell, it probably signals the end of the porting process. But it is most likely only the beginning of the adventure, as the port now needs to be maintained (as the internal APIs sometimes change quickly), and can also be enhanced in numerous ways: adding support for multiprocessor and NUMA systems, implementing more device drivers, etc.

一旦一个全功能的 `init` 进程能够运行，并且能够提供一个 shell 的入口，这可能就是本次移植过程的结束信号。但是整个冒险可能刚刚开始，因为这个移植现在需要进行维护（因为内部的 API 有时变化的很快），而且还可以通过以下几种方式进行增强：增加多处理器支持和 NUMA 系统，实现更多设备驱动等。

> By describing the long journey of porting Linux to a new processor architecture, I hope that this series of articles will contribute to remedying the lack of documentation in this area and will help the next brave programmer who one day embarks upon this challenging, but ultimately rewarding, experience.

通过描述将 Linux 移植到新处理器架构的漫长过程，我希望本系列文章将有助于弥补这方面文档的不足，并将帮助下一个勇敢的程序员，有朝一日，他们也会发起类似挑战，并终将在人生履历上增加灿烂的一笔。

> [The author would like to thank Ena Lupine for her help in writing and publishing these articles.]

[作者要感谢 Ena Lupine 在撰写和发表这些文章时提供的帮助。]
