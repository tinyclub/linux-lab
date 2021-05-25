---
layout: post
author: 'VainPointer'
title: "LWN 531148: Linux 内核文件中的非常规节"
draft: true
album: "LWN 中文翻译"
group: "translation"
license: "cc-by-sa-4.0"
permalink: /lwn-531148/
description: "LWN 文章翻译，Linux 内核文件中的非常规节"
category:
  - 启动管理
  - LWN
tags:
  - Linux
  - ELF
---

> 原文：[Special sections in Linux binaries](https://lwn.net/Articles/531148/)
> 原创：By Daniel Pierre Bovet @ **January 3, 2013**
> 翻译：By [VainPointer](https://gitee.com/vainpointer)
> 校对：By [unicornx](https://gitee.com/unicornx)

> A section is an area in an object file that contains information which is useful for linking: the program's code and data, relocation information, and more. It turns out that the Linux kernel has some additional types of sections, called "special sections", that are used to implement various kernel features. Special sections aren't well known, so it is worth shedding some light on the topic.

目标文件 (object file) 中的节 (section) 包含了用于链接的信息：程序的代码和数据、重定位信息等。本文介绍 Linux 内核中一些附加类型的节，称为 “非常规节 (special section)”，用于实现各种内核特性。非常规节并不广为人知，所以值得对这个话题做一些解释。

> # Segments and sections

# 段 (segment) 与节 (section)

> Although Linux supports several binary file formats, ELF ([Executable and Linking Format](http://en.wikipedia.org/wiki/Executable_and_Linkable_Format)) is the preferred format since it is flexible and extensible by design, and it is not bound to any particular processor or architecture. ELF binary files consist of an ELF header followed by a few segments. Each segment, in turn, includes one or more sections. The length of each segment and of each section is specified in the ELF header. Most segments, and thus most sections, have an initial address which is also specified in the ELF header. In addition, each segment has its own access rights.

尽管 Linux 支持几种二进制文件格式，但 ELF ([Executable and Linking Format][1]) 由于其设计得灵活、可拓展，并且不受限于任何特定的处理器或架构，而成为了首选格式。ELF 二进制文件由一个 ELF 头和几个段组成。每个段又包含一个或多个节。每个段和每个节的长度在 ELF 头中指定。大多数段和节有一个初始地址，也在 ELF 头中指定。此外，每个段都有自己的访问权限。

> The linker merges together all sections of the same type included in the input object files into a single section and assigns an initial address to it. For instance, the `.text` sections of all object files are merged together into a single `.text` section, which by default contains all of the code in the program. Some of the segments defined in an ELF binary file are used by the GNU loader to assign memory regions with specific access rights to the process.

目标文件输入到链接器，相同类型的所有节会被合并到一个节中，并为其指定初始地址。例如，所有目标文件的  `.text` 节合并到一个 `.text` 节中，默认情况下该节包含程序中的所有代码。GNU 加载器基于 ELF 二进制文件中定义的段来分配内存区域并赋予这些内存区域以特定的访问权限。

> Executable files include four canonical sections called, by convention, `.text`, `.data`, `.rodata`, and `.bss`. The `.text` section contains executable code and is packed into a segment which has the read and execute access rights. The `.data` and `.bss` sections contain initialized and uninitialized data respectively, and are packed into a segment which has the read and write access rights.

可执行文件包括四个典型的节，按惯例称为 `.text`、`.data`、`.rodata` 和 `.bss`。`.text` 节包含可执行代码，并被打包在具有读取和执行访问权限的段。`.data` 节和 `.bss` 节分别包含初始化和未初始化的数据，并被打包在具有读写访问权限的段中。

> Linux loads the `.text` section into memory only once, no matter how many times an application is loaded. This reduces memory usage and launch time and is safe because the code doesn't change. For that reason, the `.rodata` section, which contains read-only initialized data, is packed into the same segment that contains the `.text` section. The `.data` section contains information that could be changed during application execution, so this section must be copied for every instance.

一个程序不管被加载了多少次，Linux 只将其 `.text` 节加载到内存中一次。这减少了内存使用量和启动时间，而且因为代码不会改变还是安全的。由于这个原因，包含已初始化的只读数据的  `.rodata` 节被打包到 `.text` 节的同一段中。`.data`  节中包含在程序执行期间可能更改的信息，因此必须为每个实例复制此节。

> The "`readelf -S`" command lists the sections included in an executable file, while the "`readelf -l`" command lists the segments included in an executable file.

“`readelf-S`” 命令列出可执行文件中的节，而 “`readelf-l`” 命令列出可执行文件中的段。

> # Defining a section

# 节的定义

> Where are the sections declared? If you look at a standard C program you won't find any reference to a section. However, if you look at the assembly version of the C program you will find several assembly directives that define the beginning of a section. More precisely, the "`.text`", "`.data`", and "`.section rodata`" directives identify the beginning of the the three canonical sections mentioned previously, while the "`.comm `" directive defines an area of uninitialized data.

节是在何处被声明的？如果你看一个标准的 C 程序，你将找不到任何一个节的引用。但是，如果你查看 C 程序的汇编版本，你将发现几个定义节的汇编标记 (directive)。即，“`.text`”、“`.data`” 和 “`.section rodata`” 标记标识了前述的三个典型的节的起始处，而 “`.comm`” 标记定义了未初始化数据的区域。

> The GNU C compiler translates a source file into the equivalent assembly language file. The next step is carried out by the GNU assembler, which produces an object file. This file is an *ELF relocatable* file which contains only sections (segments which have absolute addresses cannot be defined in a relocatable file). Sections are now filled, with the exception of the `.bss` section, which just has a length associated with it.

GNU C 编译器（译者注：cc1）将源文件翻译为等效的汇编语言文件。下一步由 GNU 汇编器（译者注：as）生成一个目标文件。此文件是一个仅包含节的 *ELF 可重定位 (relocatable)* 文件（含有绝对地址的段不能在可重定位文件中定义）。此时，除了 `.bss` 节只有与其相关联的长度信息，其他节都已填充好了，

> The assembler scans the assembly lines, translates them into binary code, and inserts the binary code into sections. Each section has its own offset which tells the assembler where to insert the next byte. The assembler acts on one section at a time, which is called the *current section*. In some cases, for instance to allocate space to uninitialized global variables, the assembler does not add bytes in the current section, it just increments its offset.

汇编器 (assembler) 扫描汇编语言的行，将它们转换成二进制代码，并将二进制代码插入到各个节中。每个节都有自己的偏移量，以告知汇编器在何处插入下一个字节。汇编器一次一个节地工作，称为*当前节*。在某些情况下，汇编器不在当前节中添加字节，只增加其偏移量，例如在给未初始化的全局变量分配空间时。

![sections](/wp-content/uploads/2021/05/lwn-531148.png)

> Each assembly language program is assembled separately; the assembler assumes thus that the starting address of an object program is always 0. The GNU linker receives as input a group of these object files and combines them into a single executable file. This kind of linkage is called *static linkage* because it is performed before running the program.

每一个汇编语言程序都是单独汇编的；汇编器假定目标程序的起始地址总是 0。GNU 链接器 (译者注：ld) 接收一组目标文件作为输入，并将它们组合成一个可执行文件。这种链接称为 “静态链接”，因为它是在运行程序之前完成的。

> The linker relies on a linker script to decide which address to assign to each section of the executable file. To get the default script of your system, you can issue the command:

链接器依赖链接器脚本来决定将哪个地址分配给可执行文件的每个部分。要获取系统的默认脚本，可以执行命令：

    ld --verbose

> # Special sections

# 非常规节

> If you compare the sections present in a simple executable file, say one associated with `helloworld.c`, with those present in the Linux kernel executable, you will notice that Linux relies on many *special sections* not present in conventional executable files. The number of such sections depends on the hardware platform. On an x86_64 system over 30 special sections are defined, while on an ARM system there are about ten.

如果将一个简单可执行文件（例如由 `helloworld.c` 编译出的程序）中的节与 Linux 内核可执行文件中的节进行比较，你会注意到 Linux 依赖于许多常规可执行文件中没有的*非常规节*。这些节的数量取决于硬件平台。在 x86_64 系统上，定义了 30 多个非常规节，而在 ARM 系统上，定义了大约 10 个。

> You can use the `readelf` command to extract data from the ELF header of `vmlinux`, which is the kernel executable. When issuing this command on an x86_64 box you get something like:

可以使用 `readelf` 命令从内核可执行文件 `vmlinux` 的 ELF 头中提取数据。在 x86_64 上执行此命令时，会得到如下结果：

    Elf file type is EXEC (Executable file)
    Entry point 0x1000000
    There are 6 program headers, starting at offset 64
    
    Program Headers:
      Type           Offset             VirtAddr           PhysAddr
    	               FileSiz            MemSiz              Flags  Align
      LOAD           0x0000000000200000 0xffffffff81000000 0x0000000001000000
    	               0x00000000007a3000 0x00000000007a3000  R E    200000
      LOAD           0x0000000000a00000 0xffffffff81800000 0x0000000001800000
    	               0x00000000000c7b40 0x00000000000c7b40  RW     200000
      LOAD           0x0000000000c00000 0xffffffffff600000 0x00000000018c8000
    	               0x0000000000000d60 0x0000000000000d60  R E    200000
      LOAD           0x0000000000e00000 0x0000000000000000 0x00000000018c9000
    	               0x0000000000010f40 0x0000000000010f40  RW     200000
      LOAD           0x0000000000eda000 0xffffffff818da000 0x00000000018da000
    	               0x0000000000095000 0x0000000000163000  RWE    200000
      NOTE           0x0000000000713e08 0xffffffff81513e08 0x0000000001513e08
    	               0x0000000000000024 0x0000000000000024         4
    
     Section to Segment mapping:
      Segment Sections...
       00     .text .notes __ex_table .rodata __bug_table .pci_fixup __ksymtab 
          __ksymtab_gpl __ksymtab_strings __init_rodata __param __modver 
       01     .data 
       02     .vsyscall_0 .vsyscall_fn .vsyscall_1 .vsyscall_2 .vsyscall_var_jiffies 
          .vsyscall_var_vgetcpu_mode .vsyscall_var_vsyscall_gtod_data 
       03     .data..percpu 
       04     .init.text .init.data .x86_trampoline .x86_cpu_dev.init .altinstructions 
          .altinstr_replacement .iommu_table .apicdrivers .exit.text .smp_locks 
          .data_nosave .bss .brk 
       05     .notes 

> # Defining a Linux special section

# Linux 非常规节的定义

> Special sections are defined in the *Linux linker script*, which is a linker script distinct from the default linker script mentioned above. The corresponding source file is stored in the `kernel/vmlinux.ld.S` in the architecture-specific subtree. This file uses a set of macros defined in the `linux/include/asm_generic/vmlinux.lds.h` header file.

*Linux 链接器脚本* (linker script) 中定义了非常规节，它不同于上面提到的默认链接器脚本。相应的源文件存储在指定架构的子树中的 `kernel/vmlinux.ld.S` 中。此文件使用了在 `linux/include/asm_generic/vmlinux.lds.h` 头文件中定义的一组宏。

> The linker script for the ARM hardware platform contains an easy-to-follow definition of a special section:

用于 ARM 硬件平台的链接器脚本包含一个易于理解的非常规节的定义：

    . = ALIGN(4);
    __start___ex_table = .;
    *(__ex_table)
    __stop___ex_table = .;


> The `__ex_table` special section is aligned to a multiple of four bytes. Furthermore, the linker creates a pair of identifiers, namely `__start___ex_table` and `__stop___ex_table`, and sets their addresses to the beginning and the end of `__ex_table`. Linux functions can use these identifiers to iterate through the bytes of `__ex_table`. Those identifiers must be declared as `extern` because they are defined in the linker script.

`__ex_table` 非常规节 4 字节对齐。此外，链接器创建一对标识符，即 `__start___ex_table` 和 `__stop___ex_table`，并将它们的地址设置为 `__ex_table` 的起始处和末尾处。Linux 函数可以使用这些标识符来遍历 `__ex_table` 的字节码。这些标识符必须声明为 `extern`，因为它们是在链接器脚本中定义的。

> Defining and using special sections can thus be summarized as follows:
>
> * Define the special section "`.special`" in the Linux linker script together with the pair of identifiers that delimit it.
> * Insert the `.section .special` assembly directive into the Linux code to specify that all bytes up to the next `.section` assembly directive must be inserted in `.special`.
> * Use the pair of identifiers to act on those bytes in the kernel.

定义和使用非常规节可概括如下：

* 在 Linux 链接器脚本中定义非常规节 `.special`，同时定义用于分隔的标识符对。
* 在 Linux 代码中插入 `.section .special` 汇编标记，以指定下一个 `.section` 汇编标记之前的所有字节码必须插入`.special` 中。
* 使用这对标识符对内核中的那些字节码进行操作。

> This technique seems to apply to assembly code only. Luckily, the GNU C compiler offers the non-standard `attribute` construct to create special sections. The

这种技术似乎只适用于汇编代码。幸运的是，GNU C 编译器提供了非标准的 `attribute` 机制来创建非常规节。例如，

    __attribute__((__section__(".init.data")))

> declaration, for instance, tells the compiler that the code following that declaration must be inserted into the `.init.data` section. To make the code more readable, suitable macros are defined. The `__initdata` macro, for instance, is defined as:

声明告诉编译器该声明后面的代码必须插入到 `.init.data` 节中。为了使代码更具可读性可定义合适的宏。如将 `__initdata` 宏定义为：

    #define __initdata __attribute__((__section__(".init.data")))

> # Some examples

# 一些例子

> As seen in the previous `readelf` listing, all special sections appearing in the Linux kernel end up packed in one of the segments defined in the `vmlinux` ELF header. Each special section fulfills a particular purpose. The following list groups some of the Linux special sections according to the type of information stored in them. Whenever applicable, the name of the macro used in the Linux code to refer to the section is mentioned instead of the special section's name.

在前面 `readelf` 的结果中可以看到，Linux 内核中出现的所有非常规节最终都打包在 `vmlinux` ELF 的一个段中。每一个非常规节都实现了一个特定的目的。下面的列表根据存储在其中的数据信息类型对一些 Linux 非常规节进行了分类。合适的情况下，用 Linux 代码中的对应的宏来指代其非常规节的名称。

> - Binary code
> 
>   Functions invoked only during the initialization of Linux are declared as `__init` and placed in the `.init.text` section. Once the system is initialized, Linux uses the section delimiters to release the page frames allocated to that section.
>   
>   Functions declared as `__sched` are inserted into the `.sched.text` special section so that they will be skipped by the `get_wchan()` function, which is invoked when reading the `/proc/PID/wchan` file. This file contains the name of the function, if any, on which process `PID` is blocked (see [WCHAN the waiting channel ](http://weichong78.blogspot.it/2006/10/wchan-waiting-channel.html)for further details). The section delimiters bracket the sequence of addresses to be skipped. The `down_read()` function, for instance, is declared as `__sched` because it gives no helpful information on the event that is blocking the process.

* 二进制代码

  仅在 Linux 初始化期间调用的函数被声明为 `__init` 并放在 `.init.text` 节中。系统初始化后，Linux 使用节分隔符来释放分配给该节的页帧。

  声明为 `__sched` 的函数被插入到 `.sched.text` 非常规节中，这样 `get__wchan()` 函数将跳过这些函数，`get__wchan()` 函数在读取 `/proc/PID/wchan` 文件时被调用。该文件会列出导致进程 `PID` 阻塞时的函数名（更多细节请参阅 [WCHAN the waiting channel][2]）。节分隔符括起要跳过的地址序列。例如，`down_read()` 函数被声明为 `__sched`，因为它没有提供有关阻塞进程的事件的有用信息（译者注：`get__wchan()` 希望获得的是哪个函数在调用 `down_read()` 或类似的函数时进入了阻塞 ）。

> - Initialized data
> 
>   Global variables used only during the initialization of Linux are declared as `__initdata` and placed in the `.init.data` section. Once the system is initialized, Linux uses the section delimiters to release the page frames allocated to the section.
>   
>   The `EXPORT_SYMBOL()` macro makes the identifier passed as parameter accessible to kernel modules. The identifier's string constant is stored in the `__ksymtab_strings` section.

* 初始化的数据

  仅在 Linux 初始化期间使用的全局变量被声明为 `__initdata` 并放在 `.init.data` 节中。系统初始化后，Linux 使用节分隔符来释放分配给该节的页帧。

  `EXPORT__SYMBOL()` 宏使作为参数传递的标识符可供内核模块访问。标识符的字符串常量存储在 `__ksymtab_strings` 节。

> - Function pointers
> 
>   To invoke an `__init` function during the initialization phase, Linux offers an extensive set of macros (defined in `<linux/init.h>`); `module_init()` is a well-known example. Each of these macros puts a function pointer passed as its parameter in a `.initcall*i*.init` section (`__init` functions are grouped in several classes). During system initialization, Linux uses the section delimiters to successively invoke all of the functions pointed to.

* 函数指针

  为了在初始化阶段调用 `__init` 函数，Linux 提供了一组可扩展的宏（在 `<Linux/init.h>`  中定义）；`module_init()` 就是一个众所周知的例子。这些宏把作为参数传递的函数指针放在 `.initcall*i*.init` 节中（`__init` 函数分为几个类）。在系统初始化期间，Linux 使用节分隔符来连续调用其指向的所有函数。

> - Pairs of instruction pointers
> 
>   The `_ASM_EXTABLE(addr1, addr2)` macro allows the page fault exception handler to determine whether an exception was caused by a kernel instruction at address `addr1` while trying to read or write a byte into a process address space. If so, the kernel jumps to `addr2` that contains the *fixup code*, otherwise a kernel oops occurs. The delimiters of the `__ex_table` special section (see the previous linker script example) set the range of critical kernel instructions that transfer bytes from or to user space.

* 指令指针对

  `_ASM_EXTABLE(addr1，addr2)` 宏允许页面故障异常处理程序确定异常是否是由地址 `addr1` 处的内核指令引起的，同时尝试读取或写入一个字节到进程地址空间。如果是，内核跳转到包含*固定代码*的 `addr2`，否则会出现内核 Oops。`__ex_table` 非常规节（请参阅前面的链接器脚本示例）的分隔符设置了将字节码从用户空间传出或传入的关键内核指令的范围。

> - Pairs of addresses
> 
>   The `EXPORT_SYMBOL()` macro mentioned earlier also inserts in the `ksymtab` (or `ksymtab_gpl`) special section a pair of addresses: the identifier's address and the address of the corresponding string constant in `ksymtab` (or `ksymtab_gpl`). When linking a module, the special sections filled by `EXPORT_SYMBOL()` allow the kernel to do a binary search to determine whether an identifier declared as `extern` by the module belongs to the set of exported symbols.

* 地址对

  前面提到的 `EXPORT_SYMBOL()` 宏还在 `ksymtab`（或 `ksymtab_gpl`）非常规节中插入一对地址：标识符的地址和 `ksymtab`（或 `ksymtab_gpl`）中相应的字符串常量的地址。当链接一个模块时，由 `EXPORT_SYMBOL()` 填充的非常规节允许内核进行二分查找，以确定模块声明为 `extern` 的标识是否属于一组已导出的符号。

> - Relative addresses
> 
>   On SMP systems, the `DEFINE_PER_CPU(type, varname)` macro inserts the `varname` uninitialized global variable of `type` in the `.data..percpu` special section. Variables stored in that section are called *per-CPU variables*. Since `.data..percpu` is stored in a segment whose initial address is set to 0, the addresses of per-CPU variables are relative addresses. During system initialization, Linux allocates a memory area large enough to store the `NR_CPUS` groups of per-CPU variables. The section delimiters are used to determine the size of the group.

* 相对地址

  在 SMP 系统上，`DEFINE_PER_CPU(type，varname)` 宏将类型为 `type` 的未初始化的全局变量 `varname` 插入到 `.data..percpu` 非常规节中 。存储在该节中的变量称为 *per-CPU 变量*。由于 `.data..percpu` 存储在初始地址设置为 0 的段中，因此 per-CPU 变量的地址都是相对地址。在系统初始化期间，Linux 分配足够大的内存区域来存储`NR_CPUS` 组 per-CPU 变量 。节分隔符用于确定组的大小。

> - Structures
> 
>   The kernel's [SMP alternatives](https://lwn.net/Articles/164121/) mechanism allows a single kernel to be built optimally for multiple versions of a given processor architecture. Through the magic of boot-time code patching, advanced instructions can be exploited if, and only if, the system's processor is able to execute those instructions. This mechanism is controlled with the `alternative()` macro:
>   
>       alternative(oldinstr, newinstr, feature);
>   
>   This macro first stores `oldinstr` in the `.text` regular section. It then stores in the `.altinstructions` special section a structure that includes the following fields: the address of the `oldinstr`, the address of the `newinstr`, the `feature` flags, the length of the `oldinstr`, and the length of the `newinstr`. It stores `newinstr` in a `.altinstr_replacement` special section. Early in the boot process, every alternative instruction which is supported by the running processor is patched directly into the loaded kernel image; it will be filled with no-op instructions if need be.

* 结构体

  内核 [SMP alternatives][3] 提供了 “一次内核优化构建可提供给多个给定处理器架构的版本使用” 的机制。通过引导时间的代码修补魔术，高级指令当且仅当系统的处理器可被执行时才会被真正释放。此机制由 `alternative()` 宏控制：

      alternative(oldinstr, newinstr, feature);

  该宏首先将 `oldinstr` 存储在 `.text` 常规节中。接着在 `altinstructions` 非常规节的一个结构体中，存储以下字段：`oldinstr` 的地址，`newinstr` 的地址，`feature` 标记，`oldinstr` 的长度以及 `newinstr` 的长度。它将 `newinstr` 存储在 `.altinstr_replacement` 非常规节中。在启动过程的早期，被当前运行的处理器支持的每个替代指令都直接修补到了已加载的内核映像中；如果需要，将会填充 no-op 指令。

> Additional special sections, besides `__ksymtab` and `__ksymtab_strings`, are introduced to handle modules. Kernel objects of the form `*.ko` have an ELF relocatable format and the ELF header of such files defines a pair of special sections called `.modinfo` and `.gnu.linkonce.this_module`. Unlike the special sections of the static kernel, these two sections are "address-less" because kernel objects do not contain segments.

除了 `_ksymtab` 和 `_ksymtab_strings` 之外，还引入了其他非常规节来处理模块。内核目标文件 `*.ko` 具有 ELF 可重定位格式，此类文件的 ELF 头定义了一对非常规节，称为 `.modinfo` 和 `.gnu.linkonce.this_module`。与静态内核的非常规节不同，这两个部分 “无地址”，因为内核目标文件不包含段。

> The `.modinfo` section is used by the `modinfo` command to show information about the kernel module. The data stored in the section is not loaded in the kernel address space. The `.gnu.linkonce.this_module` special section includes a `module` structure which contains, among other fields, the module's name. When inserting a module, the `init_module()` system call reads the `module` structure from this special section into an area of dynamic memory.

 `.modinfo` 非常规节能被`modinfo` 命令解析来显示有关内核模块的信息。存储在该节中的数据不会加载到内核地址空间中。`.gnu.linkone.this_module` 非常规节包含一个 `module` 结构，其中包含模块名称等字段。插入模块时，`init_module()` 系统调用会将这个非常规节的 `module` 结构体读取到动态内存区域。

> # Conclusion

# 小结

> Although special sections can be defined in application programs too, there is no doubt that kernel developers have been quite creative in exploiting them. In fact, the examples listed above are by no means exhaustive and new special sections keep popping up in recent kernel releases. Without special sections, implementing some kernel features like those above would be rather difficult.

尽管也可以在应用程序中定义非常规节，但毫无疑问，内核开发人员非常有创意地利用了非常规节。事实上，上面列出的例子绝不是详尽无遗的，新的非常规节在最近的内核版本中不断涌现。如果没有非常规节，实现一些像上面这样的内核特性将相当困难。

[1]: http://en.wikipedia.org/wiki/Executable_and_Linkable_Format
[2]: http://weichong78.blogspot.it/2006/10/wchan-waiting-channel.html
[3]: https://lwn.net/Articles/164121/